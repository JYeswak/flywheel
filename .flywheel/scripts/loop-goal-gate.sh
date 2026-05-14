#!/usr/bin/env bash
# loop-goal-gate.sh — gated-loop halt check (bszgl.3 / MISSION anchor extension 2026-05-14)
#
# Reads the current goal's blocker set. If ALL blockers are owner:external or
# owner:joshua, emits GATED and exits 2, signalling the loop to halt rather than
# burn tokens on adjacent work.
#
# Exit codes:
#   0 — not gated, loop may continue
#   1 — error reading blockers
#   2 — GATED: all remaining blockers require external action, halt the loop
#
# Usage:
#   loop-goal-gate.sh [--repo PATH] [--json]
#   loop-goal-gate.sh --blockers-json '{"blockers":[...]}' [--json]
#
# The --blockers-json flag accepts pre-computed blocker output from
# scripts/publication_readiness.py --json or any script emitting
# {"blockers":[{"owner":"joshua",...},{"owner":"external-system",...}]}
#
# Without --blockers-json, reads from publication_readiness.py --json in REPO.
#
# Doctrine: .flywheel/MISSION.md anchor extension 2026-05-14
# Enforcement: flywheel:tick calls this before every dispatch decision.

set -euo pipefail

REPO="${LOOP_GOAL_GATE_REPO:-$PWD}"
JSON_OUT=0
BLOCKERS_JSON=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="$2"; shift 2 ;;
    --json) JSON_OUT=1; shift ;;
    --blockers-json) BLOCKERS_JSON="$2"; shift 2 ;;
    --help) grep '^#' "$0" | sed 's/^# \?//'; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }

emit() {
  local status="$1" reason="$2" total="${3:-0}" external="${4:-0}"
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc \
      --arg status "$status" \
      --arg reason "$reason" \
      --arg repo "$REPO" \
      --arg ts "$(now_iso)" \
      --argjson total "$total" \
      --argjson external "$external" \
      '{schema_version:"loop-goal-gate/v1",status:$status,reason:$reason,repo:$repo,ts:$ts,
        blocker_total:$total,external_blocker_count:$external}'
  else
    echo "loop-goal-gate: status=$status reason=$reason blockers_total=$total external=$external"
  fi
}

# ── Resolve blocker set ────────────────────────────────────────────────────────

if [[ -z "$BLOCKERS_JSON" ]]; then
  READINESS_SCRIPT="$REPO/scripts/publication_readiness.py"
  if [[ -f "$READINESS_SCRIPT" ]]; then
    BLOCKERS_JSON="$(python3 "$READINESS_SCRIPT" --json 2>/dev/null || echo '{}')"
  else
    # Fallback: check open beads for external-owner blockers via br
    BR_BIN="${BR_BIN:-br}"
    if command -v "$BR_BIN" &>/dev/null; then
      BLOCKERS_JSON="$("$BR_BIN" list --status=open --json 2>/dev/null | \
        jq '{blockers:[.[]|select(.priority=="P0")|{owner:(.owner//"agent"),code:.id,blocker_code:.id}]}' \
        2>/dev/null || echo '{}')"
    else
      emit "unknown" "no_readiness_script_or_br" 0 0
      exit 1
    fi
  fi
fi

# ── Classify blockers ──────────────────────────────────────────────────────────

TOTAL_BLOCKERS=0
EXTERNAL_BLOCKERS=0

# publication_readiness.py emits top-level "blockers" array with "owner" field
# Each blocker: {"code":"remote_repo_private","owner":"joshua",...}
while IFS= read -r blocker; do
  [[ -z "$blocker" ]] && continue
  TOTAL_BLOCKERS=$((TOTAL_BLOCKERS + 1))
  owner="$(printf '%s\n' "$blocker" | jq -r '.owner // "agent"' 2>/dev/null || echo "agent")"
  case "$owner" in
    joshua|external|external-system|human|operator)
      EXTERNAL_BLOCKERS=$((EXTERNAL_BLOCKERS + 1))
      ;;
  esac
done < <(printf '%s\n' "$BLOCKERS_JSON" | jq -c '.blockers[]? // .next_actions[]? // empty' 2>/dev/null || true)

# Also check top-level status field from publication_readiness.py
TOP_STATUS="$(printf '%s\n' "$BLOCKERS_JSON" | jq -r '.status // "unknown"' 2>/dev/null || echo "unknown")"

# ── Verdict ────────────────────────────────────────────────────────────────────

if [[ "$TOTAL_BLOCKERS" -eq 0 ]]; then
  if [[ "$TOP_STATUS" == "pass" ]]; then
    emit "pass" "goal_complete_no_blockers" 0 0
    exit 0
  fi
  # No blockers found but status not pass — can't determine gating
  emit "clear" "no_blockers_detected_loop_may_continue" 0 0
  exit 0
fi

if [[ "$TOTAL_BLOCKERS" -gt 0 && "$EXTERNAL_BLOCKERS" -eq "$TOTAL_BLOCKERS" ]]; then
  emit "gated" "all_${TOTAL_BLOCKERS}_blockers_require_external_action_halt_loop" \
    "$TOTAL_BLOCKERS" "$EXTERNAL_BLOCKERS"
  exit 2
fi

emit "clear" "agent_actionable_blockers_exist_loop_may_continue" \
  "$TOTAL_BLOCKERS" "$EXTERNAL_BLOCKERS"
exit 0
