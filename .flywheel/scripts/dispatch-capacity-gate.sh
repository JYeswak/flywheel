#!/usr/bin/env bash
set -euo pipefail

NTM="${NTM:-/Users/josh/.local/bin/ntm}"
[[ $# -ge 2 ]] || { printf 'usage: dispatch-capacity-gate.sh <session> <pane>\n' >&2; exit 1; }
SESSION="$1"; PANE="$2"
REPO="${DISPATCH_GATE_REPO:-$PWD}"
LOOP_GOAL_GATE="${LOOP_GOAL_GATE:-$(dirname "$0")/loop-goal-gate.sh}"

# ── bszgl.3: gated-loop halt check ───────────────────────────────────────────
# If all remaining goal blockers are owner:external, refuse dispatch.
# Loops must not burn tokens when gated on Joshua/external action.
if [[ -x "$LOOP_GOAL_GATE" ]]; then
  GATE_STATUS=0
  GATE_OUT="$("$LOOP_GOAL_GATE" --repo "$REPO" --json 2>/dev/null)" || GATE_STATUS=$?
  if [[ "$GATE_STATUS" -eq 2 ]]; then
    jq -nc --arg session "$SESSION" --arg pane "$PANE" --argjson gate "$GATE_OUT" \
      '{verdict:"gated",reason:"loop_gated_all_blockers_external",session:$session,
        pane:($pane|tonumber? // $pane),gate:$gate,
        action:"halt_loop_await_external_gate_clearance"}'
    exit 3
  fi
fi

# ── bszgl.3 + git-repo-discipline: git hygiene gate ───────────────────────────
# Refuse dispatch when dirty repo state has crossed the halt threshold. Below
# halt, carry the repo-discipline action into the normal capacity envelope.
REPO_DISCIPLINE_CHECK="${REPO_DISCIPLINE_CHECK:-$(dirname "$0")/repo-discipline-check.sh}"
if [[ -x "$REPO_DISCIPLINE_CHECK" ]] && git -C "$REPO" rev-parse --git-dir &>/dev/null; then
  REPO_DISCIPLINE_STATUS=0
  REPO_DISCIPLINE_OUT="$("$REPO_DISCIPLINE_CHECK" --repo "$REPO" --no-append --json 2>/dev/null)" || REPO_DISCIPLINE_STATUS=$?
  if [[ "$REPO_DISCIPLINE_STATUS" -eq 1 ]]; then
    jq -nc --arg session "$SESSION" --arg pane "$PANE" --argjson repo_hygiene "$REPO_DISCIPLINE_OUT" \
      '{verdict:"blocked",reason:"git_repo_hygiene_halt_threshold",session:$session,
        pane:($pane|tonumber? // $pane),
        repo_hygiene:$repo_hygiene,
        action:$repo_hygiene.action}'
    exit 1
  fi
  if jq -e '.commits_ahead > 300' >/dev/null 2>&1 <<<"$REPO_DISCIPLINE_OUT"; then
    GIT_AHEAD_WARNING="commits_ahead=$(jq -r '.commits_ahead' <<<"$REPO_DISCIPLINE_OUT") consider push decision"
  fi
  if jq -e '.class != "clean"' >/dev/null 2>&1 <<<"$REPO_DISCIPLINE_OUT"; then
    REPO_HYGIENE_WARNING="$(
      jq -r '"repo_hygiene=\(.class) action=\(.action) dirty_total=\(.dirty_total) handler=\(.handler)"' <<<"$REPO_DISCIPLINE_OUT"
    )"
  fi
fi

# ── repo-hygiene-operational-protocol: accretion/bloat gate ─────────────────
# This is the sister check to repo-discipline-check.sh. Dirty-tree discipline
# handles unresolved working-tree decisions; repo-hygiene-check.sh handles
# H-1..H-4 accretion failures such as tracked-but-ignored output and
# rebuildable substrate drifting into git.
REPO_HYGIENE_CHECK="${REPO_HYGIENE_CHECK:-$(dirname "$0")/repo-hygiene-check.sh}"
if [[ -x "$REPO_HYGIENE_CHECK" ]] && git -C "$REPO" rev-parse --git-dir &>/dev/null; then
  REPO_HYGIENE_STATUS=0
  REPO_HYGIENE_OUT="$("$REPO_HYGIENE_CHECK" --repo "$REPO" --json 2>/dev/null)" || REPO_HYGIENE_STATUS=$?
  if [[ "$REPO_HYGIENE_STATUS" -eq 1 ]]; then
    jq -nc --arg session "$SESSION" --arg pane "$PANE" --argjson repo_hygiene_operational "$REPO_HYGIENE_OUT" \
      '{verdict:"blocked",reason:"repo_hygiene_operational_protocol_fail",session:$session,
        pane:($pane|tonumber? // $pane),
        repo_hygiene_operational:$repo_hygiene_operational,
        action:"fix_H1_H2_repo_hygiene_failures_before_dispatch"}'
    exit 1
  fi
  if jq -e '.warn > 0' >/dev/null 2>&1 <<<"$REPO_HYGIENE_OUT"; then
    REPO_HYGIENE_OPERATIONAL_WARNING="$(
      jq -r '"repo_hygiene_protocol=warn pass=\(.pass) warn=\(.warn) fail=\(.fail)"' <<<"$REPO_HYGIENE_OUT"
    )"
  fi
fi

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

COMBINED_WARNING=""
for w in "${REPO_HYGIENE_WARNING:-}" "${REPO_HYGIENE_OPERATIONAL_WARNING:-}" "${GIT_AHEAD_WARNING:-}"; do
  [[ -z "$w" ]] && continue
  if [[ -z "$COMBINED_WARNING" ]]; then
    COMBINED_WARNING="$w"
  else
    COMBINED_WARNING="${COMBINED_WARNING}; ${w}"
  fi
done

if [[ "$ASSIGN_PANE_MATCH" -gt 0 || ( "$ACTIVITY_STATE" == "WAITING" && "$ASSIGN_IDLE_COUNT" -gt 0 ) ]]; then
  emit "available" "assign_idle_capacity" "$ACTIVITY_STATE" "$HEALTH_IDLE" "$HEALTH_SCORE" "$HEALTH_REC" "$COMBINED_WARNING"
  exit 0
fi
if [[ "$ACTIVITY_STATE" == "ERROR" && "$HEALTH_IDLE" == "true" && "$HEALTH_REC" == "HEALTHY" ]]; then
  emit "override_available" "activity_error_but_health_idle_healthy" "$ACTIVITY_STATE" "$HEALTH_IDLE" "$HEALTH_SCORE" "$HEALTH_REC" "${COMBINED_WARNING:-stale_chevron_or_api_error_pattern}"
  exit 2
fi
case "$ACTIVITY_STATE" in
  ERROR|STALLED|UNKNOWN) emit "blocked" "activity_${ACTIVITY_STATE}" "$ACTIVITY_STATE" "$HEALTH_IDLE" "$HEALTH_SCORE" "$HEALTH_REC" "$COMBINED_WARNING"; exit 1 ;;
esac
emit "blocked" "activity_${ACTIVITY_STATE}" "$ACTIVITY_STATE" "$HEALTH_IDLE" "$HEALTH_SCORE" "$HEALTH_REC" "$COMBINED_WARNING"
exit 1

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-20-cross-orch-handoff.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-63-phase-tick-bounded-action.md`
