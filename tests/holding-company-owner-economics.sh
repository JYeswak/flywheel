#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/holding-company-owner-economics-validate.py"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/holding-company-owner-economics.schema.json"
LEDGER="$ROOT/state/holding-company-owner-economics.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/holding-company-owner-economics.XXXXXX")"
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
assert_jq "$TMP/current.json" '.status == "pass" and .clear_count == 0 and .deals[0].owner_economics_gate_status == "blocked"' "current ledger validates and blocks owner economics"

jq '
  .clear_count = 1
  | .deals[0].status = "signed"
  | .deals[0].owner_operator_slug = "fixture-owner"
  | .deals[0].owner_equity_percent = 25
  | .deals[0].holding_company_equity_percent = 75
  | .deals[0].profit_distribution_tiers = [
      {"tier_id":"base", "owner_distribution_percent":45, "basis_ref":"urn:distribution-basis:base"},
      {"tier_id":"growth", "owner_distribution_percent":75, "basis_ref":"urn:distribution-basis:growth"}
    ]
  | .deals[0].signed_owner_operator_receipt = "urn:signed-owner:fixture"
  | .deals[0].cap_table_ref = "urn:cap-table:fixture"
  | .deals[0].distribution_terms_ref = "urn:distribution-terms:fixture"
  | .deals[0].legal_review_ref = "urn:legal-review:fixture"
' "$LEDGER" >"$TMP/signed.json"
"$SCRIPT" --ledger "$TMP/signed.json" --json >"$TMP/signed.out.json"
assert_jq "$TMP/signed.out.json" '.status == "pass" and .clear_count == 1 and .deals[0].owner_economics_gate_status == "clear"' "signed 25 percent equity and 45-75 distribution clears"

jq '.deals[0].owner_equity_percent = 30 | .deals[0].holding_company_equity_percent = 70' "$TMP/signed.json" >"$TMP/equity-mismatch.json"
if "$SCRIPT" --ledger "$TMP/equity-mismatch.json" --json >"$TMP/equity-mismatch.out.json" 2>/dev/null; then
  fail "wrong owner equity percent rejected"
else
  assert_jq "$TMP/equity-mismatch.out.json" '.status == "fail" and (.failures[] | select(.code == "owner_equity_percent_mismatch"))' "wrong owner equity percent rejected"
fi

jq '.deals[0].profit_distribution_tiers[0].owner_distribution_percent = 40' "$TMP/signed.json" >"$TMP/distribution-bounds.json"
if "$SCRIPT" --ledger "$TMP/distribution-bounds.json" --json >"$TMP/distribution-bounds.out.json" 2>/dev/null; then
  fail "distribution outside 45-75 rejected"
else
  assert_jq "$TMP/distribution-bounds.out.json" '.status == "fail" and (.failures[] | select(.code == "profit_distribution_bounds_mismatch"))' "distribution outside 45-75 rejected"
fi

jq '.deals[0].profit_distribution_tiers = [.deals[0].profit_distribution_tiers[0]]' "$TMP/signed.json" >"$TMP/not-tiered.json"
if "$SCRIPT" --ledger "$TMP/not-tiered.json" --json >"$TMP/not-tiered.out.json" 2>/dev/null; then
  fail "single-tier distribution rejected"
else
  assert_jq "$TMP/not-tiered.out.json" '.status == "fail" and (.failures[] | select(.code == "profit_distribution_not_tiered"))' "single-tier distribution rejected"
fi

jq '.clear_count = 2' "$TMP/signed.json" >"$TMP/count-mismatch.json"
if "$SCRIPT" --ledger "$TMP/count-mismatch.json" --json >"$TMP/count-mismatch.out.json" 2>/dev/null; then
  fail "owner economics clear count mismatch rejected"
else
  assert_jq "$TMP/count-mismatch.out.json" '.status == "fail" and (.failures[] | select(.code == "clear_count_mismatch"))' "owner economics clear count mismatch rejected"
fi

jq 'del(.gate)' "$LEDGER" >"$TMP/schema-invalid.json"
if "$SCRIPT" --ledger "$TMP/schema-invalid.json" --json >"$TMP/schema-invalid.out.json" 2>/dev/null; then
  fail "schema-invalid owner economics ledger rejected"
else
  assert_jq "$TMP/schema-invalid.out.json" '.status == "fail" and (.failures[] | select(.code == "schema_invalid"))' "schema-invalid owner economics ledger rejected"
fi

jq '.deals[0].holding_company_equity_percent = 70' "$TMP/signed.json" >"$TMP/holding-equity-mismatch.json"
if "$SCRIPT" --ledger "$TMP/holding-equity-mismatch.json" --json >"$TMP/holding-equity-mismatch.out.json" 2>/dev/null; then
  fail "wrong holding company equity percent rejected"
else
  assert_jq "$TMP/holding-equity-mismatch.out.json" '.status == "fail" and (.failures[] | select(.code == "holding_company_equity_percent_mismatch"))' "wrong holding company equity percent rejected"
fi

jq '.deals[0].owner_operator_slug = null | .clear_count = 0' "$TMP/signed.json" >"$TMP/no-owner-operator.json"
if "$SCRIPT" --ledger "$TMP/no-owner-operator.json" --json >"$TMP/no-owner-operator.out.json" 2>/dev/null; then
  fail "signed owner economics without owner operator rejected"
else
  assert_jq "$TMP/no-owner-operator.out.json" '.status == "fail" and (.failures[] | select(.code == "signed_status_without_owner_operator"))' "signed owner economics without owner operator rejected"
fi

jq '.deals[0].cap_table_ref = null | .clear_count = 0' "$TMP/signed.json" >"$TMP/missing-status-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-status-ref.json" --json >"$TMP/missing-status-ref.out.json" 2>/dev/null; then
  fail "signed owner economics missing status refs rejected"
else
  assert_jq "$TMP/missing-status-ref.out.json" '.status == "fail" and (.failures[] | select(.code == "owner_economics_status_missing_refs" and (.missing_refs | index("cap_table_ref"))))' "signed owner economics missing status refs rejected"
fi

jq '.deals[0].profit_distribution_tiers[0].basis_ref = null | .clear_count = 0' "$TMP/signed.json" >"$TMP/missing-tier-basis.json"
if "$SCRIPT" --ledger "$TMP/missing-tier-basis.json" --json >"$TMP/missing-tier-basis.out.json" 2>/dev/null; then
  fail "owner economics tier missing basis ref rejected"
else
  assert_jq "$TMP/missing-tier-basis.out.json" '.status == "fail" and (.failures[] | select(.code == "profit_distribution_tier_missing_basis_ref"))' "owner economics tier missing basis ref rejected"
fi

jq '.deals[0].signed_owner_operator_receipt = "state/does-not-exist-owner-economics-signed.json" | .clear_count = 0' "$TMP/signed.json" >"$TMP/missing-required-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-required-ref.json" --check-paths --json >"$TMP/missing-required-ref.out.json" 2>/dev/null; then
  fail "missing owner economics required ref rejected"
else
  assert_jq "$TMP/missing-required-ref.out.json" '.status == "fail" and (.failures[] | select(.code == "required_ref_missing" and .field == "signed_owner_operator_receipt"))' "missing owner economics required ref rejected"
fi

jq '.deals[0].evidence_refs = ["state/does-not-exist-owner-economics-evidence.json"] | .clear_count = 0' "$TMP/signed.json" >"$TMP/missing-evidence-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-evidence-ref.json" --check-paths --json >"$TMP/missing-evidence-ref.out.json" 2>/dev/null; then
  fail "missing owner economics evidence ref rejected"
else
  assert_jq "$TMP/missing-evidence-ref.out.json" '.status == "fail" and (.failures[] | select(.code == "evidence_ref_missing"))' "missing owner economics evidence ref rejected"
fi

jq '.deals[0].notes = "fixture sk-TestSecret123 should be rejected" | .clear_count = 0' "$TMP/signed.json" >"$TMP/secret-shape.json"
if "$SCRIPT" --ledger "$TMP/secret-shape.json" --json >"$TMP/secret-shape.out.json" 2>/dev/null; then
  fail "secret-shaped owner economics value rejected"
else
  assert_jq "$TMP/secret-shape.out.json" '.status == "fail" and (.failures[] | select(.code == "secret_or_raw_amount_shape_detected"))' "secret-shaped owner economics value rejected"
fi

printf 'RESULT pass=%d fail=%d\n' "$pass_count" "$fail_count"
exit "$fail_count"
