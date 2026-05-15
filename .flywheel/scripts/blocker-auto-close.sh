#!/usr/bin/env bash
# blocker-auto-close.sh — auto-close hook per blocker-discipline doctrine.
#
# When a blocker's acceptance_condition (AC) passes, this hook:
#   1. Captures the live-probe evidence (exact command, stdout, exit code).
#   2. Appends a blocker_auto_closed row to escalations.jsonl per the
#      doctrine schema (ts, event, blocker_id, ac_command, ac_stdout,
#      ac_exit_code, live_probe_at, previous_last_verified_at,
#      delta_seconds, auto_closer).
#   3. Updates the blocker JSON file with status=closed + audit metadata
#      (closed_at, closed_by, closed_reason, live_probe_evidence_ref).
#
# Bead: flywheel-nbgp6 (blocker-ac-followup-1).
# Doctrine: .flywheel/doctrine/blocker-discipline.md "Live-probe evidence shape".
# Source primitives:
#   - .flywheel/scripts/flywheel_replay_verify.py (5m9gp) — AC purity check
#   - .flywheel/scripts/blocker-ac-tick-cadence.sh (e4ulf) — Nth-tick firing
#
# Modes:
#   close --blocker-file PATH  : single-blocker auto-close attempt
#   scan [--blockers-dir PATH] : iterate all blockers in dir, attempt close
#
# Exit codes (canonical-cli-scoping universal taxonomy):
#   0  PASS (closed successfully OR no-close-needed clean run)
#   1  MISMATCH / refused (AC says still blocked; surface refuse-envelope)
#   2  usage / bad input
#   3  not-applicable (blocker file missing, malformed, or already closed)

set -euo pipefail

SCHEMA_VERSION="blocker-auto-close/v1"
ESCALATION_SCHEMA="blocker-escalation/v1"
VERSION="0.1.0"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
BLOCKERS_DIR_DEFAULT="$REPO_ROOT/.flywheel/state/blockers"
ESCALATIONS_LOG_DEFAULT="$REPO_ROOT/.flywheel/state/escalations.jsonl"
REPLAY_VERIFY_DEFAULT="$REPO_ROOT/.flywheel/scripts/flywheel_replay_verify.py"

# Defaults overridable via env
BLOCKERS_DIR="${BLOCKER_AUTO_CLOSE_BLOCKERS_DIR:-$BLOCKERS_DIR_DEFAULT}"
ESCALATIONS_LOG="${BLOCKER_AUTO_CLOSE_ESCALATIONS_LOG:-$ESCALATIONS_LOG_DEFAULT}"
REPLAY_VERIFY="${BLOCKER_AUTO_CLOSE_REPLAY_VERIFY:-$REPLAY_VERIFY_DEFAULT}"
AUTO_CLOSER_ID="${BLOCKER_AUTO_CLOSE_CLOSER_ID:-orch:auto}"

JSON_OUT=0
APPLY=0
BLOCKER_FILE=""
MODE=""
declare -a BLOCKER_AUTO_CLOSE_TEMP_FILES=()

register_temp_file() {
  BLOCKER_AUTO_CLOSE_TEMP_FILES+=("$1")
}

cleanup_temp_files() {
  local tmp
  for tmp in "${BLOCKER_AUTO_CLOSE_TEMP_FILES[@]}"; do
    [[ -n "$tmp" ]] || continue
    rm -f "$tmp"
  done
  return 0
}

trap cleanup_temp_files EXIT ERR

usage() {
  cat <<'USAGE'
blocker-auto-close.sh — auto-close hook per blocker-discipline doctrine

USAGE:
  blocker-auto-close.sh close --blocker-file PATH [--apply] [--json]
  blocker-auto-close.sh scan [--blockers-dir DIR] [--apply] [--json]
  blocker-auto-close.sh doctor|--doctor [--json]
  blocker-auto-close.sh --info|--examples|--schema|--help [--json]

OPTIONS:
  --blocker-file PATH    Path to blocker JSON file
  --blockers-dir DIR     Directory to scan for blocker JSONs (default: .flywheel/state/blockers/)
  --escalations-log P    Override path to escalations.jsonl (default: .flywheel/state/escalations.jsonl)
  --replay-verify P      Override path to flywheel_replay_verify.py
  --apply                Append to escalations.jsonl + mutate blocker file
                         (default: dry-run, no mutation)
  --json                 Emit JSON output (default: text)

ENVELOPE (per invocation):
  schema_version: blocker-auto-close/v1
  status: closed | not_closed_ac_failed | not_closed_already_closed | dry_run | error
  blocker_id, ac_verdict, ac_passes_now
  live_probe_evidence: { ac_command, ac_stdout, ac_exit_code, ... }
  escalation_row: <appended row if --apply>

EXIT CODES:
  0 closed | clean | dry_run    1 AC failed (refused)
  2 usage                       3 not-applicable
USAGE
}

emit_info() {
  jq -nc \
    --arg sv "$SCHEMA_VERSION" \
    --arg ev "$ESCALATION_SCHEMA" \
    --arg v "$VERSION" \
    --arg br "$BLOCKERS_DIR" \
    --arg el "$ESCALATIONS_LOG" \
    --arg rv "$REPLAY_VERIFY" \
    --arg c "$AUTO_CLOSER_ID" \
    '{
      schema_version:$sv,
      escalation_schema:$ev,
      name:"blocker-auto-close.sh",
      version:$v,
      doctrine:".flywheel/doctrine/blocker-discipline.md",
      primitives:{
        replay_verify:$rv,
        tick_cadence:".flywheel/scripts/blocker-ac-tick-cadence.sh"
      },
      paths:{
        blockers_dir:$br,
        escalations_log:$el
      },
      auto_closer_id:$c,
      mutation_default:"dry-run",
      modes:["close","scan"],
      escalation_row_fields:["schema_version","ts","event","blocker_id","ac_command","ac_stdout","ac_exit_code","live_probe_at","previous_last_verified_at","delta_seconds","auto_closer","ac_state_hash"],
      exit_codes:{"0":"closed_or_clean","1":"ac_failed","2":"usage","3":"not_applicable"}
    }'
}

emit_examples() {
  jq -nc '{examples:[
    "blocker-auto-close.sh close --blocker-file .flywheel/state/blockers/foo.json --json",
    "blocker-auto-close.sh close --blocker-file foo.json --apply --json",
    "blocker-auto-close.sh scan --blockers-dir .flywheel/state/blockers --json",
    "blocker-auto-close.sh scan --apply --json",
    "BLOCKER_AUTO_CLOSE_CLOSER_ID=orch:flywheel:1 blocker-auto-close.sh close --blocker-file b.json --apply"
  ]}'
}

emit_schema() {
  jq -nc \
    --arg sv "$SCHEMA_VERSION" \
    --arg ev "$ESCALATION_SCHEMA" \
    '{
      "$schema":"https://json-schema.org/draft/2020-12/schema",
      schema_version:$sv,
      title:"blocker-auto-close envelope + escalation row schemas",
      "$defs":{
        envelope:{
          type:"object",
          required:["schema_version","status","blocker_id"],
          properties:{
            schema_version:{const:$sv},
            status:{enum:["closed","not_closed_ac_failed","not_closed_already_closed","dry_run","error"]},
            blocker_id:{type:"string"},
            ac_verdict:{enum:["PASS","MISMATCH","unknown"]},
            ac_passes_now:{type:"boolean"},
            live_probe_evidence:{type:"object"},
            escalation_row:{type:["object","null"]},
            escalations_log_path:{type:"string"}
          }
        },
        escalation_row:{
          type:"object",
          required:["schema_version","ts","event","blocker_id","ac_command","ac_stdout","ac_exit_code","live_probe_at","previous_last_verified_at","delta_seconds","auto_closer"],
          properties:{
            schema_version:{const:$ev},
            ts:{type:"string"},
            event:{enum:["blocker_auto_closed","blocker_manually_closed"]},
            blocker_id:{type:"string"},
            ac_command:{type:"string"},
            ac_stdout:{type:"string"},
            ac_exit_code:{type:"integer"},
            live_probe_at:{type:"string"},
            previous_last_verified_at:{type:["string","null"]},
            delta_seconds:{type:["integer","null"]},
            auto_closer:{type:"string"},
            ac_state_hash:{type:["string","null"]}
          }
        }
      }
    }'
}

doctor_check() {
  local name="$1" status="$2" detail="$3"
  jq -nc --arg name "$name" --arg status "$status" --arg detail "$detail" \
    '{name:$name,status:$status,detail:$detail}'
}

emit_doctor() {
  local checks=()
  local status="pass"

  if command -v jq >/dev/null 2>&1; then
    checks+=("$(doctor_check "jq_available" "pass" "$(command -v jq)")")
  else
    printf '{"schema_version":"blocker-auto-close.doctor.v1","command":"doctor","status":"fail","mode":"read_only","mutates":false,"checks":[{"name":"jq_available","status":"fail","detail":"jq not found"}]}\n'
    return 1
  fi

  if command -v python3 >/dev/null 2>&1; then
    checks+=("$(doctor_check "python3_available" "pass" "$(command -v python3)")")
  else
    checks+=("$(doctor_check "python3_available" "fail" "python3 not found")")
    status="fail"
  fi

  if [[ -r "$REPLAY_VERIFY" ]]; then
    checks+=("$(doctor_check "replay_verify_readable" "pass" "$REPLAY_VERIFY")")
  else
    checks+=("$(doctor_check "replay_verify_readable" "fail" "$REPLAY_VERIFY")")
    status="fail"
  fi

  if [[ -d "$BLOCKERS_DIR" ]]; then
    checks+=("$(doctor_check "blockers_dir_available" "pass" "$BLOCKERS_DIR")")
  else
    checks+=("$(doctor_check "blockers_dir_available" "warn" "$BLOCKERS_DIR missing; scan mode will be not-applicable")")
    [[ "$status" == "pass" ]] && status="warn"
  fi

  local escalation_parent
  escalation_parent="$(dirname "$ESCALATIONS_LOG")"
  if [[ -d "$escalation_parent" ]]; then
    checks+=("$(doctor_check "escalations_parent_available" "pass" "$escalation_parent")")
  else
    checks+=("$(doctor_check "escalations_parent_available" "warn" "$escalation_parent missing until --apply creates it")")
    [[ "$status" == "pass" ]] && status="warn"
  fi

  checks+=("$(doctor_check "mutation_default_dry_run" "pass" "--apply is required before blocker/escalation mutation")")
  checks+=("$(doctor_check "doctor_read_only" "pass" "doctor does not evaluate acceptance_condition commands and writes no blocker or escalation files")")

  printf '%s\n' "${checks[@]}" | jq -s \
    --arg sv "$SCHEMA_VERSION" \
    --arg status "$status" \
    --arg blockers_dir "$BLOCKERS_DIR" \
    --arg escalations_log "$ESCALATIONS_LOG" \
    --arg replay_verify "$REPLAY_VERIFY" \
    '{schema_version:"blocker-auto-close.doctor.v1",command:"doctor",status:$status,mode:"read_only",mutates:false,blocker_schema_version:$sv,blockers_dir:$blockers_dir,escalations_log:$escalations_log,replay_verify:$replay_verify,checks:.}'

  [[ "$status" == "fail" ]] && return 1 || return 0
}

# ---------- helpers ----------

now_iso() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }

# Convert ISO8601 UTC to epoch seconds.
iso_to_epoch() {
  local iso="$1"
  [[ -z "$iso" ]] && { printf '\n'; return; }
  if date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$iso" '+%s' 2>/dev/null; then
    return
  fi
  date -u -d "$iso" '+%s' 2>/dev/null || printf '\n'
}

# Try AC twice via flywheel_replay_verify; return JSON envelope.
run_ac_verify() {
  local blocker_file="$1"
  local out rc=0
  out="$(python3 "$REPLAY_VERIFY" blocker-ac --json --blocker-file "$blocker_file" 2>&1)" || rc=$?
  if jq -e . >/dev/null 2>&1 <<<"$out"; then
    printf '%s\n' "$out"
  else
    jq -nc --arg raw "$out" --argjson rc "$rc" \
      '{verdict:"unknown",ac_pure:false,ac_passes_now:false,replay_verify_rc:$rc,raw:$raw}'
  fi
  return 0
}

# Run the AC command directly (single invocation, capture exit + stdout).
# Used to capture the live-probe evidence for the escalation row.
run_ac_live_probe() {
  local ac_command="$1"
  local timeout_s="${2:-10}"
  local tmpout
  tmpout="$(mktemp "${TMPDIR:-/tmp}/blocker-ac-stdout.XXXXXX")"
  register_temp_file "$tmpout"
  local rc=0
  if command -v timeout >/dev/null 2>&1; then
    timeout "$timeout_s" bash -c "$ac_command" >"$tmpout" 2>&1 || rc=$?
  else
    # macOS lacks GNU timeout; fall back to plain run (matches replay-verify which uses subprocess timeout in python).
    bash -c "$ac_command" >"$tmpout" 2>&1 || rc=$?
  fi
  local stdout_str
  stdout_str="$(cat "$tmpout")"
  rm -f "$tmpout"
  jq -nc --arg s "$stdout_str" --argjson rc "$rc" \
    '{ac_stdout:$s,ac_exit_code:$rc}'
}

# Compose the doctrine-compliant escalation row.
compose_escalation_row() {
  local blocker_id="$1"
  local ac_command="$2"
  local live_probe_json="$3"  # from run_ac_live_probe
  local previous_last_verified_at="$4"
  local ac_state_hash="$5"

  local live_probe_at
  live_probe_at="$(now_iso)"

  # Compute delta_seconds
  local delta="null"
  if [[ -n "$previous_last_verified_at" && "$previous_last_verified_at" != "null" ]]; then
    local prev_epoch now_epoch
    prev_epoch="$(iso_to_epoch "$previous_last_verified_at")"
    now_epoch="$(date -u +%s)"
    if [[ -n "$prev_epoch" ]] && [[ "$prev_epoch" =~ ^[0-9]+$ ]]; then
      delta="$((now_epoch - prev_epoch))"
    fi
  fi

  local ac_stdout ac_exit_code
  ac_stdout="$(jq -r '.ac_stdout' <<<"$live_probe_json")"
  ac_exit_code="$(jq -r '.ac_exit_code' <<<"$live_probe_json")"

  jq -nc \
    --arg sv "$ESCALATION_SCHEMA" \
    --arg ts "$live_probe_at" \
    --arg event "blocker_auto_closed" \
    --arg bid "$blocker_id" \
    --arg ac "$ac_command" \
    --arg out "$ac_stdout" \
    --argjson rc "$ac_exit_code" \
    --arg lpa "$live_probe_at" \
    --arg plv "$previous_last_verified_at" \
    --argjson delta "$delta" \
    --arg closer "$AUTO_CLOSER_ID" \
    --arg hash "$ac_state_hash" \
    '{
      schema_version:$sv,
      ts:$ts,
      event:$event,
      blocker_id:$bid,
      ac_command:$ac,
      ac_stdout:$out,
      ac_exit_code:$rc,
      live_probe_at:$lpa,
      previous_last_verified_at:(if $plv == "" then null else $plv end),
      delta_seconds:$delta,
      auto_closer:$closer,
      ac_state_hash:(if $hash == "" then null else $hash end)
    }'
}

# Append escalation row + mutate blocker file (apply mode only).
apply_close() {
  local blocker_file="$1"
  local escalation_row="$2"
  local closed_at="$3"

  # Append escalation row to escalations.jsonl
  mkdir -p "$(dirname "$ESCALATIONS_LOG")"
  if ! printf '%s\n' "$escalation_row" >>"$ESCALATIONS_LOG"; then
    return 1
  fi

  # Update blocker file: status=closed + audit metadata
  local tmp_new
  tmp_new="$(mktemp "${blocker_file}.auto-close.XXXXXX")"
  register_temp_file "$tmp_new"
  if ! jq --arg ca "$closed_at" --arg closer "$AUTO_CLOSER_ID" \
     --argjson row "$escalation_row" \
    '. + {
      status:"closed",
      closed_at:$ca,
      closed_by:$closer,
      closed_reason:"ac_passed_auto_close_hook",
      live_probe_evidence:$row
    }' "$blocker_file" >"$tmp_new"; then
    return 1
  fi
  if ! mv "$tmp_new" "$blocker_file"; then
    return 1
  fi
}

# Process one blocker. Emits envelope to stdout. Returns canonical exit code.
process_blocker() {
  local blocker_file="$1"

  if [[ ! -r "$blocker_file" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" --arg f "$blocker_file" \
      '{schema_version:$sv,status:"error",blocker_id:null,reason:"blocker file not readable",blocker_file:$f}'
    return 3
  fi

  local body
  body="$(cat "$blocker_file")"
  if ! jq -e . >/dev/null 2>&1 <<<"$body"; then
    jq -nc --arg sv "$SCHEMA_VERSION" --arg f "$blocker_file" \
      '{schema_version:$sv,status:"error",blocker_id:null,reason:"blocker file is not valid JSON",blocker_file:$f}'
    return 3
  fi

  local blocker_id ac_command status previous_last_verified_at
  blocker_id="$(jq -r '.blocker_id // .id // ""' <<<"$body")"
  [[ -z "$blocker_id" ]] && blocker_id="$(basename "$blocker_file" .json)"
  ac_command="$(jq -r '.acceptance_condition // .ac // ""' <<<"$body")"
  status="$(jq -r '.status // "open"' <<<"$body")"
  previous_last_verified_at="$(jq -r '.last_verified_at // ""' <<<"$body")"

  if [[ -z "$ac_command" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" --arg b "$blocker_id" --arg f "$blocker_file" \
      '{schema_version:$sv,status:"error",blocker_id:$b,reason:"missing acceptance_condition / ac field",blocker_file:$f}'
    return 3
  fi

  if [[ "$status" == "closed" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" --arg b "$blocker_id" --arg f "$blocker_file" \
      '{schema_version:$sv,status:"not_closed_already_closed",blocker_id:$b,blocker_file:$f}'
    return 3
  fi

  # Run AC purity check via flywheel_replay_verify
  local ac_envelope
  ac_envelope="$(run_ac_verify "$blocker_file")"
  local ac_verdict ac_passes_now ac_state_hash
  ac_verdict="$(jq -r '.verdict // "unknown"' <<<"$ac_envelope")"
  ac_passes_now="$(jq -r '.ac_passes_now // false' <<<"$ac_envelope")"
  ac_state_hash="$(jq -r '.state_hash // ""' <<<"$ac_envelope")"

  if [[ "$ac_verdict" != "PASS" ]] || [[ "$ac_passes_now" != "true" ]]; then
    jq -nc \
      --arg sv "$SCHEMA_VERSION" \
      --arg b "$blocker_id" \
      --arg v "$ac_verdict" \
      --arg p "$ac_passes_now" \
      --arg f "$blocker_file" \
      --argjson ace "$ac_envelope" \
      '{schema_version:$sv,status:"not_closed_ac_failed",blocker_id:$b,ac_verdict:$v,ac_passes_now:($p == "true"),blocker_file:$f,ac_envelope:$ace}'
    return 1
  fi

  # AC passes — run live probe to capture evidence
  local live_probe_json
  live_probe_json="$(run_ac_live_probe "$ac_command")"

  local escalation_row closed_at
  closed_at="$(now_iso)"
  escalation_row="$(compose_escalation_row "$blocker_id" "$ac_command" "$live_probe_json" "$previous_last_verified_at" "$ac_state_hash")"

  if [[ "$APPLY" -eq 1 ]]; then
    if ! apply_close "$blocker_file" "$escalation_row" "$closed_at"; then
      jq -nc \
        --arg sv "$SCHEMA_VERSION" \
        --arg b "$blocker_id" \
        --arg el "$ESCALATIONS_LOG" \
        --arg f "$blocker_file" \
        --argjson row "$escalation_row" \
        --argjson lpe "$live_probe_json" \
        '{schema_version:$sv,status:"close_failed",blocker_id:$b,ac_verdict:"PASS",ac_passes_now:true,
          live_probe_evidence:$lpe,escalation_row:$row,escalations_log_path:$el,
          blocker_file:$f,reason:"failed to append escalation row or mutate blocker file"}'
      return 1
    fi
    jq -nc \
      --arg sv "$SCHEMA_VERSION" \
      --arg b "$blocker_id" \
      --arg el "$ESCALATIONS_LOG" \
      --arg f "$blocker_file" \
      --arg ca "$closed_at" \
      --argjson row "$escalation_row" \
      --argjson lpe "$live_probe_json" \
      '{schema_version:$sv,status:"closed",blocker_id:$b,ac_verdict:"PASS",ac_passes_now:true,
        live_probe_evidence:$lpe,escalation_row:$row,escalations_log_path:$el,
        blocker_file:$f,closed_at:$ca,auto_closer:env.BLOCKER_AUTO_CLOSE_CLOSER_ID // "orch:auto"}'
  else
    jq -nc \
      --arg sv "$SCHEMA_VERSION" \
      --arg b "$blocker_id" \
      --arg el "$ESCALATIONS_LOG" \
      --arg f "$blocker_file" \
      --argjson row "$escalation_row" \
      --argjson lpe "$live_probe_json" \
      '{schema_version:$sv,status:"dry_run",blocker_id:$b,ac_verdict:"PASS",ac_passes_now:true,
        live_probe_evidence:$lpe,planned_escalation_row:$row,planned_escalations_log:$el,
        blocker_file:$f,would_close:true,note:"add --apply to mutate"}'
  fi
  return 0
}

# Scan a directory of blockers, process each.
process_scan() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" --arg d "$dir" \
      '{schema_version:$sv,command:"scan",status:"not_initialized",blockers_dir:$d,reason:"directory does not exist",results:[]}'
    return 3
  fi

  local results_jsonl=""
  local closed=0 not_closed=0 errors=0 total=0
  local f
  shopt -s nullglob
  for f in "$dir"/*.json; do
    total=$((total + 1))
    local row
    row="$(process_blocker "$f")" || true
    results_jsonl+="$row"$'\n'
    local s
    s="$(jq -r '.status // "error"' <<<"$row")"
    case "$s" in
      closed) closed=$((closed + 1)) ;;
      not_closed_ac_failed|not_closed_already_closed) not_closed=$((not_closed + 1)) ;;
      dry_run) closed=$((closed + 1)) ;;
      *) errors=$((errors + 1)) ;;
    esac
  done
  shopt -u nullglob

  if [[ -z "$results_jsonl" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" --arg d "$dir" \
      '{schema_version:$sv,command:"scan",status:"empty",blockers_dir:$d,total:0,closed:0,not_closed:0,errors:0,results:[]}'
    return 0
  fi

  printf '%s' "$results_jsonl" | jq -sc \
    --arg sv "$SCHEMA_VERSION" \
    --arg d "$dir" \
    --argjson total "$total" \
    --argjson closed "$closed" \
    --argjson nc "$not_closed" \
    --argjson e "$errors" \
    '{schema_version:$sv,command:"scan",status:(if $e>0 then "warn" else "ok" end),
      blockers_dir:$d,total:$total,closed:$closed,not_closed:$nc,errors:$e,results:.}'
  return 0
}

# ---------- main ----------

while [[ $# -gt 0 ]]; do
  case "$1" in
    --info) emit_info; exit 0 ;;
    --examples) emit_examples; exit 0 ;;
    --schema) emit_schema; exit 0 ;;
    doctor|--doctor) emit_doctor; exit $? ;;
    --help|-h) usage; exit 0 ;;
    --json) JSON_OUT=1; shift ;;
    --apply) APPLY=1; shift ;;
    --blocker-file) BLOCKER_FILE="${2:-}"; shift 2 ;;
    --blocker-file=*) BLOCKER_FILE="${1#--blocker-file=}"; shift ;;
    --blockers-dir) BLOCKERS_DIR="${2:-}"; shift 2 ;;
    --blockers-dir=*) BLOCKERS_DIR="${1#--blockers-dir=}"; shift ;;
    --escalations-log) ESCALATIONS_LOG="${2:-}"; shift 2 ;;
    --escalations-log=*) ESCALATIONS_LOG="${1#--escalations-log=}"; shift ;;
    --replay-verify) REPLAY_VERIFY="${2:-}"; shift 2 ;;
    --replay-verify=*) REPLAY_VERIFY="${1#--replay-verify=}"; shift ;;
    close|scan) MODE="$1"; shift ;;
    --) shift; break ;;
    *) echo "ERR: unknown arg: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ -z "$MODE" ]]; then
  echo "ERR: mode required (close | scan)" >&2
  usage >&2
  exit 2
fi

case "$MODE" in
  close)
    if [[ -z "$BLOCKER_FILE" ]]; then
      echo "ERR: --blocker-file required for close mode" >&2
      usage >&2
      exit 2
    fi
    # set +e around the substitution — process_blocker uses `return N`
    # for canonical exit codes; without disabling -e, the assignment
    # would short-circuit and bash would exit before printing the
    # envelope. We want the envelope on stdout regardless of rc.
    set +e
    out="$(process_blocker "$BLOCKER_FILE")"
    rc=$?
    set -e
    if [[ "$JSON_OUT" -eq 1 ]]; then
      printf '%s\n' "$out"
    else
      jq -r '"\(.status) blocker_id=\(.blocker_id // "?") ac_verdict=\(.ac_verdict // "n/a")"' <<<"$out"
    fi
    exit "$rc"
    ;;
  scan)
    set +e
    out="$(process_scan "$BLOCKERS_DIR")"
    rc=$?
    set -e
    if [[ "$JSON_OUT" -eq 1 ]]; then
      printf '%s\n' "$out"
    else
      jq -r '"\(.status) scan dir=\(.blockers_dir) total=\(.total) closed=\(.closed) not_closed=\(.not_closed) errors=\(.errors)"' <<<"$out"
    fi
    exit "$rc"
    ;;
esac
