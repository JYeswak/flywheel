#!/bin/bash
# codex-goal-activate.sh
#
# Reliable activation of codex /goal mode in a flywheel pane.
#
# The mechanism (per Joshua-direct 2026-05-20):
#   1. `/goal` must be TYPED keystroke-by-keystroke so codex's slash-command
#      palette engages (shows /goal highlighted in blue in the input box).
#   2. The task text is THEN typed/pasted after.
#   3. Enter submits.
#
# ntm send --file pastes the whole packet as one bracketed-paste block, which
# bypasses codex's slash-command palette → codex sees /goal as literal chat text
# rather than a command, and never enters goal mode.
#
# This script uses tmux send-keys to type /goal first (palette-triggering),
# probes for the primed-blue state, then sends the task text, then Enter,
# then verifies Goal-in-progress within --max-entry-wait-s.
#
# Usage:
#   codex-goal-activate.sh --session flywheel --pane 2 --task-file /tmp/task.txt
#   codex-goal-activate.sh --session flywheel --pane 2 --task "short task"
#
# Exit codes:
#   0 = Goal-in-progress confirmed within window
#   1 = activation failed (no Goal-in-progress after window)
#   2 = pre-flight failed (pane not ready, codex not running, etc.)
#   3 = primed-blue state never reached after /goal keystrokes
#
# Schema: codex_goal_activate.v1

set -euo pipefail

SESSION=""
PANE=""
TASK=""
TASK_FILE=""
MAX_ENTRY_WAIT_S=30
PRIMED_PROBE_TIMEOUT_S=15
JSON_OUT=false

usage() {
  cat <<USAGE
Usage: $0 --session <s> --pane <n> (--task <txt> | --task-file <path>)
                [--max-entry-wait-s 30] [--primed-probe-timeout-s 5] [--json]
USAGE
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session) SESSION="$2"; shift 2 ;;
    --pane) PANE="$2"; shift 2 ;;
    --task) TASK="$2"; shift 2 ;;
    --task-file) TASK_FILE="$2"; shift 2 ;;
    --max-entry-wait-s) MAX_ENTRY_WAIT_S="$2"; shift 2 ;;
    --primed-probe-timeout-s) PRIMED_PROBE_TIMEOUT_S="$2"; shift 2 ;;
    --json) JSON_OUT=true; shift ;;
    -h|--help) usage ;;
    *) echo "unknown flag: $1" >&2; usage ;;
  esac
done

[[ -z "$SESSION" || -z "$PANE" ]] && usage
[[ -z "$TASK" && -z "$TASK_FILE" ]] && { echo "must provide --task or --task-file" >&2; exit 2; }
[[ -n "$TASK_FILE" ]] && TASK="$(cat "$TASK_FILE")"

TARGET="${SESSION}:0.${PANE}"

emit_json() {
  local outcome="$1" stage="$2" detail="$3"
  if [[ "$JSON_OUT" == "true" ]]; then
    printf '{"schema_version":"codex_goal_activate.v1","ts":"%s","session":"%s","pane":%s,"outcome":"%s","stage":"%s","detail":"%s"}\n' \
      "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$SESSION" "$PANE" "$outcome" "$stage" "$detail"
  else
    echo "[$(date -u +%H:%M:%S)] $outcome stage=$stage detail=$detail" >&2
  fi
}

classify_pane_state() {
  local snap
  snap="$(tmux capture-pane -t "$TARGET" -p 2>/dev/null | tail -15)"
  if echo "$snap" | grep -qE 'Pursuing goal \(([0-9]+[ms]|[0-9]+m [0-9]+s)'; then echo "goal-in-progress"
  elif echo "$snap" | grep -q "Replace current goal"; then echo "replace-goal-dialog"
  elif echo "$snap" | grep -q "Goal paused"; then echo "goal-paused"
  elif echo "$snap" | grep -q "Goal completed"; then echo "goal-completed"
  elif echo "$snap" | grep -qE 'Worked for [0-9]+m [0-9]+s'; then echo "goal-completing"
  elif echo "$snap" | grep -qE "Working \([0-9]+s"; then echo "working-non-goal"
  elif echo "$snap" | grep -q "Application not found\|josh@"; then echo "shell-no-codex"
  else echo "idle-chat"
  fi
}

handle_replace_dialog() {
  # If a Replace-goal dialog appears, send Enter to confirm "Replace current goal" (highlighted default)
  local snap
  snap="$(tmux capture-pane -t "$TARGET" -p 2>/dev/null | tail -10)"
  if echo "$snap" | grep -q "Replace current goal"; then
    emit_json "info" "stage4.5" "Replace-goal dialog detected — sending Enter to confirm"
    tmux send-keys -t "$TARGET" Enter 2>/dev/null
    sleep 2
    return 0
  fi
  return 1
}

probe_primed_blue_state() {
  # codex's input box shows `› /goal` (with /goal in blue) when palette engaged.
  # We probe by capturing the prompt area and checking for the /goal token.
  local snap
  snap="$(tmux capture-pane -t "$TARGET" -p 2>/dev/null | tail -10)"
  echo "$snap" | grep -qE '›[[:space:]]+/goal( |$)'
}

# Pre-flight
state="$(classify_pane_state)"
emit_json "info" "preflight" "initial_state=$state"

case "$state" in
  shell-no-codex)
    emit_json "fail" "preflight" "codex not running on pane — relaunch required first"
    exit 2
    ;;
  goal-in-progress)
    emit_json "fail" "preflight" "pane already has active goal — finish or abandon before re-activating"
    exit 2
    ;;
  goal-paused)
    emit_json "info" "preflight" "pane goal-paused — will type /goal (codex treats fresh /goal as new goal, overriding pause)"
    ;;
  goal-completed|idle-chat)
    emit_json "info" "preflight" "pane ready for fresh /goal activation"
    ;;
  working-non-goal)
    emit_json "fail" "preflight" "working-non-goal — Joshua-rule violation already present; interrupt + clean before activate"
    exit 2
    ;;
esac

# Stage 1: type /goal keystroke-by-keystroke to trigger codex slash-command palette
emit_json "info" "stage1" "typing /goal as keystrokes to trigger palette"
tmux send-keys -t "$TARGET" "/" "g" "o" "a" "l" 2>/dev/null
sleep 1

# Probe for primed-blue state
primed=false
for ((i=0; i<PRIMED_PROBE_TIMEOUT_S; i++)); do
  if probe_primed_blue_state; then primed=true; break; fi
  sleep 1
done

if [[ "$primed" != "true" ]]; then
  emit_json "fail" "stage2" "primed-blue state never reached after /goal keystrokes within ${PRIMED_PROBE_TIMEOUT_S}s"
  exit 3
fi
emit_json "info" "stage2" "primed-blue confirmed — /goal palette engaged"

# Stage 3: type the task text via send-keys -l (literal mode, paste-safe)
# Use a temp file to avoid arg-length issues; tmux load-buffer + paste-buffer is the canonical large-text path
buf_name="codex-goal-task-$$"
task_tmp="$(mktemp)"
trap 'rm -f "$task_tmp"; tmux delete-buffer -b "$buf_name" 2>/dev/null || true' EXIT
printf "%s" "$TASK" > "$task_tmp"
tmux load-buffer -b "$buf_name" "$task_tmp"
# Send a leading space so the palette stays engaged on /goal (some codex versions need the space to commit the slash-command argument)
tmux send-keys -t "$TARGET" " " 2>/dev/null
sleep 0.3
# CRITICAL: use bracketed paste (-p) so codex treats content as a paste event, not
# keystroke-by-keystroke. Without -p, the slash-command palette eats every `/`
# character in the pasted content, corrupting file paths and large packets.
tmux paste-buffer -p -b "$buf_name" -t "$TARGET" 2>/dev/null

emit_json "info" "stage3" "task text pasted ($(wc -c < "$task_tmp") bytes)"
sleep 1

# Stage 4: submit with Enter
tmux send-keys -t "$TARGET" Enter 2>/dev/null
emit_json "info" "stage4" "Enter sent"

# Stage 5: verify Goal-in-progress within window; auto-confirm Replace-goal dialog if it appears
verify_start=$(date +%s)
replace_dialog_handled=false
while (( $(date +%s) - verify_start < MAX_ENTRY_WAIT_S )); do
  state="$(classify_pane_state)"
  case "$state" in
    goal-in-progress)
      emit_json "ok" "stage5" "Goal-in-progress confirmed after $(($(date +%s) - verify_start))s"
      exit 0
      ;;
    replace-goal-dialog)
      if [[ "$replace_dialog_handled" == "false" ]]; then
        handle_replace_dialog || true
        replace_dialog_handled=true
      fi
      ;;
    error-state|shell-no-codex)
      emit_json "fail" "stage5" "pane entered $state during activation window"
      exit 1
      ;;
  esac
  sleep 2
done

emit_json "fail" "stage5" "Goal-in-progress not reached within ${MAX_ENTRY_WAIT_S}s (final state=$state)"
exit 1
