#!/bin/bash
# pane-work-signal-classify.sh — canonical 10-state classifier for codex panes.
#
# Schema: skillos.pane_work_signal.v0.2.2
# Reference spec: .flywheel/specs/pane-work-signal-taxonomy-v0.2.md
#
# Usage:
#   pane-work-signal-classify.sh --session NAME --pane N [--json] [--lines 15]
#
# Output (with --json):
#   {schema_version, ts, session, pane, state, evidence, confidence, suppression_reason}
#
# States (in detection priority order):
#   replace-goal-dialog → goal-in-progress → goal-paused → goal-completing →
#   goal-completed → working-non-goal → error-state →
#   codex_session_interrupted → idle-chat → respawn-residue
#
# Exit 0 on classification success; nonzero only on capture failure.

set -euo pipefail

SESSION=""
PANE=""
JSON_OUT=false
LINES=15

usage() {
  cat <<USAGE >&2
Usage: $0 --session <s> --pane <n> [--json] [--lines 15]
USAGE
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session) SESSION="$2"; shift 2 ;;
    --pane)    PANE="$2"; shift 2 ;;
    --json)    JSON_OUT=true; shift ;;
    --lines)   LINES="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "unknown flag: $1" >&2; usage ;;
  esac
done

[[ -z "$SESSION" || -z "$PANE" ]] && usage

TARGET="${SESSION}:0.${PANE}"
TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

if [[ -n "${PANE_WORK_SIGNAL_FIXTURE_FILE:-}" ]]; then
  if ! snap=$(tail -"$LINES" "$PANE_WORK_SIGNAL_FIXTURE_FILE" 2>/dev/null); then
    if [[ "$JSON_OUT" == "true" ]]; then
      printf '{"schema_version":"skillos.pane_work_signal.v0.2.2","ts":"%s","session":"%s","pane":%s,"state":"capture-failed","evidence":null,"confidence":"NA","suppression_reason":null}\n' \
        "$TS" "$SESSION" "$PANE"
    else
      echo "ERROR: fixture read failed for $PANE_WORK_SIGNAL_FIXTURE_FILE" >&2
    fi
    exit 1
  fi
elif ! snap=$(tmux capture-pane -t "$TARGET" -p 2>/dev/null | tail -"$LINES"); then
  if [[ "$JSON_OUT" == "true" ]]; then
    printf '{"schema_version":"skillos.pane_work_signal.v0.2.2","ts":"%s","session":"%s","pane":%s,"state":"capture-failed","evidence":null,"confidence":"NA","suppression_reason":null}\n' \
      "$TS" "$SESSION" "$PANE"
  else
    echo "ERROR: tmux capture-pane failed for $TARGET" >&2
  fi
  exit 1
fi

# Detect in priority order
state=""
evidence=""
confidence="HIGH"
suppression=""

codex_session_interrupted_evidence() {
  local literal
  for literal in "Conversation interrupted" "Something went wrong" "Application not found"; do
    if grep -Fq "$literal" <<<"$snap"; then
      printf '%s\n' "$literal"
      return 0
    fi
  done
  if grep -Fq "Hit /feedback" <<<"$snap" || { grep -Fq "Hit " <<<"$snap" && grep -Fq "/feedback" <<<"$snap"; }; then
    printf '%s\n' "Hit /feedback"
    return 0
  fi
  return 1
}

# 1. replace-goal-dialog (highest priority — dispatcher must handle)
if echo "$snap" | grep -q "Replace current goal"; then
  state="replace-goal-dialog"
  evidence="Replace current goal"
# 2. goal-in-progress (canonical)
elif echo "$snap" | grep -qE 'Pursuing goal \(([0-9]+[ms]|[0-9]+m [0-9]+s)\)'; then
  state="goal-in-progress"
  evidence=$(echo "$snap" | grep -oE 'Pursuing goal \([^)]+\)' | tail -1)
# 2.5. Goal-active-Objective early transient before Pursuing-goal timer appears
elif echo "$snap" | grep -q "Goal active Objective:"; then
  goal_active_line=$(echo "$snap" | grep "Goal active Objective:" | tail -1)
  if echo "$snap" | grep -qE 'Working \([0-9]+s'; then
    working_line=$(echo "$snap" | grep -oE 'Working \([0-9]+s[^)]*\)' | tail -1)
    state="goal-in-progress"
    evidence="$goal_active_line | $working_line"
    confidence="MED"
  else
    state="idle-chat"
    evidence="$goal_active_line"
    confidence="MED"
    suppression="Goal-active-Objective ambiguous; awaiting Working or Pursuing-goal transition"
  fi
# 3. goal-paused
elif echo "$snap" | grep -q "Goal paused"; then
  state="goal-paused"
  evidence="Goal paused"
# 4. goal-completed
elif echo "$snap" | grep -qE 'Goal achieved \([0-9]+[ms]?\)' || echo "$snap" | grep -qE 'Goal complete\.'; then
  state="goal-completed"
  evidence=$(echo "$snap" | grep -oE 'Goal achieved \([^)]+\)|Goal complete\.' | tail -1)
# 5. goal-completing (transient, suppress higher-layer alerts)
elif echo "$snap" | grep -qE 'Worked for [0-9]+m [0-9]+s'; then
  state="goal-completing"
  evidence=$(echo "$snap" | grep -oE 'Worked for [0-9]+m [0-9]+s' | tail -1)
  suppression="goal-completing transient window — Layer 2/3 should suppress"
# 6. working-non-goal (RED FLAG — Joshua-rule violation)
elif echo "$snap" | grep -qE 'Working \([0-9]+s • esc to interrupt\)'; then
  state="working-non-goal"
  evidence=$(echo "$snap" | grep -oE 'Working \([0-9]+s[^)]*\)' | tail -1)
  confidence="MED"  # may be early-stage transient before Pursuing-goal appears
# 7. error-state (generic codex error/exception text)
elif echo "$snap" | grep -qiE 'codex.*(error|exception)|exception|traceback|panic|fatal error|error:'; then
  state="error-state"
  evidence=$(echo "$snap" | grep -oiE 'codex.*(error|exception)|exception|traceback|panic|fatal error|error:' | head -1)
# 7.5 codex_session_interrupted (Codex UI/session abort literals)
elif interrupted_evidence=$(codex_session_interrupted_evidence); then
  state="codex_session_interrupted"
  evidence="$interrupted_evidence"
# 8. idle-chat (default for prompt-only state)
elif echo "$snap" | grep -qE '^›[[:space:]]'; then
  state="idle-chat"
  evidence="chevron-prompt visible, no goal/working markers"
else
  state="unclassified"
  evidence="(none matched)"
  confidence="LOW"
fi

if [[ "$JSON_OUT" == "true" ]]; then
  # Escape evidence for JSON
  evidence_esc=$(printf '%s' "$evidence" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read())[1:-1])' 2>/dev/null || echo "$evidence")
  printf '{"schema_version":"skillos.pane_work_signal.v0.2.2","ts":"%s","session":"%s","pane":%s,"state":"%s","evidence":"%s","confidence":"%s","suppression_reason":%s}\n' \
    "$TS" "$SESSION" "$PANE" "$state" "$evidence_esc" "$confidence" \
    "$([ -n "$suppression" ] && printf '"%s"' "$suppression" || echo "null")"
else
  echo "state=$state evidence='$evidence' confidence=$confidence ${suppression:+suppression='$suppression'}"
fi

exit 0
