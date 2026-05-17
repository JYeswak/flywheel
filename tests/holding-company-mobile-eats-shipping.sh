#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/holding-company-mobile-eats-shipping-validate.py"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/holding-company-mobile-eats-shipping.schema.json"
LEDGER="$ROOT/state/holding-company-mobile-eats-shipping.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/holding-company-mobile-eats-shipping.XXXXXX")"
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
assert_jq "$TMP/current.json" '.status == "pass" and .mobile_eats_shipping_gate_status == "partial" and .product_substrate_present == true and .substrate_package_count == 27 and .counted_as_portfolio_company == false' "current Mobile Eats claim validates as product/substrate partial"

jq '
  .status = "proven"
  | .portfolio_registry_ref = "urn:portfolio-registry:mobile-eats-formed"
  | .counted_as_portfolio_company = true
  | .first_portfolio_company_claim_clear = true
  | .signed_owner_operator_receipt = "urn:receipt:signed-owner"
  | .equity_receipt = "urn:receipt:equity"
  | .first_paying_customer_receipt = "urn:receipt:first-customer"
' "$LEDGER" >"$TMP/proven.json"
"$SCRIPT" --ledger "$TMP/proven.json" --json >"$TMP/proven.out.json"
assert_jq "$TMP/proven.out.json" '.status == "pass" and .mobile_eats_shipping_gate_status == "proven" and .formation_receipts_present == true' "formed portfolio company claim clears with formation receipts"

jq '.status = "proven"' "$LEDGER" >"$TMP/proven-current.json"
if "$SCRIPT" --ledger "$TMP/proven-current.json" --json >"$TMP/proven-current.out.json" 2>/dev/null; then
  fail "proven without counted portfolio company rejected"
else
  assert_jq "$TMP/proven-current.out.json" '.failures[] | select(.code == "proven_without_counted_portfolio_company")' "proven without counted portfolio company rejected"
fi

jq '.status = "proven" | .package_threshold_met = false' "$TMP/proven.json" >"$TMP/proven-no-package-threshold.json"
if "$SCRIPT" --ledger "$TMP/proven-no-package-threshold.json" --json >"$TMP/proven-no-package-threshold.out.json" 2>/dev/null; then
  fail "proven below package threshold rejected"
else
  assert_jq "$TMP/proven-no-package-threshold.out.json" '.failures[] | select(.code == "package_threshold_flag_mismatch" or .code == "proven_below_package_threshold")' "proven below package threshold rejected"
fi

jq '.status = "proven" | .signed_owner_operator_receipt = null' "$TMP/proven.json" >"$TMP/proven-no-owner.json"
if "$SCRIPT" --ledger "$TMP/proven-no-owner.json" --json >"$TMP/proven-no-owner.out.json" 2>/dev/null; then
  fail "proven without signed owner rejected"
else
  assert_jq "$TMP/proven-no-owner.out.json" '.failures[] | select(.code == "proven_without_signed_owner_operator_receipt")' "proven without signed owner rejected"
fi

jq '.substrate_package_count = 9' "$LEDGER" >"$TMP/count-mismatch.json"
if "$SCRIPT" --ledger "$TMP/count-mismatch.json" --json >"$TMP/count-mismatch.out.json" 2>/dev/null; then
  fail "substrate count mismatch rejected"
else
  assert_jq "$TMP/count-mismatch.out.json" '.failures[] | select(.code == "substrate_package_count_mismatch")' "substrate count mismatch rejected"
fi

jq '.evidence_refs += ["/no/such/mobile-eats-evidence.md"]' "$LEDGER" >"$TMP/missing-evidence.json"
if "$SCRIPT" --ledger "$TMP/missing-evidence.json" --check-paths --json >"$TMP/missing-evidence.out.json" 2>/dev/null; then
  fail "missing evidence path rejected"
else
  assert_jq "$TMP/missing-evidence.out.json" '.failures[] | select(.code == "evidence_ref_missing")' "missing evidence path rejected"
fi

if [[ "$fail_count" -ne 0 ]]; then
  printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
