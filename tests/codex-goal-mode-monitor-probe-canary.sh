#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/codex-goal-mode-monitor-probe.sh"
FIX="$ROOT/tests/codex-goal-mode-monitor-probe-canary-fixtures"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/codex-goal-mode-probe-canary.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0

ok_json() {
  local name="$1" fixture="$2" layer="$3" expr="$4"
  local out="$TMP/${name//[^A-Za-z0-9_]/_}.json"
  set +e
  CODEX_GOAL_MODE_SESSION=fixture \
  CODEX_GOAL_MODE_STATE_DIR="$TMP/state" \
  CODEX_GOAL_MODE_TRAUMA_LOG="$TMP/trauma.jsonl" \
  CODEX_GOAL_MODE_UNKNOWN_LOG="$TMP/unknown.jsonl" \
  CODEX_GOAL_MODE_BYPASS_AUDIT="$TMP/bypass.jsonl" \
  CODEX_GOAL_MODE_CAPTURE_FILE="$FIX/$fixture" \
    "$SCRIPT" --pane 2 --dispatch-id "$name" --layer "$layer" --max-entry-wait-s 0 --json >"$out"
  rc=$?
  set -e
  if jq -e "$expr" "$out" >/dev/null; then
    pass=$((pass + 1))
    printf 'ok %d - %s\n' "$pass" "$name"
  else
    fail=$((fail + 1))
    printf 'not ok %d - %s rc=%s\n' "$((pass + fail))" "$name" "$rc" >&2
    cat "$out" >&2
  fi
}

ok_json "canary-active-goal-timer" "01-goal-in-progress.txt" 2 '.status == "ok" and .state == "goal-in-progress"'
ok_json "canary-completed-paren-form" "02-goal-completed-paren.txt" 3 '.status == "ok" and .state == "goal-completed"'
ok_json "canary-completed-terminal-form" "03-goal-completed-terminal.txt" 3 '.status == "ok" and .state == "goal-completed"'
ok_json "canary-replace-dialog" "04-replace-goal-dialog.txt" 3 '.status == "ok" and .state == "replace-goal-dialog"'
ok_json "canary-goal-active-objective-working" "05-goal-active-objective-working.txt" 2 '.status == "ok" and .state == "goal-in-progress"'
ok_json "canary-goal-active-objective-standalone" "06-goal-active-objective-standalone.txt" 3 '.status == "ok" and .state == "idle-chat"'
ok_json "canary-goal-paused" "07-goal-paused.txt" 3 '.status == "ok" and .state == "goal-paused"'
ok_json "canary-working-non-goal" "08-working-non-goal.txt" 3 '.status == "trauma_fired" and .state == "working-non-goal" and .trauma_class == "codex-goal-mode-bypassed"'
ok_json "canary-error-state" "09-error-state.txt" 3 '.status == "ok" and .state == "error-state"'

printf 'SUMMARY pass=%d fail=%d\n' "$pass" "$fail"
[[ "$pass" -eq 9 && "$fail" -eq 0 ]]
