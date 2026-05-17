#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/zeststream-holding-company.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

run_test() {
  local test_path="$1"
  local label="${test_path#$ROOT/}"
  local out="$TMP/${label//\//_}.out"

  if bash "$test_path" >"$out" 2>&1; then
    pass "$label"
  else
    fail "$label"
    cat "$out" >&2
  fi
}

mapfile -t holding_tests < <(find "$ROOT/tests" -maxdepth 1 -type f -name 'holding-company-*.sh' | sort)

run_test "$ROOT/tests/portfolio-company-registry.sh"
for test_path in "${holding_tests[@]}"; do
  run_test "$test_path"
done

expected_count=$((1 + ${#holding_tests[@]}))
if [[ "$pass_count" -eq "$expected_count" && "$fail_count" -eq 0 ]]; then
  printf 'RESULT pass=%s fail=%s checked=%s\n' "$pass_count" "$fail_count" "$expected_count"
  exit 0
fi

printf 'RESULT pass=%s fail=%s checked=%s\n' "$pass_count" "$fail_count" "$expected_count" >&2
exit 1
