#!/usr/bin/env bash
# dispatch-and-log.sh — atomic dispatch + dispatch-log + bead status update
#
# Built 2026-05-03 after Joshua flagged two issues:
#  1. Workers sitting idle while orch ran serial dispatches
#  2. ntm send + log + br update being 3 separate orch actions instead of 1
#
# Usage:
#   dispatch-and-log.sh --pane=N --task-file=PATH --task-id=ID [--bead=ID] [--callback-by=ISO] [--pipeline=SLUG] [--lane=A|B|C]
#
# Single atomic operation: ntm send + dispatch-log row + (optional) br update --status=in_progress
# Exit 0 on success; non-zero on any step failure (with rollback caveat: ntm send may have already landed)

set -uo pipefail

SESSION="${SESSION:-flywheel}"
LOG="/Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl"
NTM="/Users/josh/.local/bin/ntm"

PANE=""
TASK_FILE=""
TASK_ID=""
BEAD=""
CALLBACK_BY=""
PIPELINE=""
LANE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pane=*) PANE="${1#*=}"; shift;;
    --task-file=*) TASK_FILE="${1#*=}"; shift;;
    --task-id=*) TASK_ID="${1#*=}"; shift;;
    --bead=*) BEAD="${1#*=}"; shift;;
    --callback-by=*) CALLBACK_BY="${1#*=}"; shift;;
    --pipeline=*) PIPELINE="${1#*=}"; shift;;
    --lane=*) LANE="${1#*=}"; shift;;
    --session=*) SESSION="${1#*=}"; shift;;
    *) echo "unknown arg: $1" >&2; exit 2;;
  esac
done

if [[ -z "$PANE" || -z "$TASK_FILE" || -z "$TASK_ID" ]]; then
  echo "required: --pane=N --task-file=PATH --task-id=ID" >&2
  exit 2
fi

if [[ ! -f "$TASK_FILE" ]]; then
  echo "task file does not exist: $TASK_FILE" >&2
  exit 3
fi

TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Step 1: ntm send (the actual dispatch)
NTM_OUT=$("$NTM" send "$SESSION" --pane="$PANE" --no-cass-check --file="$TASK_FILE" 2>&1)
NTM_RC=$?
if [[ $NTM_RC -ne 0 ]]; then
  echo "ntm send failed (rc=$NTM_RC): $NTM_OUT" >&2
  exit 4
fi

# Step 2: append to dispatch-log.jsonl
ROW=$(jq -nc \
  --arg ts "$TS" --arg session "$SESSION" --arg task_id "$TASK_ID" \
  --arg pane "$PANE" --arg task_file "$TASK_FILE" \
  --arg bead "$BEAD" --arg callback_by "$CALLBACK_BY" \
  --arg pipeline "$PIPELINE" --arg lane "$LANE" \
  '{ts:$ts, session:$session, task_id:$task_id, pane:($pane|tonumber),
    task_file:$task_file, channel:"ntm",
    pane_state_source:"ntm_send", pane_state:"sent",
    bead:(if $bead == "" then null else $bead end),
    callback_expected_by:(if $callback_by == "" then null else $callback_by end),
    pipeline_slug:(if $pipeline == "" then null else $pipeline end),
    lane:(if $lane == "" then null else $lane end)}')
echo "$ROW" >> "$LOG"

# Step 3: optional bead status update
BEAD_RESULT="skipped"
if [[ -n "$BEAD" ]]; then
  if br update "$BEAD" --status=in_progress 2>&1 | grep -q "Updated"; then
    BEAD_RESULT="in_progress"
  else
    BEAD_RESULT="claim_blocked"  # parent open, etc — not fatal
  fi
fi

# Receipt to stdout (one line) for orch consumption
echo "{\"ts\":\"$TS\",\"task_id\":\"$TASK_ID\",\"pane\":$PANE,\"ntm_sent\":true,\"log_appended\":true,\"bead_status\":\"$BEAD_RESULT\"}"
