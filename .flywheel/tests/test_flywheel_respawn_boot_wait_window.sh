#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
COMMAND_PATH="${FLYWHEEL_RESPAWN_COMMAND_PATH:-$HOME/.claude/commands/flywheel/respawn.md}"
SKILL_PATH="${FLYWHEEL_RESPAWN_SKILL_PATH:-$(find "$HOME/.claude/skills" -path '*flywheel/respawn/SKILL.md' -o -path '*flywheel:respawn/SKILL.md' 2>/dev/null | head -1)}"

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_contains() {
  local file="$1" pattern="$2" label="$3"
  if grep -q -- "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label"
    sed -n '120,245p' "$file" >&2 || true
  fi
}

assert_not_contains() {
  local file="$1" pattern="$2" label="$3"
  if grep -q -- "$pattern" "$file"; then
    fail "$label"
    grep -n -- "$pattern" "$file" >&2 || true
  else
    pass "$label"
  fi
}

test -n "$SKILL_PATH" && test -e "$SKILL_PATH" && pass "skill_path_found" || fail "skill_path_found"
test -f "$COMMAND_PATH" && pass "command_path_found" || fail "command_path_found"

assert_contains "$SKILL_PATH" "15-20 seconds" "skill_wait_window_15_20"
assert_not_contains "$SKILL_PATH" "Wait 5-8 seconds" "skill_wait_window_no_5_8"
assert_contains "$SKILL_PATH" "stale scrollback" "skill_stale_scrollback_warning"
assert_contains "$SKILL_PATH" "Probing too fast post-respawn" "skill_antipattern_row"
assert_contains "$SKILL_PATH" "--robot-tail=<session> --panes=<pane> --lines=10" "skill_robot_tail_probe"
assert_contains "$COMMAND_PATH" "15-20 seconds" "command_wait_window_15_20"
assert_contains "$COMMAND_PATH" "Robot-activity .*codex_chevron_prompt" "command_error_with_chevron_note"

printf 'Summary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
