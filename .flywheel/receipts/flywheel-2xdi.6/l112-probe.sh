#!/usr/bin/env bash
set -euo pipefail

test_file=/Users/josh/.claude/skills/.flywheel/tests/test_flywheel_loop_readiness_gate.sh

bash -n "$test_file"
out="$("$test_file")"

rg -q 'ALL PASS \(flywheel_loop_readiness_gate\)' <<<"$out"
printf 'pass\n'
