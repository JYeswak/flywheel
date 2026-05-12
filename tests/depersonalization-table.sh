#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$ROOT"

pass_count=0
fail_count=0

pass() {
  pass_count=$((pass_count + 1))
  printf 'PASS %s\n' "$1"
}

fail() {
  fail_count=$((fail_count + 1))
  printf 'FAIL %s\n' "$1" >&2
}

if python3 scripts/validate-depersonalization-table.py >/tmp/flywheel-depersonalization-table-validation.json; then
  pass "table validates"
else
  cat /tmp/flywheel-depersonalization-table-validation.json >&2 || true
  fail "table validates"
fi

if jq -e '.status == "pass" and .rows >= 15 and (.errors | length) == 0' /tmp/flywheel-depersonalization-table-validation.json >/dev/null; then
  pass "validation receipt shape"
else
  fail "validation receipt shape"
fi

for expected in direct-identifier client-identifier path-identifier session-identifier runtime-identifier quasi-identifier; do
  if rg -q "class: ${expected}" de-personalization-table.yaml; then
    pass "class covered: ${expected}"
  else
    fail "class covered: ${expected}"
  fi
done

if rg -q 'risk: credential' de-personalization-table.yaml; then
  fail "table should not contain credential values"
else
  pass "no credential values in table"
fi

if python3 scripts/validate-depersonalization-table.py /tmp/missing-table.yaml >/tmp/flywheel-missing-table-validation.json 2>/dev/null; then
  fail "missing table rejected"
else
  pass "missing table rejected"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
