#!/usr/bin/env bash
set -euo pipefail

SCHEMA_VERSION="flywheel-dispatch-wrapper/v0.1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SESSION="${FLYWHEEL_DISPATCH_SESSION:-flywheel}"
PANE=""
FILE=""
DISPATCH_ID=""
AGENT_TYPE="${FLYWHEEL_DISPATCH_AGENT_TYPE:-}"
AGENT_TYPE_SOURCE="topology"
[[ -n "${FLYWHEEL_DISPATCH_AGENT_TYPE:-}" ]] && AGENT_TYPE_SOURCE="env"
DISPATCH_LOG="${FLYWHEEL_DISPATCH_LOG:-$ROOT/.flywheel/dispatch-log.jsonl}"
NTM_BIN="${FLYWHEEL_NTM_BIN:-${NTM:-/Users/josh/.local/bin/ntm}}"
ACTIVATE="${CODEX_GOAL_ACTIVATE:-$ROOT/.flywheel/scripts/codex-goal-activate.sh}"
PROBE="${CODEX_GOAL_MODE_PROBE:-$ROOT/.flywheel/scripts/codex-goal-mode-monitor-probe.sh}"
TOPOLOGY="${FLYWHEEL_SESSION_TOPOLOGY:-${NTM_SESSION_TOPOLOGY:-$HOME/.local/state/flywheel/session-topology.jsonl}}"
CODEX_PAYLOAD_DIR="${CODEX_GOAL_PAYLOAD_DIR:-$ROOT/.flywheel/dispatches}"
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

normalize_agent_type() {
  local value
  value="$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')"
  case "$value" in
    codex|codex-*) printf 'codex\n' ;;
    claude|cc|claude-code|claude_code) printf 'claude\n' ;;
    gemini|other|unknown) printf '%s\n' "$value" ;;
    "") printf 'codex\n' ;;
    *) printf 'other\n' ;;
  esac
}

resolve_agent_type_from_topology() {
  [[ -f "$TOPOLOGY" ]] || return 1
  command -v jq >/dev/null 2>&1 || return 1
  jq -rs --arg session "$SESSION" --arg pane "$PANE" '
    def pane_s: $pane;
    def latest:
      map(select((.session // "") == $session))
      | sort_by(.effective_at // .ts // "")
      | last // {};
    latest as $row
    | (
        ($row.worker_kinds[pane_s] // empty),
        ($row.pane_kinds[pane_s] // empty),
        (if ((($row.orchestrator_pane // null) | tostring) == pane_s) then ($row.orchestrator_kind // empty) else empty end),
        (if ((($row.callback_pane // null) | tostring) == pane_s) then ($row.callback_kind // $row.orchestrator_kind // empty) else empty end),
        (($row.workers // [])[]? | select(((.pane // .pane_idx // null) | tostring) == pane_s) | (.kind // .agent_type // empty)),
        (($row.agents // [])[]? | select(((.pane // .pane_idx // null) | tostring) == pane_s) | (.agent_type // .type // empty))
      )
      | select(. != null and . != "")
  ' "$TOPOLOGY" 2>/dev/null || true
}

resolve_agent_type() {
  if [[ -n "$AGENT_TYPE" ]]; then
    AGENT_TYPE="$(normalize_agent_type "$AGENT_TYPE")"
    return 0
  fi
  local detected
  detected="$(resolve_agent_type_from_topology | head -n 1 || true)"
  if [[ -n "$detected" ]]; then
    AGENT_TYPE="$(normalize_agent_type "$detected")"
    AGENT_TYPE_SOURCE="topology"
  else
    AGENT_TYPE="codex"
    AGENT_TYPE_SOURCE="default"
  fi
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
    --agent-type) [[ $# -ge 2 ]] || die_usage "--agent-type requires TYPE"; AGENT_TYPE="$2"; AGENT_TYPE_SOURCE="arg"; shift 2 ;;
    --agent-type=*) AGENT_TYPE="${1#*=}"; AGENT_TYPE_SOURCE="arg"; shift ;;
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
resolve_agent_type

monitor_probe_id="$(uuid)"
append_bypass_audit
task_file_abs="$(cd "$(dirname "$FILE")" && pwd -P)/$(basename "$FILE")"
task_file_for_log="$task_file_abs"
task_summary="$(head -n 1 "$FILE" | cut -c1-100)"
if [[ "$DRY_RUN" -eq 0 ]]; then
  if [[ "$AGENT_TYPE" == "codex" ]]; then
    mkdir -p "$CODEX_PAYLOAD_DIR"
    CODEX_PAYLOAD_FILE="$CODEX_PAYLOAD_DIR/codex-${DISPATCH_ID}.md"
    cat "$FILE" >"$CODEX_PAYLOAD_FILE"
    task_file_for_log="$(cd "$(dirname "$CODEX_PAYLOAD_FILE")" && pwd -P)/$(basename "$CODEX_PAYLOAD_FILE")"
    CODEX_PAYLOAD_REL="${task_file_for_log#"$ROOT"/}"
    CODEX_SHORT_DIRECTIVE_FILE="$(mktemp "${TMPDIR:-/tmp}/codex-${DISPATCH_ID}-directive.XXXXXX.txt")"
    trap 'rm -f "${CODEX_SHORT_DIRECTIVE_FILE:-}"' EXIT
    printf 'Read %s as your full task contract and execute it per the deliverables, acceptance, loop contract, and FIRST ACTION steps inside. Task id: %s.\n' \
      "$CODEX_PAYLOAD_REL" "$DISPATCH_ID" >"$CODEX_SHORT_DIRECTIVE_FILE"
    FLYWHEEL_DISPATCH_WRAPPER=1 "$ACTIVATE" \
      --session "$SESSION" \
      --pane "$PANE" \
      --task-file "$CODEX_SHORT_DIRECTIVE_FILE" \
      --max-entry-wait-s "$PROBE_MAX_ENTRY_WAIT_S" \
      --json
  else
    FLYWHEEL_DISPATCH_WRAPPER=1 "$NTM_BIN" send "$SESSION" --pane="$PANE" --file="$FILE"
  fi
fi

jq -nc \
  --arg ts "$(now_iso)" \
  --arg dispatch_id "$DISPATCH_ID" \
  --arg task_id "$DISPATCH_ID" \
  --arg session "$SESSION" \
  --argjson pane "$PANE" \
  --arg from "flywheel:1" \
  --arg to "${SESSION}:${PANE}" \
  --arg task_summary "$task_summary" \
  --arg task_file "$task_file_for_log" \
  --arg agent_type "$AGENT_TYPE" \
  --arg agent_type_source "$AGENT_TYPE_SOURCE" \
  --arg monitor_probe_id "$monitor_probe_id" \
  '{schema_version:2,event:"dispatch_sent",task_id:$task_id,dispatch_id:$dispatch_id,ts:$ts,dispatch_ts:$ts,from:$from,to:$to,pane:$pane,session:$session,task_summary:$task_summary,task_file:$task_file,agent_type:$agent_type,agent_type_source:$agent_type_source,pane_state_source:"raw_capture",mission_anchor:"continuous-orchestrator-uptime-self-sustaining-fleet",mission_fitness_claim:"Codex /goal-mode monitoring enforces semantic dispatch entry and persistence.",mission_fitness_class:"direct",idempotency_token:$dispatch_id,callback_received_at:null,callback_ts:null,mode:"goal",origin_task_id:$dispatch_id,goal_id:$dispatch_id,sprint_id:null,tick_id:null,monitor_probe_id:$monitor_probe_id,goal_mode_trauma_fired:[],dispatch_skill_version:"flywheel-dispatch-wrapper/v0.1"}' >>"$DISPATCH_LOG"

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
