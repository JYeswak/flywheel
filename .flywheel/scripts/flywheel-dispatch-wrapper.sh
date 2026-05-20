#!/usr/bin/env bash
set -euo pipefail

SCHEMA_VERSION="flywheel-dispatch-wrapper/v0.1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SESSION="${FLYWHEEL_DISPATCH_SESSION:-flywheel}"
PANE=""
FILE=""
DISPATCH_ID=""
AGENT_TYPE="${FLYWHEEL_DISPATCH_AGENT_TYPE:-codex}"
DISPATCH_LOG="${FLYWHEEL_DISPATCH_LOG:-$ROOT/.flywheel/dispatch-log.jsonl}"
NTM_BIN="${FLYWHEEL_NTM_BIN:-${NTM:-/Users/josh/.local/bin/ntm}}"
PROBE="${CODEX_GOAL_MODE_PROBE:-$ROOT/.flywheel/scripts/codex-goal-mode-monitor-probe.sh}"
BYPASS_AUDIT="${CODEX_GOAL_MODE_BYPASS_AUDIT:-$HOME/.local/state/codex-goal-mode-bypass-audit.jsonl}"
JSON_OUT=0
DRY_RUN=0
CALLBACK=0
FOREGROUND_PROBE="${CODEX_GOAL_MODE_WRAPPER_FOREGROUND_PROBE:-0}"
PROBE_MAX_ENTRY_WAIT_S="${CODEX_GOAL_MODE_WRAPPER_MAX_ENTRY_WAIT_S:-30}"

usage() {
  cat <<'EOF'
usage:
  flywheel-dispatch-wrapper.sh --session NAME --pane N --file PATH [--dispatch-id ID] [--json] [--dry-run]
  flywheel-dispatch-wrapper.sh --callback --session NAME --pane N --dispatch-id ID [--json] [--dry-run]

Wraps ntm send for Codex dispatches and wires Layer 2/3/4 goal-mode monitoring.
EOF
}

die_usage() {
  printf 'flywheel-dispatch-wrapper: %s\n' "$1" >&2
  usage >&2
  exit 2
}

uuid() {
  if command -v uuidgen >/dev/null 2>&1; then
    uuidgen | tr '[:upper:]' '[:lower:]'
  else
    python3 - <<'PY'
import uuid
print(uuid.uuid4())
PY
  fi
}

now_iso() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session) [[ $# -ge 2 ]] || die_usage "--session requires NAME"; SESSION="$2"; shift 2 ;;
    --session=*) SESSION="${1#*=}"; shift ;;
    --pane) [[ $# -ge 2 ]] || die_usage "--pane requires N"; PANE="$2"; shift 2 ;;
    --pane=*) PANE="${1#*=}"; shift ;;
    --file) [[ $# -ge 2 ]] || die_usage "--file requires PATH"; FILE="$2"; shift 2 ;;
    --file=*) FILE="${1#*=}"; shift ;;
    --dispatch-id) [[ $# -ge 2 ]] || die_usage "--dispatch-id requires ID"; DISPATCH_ID="$2"; shift 2 ;;
    --dispatch-id=*) DISPATCH_ID="${1#*=}"; shift ;;
    --agent-type) [[ $# -ge 2 ]] || die_usage "--agent-type requires TYPE"; AGENT_TYPE="$2"; shift 2 ;;
    --agent-type=*) AGENT_TYPE="${1#*=}"; shift ;;
    --dispatch-log) [[ $# -ge 2 ]] || die_usage "--dispatch-log requires PATH"; DISPATCH_LOG="$2"; shift 2 ;;
    --dispatch-log=*) DISPATCH_LOG="${1#*=}"; shift ;;
    --probe-max-entry-wait-s) [[ $# -ge 2 ]] || die_usage "--probe-max-entry-wait-s requires N"; PROBE_MAX_ENTRY_WAIT_S="$2"; shift 2 ;;
    --probe-max-entry-wait-s=*) PROBE_MAX_ENTRY_WAIT_S="${1#*=}"; shift ;;
    --foreground-probe) FOREGROUND_PROBE=1; shift ;;
    --callback) CALLBACK=1; shift ;;
    --json) JSON_OUT=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) die_usage "unknown argument: $1" ;;
  esac
done

[[ "$PANE" =~ ^[0-9]+$ ]] || die_usage "--pane must be an integer"
[[ -n "$DISPATCH_ID" ]] || DISPATCH_ID="dispatch-$(uuid)"
mkdir -p "$(dirname "$DISPATCH_LOG")" "$(dirname "$BYPASS_AUDIT")"

append_bypass_audit() {
  [[ -n "${CODEX_GOAL_FORMAT_BYPASS:-}" ]] || return 0
  jq -nc \
    --arg ts "$(now_iso)" \
    --arg bypass_class "RUNTIME_TRAUMA_SUPPRESS" \
    --arg dispatch_id "$DISPATCH_ID" \
    --arg session "$SESSION" \
    --argjson pane "$PANE" \
    --arg reason "$CODEX_GOAL_FORMAT_BYPASS" \
    --arg authorized_by "${USER:-unknown}" \
    '{ts:$ts,bypass_class:$bypass_class,dispatch_id:$dispatch_id,pane:$pane,session:$session,reason:$reason,authorized_by:$authorized_by,joshua_signature:null,schema_version:"codex_goal_mode_bypass_audit.v1"}' >>"$BYPASS_AUDIT"
}

emit() {
  local status="$1" monitor_probe_id="$2" probe_pid="${3:-}"
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc \
      --arg schema_version "$SCHEMA_VERSION" \
      --arg status "$status" \
      --arg session "$SESSION" \
      --argjson pane "$PANE" \
      --arg dispatch_id "$DISPATCH_ID" \
      --arg monitor_probe_id "$monitor_probe_id" \
      --arg probe_pid "$probe_pid" \
      --arg dispatch_log "$DISPATCH_LOG" \
      '{schema_version:$schema_version,status:$status,session:$session,pane:$pane,dispatch_id:$dispatch_id,monitor_probe_id:$monitor_probe_id,dispatch_log:$dispatch_log}
       + (if $probe_pid != "" then {layer2_probe_pid:($probe_pid|tonumber)} else {} end)'
  else
    printf 'flywheel-dispatch-wrapper status=%s dispatch_id=%s pane=%s monitor_probe_id=%s\n' "$status" "$DISPATCH_ID" "$PANE" "$monitor_probe_id"
  fi
}

if [[ "$CALLBACK" -eq 1 ]]; then
  set +e
  CODEX_GOAL_MODE_SESSION="$SESSION" "$PROBE" --pane "$PANE" --dispatch-id "$DISPATCH_ID" --layer 4 --json
  rc=$?
  set -e
  jq -nc \
    --arg ts "$(now_iso)" \
    --arg event "callback" \
    --arg dispatch_id "$DISPATCH_ID" \
    --arg task_id "$DISPATCH_ID" \
    --arg session "$SESSION" \
    --argjson pane "$PANE" \
    --argjson layer4_rc "$rc" \
    '{schema_version:2,event:$event,ts:$ts,callback_ts:$ts,callback_received_at:$ts,dispatch_id:$dispatch_id,task_id:$task_id,session:$session,pane:$pane,layer4_probe_rc:$layer4_rc}' >>"$DISPATCH_LOG"
  emit "callback_recorded" ""
  exit "$rc"
fi

[[ -n "$FILE" ]] || die_usage "--file is required"
[[ -f "$FILE" ]] || die_usage "dispatch file not found: $FILE"

monitor_probe_id="$(uuid)"
append_bypass_audit
if [[ "$DRY_RUN" -eq 0 ]]; then
  FLYWHEEL_DISPATCH_WRAPPER=1 "$NTM_BIN" send "$SESSION" --pane="$PANE" --file="$FILE"
fi

jq -nc \
  --arg ts "$(now_iso)" \
  --arg dispatch_id "$DISPATCH_ID" \
  --arg task_id "$DISPATCH_ID" \
  --arg session "$SESSION" \
  --argjson pane "$PANE" \
  --arg from "flywheel:1" \
  --arg to "${SESSION}:${PANE}" \
  --arg task_summary "$(head -n 1 "$FILE" | cut -c1-100)" \
  --arg task_file "$(cd "$(dirname "$FILE")" && pwd -P)/$(basename "$FILE")" \
  --arg agent_type "$AGENT_TYPE" \
  --arg monitor_probe_id "$monitor_probe_id" \
  '{schema_version:2,event:"dispatch_sent",task_id:$task_id,dispatch_id:$dispatch_id,ts:$ts,dispatch_ts:$ts,from:$from,to:$to,pane:$pane,session:$session,task_summary:$task_summary,task_file:$task_file,agent_type:$agent_type,pane_state_source:"raw_capture",mission_anchor:"continuous-orchestrator-uptime-self-sustaining-fleet",mission_fitness_claim:"Codex /goal-mode monitoring enforces semantic dispatch entry and persistence.",mission_fitness_class:"direct",idempotency_token:$dispatch_id,callback_received_at:null,callback_ts:null,mode:"goal",origin_task_id:$dispatch_id,goal_id:$dispatch_id,sprint_id:null,tick_id:null,monitor_probe_id:$monitor_probe_id,goal_mode_trauma_fired:[],dispatch_skill_version:"flywheel-dispatch-wrapper/v0.1"}' >>"$DISPATCH_LOG"

if [[ "$AGENT_TYPE" != "codex" ]]; then
  emit "sent_unmonitored_non_codex" "$monitor_probe_id"
  exit 0
fi

if [[ "$FOREGROUND_PROBE" == "1" ]]; then
  CODEX_GOAL_MODE_SESSION="$SESSION" "$PROBE" --pane "$PANE" --dispatch-id "$DISPATCH_ID" --layer 2 --max-entry-wait-s "$PROBE_MAX_ENTRY_WAIT_S" --json --dry-run >/tmp/codex-goal-mode-layer2-"$DISPATCH_ID".json 2>&1 || true
  emit "sent_layer2_probe_completed" "$monitor_probe_id"
else
  (CODEX_GOAL_MODE_SESSION="$SESSION" "$PROBE" --pane "$PANE" --dispatch-id "$DISPATCH_ID" --layer 2 --max-entry-wait-s "$PROBE_MAX_ENTRY_WAIT_S" --json >/tmp/codex-goal-mode-layer2-"$DISPATCH_ID".json 2>&1 || true) &
  emit "sent_layer2_probe_started" "$monitor_probe_id" "$!"
fi
