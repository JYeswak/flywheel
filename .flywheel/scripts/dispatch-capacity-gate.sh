#!/usr/bin/env bash
set -euo pipefail

NTM="${NTM:-/Users/josh/.local/bin/ntm}"
[[ $# -ge 2 ]] || { printf 'usage: dispatch-capacity-gate.sh <session> <pane>\n' >&2; exit 1; }
SESSION="$1"; PANE="$2"

json_source() {
  local env_name="$1" file_env_name="$2"; shift 2
  local value="${!env_name:-}" file_value="${!file_env_name:-}"
  [[ -n "$value" ]] && { printf '%s\n' "$value"; return 0; }
  [[ -n "$file_value" ]] && { cat "$file_value"; return 0; }
  "$@" 2>/dev/null || printf '{}\n'
}

emit() {
  local verdict="$1" reason="$2" activity="$3" idle="$4" score="$5" rec="$6" warning="${7:-}"
  jq -nc --arg verdict "$verdict" --arg reason "$reason" --arg session "$SESSION" --arg pane "$PANE" \
    --arg activity "$activity" --arg rec "$rec" --arg warning "$warning" --argjson is_idle "$idle" --argjson score "$score" \
    '{verdict:$verdict,reason:$reason,session:$session,pane:($pane|tonumber? // $pane),activity:$activity,
      health:{is_idle:$is_idle,score:$score,rec:$rec}} + (if $warning == "" then {} else {warning:$warning} end)'
}

ASSIGN_JSON="$(json_source ASSIGN_JSON ASSIGN_JSON_FILE "$NTM" assign "$SESSION" --dry-run --json)"
HEALTH_JSON="$(json_source HEALTH_JSON HEALTH_JSON_FILE "$NTM" health "$SESSION" --pane "$PANE" --json)"
ASSIGN_PANE_MATCH="$(
  jq -r --arg p "$PANE" '
    [.data.assignments[]? | select((.pane|tostring) == $p)] | length
  ' <<<"$ASSIGN_JSON" 2>/dev/null || echo 0
)"
ASSIGN_IDLE_COUNT="$(
  jq -r '.data.summary.idle_agent_count // .summary.idle_agent_count // 0' <<<"$ASSIGN_JSON" 2>/dev/null || echo 0
)"

read -r RAW_ACTIVITY HEALTH_STATUS PROCESS_STATUS HEALTH_SCORE HEALTH_IDLE_HINT < <(
  jq -r --arg p "$PANE" '
    def pane_id: (.pane? // .pane_idx? // .index? // .pane_index? // "");
    first(.agents[]? | select((pane_id|tostring) == $p)) // {} |
    [(.activity // .state // "unknown"), (.status // ""), (.process_status // ""), ((.health_score // .score // 0)|tonumber? // 0), ((.local_state.is_idle // .is_idle // false)|tostring)] | @tsv
  ' <<<"$HEALTH_JSON"
)

RAW_ACTIVITY="${RAW_ACTIVITY:-unknown}"
HEALTH_STATUS="${HEALTH_STATUS:-}"
PROCESS_STATUS="${PROCESS_STATUS:-}"
HEALTH_SCORE="${HEALTH_SCORE:-0}"
case "$(printf '%s' "$RAW_ACTIVITY" | tr '[:lower:]' '[:upper:]')" in
  IDLE|WAITING) ACTIVITY_STATE="WAITING" ;;
  ACTIVE|THINKING|GENERATING|RUNNING) ACTIVITY_STATE="THINKING" ;;
  ERROR) ACTIVITY_STATE="ERROR" ;;
  STALLED) ACTIVITY_STATE="STALLED" ;;
  *) ACTIVITY_STATE="UNKNOWN" ;;
esac

if [[ "$HEALTH_IDLE_HINT" == "true" || ( "$PROCESS_STATUS" == "running" && "$RAW_ACTIVITY" == "idle" ) ]]; then HEALTH_IDLE=true; else HEALTH_IDLE=false; fi
if [[ "$HEALTH_STATUS" == "ok" || "$HEALTH_SCORE" -ge 80 ]]; then HEALTH_REC="HEALTHY"; else HEALTH_REC="$(printf '%s' "${HEALTH_STATUS:-UNKNOWN}" | tr '[:lower:]' '[:upper:]')"; fi

if [[ "$ASSIGN_PANE_MATCH" -gt 0 || ( "$ACTIVITY_STATE" == "WAITING" && "$ASSIGN_IDLE_COUNT" -gt 0 ) ]]; then
  emit "available" "assign_idle_capacity" "$ACTIVITY_STATE" "$HEALTH_IDLE" "$HEALTH_SCORE" "$HEALTH_REC"
  exit 0
fi
if [[ "$ACTIVITY_STATE" == "ERROR" && "$HEALTH_IDLE" == "true" && "$HEALTH_REC" == "HEALTHY" ]]; then
  emit "override_available" "activity_error_but_health_idle_healthy" "$ACTIVITY_STATE" "$HEALTH_IDLE" "$HEALTH_SCORE" "$HEALTH_REC" "stale_chevron_or_api_error_pattern"
  exit 2
fi
case "$ACTIVITY_STATE" in
  ERROR|STALLED|UNKNOWN) emit "blocked" "activity_${ACTIVITY_STATE}" "$ACTIVITY_STATE" "$HEALTH_IDLE" "$HEALTH_SCORE" "$HEALTH_REC"; exit 1 ;;
esac
emit "blocked" "activity_${ACTIVITY_STATE}" "$ACTIVITY_STATE" "$HEALTH_IDLE" "$HEALTH_SCORE" "$HEALTH_REC"
exit 1
