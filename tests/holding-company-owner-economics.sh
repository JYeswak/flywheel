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

printf 'RESULT pass=%d fail=%d\n' "$pass_count" "$fail_count"
exit "$fail_count"
