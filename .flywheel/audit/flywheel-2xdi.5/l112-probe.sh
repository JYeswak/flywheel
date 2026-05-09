#!/usr/bin/env bash
set -euo pipefail

test_file=/Users/josh/.claude/skills/.flywheel/tests/test_flywheel_loop_memory_health.sh

bash -n "$test_file"
out="$(timeout 90 "$test_file")"

rg -q 'ALL PASS \(flywheel_loop_memory_health\)' <<<"$out"
printf 'pass\n'
