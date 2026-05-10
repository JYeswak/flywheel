#!/usr/bin/env bash
# blocker-fail-escalator.sh — escalation policy per blocker-discipline doctrine.
#
# When a blocker's acceptance_condition (AC) fails the Nth consecutive
# time (default N=4 or per-blocker ac_check_interval_ticks override):
#   1. Append a blocker_ac_failed_escalated row to escalations.jsonl.
#   2. Send an Agent Mail message to Joshua naming the blocker.
#   3. Reset the fail counter (escalation already happened).
#
# Sister to blocker-auto-close.sh (nbgp6) — they mirror each other:
# auto-close handles PASS path, this handles FAIL path. Both write to
# the same escalations.jsonl ledger with different `event` values.
#
# Bead: flywheel-ukbej (blocker-ac-followup-2).
# Doctrine: .flywheel/doctrine/blocker-discipline.md
#   orch responsibility #2: "If AC fails Nth time consecutively: escalate to Joshua"
#   tick output #5: "Escalated blockers (AC failed Nth consecutive)"
#
# Source primitives:
#   - flywheel_replay_verify.py (5m9gp) — AC purity + live probe
#   - blocker-ac-tick-cadence.sh (e4ulf) — Nth-tick firing
#   - blocker-auto-close.sh (nbgp6) — sibling for PASS path
#
# Per-blocker fail counter at $COUNTER_DIR/<blocker_id>.json (incremented
# on each FAIL/MISMATCH, reset on PASS or after escalation).

set -euo pipefail

SCHEMA_VERSION="blocker-fail-escalator/v1"
ESCALATION_SCHEMA="blocker-escalation/v1"
VERSION="0.1.0"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
BLOCKERS_DIR_DEFAULT="$REPO_ROOT/.flywheel/state/blockers"
ESCALATIONS_LOG_DEFAULT="$REPO_ROOT/.flywheel/state/escalations.jsonl"
REPLAY_VERIFY_DEFAULT="$REPO_ROOT/.flywheel/scripts/flywheel_replay_verify.py"
COUNTER_DIR_DEFAULT="$HOME/.local/state/flywheel/blocker-fail-counts"
AGENT_MAIL_BIN_DEFAULT="/Users/josh/.local/bin/mcp-agent-mail"
AGENT_MAIL_PROJECT_DEFAULT="flywheel"
AGENT_MAIL_SENDER_DEFAULT="orch:flywheel:1"
AGENT_MAIL_RECIPIENT_DEFAULT="Joshua"
DEFAULT_N=4

BLOCKERS_DIR="${BLOCKER_FAIL_ESCALATOR_BLOCKERS_DIR:-$BLOCKERS_DIR_DEFAULT}"
ESCALATIONS_LOG="${BLOCKER_FAIL_ESCALATOR_ESCALATIONS_LOG:-$ESCALATIONS_LOG_DEFAULT}"
REPLAY_VERIFY="${BLOCKER_FAIL_ESCALATOR_REPLAY_VERIFY:-$REPLAY_VERIFY_DEFAULT}"
COUNTER_DIR="${BLOCKER_FAIL_ESCALATOR_COUNTER_DIR:-$COUNTER_DIR_DEFAULT}"
AGENT_MAIL_BIN="${BLOCKER_FAIL_ESCALATOR_AGENT_MAIL_BIN:-$AGENT_MAIL_BIN_DEFAULT}"
AGENT_MAIL_PROJECT="${BLOCKER_FAIL_ESCALATOR_AGENT_MAIL_PROJECT:-$AGENT_MAIL_PROJECT_DEFAULT}"
AGENT_MAIL_SENDER="${BLOCKER_FAIL_ESCALATOR_AGENT_MAIL_SENDER:-$AGENT_MAIL_SENDER_DEFAULT}"
AGENT_MAIL_RECIPIENT="${BLOCKER_FAIL_ESCALATOR_AGENT_MAIL_RECIPIENT:-$AGENT_MAIL_RECIPIENT_DEFAULT}"
THRESHOLD_N="${BLOCKER_FAIL_ESCALATOR_THRESHOLD_N:-$DEFAULT_N}"
SKIP_AGENT_MAIL="${BLOCKER_FAIL_ESCALATOR_SKIP_AGENT_MAIL:-0}"

JSON_OUT=0
APPLY=0
BLOCKER_FILE=""
MODE=""

usage() {
  cat <<'USAGE'
blocker-fail-escalator.sh — escalation policy per blocker-discipline doctrine

USAGE:
  blocker-fail-escalator.sh check --blocker-file PATH [--apply] [--json]
  blocker-fail-escalator.sh scan [--blockers-dir DIR] [--apply] [--json]
  blocker-fail-escalator.sh --info|--examples|--schema|--help [--json]

OPTIONS:
  --blocker-file PATH       Path to blocker JSON
  --blockers-dir DIR        Directory to scan (default: .flywheel/state/blockers/)
  --escalations-log P       Override path to escalations.jsonl
  --counter-dir P           Override per-blocker fail counter dir
  --threshold-n N           Override Nth-consecutive threshold (default 4)
  --replay-verify P         Override path to flywheel_replay_verify.py
  --skip-agent-mail         Don't try to send Agent Mail (still appends escalation row)
  --apply                   Mutate (append row, increment counter, send mail)
  --json                    Emit JSON

VERDICTS (envelope.status):
  not_escalated_ac_passed     - AC passed; counter reset to 0
  not_escalated_below_threshold - AC failed but consecutive_fail_count < N
  escalated                   - AC failed Nth time; row appended + mail sent
  dry_run                     - Preview (no mutation)
  error                       - Missing file, malformed JSON, etc.

EXIT CODES:
  0 escalated | not_escalated | dry_run
  1 ac_pure_mismatch (replay-verify says AC isn't pure — separate trauma)
  2 usage
  3 not-applicable (file missing, no AC, already closed)
USAGE
}

emit_info() {
  jq -nc \
    --arg sv "$SCHEMA_VERSION" \
    --arg ev "$ESCALATION_SCHEMA" \
    --arg v "$VERSION" \
    --arg br "$BLOCKERS_DIR" \
    --arg el "$ESCALATIONS_LOG" \
    --arg cd "$COUNTER_DIR" \
    --arg rv "$REPLAY_VERIFY" \
    --arg amb "$AGENT_MAIL_BIN" \
    --arg amp "$AGENT_MAIL_PROJECT" \
    --arg ams "$AGENT_MAIL_SENDER" \
    --arg amr "$AGENT_MAIL_RECIPIENT" \
    --argjson n "$THRESHOLD_N" \
    '{
      schema_version:$sv,
      escalation_schema:$ev,
      name:"blocker-fail-escalator.sh",
      version:$v,
      doctrine:".flywheel/doctrine/blocker-discipline.md",
      sibling:"blocker-auto-close.sh (PASS-path counterpart)",
      primitives:{
        replay_verify:$rv,
        tick_cadence:".flywheel/scripts/blocker-ac-tick-cadence.sh"
      },
      paths:{
        blockers_dir:$br,
        escalations_log:$el,
        counter_dir:$cd,
        agent_mail_bin:$amb
      },
      agent_mail:{
        project:$amp,
        sender:$ams,
        recipient:$amr
      },
      threshold_n:$n,
      mutation_default:"dry-run",
      modes:["check","scan"],
      escalation_row_fields:["schema_version","ts","event","blocker_id","ac_command","ac_stdout","ac_exit_code","live_probe_at","previous_last_verified_at","delta_seconds","auto_closer","ac_state_hash","consecutive_fail_count","threshold_n","agent_mail_status"],
      exit_codes:{"0":"escalated|not_escalated|dry_run","1":"ac_pure_mismatch","2":"usage","3":"not_applicable"}
    }'
}

emit_examples() {
  jq -nc '{examples:[
    "blocker-fail-escalator.sh check --blocker-file .flywheel/state/blockers/foo.json --json",
    "blocker-fail-escalator.sh check --blocker-file foo.json --apply --json",
    "blocker-fail-escalator.sh scan --blockers-dir .flywheel/state/blockers --json",
    "blocker-fail-escalator.sh scan --apply --json",
    "BLOCKER_FAIL_ESCALATOR_THRESHOLD_N=2 blocker-fail-escalator.sh check --blocker-file b.json --apply",
    "BLOCKER_FAIL_ESCALATOR_SKIP_AGENT_MAIL=1 blocker-fail-escalator.sh scan --apply"
  ]}'
}

emit_schema() {
  jq -nc \
    --arg sv "$SCHEMA_VERSION" \
    --arg ev "$ESCALATION_SCHEMA" \
    '{
      "$schema":"https://json-schema.org/draft/2020-12/schema",
      schema_version:$sv,
      title:"blocker-fail-escalator envelope + escalation row schemas",
      "$defs":{
        envelope:{
          type:"object",
          required:["schema_version","status","blocker_id"],
          properties:{
            schema_version:{const:$sv},
            status:{enum:["escalated","not_escalated_ac_passed","not_escalated_below_threshold","dry_run","error","ac_pure_mismatch"]},
            blocker_id:{type:"string"},
            consecutive_fail_count:{type:["integer","null"]},
            threshold_n:{type:["integer","null"]},
            ac_verdict:{enum:["PASS","MISMATCH","unknown"]},
            ac_passes_now:{type:"boolean"},
            agent_mail_status:{enum:["sent","skipped_no_cli","skipped_flag","skipped_dry_run","failed"]},
            escalation_row:{type:["object","null"]},
            escalations_log_path:{type:"string"}
          }
        },
        escalation_row:{
          type:"object",
          required:["schema_version","ts","event","blocker_id","ac_command","ac_stdout","ac_exit_code","live_probe_at","previous_last_verified_at","delta_seconds","auto_closer","consecutive_fail_count","threshold_n","agent_mail_status"],
          properties:{
            schema_version:{const:$ev},
            ts:{type:"string"},
            event:{enum:["blocker_auto_closed","blocker_manually_closed","blocker_ac_failed_escalated"]},
            blocker_id:{type:"string"},
            ac_command:{type:"string"},
            ac_stdout:{type:"string"},
            ac_exit_code:{type:"integer"},
            live_probe_at:{type:"string"},
            previous_last_verified_at:{type:["string","null"]},
            delta_seconds:{type:["integer","null"]},
            auto_closer:{type:"string"},
            ac_state_hash:{type:["string","null"]},
            consecutive_fail_count:{type:"integer"},
            threshold_n:{type:"integer"},
            agent_mail_status:{enum:["sent","skipped_no_cli","skipped_flag","skipped_dry_run","failed"]}
          }
        }
      }
    }'
}

# ---------- helpers ----------

now_iso() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }

iso_to_epoch() {
  local iso="$1"
  [[ -z "$iso" ]] && { printf '\n'; return; }
  if date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$iso" '+%s' 2>/dev/null; then
    return
  fi
  date -u -d "$iso" '+%s' 2>/dev/null || printf '\n'
}

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
}

run_ac_live_probe() {
  local ac_command="$1"
  local timeout_s="${2:-10}"
  local tmpout
  tmpout="$(mktemp "${TMPDIR:-/tmp}/blocker-fail-stdout.XXXXXX")"
  local rc=0
  if command -v timeout >/dev/null 2>&1; then
    timeout "$timeout_s" bash -c "$ac_command" >"$tmpout" 2>&1 || rc=$?
  else
    bash -c "$ac_command" >"$tmpout" 2>&1 || rc=$?
  fi
  local stdout_str
  stdout_str="$(cat "$tmpout")"
  : >"$tmpout"
  rmdir "$(dirname "$tmpout")" 2>/dev/null || true
  # Tmpout itself is a file (not a dir) — clean explicitly
  if [[ -f "$tmpout" ]]; then
    : >"$tmpout"
  fi
  jq -nc --arg s "$stdout_str" --argjson rc "$rc" \
    '{ac_stdout:$s,ac_exit_code:$rc}'
}

# Read counter state for a blocker. Returns JSON with counter + last_fail_at.
read_counter() {
  local blocker_id="$1"
  local counter_file="$COUNTER_DIR/${blocker_id}.json"
  if [[ -r "$counter_file" ]]; then
    cat "$counter_file"
  else
    jq -nc '{counter:0,last_fail_at:null,last_fail_state_hash:null}'
  fi
}

# Write counter state. Apply-only.
write_counter() {
  local blocker_id="$1" counter="$2" last_fail_at="$3" state_hash="$4"
  mkdir -p "$COUNTER_DIR"
  local counter_file="$COUNTER_DIR/${blocker_id}.json"
  jq -nc --argjson c "$counter" --arg lfa "$last_fail_at" --arg sh "$state_hash" \
    '{counter:$c,last_fail_at:(if $lfa == "" then null else $lfa end),last_fail_state_hash:(if $sh == "" then null else $sh end)}' >"$counter_file"
}

# Reset counter to 0.
reset_counter() {
  local blocker_id="$1"
  if [[ -f "$COUNTER_DIR/${blocker_id}.json" ]]; then
    : >"$COUNTER_DIR/${blocker_id}.json"
    jq -nc '{counter:0,last_fail_at:null,last_fail_state_hash:null}' >"$COUNTER_DIR/${blocker_id}.json"
  fi
}

# Compose escalation row (mirrors nbgp6's auto-close row, different event +
# adds consecutive_fail_count + threshold_n + agent_mail_status).
compose_escalation_row() {
  local blocker_id="$1"
  local ac_command="$2"
  local live_probe_json="$3"
  local previous_last_verified_at="$4"
  local ac_state_hash="$5"
  local consecutive_fail_count="$6"
  local threshold_n="$7"
  local agent_mail_status="$8"

  local live_probe_at delta="null"
  live_probe_at="$(now_iso)"
  if [[ -n "$previous_last_verified_at" && "$previous_last_verified_at" != "null" ]]; then
    local prev_epoch now_epoch
    prev_epoch="$(iso_to_epoch "$previous_last_verified_at")"
    now_epoch="$(date -u +%s)"
    if [[ -n "$prev_epoch" && "$prev_epoch" =~ ^[0-9]+$ ]]; then
      delta="$((now_epoch - prev_epoch))"
    fi
  fi

  local ac_stdout ac_exit_code
  ac_stdout="$(jq -r '.ac_stdout' <<<"$live_probe_json")"
  ac_exit_code="$(jq -r '.ac_exit_code' <<<"$live_probe_json")"

  jq -nc \
    --arg sv "$ESCALATION_SCHEMA" \
    --arg ts "$live_probe_at" \
    --arg event "blocker_ac_failed_escalated" \
    --arg bid "$blocker_id" \
    --arg ac "$ac_command" \
    --arg out "$ac_stdout" \
    --argjson rc "$ac_exit_code" \
    --arg lpa "$live_probe_at" \
    --arg plv "$previous_last_verified_at" \
    --argjson delta "$delta" \
    --arg closer "$AGENT_MAIL_SENDER" \
    --arg hash "$ac_state_hash" \
    --argjson cfc "$consecutive_fail_count" \
    --argjson tn "$threshold_n" \
    --arg ams "$agent_mail_status" \
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
      ac_state_hash:(if $hash == "" then null else $hash end),
      consecutive_fail_count:$cfc,
      threshold_n:$tn,
      agent_mail_status:$ams
    }'
}

# Send Agent Mail message via mcp-agent-mail CLI. Best-effort:
# returns "sent" | "skipped_no_cli" | "failed".
send_agent_mail() {
  local blocker_id="$1" ac_command="$2" consecutive="$3" threshold="$4" blocker_file="$5"

  if [[ "$SKIP_AGENT_MAIL" == "1" ]]; then
    printf 'skipped_flag'
    return 0
  fi
  if ! command -v "$AGENT_MAIL_BIN" >/dev/null 2>&1; then
    printf 'skipped_no_cli'
    return 0
  fi

  local subject body
  subject="blocker AC failed ${consecutive}x consecutively: ${blocker_id}"
  body="Blocker '${blocker_id}' has failed its acceptance_condition ${consecutive} consecutive times (threshold N=${threshold}).

ac_command: ${ac_command}
blocker_file: ${blocker_file}
escalations.jsonl: ${ESCALATIONS_LOG}

Per blocker-discipline doctrine (orch responsibility #2): when AC fails
Nth consecutive time, escalate to Joshua. This is that escalation.

To re-evaluate manually:
  python3 ${REPLAY_VERIFY} blocker-ac --blocker-file ${blocker_file} --json

To force-close if conditions have cleared:
  ${REPO_ROOT}/.flywheel/scripts/blocker-auto-close.sh close --blocker-file ${blocker_file} --apply --json"

  # mcp-agent-mail mail send <project> --to <agent> --subject <subj> <body>
  if "$AGENT_MAIL_BIN" mail send "$AGENT_MAIL_PROJECT" --to "$AGENT_MAIL_RECIPIENT" --subject "$subject" "$body" >/dev/null 2>&1; then
    printf 'sent'
  else
    printf 'failed'
  fi
}

# Process one blocker.
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

  local blocker_id ac_command status previous_last_verified_at threshold_n
  blocker_id="$(jq -r '.blocker_id // .id // ""' <<<"$body")"
  [[ -z "$blocker_id" ]] && blocker_id="$(basename "$blocker_file" .json)"
  ac_command="$(jq -r '.acceptance_condition // .ac // ""' <<<"$body")"
  status="$(jq -r '.status // "open"' <<<"$body")"
  previous_last_verified_at="$(jq -r '.last_verified_at // ""' <<<"$body")"
  threshold_n="$(jq -r ".ac_check_interval_ticks // ${THRESHOLD_N}" <<<"$body")"
  [[ "$threshold_n" =~ ^[0-9]+$ ]] || threshold_n="$THRESHOLD_N"
  [[ "$threshold_n" -lt 1 ]] && threshold_n="$THRESHOLD_N"

  if [[ -z "$ac_command" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" --arg b "$blocker_id" \
      '{schema_version:$sv,status:"error",blocker_id:$b,reason:"missing acceptance_condition / ac field"}'
    return 3
  fi
  if [[ "$status" == "closed" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" --arg b "$blocker_id" \
      '{schema_version:$sv,status:"error",blocker_id:$b,reason:"blocker already closed",blocker_status:"closed"}'
    return 3
  fi

  # Run AC purity check
  local ac_envelope ac_verdict ac_passes_now ac_state_hash
  ac_envelope="$(run_ac_verify "$blocker_file")"
  ac_verdict="$(jq -r '.verdict // "unknown"' <<<"$ac_envelope")"
  ac_passes_now="$(jq -r '.ac_passes_now // false' <<<"$ac_envelope")"
  ac_state_hash="$(jq -r '.state_hash // ""' <<<"$ac_envelope")"

  if [[ "$ac_verdict" == "MISMATCH" ]]; then
    # AC predicate is not pure — separate trauma, not a "consecutive fail".
    jq -nc \
      --arg sv "$SCHEMA_VERSION" --arg b "$blocker_id" \
      --arg v "$ac_verdict" --argjson ace "$ac_envelope" \
      '{schema_version:$sv,status:"ac_pure_mismatch",blocker_id:$b,ac_verdict:$v,
        reason:"AC predicate is not pure; cannot judge consecutive failures",ac_envelope:$ace}'
    return 1
  fi

  # Read current counter
  local counter_json prev_counter
  counter_json="$(read_counter "$blocker_id")"
  prev_counter="$(jq -r '.counter' <<<"$counter_json")"

  if [[ "$ac_passes_now" == "true" ]]; then
    # AC passed — reset counter (no escalation needed)
    if [[ "$APPLY" -eq 1 ]] && [[ "$prev_counter" -gt 0 ]]; then
      reset_counter "$blocker_id"
    fi
    jq -nc \
      --arg sv "$SCHEMA_VERSION" --arg b "$blocker_id" \
      --argjson prev "$prev_counter" --argjson tn "$threshold_n" \
      '{schema_version:$sv,status:"not_escalated_ac_passed",blocker_id:$b,
        ac_verdict:"PASS",ac_passes_now:true,
        consecutive_fail_count:0,previous_consecutive_fail_count:$prev,threshold_n:$tn,
        note:"counter reset on PASS (blocker not closed — auto-close hook owns that)"}'
    return 0
  fi

  # AC failed — increment counter
  local new_counter=$((prev_counter + 1))

  if [[ "$new_counter" -lt "$threshold_n" ]]; then
    # Below threshold — increment counter, don't escalate yet
    if [[ "$APPLY" -eq 1 ]]; then
      write_counter "$blocker_id" "$new_counter" "$(now_iso)" "$ac_state_hash"
    fi
    jq -nc \
      --arg sv "$SCHEMA_VERSION" --arg b "$blocker_id" \
      --argjson nc "$new_counter" --argjson tn "$threshold_n" \
      '{schema_version:$sv,status:"not_escalated_below_threshold",blocker_id:$b,
        ac_verdict:"PASS",ac_passes_now:false,
        consecutive_fail_count:$nc,threshold_n:$tn,
        note:"counter incremented; not yet at threshold"}'
    return 0
  fi

  # AT threshold — escalate
  local live_probe_json
  live_probe_json="$(run_ac_live_probe "$ac_command")"

  local agent_mail_status escalation_row
  if [[ "$APPLY" -eq 1 ]]; then
    agent_mail_status="$(send_agent_mail "$blocker_id" "$ac_command" "$new_counter" "$threshold_n" "$blocker_file")"
  else
    agent_mail_status="skipped_dry_run"
  fi

  escalation_row="$(compose_escalation_row "$blocker_id" "$ac_command" "$live_probe_json" "$previous_last_verified_at" "$ac_state_hash" "$new_counter" "$threshold_n" "$agent_mail_status")"

  if [[ "$APPLY" -eq 1 ]]; then
    mkdir -p "$(dirname "$ESCALATIONS_LOG")"
    printf '%s\n' "$escalation_row" >>"$ESCALATIONS_LOG"
    # Reset counter after escalation — the next failure starts a fresh streak.
    reset_counter "$blocker_id"

    jq -nc \
      --arg sv "$SCHEMA_VERSION" --arg b "$blocker_id" \
      --argjson nc "$new_counter" --argjson tn "$threshold_n" \
      --arg ams "$agent_mail_status" --arg el "$ESCALATIONS_LOG" \
      --argjson row "$escalation_row" --argjson lpe "$live_probe_json" \
      '{schema_version:$sv,status:"escalated",blocker_id:$b,
        ac_verdict:"PASS",ac_passes_now:false,
        consecutive_fail_count:$nc,threshold_n:$tn,
        agent_mail_status:$ams,escalations_log_path:$el,
        live_probe_evidence:$lpe,escalation_row:$row}'
  else
    jq -nc \
      --arg sv "$SCHEMA_VERSION" --arg b "$blocker_id" \
      --argjson nc "$new_counter" --argjson tn "$threshold_n" \
      --arg ams "$agent_mail_status" --arg el "$ESCALATIONS_LOG" \
      --argjson row "$escalation_row" --argjson lpe "$live_probe_json" \
      '{schema_version:$sv,status:"dry_run",blocker_id:$b,
        ac_verdict:"PASS",ac_passes_now:false,
        consecutive_fail_count:$nc,threshold_n:$tn,
        agent_mail_status:$ams,planned_escalations_log:$el,
        live_probe_evidence:$lpe,planned_escalation_row:$row,would_escalate:true,
        note:"add --apply to mutate (append row + reset counter + send mail)"}'
  fi
  return 0
}

process_scan() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" --arg d "$dir" \
      '{schema_version:$sv,command:"scan",status:"not_initialized",blockers_dir:$d,reason:"directory does not exist",results:[]}'
    return 3
  fi

  local results_jsonl="" escalated=0 not_escalated=0 errors=0 total=0
  local f
  shopt -s nullglob
  for f in "$dir"/*.json; do
    total=$((total + 1))
    local row
    set +e
    row="$(process_blocker "$f")"
    set -e
    results_jsonl+="$row"$'\n'
    local s
    s="$(jq -r '.status // "error"' <<<"$row")"
    case "$s" in
      escalated|dry_run) escalated=$((escalated + 1)) ;;
      not_escalated_*) not_escalated=$((not_escalated + 1)) ;;
      *) errors=$((errors + 1)) ;;
    esac
  done
  shopt -u nullglob

  if [[ -z "$results_jsonl" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" --arg d "$dir" \
      '{schema_version:$sv,command:"scan",status:"empty",blockers_dir:$d,total:0,escalated:0,not_escalated:0,errors:0,results:[]}'
    return 0
  fi

  printf '%s' "$results_jsonl" | jq -sc \
    --arg sv "$SCHEMA_VERSION" --arg d "$dir" \
    --argjson total "$total" --argjson esc "$escalated" \
    --argjson ne "$not_escalated" --argjson e "$errors" \
    '{schema_version:$sv,command:"scan",status:(if $e>0 then "warn" else "ok" end),
      blockers_dir:$d,total:$total,escalated:$esc,not_escalated:$ne,errors:$e,results:.}'
  return 0
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
    --blocker-file) BLOCKER_FILE="${2:-}"; shift 2 ;;
    --blocker-file=*) BLOCKER_FILE="${1#--blocker-file=}"; shift ;;
    --blockers-dir) BLOCKERS_DIR="${2:-}"; shift 2 ;;
    --blockers-dir=*) BLOCKERS_DIR="${1#--blockers-dir=}"; shift ;;
    --escalations-log) ESCALATIONS_LOG="${2:-}"; shift 2 ;;
    --escalations-log=*) ESCALATIONS_LOG="${1#--escalations-log=}"; shift ;;
    --counter-dir) COUNTER_DIR="${2:-}"; shift 2 ;;
    --counter-dir=*) COUNTER_DIR="${1#--counter-dir=}"; shift ;;
    --threshold-n) THRESHOLD_N="${2:-}"; shift 2 ;;
    --threshold-n=*) THRESHOLD_N="${1#--threshold-n=}"; shift ;;
    --replay-verify) REPLAY_VERIFY="${2:-}"; shift 2 ;;
    --replay-verify=*) REPLAY_VERIFY="${1#--replay-verify=}"; shift ;;
    --skip-agent-mail) SKIP_AGENT_MAIL=1; shift ;;
    check|scan) MODE="$1"; shift ;;
    --) shift; break ;;
    *) echo "ERR: unknown arg: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ -z "$MODE" ]]; then
  echo "ERR: mode required (check | scan)" >&2
  usage >&2
  exit 2
fi

case "$MODE" in
  check)
    if [[ -z "$BLOCKER_FILE" ]]; then
      echo "ERR: --blocker-file required for check mode" >&2
      usage >&2
      exit 2
    fi
    set +e
    out="$(process_blocker "$BLOCKER_FILE")"
    rc=$?
    set -e
    if [[ "$JSON_OUT" -eq 1 ]]; then
      printf '%s\n' "$out"
    else
      jq -r '"\(.status) blocker_id=\(.blocker_id // "?") fail_count=\(.consecutive_fail_count // 0)/\(.threshold_n // 0) agent_mail=\(.agent_mail_status // "n/a")"' <<<"$out"
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
      jq -r '"\(.status) scan dir=\(.blockers_dir) total=\(.total) escalated=\(.escalated) not_escalated=\(.not_escalated) errors=\(.errors)"' <<<"$out"
    fi
    exit "$rc"
    ;;
esac
