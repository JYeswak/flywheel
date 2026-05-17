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

check_inventory_parity() {
  local schema_names="$TMP/holding-schema-names.txt"
  local test_names="$TMP/holding-test-names.txt"
  local missing_tests="$TMP/missing-tests.txt"
  local missing_schemas="$TMP/missing-schemas.txt"

  find "$ROOT/.flywheel/validation-schema/v1" -maxdepth 1 -type f -name 'holding-company-*.schema.json' \
    | sed 's#.*/##; s#\.schema\.json$##' \
    | sort >"$schema_names"
  find "$ROOT/tests" -maxdepth 1 -type f -name 'holding-company-*.sh' \
    | sed 's#.*/##; s#\.sh$##' \
    | sort >"$test_names"

  comm -23 "$schema_names" "$test_names" >"$missing_tests"
  comm -13 "$schema_names" "$test_names" >"$missing_schemas"

  if [[ -s "$missing_tests" || -s "$missing_schemas" ]]; then
    fail "holding-company schema/test inventory parity"
    if [[ -s "$missing_tests" ]]; then
      printf 'missing tests for schemas:\n' >&2
      sed 's/^/  /' "$missing_tests" >&2
    fi
    if [[ -s "$missing_schemas" ]]; then
      printf 'missing schemas for tests:\n' >&2
      sed 's/^/  /' "$missing_schemas" >&2
    fi
  else
    pass "holding-company schema/test inventory parity"
  fi
}

check_portfolio_registry_pair() {
  local schema="$ROOT/.flywheel/validation-schema/v1/portfolio-company-registry.schema.json"
  local test="$ROOT/tests/portfolio-company-registry.sh"

  if [[ -f "$schema" && -f "$test" ]]; then
    pass "portfolio-company registry schema/test pair"
  else
    fail "portfolio-company registry schema/test pair"
    [[ -f "$schema" ]] || printf 'missing schema: %s\n' "${schema#$ROOT/}" >&2
    [[ -f "$test" ]] || printf 'missing test: %s\n' "${test#$ROOT/}" >&2
  fi
}

mapfile -t holding_tests < <(find "$ROOT/tests" -maxdepth 1 -type f -name 'holding-company-*.sh' | sort)

check_inventory_parity
check_portfolio_registry_pair
run_test "$ROOT/tests/portfolio-company-registry.sh"
for test_path in "${holding_tests[@]}"; do
  run_test "$test_path"
done

expected_count=$((3 + ${#holding_tests[@]}))
if [[ "$pass_count" -eq "$expected_count" && "$fail_count" -eq 0 ]]; then
  printf 'RESULT pass=%s fail=%s checked=%s\n' "$pass_count" "$fail_count" "$expected_count"
  exit 0
fi

printf 'RESULT pass=%s fail=%s checked=%s\n' "$pass_count" "$fail_count" "$expected_count" >&2
exit 1
