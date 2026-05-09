#!/usr/bin/env bash
# codex-budget-watchdog.sh — when fleet is draining AND all codex panes idle,
# auto-rotate to next caam profile.
#
# Run as a launchd job every 60s OR via flywheel:tick.
#
# Decision tree:
#   1. read codex-budget state
#   2. if fleet_state=ready → no-op
#   3. if fleet_state=draining or limit_hit:
#      a. check ALL codex panes across ALL ntm sessions
#      b. if any THINKING/GENERATING → wait (let in-flight finish)
#      c. if all WAITING → invoke rotate-codex with next profile
#      d. log decision to ledger

set -uo pipefail

STATE_FILE="${CODEX_BUDGET_STATE:-$HOME/.local/state/flywheel/codex-account-budget.json}"
LEDGER="$HOME/.local/state/flywheel/codex-budget-watchdog.jsonl"
ROTATE="$HOME/.local/bin/rotate-codex"
APPLY=0
NEXT_PROFILE="${CODEX_NEXT_PROFILE:-}"

mkdir -p "$(dirname "$LEDGER")"

while [ $# -gt 0 ]; do
  case "$1" in
    --apply) APPLY=1; shift ;;
    --dry-run) APPLY=0; shift ;;
    --next-profile) NEXT_PROFILE="$2"; shift 2 ;;
    *) echo "Unknown: $1" >&2; exit 2 ;;
  esac
done

log() {
  local action="$1" detail="${2:-}"
  echo "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"action\":\"$action\",\"detail\":\"$detail\"}" >> "$LEDGER"
}

if [ ! -f "$STATE_FILE" ]; then
  log "skip" "no_state_file"
  exit 0
fi

FLEET_STATE=$(jq -r '.fleet_state // "ready"' "$STATE_FILE")

if [ "$FLEET_STATE" = "ready" ]; then
  log "skip" "fleet_state=ready"
  exit 0
fi

# === fleet is draining or limit_hit — check all codex panes idle ===
SESSIONS=$(/Users/josh/.local/bin/ntm list 2>/dev/null | awk -F: '/[a-z].*windows/ {gsub(/^ +/,"",$1); print $1}')

THINKING_PANES=""
TOTAL_CODEX=0
IDLE_CODEX=0

for sess in $SESSIONS; do
  PANES=$(/Users/josh/.local/bin/ntm --robot-activity="$sess" --activity-type=codex 2>/dev/null | jq -r '.agents[] | "\(.pane_idx)|\(.state)"' 2>/dev/null)
  if [ -z "$PANES" ]; then continue; fi
  while IFS='|' read -r pane state; do
    [ -z "$pane" ] && continue
    TOTAL_CODEX=$((TOTAL_CODEX + 1))
    case "$state" in
      WAITING) IDLE_CODEX=$((IDLE_CODEX + 1)) ;;
      THINKING|GENERATING) THINKING_PANES="$THINKING_PANES $sess:$pane" ;;
    esac
  done <<< "$PANES"
done

ALL_IDLE=0
[ "$TOTAL_CODEX" -gt 0 ] && [ "$IDLE_CODEX" = "$TOTAL_CODEX" ] && ALL_IDLE=1

# === Update state file with fleet idle status ===
TMP=$(mktemp /tmp/.budget-state.XXXXXX.json)
jq --argjson total "$TOTAL_CODEX" --argjson idle "$IDLE_CODEX" --argjson all_idle "$ALL_IDLE" \
   --arg thinking "$THINKING_PANES" \
  '. + {fleet_panes: {total_codex: $total, idle_codex: $idle, all_idle: ($all_idle == 1), thinking_panes: $thinking}}' \
  "$STATE_FILE" > "$TMP" && mv "$TMP" "$STATE_FILE"

# === Decision ===
if [ "$ALL_IDLE" = "0" ]; then
  log "wait_for_idle" "thinking=$THINKING_PANES idle=$IDLE_CODEX/$TOTAL_CODEX state=$FLEET_STATE"
  echo "[wait] fleet_state=$FLEET_STATE; $IDLE_CODEX/$TOTAL_CODEX codex panes idle; thinking on:$THINKING_PANES"
  exit 0
fi

# All idle — rotate
echo "[ready_to_rotate] fleet_state=$FLEET_STATE; all $TOTAL_CODEX codex panes idle"

if [ "$APPLY" = "0" ]; then
  log "would_rotate_dry_run" "all_idle=$IDLE_CODEX/$TOTAL_CODEX"
  echo "[dry-run] would invoke: $ROTATE ${NEXT_PROFILE:-<interactive>}"
  exit 0
fi

# Apply
if [ -z "$NEXT_PROFILE" ]; then
  echo "[error] --apply requires --next-profile NAME (or env CODEX_NEXT_PROFILE)" >&2
  log "abort" "no_next_profile"
  exit 1
fi

log "rotate_invoked" "profile=$NEXT_PROFILE all_idle=$IDLE_CODEX/$TOTAL_CODEX"
"$ROTATE" "$NEXT_PROFILE"
ROTATE_EXIT=$?
log "rotate_done" "exit=$ROTATE_EXIT profile=$NEXT_PROFILE"
exit $ROTATE_EXIT
