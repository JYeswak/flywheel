#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/holding-company-runway-receipt-validate.py"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/holding-company-runway-receipt.schema.json"
RECEIPT="$ROOT/state/holding-company-runway-current.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/holding-company-runway.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

if python3 -m py_compile "$SCRIPT"; then
  pass "validator py_compile"
else
  fail "validator py_compile"
fi

jq empty "$SCHEMA" && pass "schema json valid" || fail "schema json valid"
jq empty "$RECEIPT" && pass "receipt json valid" || fail "receipt json valid"

"$SCRIPT" --receipt "$RECEIPT" --check-paths --json >"$TMP/current.json"
assert_jq "$TMP/current.json" '.status == "pass" and .runway_gate_status == "blocked" and .required_months == 18 and .verified_runway_months == null' "current not-provided receipt validates but blocks launch"

jq '.status = "pass" | .verified_runway_months = 18.5 | .calculation_basis.scenario = "base" | .calculation_basis.method = "cash_on_hand_divided_by_monthly_burn" | .calculation_basis.last_reviewed_at = "2026-05-17T07:01:00Z"' "$RECEIPT" >"$TMP/pass.json"
"$SCRIPT" --receipt "$TMP/pass.json" --json >"$TMP/pass.out.json"
assert_jq "$TMP/pass.out.json" '.status == "pass" and .runway_gate_status == "clear"' "18 month pass clears sub 1 gate"

jq '.status = "pass" | .verified_runway_months = 17.9 | .calculation_basis.scenario = "base" | .calculation_basis.method = "cash_on_hand_divided_by_monthly_burn"' "$RECEIPT" >"$TMP/short.json"
if "$SCRIPT" --receipt "$TMP/short.json" --json >"$TMP/short.out.json" 2>/dev/null; then
  fail "short runway pass rejected"
else
  assert_jq "$TMP/short.out.json" '.status == "fail" and (.failures[] | select(.code == "pass_status_below_required_months"))' "short runway pass rejected"
fi

jq '.status = "blocked" | .verified_runway_months = 20' "$RECEIPT" >"$TMP/blocked-with-months.json"
if "$SCRIPT" --receipt "$TMP/blocked-with-months.json" --json >"$TMP/blocked-with-months.out.json" 2>/dev/null; then
  fail "blocked receipt with months rejected"
else
  assert_jq "$TMP/blocked-with-months.out.json" '.status == "fail" and (.failures[] | select(.code == "blocked_status_with_verified_months"))' "blocked receipt with months rejected"
fi

jq '.next_action = "cash balance is $100000, do not store this"' "$RECEIPT" >"$TMP/raw-amount.json"
if "$SCRIPT" --receipt "$TMP/raw-amount.json" --json >"$TMP/raw-amount.out.json" 2>/dev/null; then
  fail "raw amount rejected"
else
  assert_jq "$TMP/raw-amount.out.json" '.status == "fail" and (.failures[] | select(.code == "secret_or_raw_amount_shape_detected"))' "raw amount rejected"
fi

printf 'RESULT pass=%d fail=%d\n' "$pass_count" "$fail_count"
exit "$fail_count"
