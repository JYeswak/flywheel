#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/test-loop-driver-doctor.sh"

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

bash -n "$SCRIPT" && pass "loop_driver_doctor_syntax" || fail "loop_driver_doctor_syntax"
grep -F -- 'ntm send synthetic --pane=1 --no-cass-check --file /tmp/synthetic-prompt' "$SCRIPT" >/dev/null \
  && pass "loop_driver_tick_script_no_cass_check_argv_order" || fail "loop_driver_tick_script_no_cass_check_argv_order"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
