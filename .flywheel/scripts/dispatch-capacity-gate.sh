#!/usr/bin/env bash
set -euo pipefail

NTM="${NTM:-/Users/josh/.local/bin/ntm}"

usage() {
  printf 'usage: dispatch-capacity-gate.sh <session> <pane>\n' >&2
}

if [ "$#" -lt 2 ]; then
  usage
  exit 1
fi

SESSION="$1"
PANE="$2"

json_from_env_or_file() {
  local env_name="$1" file_env_name="$2" command_name="$3"
  local value="${!env_name:-}" file_value="${!file_env_name:-}"

  if [ -n "$value" ]; then
    printf '%s\n' "$value"
    return 0
  fi
  if [ -n "$file_value" ]; then
    cat "$file_value"
    return 0
  fi

  case "$command_name" in
    activity)
      "$NTM" --robot-activity="$SESSION" --activity-type=codex,claude --json 2>/dev/null
      ;;
    health)
      "$NTM" --robot-agent-health="$SESSION" --no-caut --json 2>/dev/null
      ;;
    *)
      return 1
      ;;
  esac
}

emit() {
  local verdict="$1" reason="$2" activity="$3" is_idle="$4" score="$5" rec="$6" warning="${7:-}"
  jq -nc \
    --arg verdict "$verdict" \
    --arg reason "$reason" \
    --arg session "$SESSION" \
    --arg pane "$PANE" \
    --arg activity "$activity" \
    --arg rec "$rec" \
    --arg warning "$warning" \
    --argjson is_idle "$is_idle" \
    --argjson score "$score" '
      {
        verdict: $verdict,
        reason: $reason,
        session: $session,
        pane: ($pane | tonumber? // $pane),
        activity: $activity,
        health: {is_idle: $is_idle, score: $score, rec: $rec}
      }
      + (if $warning == "" then {} else {warning: $warning} end)
    '
}

ACTIVITY_JSON="$(json_from_env_or_file ACTIVITY_JSON ACTIVITY_JSON_FILE activity || printf '{}')"
HEALTH_JSON="$(json_from_env_or_file HEALTH_JSON HEALTH_JSON_FILE health || printf '{}')"

ACTIVITY_STATE="$(
  jq -r --arg p "$PANE" '
    def pane_id: (.pane? // .pane_idx? // .index? // .pane_index? // "");
    (
      first(.agents[]? | select((pane_id | tostring) == $p) | (.state // "")) //
      first(.panes[]? | select((pane_id | tostring) == $p) | (.state // "")) //
      ""
    ) | ascii_upcase
  ' <<<"$ACTIVITY_JSON"
)"
[ -n "$ACTIVITY_STATE" ] || ACTIVITY_STATE="UNKNOWN"

read -r HEALTH_IDLE HEALTH_SCORE HEALTH_REC < <(
  jq -r --arg p "$PANE" '
    def pane_id: (.pane? // .pane_idx? // .index? // .pane_index? // "");
    def pane:
      if (.panes | type) == "object" then
        .panes[$p] // first(.panes[]? | select((pane_id | tostring) == $p)) // {}
      elif (.panes | type) == "array" then
        first(.panes[]? | select((pane_id | tostring) == $p)) // {}
      else
        {}
      end;
    pane as $pane
    | [
        (($pane.local_state.is_idle // $pane.is_idle // false) | tostring),
        (($pane.health_score // $pane.score // 0) | tonumber? // 0),
        (($pane.recommendation // $pane.status // "") | tostring | ascii_upcase)
      ] | @tsv
  ' <<<"$HEALTH_JSON"
)

case "$HEALTH_IDLE" in
  true|false) ;;
  *) HEALTH_IDLE=false ;;
esac
[ -n "${HEALTH_SCORE:-}" ] || HEALTH_SCORE=0
[ -n "${HEALTH_REC:-}" ] || HEALTH_REC=""

if [ "$ACTIVITY_STATE" = "WAITING" ]; then
  emit "available" "activity_waiting" "$ACTIVITY_STATE" "$HEALTH_IDLE" "$HEALTH_SCORE" "$HEALTH_REC"
  exit 0
fi

if [ "$ACTIVITY_STATE" = "ERROR" ] && [ "$HEALTH_IDLE" = "true" ] && [ "$HEALTH_REC" = "HEALTHY" ]; then
  emit \
    "override_available" \
    "activity_error_but_health_idle_healthy" \
    "$ACTIVITY_STATE" \
    "$HEALTH_IDLE" \
    "$HEALTH_SCORE" \
    "$HEALTH_REC" \
    "stale_chevron_or_api_error_pattern"
  exit 2
fi

case "$ACTIVITY_STATE" in
  ERROR|STALLED|UNKNOWN)
    emit "blocked" "activity_${ACTIVITY_STATE}" "$ACTIVITY_STATE" "$HEALTH_IDLE" "$HEALTH_SCORE" "$HEALTH_REC"
    exit 1
    ;;
esac

emit "blocked" "activity_${ACTIVITY_STATE}" "$ACTIVITY_STATE" "$HEALTH_IDLE" "$HEALTH_SCORE" "$HEALTH_REC"
exit 1
