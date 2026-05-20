#!/usr/bin/env bash
# blocker-discipline-tick-chain.sh
# flywheel-cli-surface: true
#
# Orchestration chain that ties together the 4 blocker-discipline
# primitives into a single per-tick invocation:
#
#   1. blocker-ac-tick-cadence.sh tick (e4ulf)
#      → bumps tick counter; fires flywheel_replay_verify --blocker-ac
#        on stale blockers at Nth-tick cadence; records audit log.
#
#   2. blocker-auto-close.sh scan (nbgp6)
#      → for each open blocker whose AC passes, append blocker_auto_closed
#        row to escalations.jsonl + mutate blocker file (status=closed).
#        Idempotent: re-applies are no-ops on already-closed blockers.
#
#   3. blocker-fail-escalator.sh scan (ukbej)
#      → for each open blocker whose AC fails, increment per-blocker fail
#        counter; if counter reaches threshold N, append
#        blocker_ac_failed_escalated row to escalations.jsonl + send
#        Agent Mail (best-effort) + reset counter (fresh streak).
#        Counter reset on PASS handled by ukbej itself.
#
# Each step is independently idempotent. Chain orchestration just
# sequences them. First-stage failure does NOT halt the chain — auto-close
# and fail-escalator are independent of tick-cadence's outcome (they read
# blockers directly from the dir).
#
# Bead: flywheel-yy9qi (combined wire-in: 4 primitives → 1 chain).
#
# Modes:
#   tick                : run all 3 stages (default)
#   doctor              : probe all 4 primitives + state dirs
#   validate            : verify chain wiring is functional
#   audit               : tail composite audit log
#
# Bypass: --skip-stage <name> for surgical partial runs
#         (e.g. --skip-stage tick-cadence to re-run just close+escalator).

set -euo pipefail

SCHEMA_VERSION="blocker-discipline-tick-chain/v1"
VERSION="0.1.0"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"

BLOCKERS_DIR="${BLOCKER_DISCIPLINE_BLOCKERS_DIR:-$REPO_ROOT/.flywheel/state/blockers}"
ESCALATIONS_LOG="${BLOCKER_DISCIPLINE_ESCALATIONS_LOG:-$REPO_ROOT/.flywheel/state/escalations.jsonl}"
COUNTER_DIR="${BLOCKER_DISCIPLINE_COUNTER_DIR:-$HOME/.local/state/flywheel/blocker-fail-counts}"
TICK_CADENCE_BIN="${BLOCKER_DISCIPLINE_TICK_CADENCE_BIN:-$REPO_ROOT/.flywheel/scripts/blocker-ac-tick-cadence.sh}"
AUTO_CLOSE_BIN="${BLOCKER_DISCIPLINE_AUTO_CLOSE_BIN:-$REPO_ROOT/.flywheel/scripts/blocker-auto-close.sh}"
FAIL_ESCALATOR_BIN="${BLOCKER_DISCIPLINE_FAIL_ESCALATOR_BIN:-$REPO_ROOT/.flywheel/scripts/blocker-fail-escalator.sh}"
REPLAY_VERIFY_BIN="${BLOCKER_DISCIPLINE_REPLAY_VERIFY_BIN:-$REPO_ROOT/.flywheel/scripts/flywheel_replay_verify.py}"
THRESHOLD_N="${BLOCKER_DISCIPLINE_THRESHOLD_N:-4}"
SKIP_AGENT_MAIL="${BLOCKER_DISCIPLINE_SKIP_AGENT_MAIL:-0}"

JSON_OUT=0
APPLY=0
MODE=""
SKIP_STAGES=""

usage() {
  cat <<'USAGE'
blocker-discipline-tick-chain.sh — orchestrate AC re-evaluation +
auto-close + fail-escalator per blocker-discipline doctrine.

USAGE:
  blocker-discipline-tick-chain.sh tick [--apply] [--json] [--skip-stage NAME]
  blocker-discipline-tick-chain.sh doctor [--json]
  blocker-discipline-tick-chain.sh validate [--json]
  blocker-discipline-tick-chain.sh audit [--tail N] [--json]
  blocker-discipline-tick-chain.sh --info|--examples|--schema|--help [--json]

OPTIONS:
  --apply               Mutate (default: dry-run). Each stage runs in
                        --apply mode when this flag is set.
  --json                Emit JSON envelope (default: text)
  --skip-stage NAME     Skip a stage. Repeatable. Names: tick-cadence |
                        auto-close | fail-escalator
  --blockers-dir DIR    Override default .flywheel/state/blockers/
  --escalations-log P   Override default escalations.jsonl path
  --counter-dir DIR     Override default fail-counter dir

ENV OVERRIDES:
  BLOCKER_DISCIPLINE_THRESHOLD_N        (default 4)
  BLOCKER_DISCIPLINE_SKIP_AGENT_MAIL=1  (skip Agent Mail send)

EXIT CODES:
  0 all stages clean | 1 one or more stages failed
  2 usage | 3 not-applicable (substrate missing)
USAGE
}

emit_info() {
  jq -nc \
    --arg sv "$SCHEMA_VERSION" \
    --arg v "$VERSION" \
    --arg br "$BLOCKERS_DIR" \
    --arg el "$ESCALATIONS_LOG" \
    --arg cd "$COUNTER_DIR" \
    --arg tc "$TICK_CADENCE_BIN" \
    --arg ac "$AUTO_CLOSE_BIN" \
    --arg fe "$FAIL_ESCALATOR_BIN" \
    --arg rv "$REPLAY_VERIFY_BIN" \
    --argjson n "$THRESHOLD_N" \
    '{
      schema_version:$sv,
      name:"blocker-discipline-tick-chain.sh",
      version:$v,
      doctrine:".flywheel/doctrine/blocker-discipline.md",
      stages:["tick-cadence","auto-close","fail-escalator"],
      primitives:{
        replay_verify:$rv,
        tick_cadence:$tc,
        auto_close:$ac,
        fail_escalator:$fe
      },
      paths:{
        blockers_dir:$br,
        escalations_log:$el,
        counter_dir:$cd
      },
      threshold_n:$n,
      mutation_default:"dry-run",
      modes:["tick","doctor","validate","audit"],
      stage_idempotency:"each stage is independently idempotent; chain runs all 3 sequentially without halting on individual failures",
      exit_codes:{"0":"clean","1":"stage_failed","2":"usage","3":"substrate_missing"}
    }'
}

emit_examples() {
  jq -nc '{examples:[
    "blocker-discipline-tick-chain.sh tick --json",
    "blocker-discipline-tick-chain.sh tick --apply --json",
    "blocker-discipline-tick-chain.sh tick --apply --skip-stage tick-cadence --json",
    "blocker-discipline-tick-chain.sh doctor --json",
    "blocker-discipline-tick-chain.sh validate --json",
    "blocker-discipline-tick-chain.sh audit --tail 5 --json"
  ]}'
}

emit_schema() {
  jq -nc \
    --arg sv "$SCHEMA_VERSION" \
    '{
      "$schema":"https://json-schema.org/draft/2020-12/schema",
      schema_version:$sv,
      title:"blocker-discipline-tick-chain envelope",
      "$defs":{
        envelope:{
          type:"object",
          required:["schema_version","mode","status","stages"],
          properties:{
            schema_version:{const:$sv},
            mode:{enum:["tick","doctor","validate","audit"]},
            status:{enum:["clean","stage_failed","substrate_missing","skipped","unknown"]},
            apply:{type:"boolean"},
            stages:{
              type:"object",
              properties:{
                "tick-cadence":{type:"object"},
                "auto-close":{type:"object"},
                "fail-escalator":{type:"object"}
              }
            },
            summary:{
              type:"object",
              properties:{
                blockers_total:{type:"integer"},
                ac_fired:{type:"integer"},
                auto_closed:{type:"integer"},
                escalated:{type:"integer"},
                ac_pure_mismatch:{type:"integer"},
                stages_failed:{type:"integer"}
              }
            }
          }
        }
      }
    }'
}

# ---------- helpers ----------

now_iso() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }

stage_skipped() {
  local name="$1"
  case ",$SKIP_STAGES," in
    *,$name,*) return 0 ;;
    *) return 1 ;;
  esac
}

# Run a stage and capture its JSON output. Returns rc.
run_stage() {
  local stage_name="$1"; shift
  local out rc=0
  set +e
  out="$("$@" 2>&1)"
  rc=$?
  set -e
  # If output isn't valid JSON, wrap it as raw
  if ! jq -e . >/dev/null 2>&1 <<<"$out"; then
    out="$(jq -nc --arg raw "$out" --argjson rc "$rc" --arg s "$stage_name" \
      '{stage:$s,raw:$raw,exit_code:$rc}')"
  fi
  printf '%s' "$out"
  return "$rc"
}

# ---------- modes ----------

cmd_doctor() {
  local checks_jsonl="" overall="ok"
  _add() {
    local n="$1" s="$2" d="$3"
    [[ "$s" == "fail" ]] && overall="fail"
    checks_jsonl+="$(jq -nc --arg c "$n" --arg s "$s" --arg d "$d" '{check:$c,status:$s,detail:$d}')"$'\n'
  }

  for prim_var in TICK_CADENCE_BIN AUTO_CLOSE_BIN FAIL_ESCALATOR_BIN REPLAY_VERIFY_BIN; do
    local p="${!prim_var}"
    local label
    label="$(printf '%s' "$prim_var" | tr '[:upper:]' '[:lower:]')"
    if [[ -x "$p" ]] || [[ -r "$p" && "$p" == *.py ]]; then
      _add "$label" ok "$p"
    else
      _add "$label" fail "missing or not executable: $p"
    fi
  done

  # Blockers dir + counter dir + escalations log dir creatable
  if [[ -d "$BLOCKERS_DIR" && -r "$BLOCKERS_DIR" ]]; then
    _add blockers_dir ok "$BLOCKERS_DIR"
  elif [[ ! -e "$BLOCKERS_DIR" ]]; then
    _add blockers_dir warn "absent (will be created on first blocker file): $BLOCKERS_DIR"
  else
    _add blockers_dir fail "exists but not readable: $BLOCKERS_DIR"
  fi

  local elog_dir
  elog_dir="$(dirname -- "$ESCALATIONS_LOG")"
  if [[ -d "$elog_dir" && -w "$elog_dir" ]]; then
    _add escalations_log_dir ok "$elog_dir"
  elif [[ ! -e "$elog_dir" ]]; then
    _add escalations_log_dir warn "absent (will be created on first escalation): $elog_dir"
  else
    _add escalations_log_dir fail "exists but not writable: $elog_dir"
  fi

  if [[ -d "$COUNTER_DIR" && -w "$COUNTER_DIR" ]]; then
    _add counter_dir ok "$COUNTER_DIR"
  elif [[ ! -e "$COUNTER_DIR" ]]; then
    _add counter_dir warn "absent (will be created on first fail): $COUNTER_DIR"
  else
    _add counter_dir fail "exists but not writable: $COUNTER_DIR"
  fi

  printf '%s' "$checks_jsonl" | jq -sc \
    --arg sv "$SCHEMA_VERSION" --arg ts "$(now_iso)" --arg status "$overall" \
    '{schema_version:$sv,mode:"doctor",ts:$ts,status:$status,checks:.}'
  [[ "$overall" == "ok" ]] && return 0 || return 3
}

cmd_validate() {
  local pass=0 fail=0 results_jsonl=""
  _check() {
    local name="$1" cmd="$2"
    if eval "$cmd" >/dev/null 2>&1; then
      pass=$((pass + 1))
      results_jsonl+="$(jq -nc --arg c "$name" --arg s "ok" '{check:$c,status:$s}')"$'\n'
    else
      fail=$((fail + 1))
      results_jsonl+="$(jq -nc --arg c "$name" --arg s "fail" '{check:$c,status:$s}')"$'\n'
    fi
  }

  _check tick_cadence_help "[[ -x '$TICK_CADENCE_BIN' ]] && '$TICK_CADENCE_BIN' --help"
  _check auto_close_info "[[ -x '$AUTO_CLOSE_BIN' ]] && '$AUTO_CLOSE_BIN' --info"
  _check fail_escalator_info "[[ -x '$FAIL_ESCALATOR_BIN' ]] && '$FAIL_ESCALATOR_BIN' --info"
  _check replay_verify_help "python3 '$REPLAY_VERIFY_BIN' --help"

  local status="ok"
  [[ "$fail" -gt 0 ]] && status="fail"
  printf '%s' "$results_jsonl" | jq -sc \
    --arg sv "$SCHEMA_VERSION" --arg status "$status" \
    --argjson p "$pass" --argjson f "$fail" \
    '{schema_version:$sv,mode:"validate",status:$status,pass:$p,fail:$f,checks:.}'
  [[ "$fail" -eq 0 ]] && return 0 || return 1
}

cmd_audit() {
  local tail_n=10
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --tail) tail_n="${2:-10}"; shift 2 ;;
      --tail=*) tail_n="${1#--tail=}"; shift ;;
      *) shift ;;
    esac
  done

  local rows="[]"
  if [[ -f "$ESCALATIONS_LOG" ]]; then
    rows="$(tail -n "$tail_n" "$ESCALATIONS_LOG" 2>/dev/null | jq -sc '.' 2>/dev/null || printf '[]')"
  fi
  jq -nc \
    --arg sv "$SCHEMA_VERSION" --arg log "$ESCALATIONS_LOG" \
    --argjson tn "$tail_n" --argjson rows "$rows" \
    '{schema_version:$sv,mode:"audit",escalations_log:$log,tail_n:$tn,rows:$rows,row_count:($rows | length)}'
}

cmd_tick() {
  local apply_flag=()
  [[ "$APPLY" -eq 1 ]] && apply_flag=("--apply")

  local stages_failed=0
  local tick_cadence_out="null"
  local auto_close_out="null"
  local fail_escalator_out="null"

  # Stage 1: tick-cadence
  if stage_skipped "tick-cadence"; then
    tick_cadence_out="$(jq -nc '{skipped:true,stage:"tick-cadence"}')"
  else
    if [[ -x "$TICK_CADENCE_BIN" ]]; then
      tick_cadence_out="$(run_stage tick-cadence "$TICK_CADENCE_BIN" tick --json "${apply_flag[@]}" 2>/dev/null)"
      local rc=$?
      [[ "$rc" -ne 0 ]] && stages_failed=$((stages_failed + 1))
    else
      tick_cadence_out="$(jq -nc --arg p "$TICK_CADENCE_BIN" '{stage:"tick-cadence",error:"binary missing",path:$p}')"
      stages_failed=$((stages_failed + 1))
    fi
  fi

  # Stage 2: auto-close scan
  if stage_skipped "auto-close"; then
    auto_close_out="$(jq -nc '{skipped:true,stage:"auto-close"}')"
  else
    if [[ -x "$AUTO_CLOSE_BIN" ]]; then
      auto_close_out="$(run_stage auto-close "$AUTO_CLOSE_BIN" scan --json --blockers-dir "$BLOCKERS_DIR" --escalations-log "$ESCALATIONS_LOG" "${apply_flag[@]}" 2>/dev/null)"
      # Note: scan returns 0 even with mixed verdicts; only "warn" if errors > 0.
    else
      auto_close_out="$(jq -nc --arg p "$AUTO_CLOSE_BIN" '{stage:"auto-close",error:"binary missing",path:$p}')"
      stages_failed=$((stages_failed + 1))
    fi
  fi

  # Stage 3: fail-escalator scan
  if stage_skipped "fail-escalator"; then
    fail_escalator_out="$(jq -nc '{skipped:true,stage:"fail-escalator"}')"
  else
    if [[ -x "$FAIL_ESCALATOR_BIN" ]]; then
      local sam_args=()
      [[ "$SKIP_AGENT_MAIL" == "1" ]] && sam_args=(--skip-agent-mail)
      # Export env vars before run_stage; K=V prefix doesn't propagate
      # through function-arg expansion (run_stage tries to exec the K=V
      # token as a command name).
      export BLOCKER_FAIL_ESCALATOR_THRESHOLD_N="$THRESHOLD_N"
      export BLOCKER_FAIL_ESCALATOR_SKIP_AGENT_MAIL="$SKIP_AGENT_MAIL"
      fail_escalator_out="$(run_stage fail-escalator "$FAIL_ESCALATOR_BIN" scan --json --blockers-dir "$BLOCKERS_DIR" --escalations-log "$ESCALATIONS_LOG" --counter-dir "$COUNTER_DIR" --threshold-n "$THRESHOLD_N" "${apply_flag[@]}" "${sam_args[@]}" 2>/dev/null)"
    else
      fail_escalator_out="$(jq -nc --arg p "$FAIL_ESCALATOR_BIN" '{stage:"fail-escalator",error:"binary missing",path:$p}')"
      stages_failed=$((stages_failed + 1))
    fi
  fi

  # Compose summary by introspecting each stage's output.
  local blockers_total ac_fired auto_closed escalated mismatch
  blockers_total="$(jq -r '(.blocker_count // 0) // 0' <<<"$tick_cadence_out" 2>/dev/null || printf '0')"
  ac_fired="$(jq -r '(.fired // 0) // 0' <<<"$tick_cadence_out" 2>/dev/null || printf '0')"
  auto_closed="$(jq -r '(.closed // 0) // 0' <<<"$auto_close_out" 2>/dev/null || printf '0')"
  escalated="$(jq -r '(.escalated // 0) // 0' <<<"$fail_escalator_out" 2>/dev/null || printf '0')"
  mismatch="$(jq -r '[(.results // [])[] | select(.status == "ac_pure_mismatch")] | length' <<<"$fail_escalator_out" 2>/dev/null || printf '0')"

  local status
  if [[ "$stages_failed" -gt 0 ]]; then status="stage_failed"; else status="clean"; fi

  local apply_bool="false"
  [[ "$APPLY" -eq 1 ]] && apply_bool="true"

  jq -nc \
    --arg sv "$SCHEMA_VERSION" \
    --arg ts "$(now_iso)" \
    --arg status "$status" \
    --argjson apply "$apply_bool" \
    --argjson tc "$tick_cadence_out" \
    --argjson ac "$auto_close_out" \
    --argjson fe "$fail_escalator_out" \
    --argjson bt "${blockers_total:-0}" \
    --argjson af "${ac_fired:-0}" \
    --argjson acl "${auto_closed:-0}" \
    --argjson esc "${escalated:-0}" \
    --argjson mm "${mismatch:-0}" \
    --argjson sf "$stages_failed" \
    '{schema_version:$sv,mode:"tick",ts:$ts,status:$status,apply:$apply,
      stages:{"tick-cadence":$tc,"auto-close":$ac,"fail-escalator":$fe},
      summary:{blockers_total:$bt,ac_fired:$af,auto_closed:$acl,escalated:$esc,ac_pure_mismatch:$mm,stages_failed:$sf}}'

  [[ "$stages_failed" -eq 0 ]] && return 0 || return 1
}

# ---------- main ----------

while [[ $# -gt 0 ]]; do
  case "$1" in
    --info) emit_info; exit 0 ;;
    --examples) emit_examples; exit 0 ;;
    --schema) emit_schema; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    --json) JSON_OUT=1; shift ;;
    --apply) APPLY=1; shift ;;
    --skip-stage) SKIP_STAGES="${SKIP_STAGES},${2:-}"; shift 2 ;;
    --skip-stage=*) SKIP_STAGES="${SKIP_STAGES},${1#--skip-stage=}"; shift ;;
    --blockers-dir) BLOCKERS_DIR="${2:-}"; shift 2 ;;
    --escalations-log) ESCALATIONS_LOG="${2:-}"; shift 2 ;;
    --counter-dir) COUNTER_DIR="${2:-}"; shift 2 ;;
    --threshold-n) THRESHOLD_N="${2:-}"; shift 2 ;;
    --tail) TAIL_N="${2:-10}"; shift 2 ;;
    tick|doctor|validate|audit) MODE="$1"; shift ;;
    --) shift; break ;;
    *) echo "ERR: unknown arg: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -z "$MODE" ]] && { echo "ERR: mode required" >&2; usage >&2; exit 2; }

case "$MODE" in
  tick)
    set +e
    out="$(cmd_tick)"
    rc=$?
    set -e
    if [[ "$JSON_OUT" -eq 1 ]]; then
      printf '%s\n' "$out"
    else
      jq -r '"\(.status) ac_fired=\(.summary.ac_fired) auto_closed=\(.summary.auto_closed) escalated=\(.summary.escalated) mismatch=\(.summary.ac_pure_mismatch) failed=\(.summary.stages_failed)"' <<<"$out"
    fi
    exit "$rc"
    ;;
  doctor)
    set +e
    out="$(cmd_doctor)"
    rc=$?
    set -e
    if [[ "$JSON_OUT" -eq 1 ]]; then
      printf '%s\n' "$out"
    else
      jq -r '"\(.status) checks=\([.checks[] | .check + ":" + .status] | join(","))"' <<<"$out"
    fi
    exit "$rc"
    ;;
  validate)
    set +e
    out="$(cmd_validate)"
    rc=$?
    set -e
    if [[ "$JSON_OUT" -eq 1 ]]; then
      printf '%s\n' "$out"
    else
      jq -r '"\(.status) pass=\(.pass) fail=\(.fail)"' <<<"$out"
    fi
    exit "$rc"
    ;;
  audit)
    out="$(cmd_audit ${TAIL_N:+--tail "$TAIL_N"})"
    if [[ "$JSON_OUT" -eq 1 ]]; then
      printf '%s\n' "$out"
    else
      jq -r '"audit log=\(.escalations_log) tail_n=\(.tail_n) rows=\(.row_count)"' <<<"$out"
    fi
    exit 0
    ;;
esac

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
