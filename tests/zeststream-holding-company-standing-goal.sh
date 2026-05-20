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
  local script_names="$TMP/holding-script-names.txt"
  local missing_tests="$TMP/missing-tests.txt"
  local missing_schemas="$TMP/missing-schemas.txt"
  local missing_scripts="$TMP/missing-scripts.txt"

  find "$ROOT/.flywheel/validation-schema/v1" -maxdepth 1 -type f -name 'holding-company-*.schema.json' \
    | sed 's#.*/##; s#\.schema\.json$##' \
    | sort >"$schema_names"
  find "$ROOT/tests" -maxdepth 1 -type f -name 'holding-company-*.sh' \
    | sed 's#.*/##; s#\.sh$##' \
    | sort >"$test_names"
  find "$ROOT/.flywheel/scripts" -maxdepth 1 -type f -name 'holding-company-*-validate.py' \
    | sed 's#.*/##; s#-validate\.py$##' \
    | sort >"$script_names"

  comm -23 "$schema_names" "$test_names" >"$missing_tests"
  comm -13 "$schema_names" "$test_names" >"$missing_schemas"
  comm -23 "$schema_names" "$script_names" >"$missing_scripts"

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

  if [[ -s "$missing_scripts" ]]; then
    fail "holding-company schema/validator inventory parity"
    printf 'missing validator scripts for schemas:\n' >&2
    sed 's/^/  /' "$missing_scripts" >&2
  else
    pass "holding-company schema/validator inventory parity"
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

check_validator_failure_code_coverage() {
  local report="$TMP/validator-failure-code-coverage.json"
  if python3 - "$ROOT" >"$report" <<'PY'
import json
import re
import sys
from pathlib import Path

root = Path(sys.argv[1])
scripts = sorted((root / ".flywheel/scripts").glob("holding-company-*-validate.py"))
scripts.append(root / ".flywheel/scripts/portfolio-company-registry-validate.py")
test_paths = sorted((root / "tests").glob("holding-company-*.sh"))
test_paths.append(root / "tests/portfolio-company-registry.sh")
test_text = "\n".join(path.read_text(encoding="utf-8") for path in test_paths)
missing: dict[str, list[str]] = {}
for script in scripts:
    codes = sorted(set(re.findall(r'"code"\s*:\s*f?"([^"{]+)', script.read_text(encoding="utf-8"))))
    uncovered = [code for code in codes if code not in test_text]
    if uncovered:
        missing[str(script.relative_to(root))] = uncovered
print(json.dumps({"missing": missing}, indent=2, sort_keys=True))
sys.exit(1 if missing else 0)
PY
  then
    pass "holding-company validator failure-code coverage"
  else
    fail "holding-company validator failure-code coverage"
    jq . "$report" >&2 || cat "$report" >&2
  fi
}

mapfile -t holding_tests < <(find "$ROOT/tests" -maxdepth 1 -type f -name 'holding-company-*.sh' | sort)

check_inventory_parity
check_portfolio_registry_pair
check_validator_failure_code_coverage
run_test "$ROOT/tests/portfolio-company-registry.sh"
for test_path in "${holding_tests[@]}"; do
  run_test "$test_path"
done

expected_count=$((5 + ${#holding_tests[@]}))
if [[ "$pass_count" -eq "$expected_count" && "$fail_count" -eq 0 ]]; then
  printf 'RESULT pass=%s fail=%s checked=%s\n' "$pass_count" "$fail_count" "$expected_count"
  exit 0
fi

printf 'RESULT pass=%s fail=%s checked=%s\n' "$pass_count" "$fail_count" "$expected_count" >&2
exit 1
