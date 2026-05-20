#!/bin/bash
# codex-goal-activate.sh
#
# CANONICAL ORIGIN: skillos canonical at /Users/josh/Developer/skillos/.flywheel/scripts/codex-goal-activate.sh
# phase-c-allow-divergence (intentional local-divergence, per memory feedback_convergent_evolution_is_canonical_signal):
#   1. Bracketed-paste fix (tmux paste-buffer -p flag) — adopted from canonical
#   2. PRIMED_PROBE_TIMEOUT_S default 5→15 — flywheel-side empirical: codex 0.130
#      palette render delay observed >5s on some captures; 15s eliminates false-fails
#   3. capture-pane tail -10 → tail -30 — flywheel-side empirical: codex TUI renders
#      many blank trailing lines that hid the primed /goal line; -30 covers the gap
#   4. Stage 0.5 stale-chevron-clear functions — adopted from skillos canonical
#      commits 3a647cc4 + 8c057a67 (greenlight 1 ratified 2026-05-20T06:18Z)
#   5. Stage 0.3 context-pre-clear (/clear before /goal) — adopted from skillos
#      canonical commit 1ed3ea30 (bypass-mitigation candidate 2 ratified 2026-05-20T06:52Z).
#      Escape hatch: CODEX_GOAL_SKIP_CONTEXT_CLEAR=1 for A/B testing.
# Functional parity with canonical maintained; shasum divergence is intentional + documented.
# Reverse-propagation candidates: bug-patches 2+3 should land in skillos canonical
# at next bi-directional sync cadence.
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
  local snap chevron_text
  snap="$(tmux capture-pane -t "$TARGET" -p 2>/dev/null | tail -15)"
  if echo "$snap" | grep -qE 'Pursuing goal \(([0-9]+[ms]|[0-9]+m [0-9]+s)'; then echo "goal-in-progress"
  elif echo "$snap" | grep -q "Replace current goal"; then echo "replace-goal-dialog"
  elif echo "$snap" | grep -q "Goal paused"; then echo "goal-paused"
  elif echo "$snap" | grep -q "Goal completed"; then echo "goal-completed"
  elif echo "$snap" | grep -qE 'Worked for [0-9]+m [0-9]+s'; then echo "goal-completing"
  elif echo "$snap" | grep -q "Conversation interrupted"; then echo "codex_session_interrupted"
  elif echo "$snap" | grep -qE "Working \([0-9]+s"; then echo "working-non-goal"
  elif echo "$snap" | grep -q "Application not found\|josh@"; then echo "shell-no-codex"
  else
    # Stale-chevron detection (CFS:1 N=4 trauma class 2026-05-20):
    # Plain ntm send lands text in chevron but codex doesn't auto-submit; subsequent
    # /clear + /goal keystrokes append to stale buffer → 'Conversation interrupted'.
    # Detect by capturing the chevron-line text; if it's NOT a default codex idle
    # placeholder hint, treat as stale-chevron-pending-text → caller must respawn.
    chevron_text="$(echo "$snap" | grep -oE '^›[[:space:]]+.+' | tail -1 | sed -E 's/^›[[:space:]]+//')"
    if [[ -n "$chevron_text" ]] && ! echo "$chevron_text" | grep -qE '^(Implement \{feature\}|Find and fix a bug in @filename|Improve documentation in @filename|Run /review on my current changes|Summarize recent commits|Use /skills to list available skills|Explain this codebase|Write tests for @filename)$'; then
      echo "stale-chevron-pending-text"
    else
      echo "idle-chat"
    fi
  fi
}

handle_replace_dialog() {
  # If a Replace-goal dialog appears, send Enter to confirm "Replace current goal" (highlighted default)
  local snap
  snap="$(tmux capture-pane -t "$TARGET" -p 2>/dev/null | tail -30)"
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
  snap="$(tmux capture-pane -t "$TARGET" -p 2>/dev/null | tail -30)"
  echo "$snap" | grep -qE '›[[:space:]]+/goal( |$)'
}

chevron_line_has_residue() {
  # Adopted from skillos canonical 2026-05-20 (greenlight 1 ratified).
  # Residue = chevron PRIMED with /goal slash-command palette (engages-once
  # state). Default codex idle placeholders like "› Implement {feature}" or
  # "› Run /review on my current changes" are NOT residue — they are the
  # normal idle state and re-typing /goal works fine over them.
  local line="$1"
  [[ -n "$line" ]] || return 1
  echo "$line" | grep -qE '^›[[:space:]]+/goal([[:space:]]|$)'
}

clear_stale_chevron_residue() {
  # Stage 0.5 — clear stale /goal palette engaged state before re-typing /goal.
  # Adopted from skillos canonical 2026-05-20 commits 3a647cc4 + 8c057a67.
  # N=3 today on skillos; primitive prevents bypass-class fires from stale-chevron.
  local snap chevron_line
  snap="$(tmux capture-pane -t "$TARGET" -p 2>/dev/null | tail -3 || true)"
  chevron_line="$(echo "$snap" | grep -E '^›[[:space:]]*' | tail -1 || true)"
  if ! chevron_line_has_residue "$chevron_line"; then
    return 0
  fi

  tmux send-keys -t "$TARGET" Escape 2>/dev/null
  sleep 1
  tmux send-keys -t "$TARGET" C-u 2>/dev/null
  sleep 1

  snap="$(tmux capture-pane -t "$TARGET" -p 2>/dev/null | tail -3 || true)"
  chevron_line="$(echo "$snap" | grep -E '^›[[:space:]]*' | tail -1 || true)"
  if chevron_line_has_residue "$chevron_line"; then
    emit_json "fail" "stage0.5" "stale-chevron residue remained after Escape + C-u"
    exit 2
  fi

  emit_json "info" "stage0.5" "cleared stale-chevron residue before /goal palette activation"
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

# Stage 0.3: context-pre-clear (bypass-mitigation candidate 2 — flywheel:1 ratified 2026-05-20T06:52Z).
# Adopted from skillos canonical 2026-05-20 commit 1ed3ea30 (initial) + b4d085db (bug fix per flywheel:1 07:31Z).
# Send /clear slash command to reset codex session-context-state before /goal palette activation.
# Mitigates bypass-class fires correlated with accumulated session context (N=7 observed 2026-05-20).
#
# BUG FIX 2026-05-20T07:31Z: /clear is ALSO a slash command requiring palette engagement (same as /goal).
# Initial impl sent /clear + Enter — Enter didn't submit, /clear stayed primed, then Stage 1 /goal typed
# on top producing "/clear /goal" concatenation. Fix: mirror /goal Stage-3 pattern — keystrokes + probe
# palette + space (commit palette to arg-mode) + Enter (submit). Escape-out if palette never primed.
#
# Skip if CODEX_GOAL_SKIP_CONTEXT_CLEAR=1 (escape hatch for cross-validation A/B testing).
if [[ "${CODEX_GOAL_SKIP_CONTEXT_CLEAR:-0}" != "1" ]]; then
  emit_json "info" "stage0.3" "context pre-clear: sending /clear via palette pattern"
  tmux send-keys -t "$TARGET" "/" "c" "l" "e" "a" "r" 2>/dev/null
  sleep 0.5
  # Probe primed-blue state for /clear (mirror probe_primed_blue_state for /goal)
  snap=$(tmux capture-pane -t "$TARGET" -p 2>/dev/null | tail -10 || true)
  if echo "$snap" | grep -qE '›[[:space:]]+/clear( |$)'; then
    emit_json "info" "stage0.3" "/clear palette primed; sending space+Enter to commit+submit"
    tmux send-keys -t "$TARGET" " " 2>/dev/null
    sleep 0.3
    tmux send-keys -t "$TARGET" Enter 2>/dev/null
    sleep 2
  else
    emit_json "warn" "stage0.3" "/clear palette not primed after keystrokes — skipping submit (won't pollute chevron)"
    # Send Escape to clear any partial input before proceeding to Stage 0.5
    tmux send-keys -t "$TARGET" Escape 2>/dev/null
    sleep 0.5
  fi
fi

# Stage 0.5: clear stale palette/input residue before typing /goal.
clear_stale_chevron_residue

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
