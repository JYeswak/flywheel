#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_contains() {
  local file="$1" pattern="$2" label="$3"
  if rg -q "$pattern" "$ROOT/$file"; then
    pass "$label"
  else
    fail "$label"
  fi
}

assert_contains "AGENTS.md" "/git-stash-janitor" "agents_names_git_stash_janitor"
assert_contains "AGENTS.md" "fleet_stash_bloat_detected" "agents_names_soft_signal"
assert_contains "AGENTS.md" "<basename>-stash-archive-YYYY-MM-DD" "agents_names_bundle_convention"
assert_contains "templates/flywheel-install/AGENTS.md" "/git-stash-janitor" "template_names_git_stash_janitor"
assert_contains ".flywheel/flywheel-loop-tick" "fleet_stash_bloat_probe" "tick_has_probe"
assert_contains ".flywheel/flywheel-loop-tick" 'git -C "\$repo" stash list' "tick_counts_stashes"
assert_contains ".flywheel/flywheel-loop-tick" "fleet_stash_bloat_detected" "tick_emits_soft_signal"
assert_contains ".flywheel/scripts/flywheel-onboard.sh" "stash_health_probe" "onboard_has_stash_health_probe"
assert_contains ".flywheel/scripts/flywheel-onboard.sh" "stash_recommend_before_continue" "onboard_recommends_before_continue"

bash -n "$ROOT/.flywheel/flywheel-loop-tick" && pass "tick_bash_syntax" || fail "tick_bash_syntax"
bash -n "$ROOT/.flywheel/scripts/flywheel-onboard.sh" && pass "onboard_bash_syntax" || fail "onboard_bash_syntax"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
