#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/flywheel-resume"

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

bash -n "$SCRIPT" && pass "resume_syntax" || fail "resume_syntax"
grep -F -- '--no-cass-check' "$SCRIPT" >/dev/null \
  && pass "resume_no_cass_check_flag_present" || fail "resume_no_cass_check_flag_present"
grep -F -- '"$NTM" send "$session" --pane="$pane" --no-cass-check "$cmd"' "$SCRIPT" >/dev/null \
  && pass "resume_argv_order" || fail "resume_argv_order"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
