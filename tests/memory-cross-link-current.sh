#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_ref() {
  local file="$1" needle="$2" label="$3"
  if grep -Fq "$needle" "$ROOT/$file"; then
    pass "$label"
  else
    fail "$label"
  fi
}

assert_ref ".flywheel/doctrine/hook-trauma-class-promotion-discipline.md" \
  "feedback_coordination_collision_detected_saturated_unpromoted.md" \
  "coordination_collision_memory_cross_link"

assert_ref ".flywheel/doctrine/hook-trauma-class-promotion-discipline.md" \
  "coordination-collision-detected" \
  "coordination_collision_trauma_class_named"

assert_ref ".flywheel/doctrine/goal-contract-no-writable-escape.md" \
  "feedback_forever_goals_must_not_hardcode_changing_lists.md" \
  "hardcoded_list_memory_cross_link"

assert_ref ".flywheel/doctrine/goal-contract-no-writable-escape.md" \
  "feedback_or_explanation_escape_is_goodhart_at_goal_layer.md" \
  "or_explanation_memory_cross_link"

assert_ref ".flywheel/doctrine/goal-contract-no-writable-escape.md" \
  "The branch cannot be a document" \
  "writable_escape_receiver_named"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'FAIL memory-cross-link-current pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'OK memory-cross-link-current pass=%d\n' "$pass_count"
