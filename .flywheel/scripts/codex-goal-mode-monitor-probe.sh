#!/usr/bin/env bash
set -euo pipefail

SCHEMA_VERSION="codex-goal-mode-monitor-probe/v0.1"
TRAUMA_SCHEMA_VERSION="codex_goal_mode_trauma.v1"
BYPASS_SCHEMA_VERSION="codex_goal_mode_bypass_audit.v1"
SESSION="${CODEX_GOAL_MODE_SESSION:-flywheel}"
PANE=""
DISPATCH_ID=""
LAYER=""
MAX_ENTRY_WAIT_S=30
PERSISTENCE_POLL_INTERVAL_S=60
FLAP_THRESHOLD=3
FLAP_WINDOW_S=300
RESPAWN_RESIDUE_S=15
COMPLETING_WINDOW_S=5
JSON_OUT=0
DRY_RUN=0
STATE_DIR="${CODEX_GOAL_MODE_STATE_DIR:-$HOME/.flywheel/state/codex-goal-mode-monitor}"
TRAUMA_LOG="${CODEX_GOAL_MODE_TRAUMA_LOG:-$HOME/.flywheel/evidence/codex-goal-mode-trauma.jsonl}"
UNKNOWN_LOG="${CODEX_GOAL_MODE_UNKNOWN_LOG:-$HOME/.flywheel/evidence/codex-goal-mode-unknown-state.jsonl}"
BYPASS_AUDIT="${CODEX_GOAL_MODE_BYPASS_AUDIT:-$HOME/.local/state/codex-goal-mode-bypass-audit.jsonl}"
CAPTURE_LINES="${CODEX_GOAL_MODE_CAPTURE_LINES:-220}"
RESUME_STUCK_S="${CODEX_GOAL_MODE_RESUME_STUCK_S:-120}"

usage() {
  cat <<'EOF'
usage: codex-goal-mode-monitor-probe.sh --pane N --dispatch-id ID --layer 2|3|4 [options]

Options:
  --max-entry-wait-s N              Layer 2 grace window (default 30)
  --persistence-poll-interval-s N   Layer 3 cadence metadata (default 60)
  --flap-threshold N                Layer 3 flap trigger count (default 3)
  --flap-window-s N                 Layer 3 flap window (default 300)
  --respawn-residue-s N             Respawn suppression window (default 15)
  --completing-window-s N           Goal-completing suppression window (default 5)
  --json                            Emit structured status
  --dry-run                         Do not append trauma rows
  --help                            Print this help

Exit codes: 0=OK, 1=trauma fired, 2=defer, 3=unknown-state
EOF
}

die_usage() {
  printf 'codex-goal-mode-monitor-probe: %s\n' "$1" >&2
  usage >&2
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pane) [[ $# -ge 2 ]] || die_usage "--pane requires N"; PANE="$2"; shift 2 ;;
    --pane=*) PANE="${1#*=}"; shift ;;
    --dispatch-id) [[ $# -ge 2 ]] || die_usage "--dispatch-id requires ID"; DISPATCH_ID="$2"; shift 2 ;;
    --dispatch-id=*) DISPATCH_ID="${1#*=}"; shift ;;
    --layer) [[ $# -ge 2 ]] || die_usage "--layer requires 2|3|4"; LAYER="$2"; shift 2 ;;
    --layer=*) LAYER="${1#*=}"; shift ;;
    --max-entry-wait-s) [[ $# -ge 2 ]] || die_usage "--max-entry-wait-s requires N"; MAX_ENTRY_WAIT_S="$2"; shift 2 ;;
    --max-entry-wait-s=*) MAX_ENTRY_WAIT_S="${1#*=}"; shift ;;
    --persistence-poll-interval-s) [[ $# -ge 2 ]] || die_usage "--persistence-poll-interval-s requires N"; PERSISTENCE_POLL_INTERVAL_S="$2"; shift 2 ;;
    --persistence-poll-interval-s=*) PERSISTENCE_POLL_INTERVAL_S="${1#*=}"; shift ;;
    --flap-threshold) [[ $# -ge 2 ]] || die_usage "--flap-threshold requires N"; FLAP_THRESHOLD="$2"; shift 2 ;;
    --flap-threshold=*) FLAP_THRESHOLD="${1#*=}"; shift ;;
    --flap-window-s) [[ $# -ge 2 ]] || die_usage "--flap-window-s requires N"; FLAP_WINDOW_S="$2"; shift 2 ;;
    --flap-window-s=*) FLAP_WINDOW_S="${1#*=}"; shift ;;
    --respawn-residue-s) [[ $# -ge 2 ]] || die_usage "--respawn-residue-s requires N"; RESPAWN_RESIDUE_S="$2"; shift 2 ;;
    --respawn-residue-s=*) RESPAWN_RESIDUE_S="${1#*=}"; shift ;;
    --completing-window-s) [[ $# -ge 2 ]] || die_usage "--completing-window-s requires N"; COMPLETING_WINDOW_S="$2"; shift 2 ;;
    --completing-window-s=*) COMPLETING_WINDOW_S="${1#*=}"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) die_usage "unknown argument: $1" ;;
  esac
done

[[ "$PANE" =~ ^[0-9]+$ ]] || die_usage "--pane must be an integer"
[[ -n "$DISPATCH_ID" ]] || die_usage "--dispatch-id is required"
[[ "$LAYER" =~ ^[234]$ ]] || die_usage "--layer must be 2, 3, or 4"

mkdir -p "$STATE_DIR" "$(dirname "$TRAUMA_LOG")" "$(dirname "$UNKNOWN_LOG")" "$(dirname "$BYPASS_AUDIT")"
HISTORY_FILE="$STATE_DIR/state-history-${DISPATCH_ID}.jsonl"
FIRED_DIR="$STATE_DIR/fired"
mkdir -p "$FIRED_DIR"

now_iso() {
  if [[ -n "${CODEX_GOAL_MODE_NOW:-}" ]]; then
    printf '%s\n' "$CODEX_GOAL_MODE_NOW"
  else
    date -u +%Y-%m-%dT%H:%M:%SZ
  fi
}

now_epoch() {
  local now
  now="$(now_iso)"
  python3 - "$now" <<'PY'
from datetime import datetime, timezone
import sys
value = sys.argv[1].replace("Z", "+00:00")
print(int(datetime.fromisoformat(value).timestamp()))
PY
}

emit_status() {
  local status="$1" state="$2" trauma="${3:-}" reason="${4:-}"
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc \
      --arg schema_version "$SCHEMA_VERSION" \
      --arg ts "$(now_iso)" \
      --arg status "$status" \
      --arg session "$SESSION" \
      --argjson pane "$PANE" \
      --arg dispatch_id "$DISPATCH_ID" \
      --argjson layer "$LAYER" \
      --arg state "$state" \
      --arg trauma_class "$trauma" \
      --arg reason "$reason" \
      --argjson persistence_poll_interval_s "$PERSISTENCE_POLL_INTERVAL_S" \
      --argjson respawn_residue_s "$RESPAWN_RESIDUE_S" \
      --argjson completing_window_s "$COMPLETING_WINDOW_S" \
      '{schema_version:$schema_version,ts:$ts,status:$status,session:$session,pane:$pane,dispatch_id:$dispatch_id,layer:$layer,state:$state}
       + {persistence_poll_interval_s:$persistence_poll_interval_s,respawn_residue_s:$respawn_residue_s,completing_window_s:$completing_window_s}
       + (if $trauma_class != "" then {trauma_class:$trauma_class} else {} end)
       + (if $reason != "" then {reason:$reason} else {} end)'
  else
    printf 'codex-goal-mode status=%s dispatch_id=%s pane=%s layer=%s state=%s' "$status" "$DISPATCH_ID" "$PANE" "$LAYER" "$state"
    [[ -z "$trauma" ]] || printf ' trauma_class=%s' "$trauma"
    [[ -z "$reason" ]] || printf ' reason=%s' "$reason"
    printf '\n'
  fi
}

capture_pane() {
  if [[ -n "${CODEX_GOAL_MODE_CAPTURE_FILE:-}" ]]; then
    cat "$CODEX_GOAL_MODE_CAPTURE_FILE"
    return 0
  fi
  if [[ -n "${CODEX_GOAL_MODE_CAPTURE_TEXT:-}" ]]; then
    printf '%s\n' "$CODEX_GOAL_MODE_CAPTURE_TEXT"
    return 0
  fi
  tmux capture-pane -p -t "${SESSION}:0.${PANE}" -S "-${CAPTURE_LINES}" 2>/dev/null \
    || tmux capture-pane -p -t "${SESSION}:${PANE}" -S "-${CAPTURE_LINES}"
}

classify_text() {
  local text_file="$1"
  python3 - "$text_file" <<'PY'
import json
import re
import sys

text = open(sys.argv[1], encoding="utf-8", errors="replace").read()
lower = text.lower()

def has(pattern):
    return re.search(pattern, text, re.I | re.M) is not None

state = "unknown"
reason = "no_detector_matched"
if has(r"respawn[- ]residue|post[- ]respawn|recently respawned"):
    state, reason = "respawn-residue", "respawn_residue_marker"
elif has(r"goal paused\s*\(/goal resume\)|\bgoal paused\b"):
    state, reason = "goal-paused", "goal_paused_text"
elif has(r"goal (completing|finalizing)|callback[- ]to[- ]goal[- ]clear|goal-box-clear"):
    state, reason = "goal-completing", "goal_completing_text"
elif has(r"goal completed|completed goal"):
    state, reason = "goal-completed", "goal_completed_text"
elif (has(r"worked for\s+[0-9]+[ms]") or has(r"goal in progress")) and not has(r"goal paused"):
    state, reason = "goal-in-progress", "worked_for_goal_text"
elif has(r"working\s*\([0-9]+[sm]?.*(esc to interrupt|interrupt)\)") and not has(r"goal paused|goal in progress|worked for|goal completed"):
    state, reason = "working-non-goal", "working_without_goal_box"
elif has(r"(traceback|exception|panic|fatal:|error:|rate limit|api error|failed)") and not has(r"goal"):
    state, reason = "error-state", "error_text_without_goal"
elif has(r"(^|\n)\s*(>|›|❯|\$)\s*$") or lower.strip() in {"", "codex", "ready"} or has(r"\bchat\b|\bask me anything\b"):
    state, reason = "idle-chat", "prompt_without_goal_or_work"

print(json.dumps({"state": state, "reason": reason, "bytes": len(text.encode()), "sample": text[-600:]}, separators=(",", ":")))
PY
}

append_history() {
  local state="$1" reason="$2"
  jq -nc \
    --arg ts "$(now_iso)" \
    --arg session "$SESSION" \
    --argjson pane "$PANE" \
    --arg dispatch_id "$DISPATCH_ID" \
    --argjson layer "$LAYER" \
    --arg state "$state" \
    --arg reason "$reason" \
    '{ts:$ts,session:$session,pane:$pane,dispatch_id:$dispatch_id,layer:$layer,state:$state,reason:$reason}' >>"$HISTORY_FILE"
}

log_unknown() {
  local class_json="$1"
  jq -nc \
    --arg ts "$(now_iso)" \
    --arg session "$SESSION" \
    --argjson pane "$PANE" \
    --arg dispatch_id "$DISPATCH_ID" \
    --argjson layer "$LAYER" \
    --argjson classifier "$class_json" \
    '{schema_version:"codex_goal_mode_unknown_state.v1",ts:$ts,session:$session,pane:$pane,dispatch_id:$dispatch_id,layer:$layer,classifier:$classifier}' >>"$UNKNOWN_LOG"
}

write_bypass_row_if_env() {
  [[ -n "${CODEX_GOAL_FORMAT_BYPASS:-}" ]] || return 0
  if [[ -s "$BYPASS_AUDIT" ]] && jq -e --arg dispatch_id "$DISPATCH_ID" --arg session "$SESSION" --argjson pane "$PANE" '
      select(.schema_version == "codex_goal_mode_bypass_audit.v1")
      | select((.dispatch_id // "") == $dispatch_id and (.session // "") == $session and ((.pane // -1) | tonumber) == $pane)
    ' "$BYPASS_AUDIT" >/dev/null 2>&1; then
    return 0
  fi
  jq -nc \
    --arg ts "$(now_iso)" \
    --arg bypass_class "RUNTIME_TRAUMA_SUPPRESS" \
    --arg dispatch_id "$DISPATCH_ID" \
    --arg session "$SESSION" \
    --argjson pane "$PANE" \
    --arg reason "$CODEX_GOAL_FORMAT_BYPASS" \
    --arg authorized_by "${USER:-unknown}" \
    --arg schema_version "$BYPASS_SCHEMA_VERSION" \
    '{ts:$ts,bypass_class:$bypass_class,dispatch_id:$dispatch_id,pane:$pane,session:$session,reason:$reason,authorized_by:$authorized_by,joshua_signature:null,schema_version:$schema_version}' >>"$BYPASS_AUDIT"
}

has_bypass() {
  write_bypass_row_if_env
  [[ -s "$BYPASS_AUDIT" ]] || return 1
  jq -e --arg dispatch_id "$DISPATCH_ID" --arg session "$SESSION" --argjson pane "$PANE" '
    select(.schema_version == "codex_goal_mode_bypass_audit.v1")
    | select((.dispatch_id // "") == $dispatch_id and (.session // "") == $session and ((.pane // -1) | tonumber) == $pane)
  ' "$BYPASS_AUDIT" >/dev/null 2>&1
}

history_json() {
  if [[ -s "$HISTORY_FILE" ]]; then
    jq -sc 'map(select(type == "object"))' "$HISTORY_FILE"
  else
    printf '[]\n'
  fi
}

fire_trauma() {
  local trauma="$1" state="$2" reason="$3"
  if has_bypass; then
    emit_status "bypassed" "$state" "$trauma" "matching_bypass_audit_row"
    return 0
  fi
  local marker
  marker="$FIRED_DIR/${DISPATCH_ID}-${LAYER}-${trauma}-${state}"
  if [[ -e "$marker" ]]; then
    emit_status "ok" "$state" "$trauma" "already_fired_for_state_window"
    return 0
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    emit_status "dry_run_would_fire" "$state" "$trauma" "$reason"
    return 0
  fi
  local hist
  hist="$(history_json)"
  jq -nc \
    --arg ts "$(now_iso)" \
    --arg trauma_class "$trauma" \
    --arg dispatch_id "$DISPATCH_ID" \
    --argjson pane "$PANE" \
    --arg session "$SESSION" \
    --argjson layer "$LAYER" \
    --arg state "$state" \
    --arg reason "$reason" \
    --argjson state_history "$hist" \
    --argjson transitions_count "$(jq '[.[] | select(.state == "goal-in-progress" or .state == "goal-paused")] | length' <<<"$hist")" \
    --argjson window_s "$FLAP_WINDOW_S" \
    --arg schema_version "$TRAUMA_SCHEMA_VERSION" \
    '{ts:$ts,trauma_class:$trauma_class,dispatch_id:$dispatch_id,pane:$pane,session:$session,layer:$layer,state:$state,reason:$reason,state_history:$state_history,transitions_count:$transitions_count,window_s:$window_s,remediation_hint:"prompt-structure-review",schema_version:$schema_version}' >>"$TRAUMA_LOG"
  : >"$marker"
  emit_status "trauma_fired" "$state" "$trauma" "$reason"
  return 1
}

classify_current() {
  local tmp class_json state reason
  tmp="$(mktemp "${TMPDIR:-/tmp}/codex-goal-mode-capture.XXXXXX")"
  capture_pane >"$tmp"
  class_json="$(classify_text "$tmp")"
  rm -f "$tmp"
  state="$(jq -r '.state' <<<"$class_json")"
  reason="$(jq -r '.reason' <<<"$class_json")"
  append_history "$state" "$reason"
  if [[ "$state" == "unknown" ]]; then
    log_unknown "$class_json"
  fi
  printf '%s\n' "$class_json"
}

paused_duration_s() {
  python3 - "$HISTORY_FILE" "$(now_iso)" <<'PY'
from datetime import datetime
import json
import sys

path, now_s = sys.argv[1], sys.argv[2]
now = datetime.fromisoformat(now_s.replace("Z", "+00:00"))
first = None
try:
    rows = [json.loads(line) for line in open(path) if line.strip()]
except FileNotFoundError:
    rows = []
for row in reversed(rows):
    if row.get("state") == "goal-paused":
        first = row.get("ts")
    else:
        break
if not first:
    print(0)
else:
    then = datetime.fromisoformat(first.replace("Z", "+00:00"))
    print(max(0, int((now - then).total_seconds())))
PY
}

flap_count() {
  python3 - "$HISTORY_FILE" "$(now_epoch)" "$FLAP_WINDOW_S" <<'PY'
import json
import sys
from datetime import datetime

path, now_epoch, window = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
states = []
try:
    rows = [json.loads(line) for line in open(path) if line.strip()]
except FileNotFoundError:
    rows = []
for row in rows:
    if row.get("state") not in {"goal-in-progress", "goal-paused"}:
        continue
    try:
        ts = int(datetime.fromisoformat(row["ts"].replace("Z", "+00:00")).timestamp())
    except Exception:
        continue
    if now_epoch - ts <= window:
        states.append(row.get("state"))
transitions = 0
prev = None
for state in states:
    if prev and state != prev:
        transitions += 1
    prev = state
print(transitions)
PY
}

ever_goal_in_progress() {
  [[ -s "$HISTORY_FILE" ]] && jq -e 'select(.state == "goal-in-progress")' "$HISTORY_FILE" >/dev/null 2>&1
}

layer2() {
  local deadline now class_json state
  deadline=$(( $(now_epoch) + MAX_ENTRY_WAIT_S ))
  while true; do
    class_json="$(classify_current)"
    state="$(jq -r '.state' <<<"$class_json")"
    case "$state" in
      goal-in-progress) emit_status "ok" "$state"; return 0 ;;
      respawn-residue|goal-completing) emit_status "defer" "$state" "" "suppression_window"; return 2 ;;
      error-state) fire_trauma "codex-goal-entry-failed" "$state" "error_state_on_entry"; return $? ;;
      unknown) emit_status "unknown" "$state" "" "fall_through_logged"; return 3 ;;
    esac
    now="$(now_epoch)"
    [[ "$now" -ge "$deadline" ]] && break
    sleep 1
  done
  fire_trauma "codex-goal-entry-failed" "$state" "no_goal_in_progress_before_deadline"
}

layer3() {
  local class_json state flaps paused_s
  class_json="$(classify_current)"
  state="$(jq -r '.state' <<<"$class_json")"
  case "$state" in
    unknown) emit_status "unknown" "$state" "" "fall_through_logged"; return 3 ;;
    respawn-residue|goal-completing) emit_status "defer" "$state" "" "suppression_window"; return 2 ;;
  esac
  flaps="$(flap_count)"
  if [[ "$flaps" -ge "$FLAP_THRESHOLD" ]]; then
    fire_trauma "codex-goal-mode-flapping" "$state" "entry_pause_transitions_${flaps}_within_${FLAP_WINDOW_S}s"
    return $?
  fi
  if [[ "$state" == "goal-paused" ]]; then
    paused_s="$(paused_duration_s)"
    if [[ "$paused_s" -ge "$RESUME_STUCK_S" ]]; then
      fire_trauma "codex-goal-resume-stuck" "$state" "goal_paused_${paused_s}s"
      return $?
    fi
  fi
  case "$state" in
    goal-paused|idle-chat|working-non-goal)
      if ever_goal_in_progress; then
        fire_trauma "codex-goal-abandoned" "$state" "mode_regression_mid_dispatch"
        return $?
      fi
      ;;
  esac
  emit_status "ok" "$state"
}

layer4() {
  if ever_goal_in_progress; then
    emit_status "ok" "goal-completed"
    return 0
  fi
  fire_trauma "codex-goal-mode-bypassed" "goal-completed" "callback_without_goal_in_progress_history"
}

case "$LAYER" in
  2) layer2 ;;
  3) layer3 ;;
  4) layer4 ;;
esac
