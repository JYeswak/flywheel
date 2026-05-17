#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/holding-company-operating-health-validate.py"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/holding-company-operating-health.schema.json"
LEDGER="$ROOT/state/holding-company-operating-health.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/holding-company-operating-health.XXXXXX")"
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
jq empty "$LEDGER" && pass "ledger json valid" || fail "ledger json valid"

"$SCRIPT" --ledger "$LEDGER" --check-paths --json >"$TMP/current.json"
assert_jq "$TMP/current.json" '.status == "pass" and .clear_count == 0 and .companies[0].operating_health_gate_status == "blocked"' "current ledger validates and blocks operating health"

jq '
  .clear_count = 1
  | .companies[0].status = "revenue_clear"
  | .companies[0].first_paying_customer_receipt = "urn:first-customer:mobile-eats"
  | .companies[0].revenue_snapshot_ref = "urn:revenue-snapshot:redacted"
  | .companies[0].owner_operator_report_ref = "urn:owner-report:mobile-eats"
  | .companies[0].operating_control_ref = "urn:operating-control:mobile-eats"
' "$LEDGER" >"$TMP/revenue-clear.json"
"$SCRIPT" --ledger "$TMP/revenue-clear.json" --json >"$TMP/revenue-clear.out.json"
assert_jq "$TMP/revenue-clear.out.json" '.status == "pass" and .clear_count == 1 and .companies[0].operating_health_gate_status == "clear"' "redacted revenue clear passes"

jq '
  .companies[0].status = "profit_clear"
  | .companies[0].positive_gross_profit_ref = "urn:gross-profit-positive:mobile-eats"
  | .companies[0].owner_distribution_ref = "urn:owner-distribution:mobile-eats"
' "$TMP/revenue-clear.json" >"$TMP/profit-clear.json"
"$SCRIPT" --ledger "$TMP/profit-clear.json" --json >"$TMP/profit-clear.out.json"
assert_jq "$TMP/profit-clear.out.json" '.status == "pass" and .clear_count == 1 and .companies[0].operating_health_gate_status == "clear"' "profit clear with owner distribution passes"

jq '.companies[0].first_paying_customer_receipt = null' "$TMP/revenue-clear.json" >"$TMP/no-customer.json"
if "$SCRIPT" --ledger "$TMP/no-customer.json" --json >"$TMP/no-customer.out.json" 2>/dev/null; then
  fail "revenue clear without first customer rejected"
else
  assert_jq "$TMP/no-customer.out.json" '.status == "fail" and (.failures[] | select(.code == "operating_health_clear_missing_refs" and (.missing_refs | index("first_paying_customer_receipt"))))' "revenue clear without first customer rejected"
fi

jq '.companies[0].positive_gross_profit_ref = null' "$TMP/profit-clear.json" >"$TMP/no-profit.json"
if "$SCRIPT" --ledger "$TMP/no-profit.json" --json >"$TMP/no-profit.out.json" 2>/dev/null; then
  fail "profit clear without positive gross profit rejected"
else
  assert_jq "$TMP/no-profit.out.json" '.status == "fail" and (.failures[] | select(.code == "operating_health_clear_missing_refs" and (.missing_refs | index("positive_gross_profit_ref"))))' "profit clear without positive gross profit rejected"
fi

jq '.companies[0].metrics_are_redacted = false' "$TMP/revenue-clear.json" >"$TMP/not-redacted.json"
if "$SCRIPT" --ledger "$TMP/not-redacted.json" --json >"$TMP/not-redacted.out.json" 2>/dev/null; then
  fail "clear without redacted metrics rejected"
else
  assert_jq "$TMP/not-redacted.out.json" '.status == "fail" and (.failures[] | select(.code == "operating_health_clear_without_redacted_metrics"))' "clear without redacted metrics rejected"
fi

jq '.companies[0].raw_amounts_present = true' "$TMP/revenue-clear.json" >"$TMP/raw-flag.json"
if "$SCRIPT" --ledger "$TMP/raw-flag.json" --json >"$TMP/raw-flag.out.json" 2>/dev/null; then
  fail "raw amount flag rejected"
else
  assert_jq "$TMP/raw-flag.out.json" '.status == "fail" and (.failures[] | select(.code == "operating_health_clear_with_raw_amounts_flag"))' "raw amount flag rejected"
fi

jq '.companies[0].notes = "Revenue is $1000 and should be rejected."' "$TMP/revenue-clear.json" >"$TMP/raw-shape.json"
if "$SCRIPT" --ledger "$TMP/raw-shape.json" --json >"$TMP/raw-shape.out.json" 2>/dev/null; then
  fail "raw amount shape rejected"
else
  assert_jq "$TMP/raw-shape.out.json" '.status == "fail" and (.failures[] | select(.code == "raw_amount_shape_detected"))' "raw amount shape rejected"
fi

jq '.clear_count = 2' "$TMP/revenue-clear.json" >"$TMP/mismatch.json"
if "$SCRIPT" --ledger "$TMP/mismatch.json" --json >"$TMP/mismatch.out.json" 2>/dev/null; then
  fail "clear count mismatch rejected"
else
  assert_jq "$TMP/mismatch.out.json" '.status == "fail" and (.failures[] | select(.code == "operating_health_clear_count_mismatch"))' "clear count mismatch rejected"
fi

printf 'RESULT pass=%d fail=%d\n' "$pass_count" "$fail_count"
exit "$fail_count"
