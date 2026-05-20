#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/portfolio-company-registry-validate.py"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/portfolio-company-registry.schema.json"
REGISTRY="$ROOT/state/zeststream-portfolio-company-registry.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/portfolio-company-registry.XXXXXX")"
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
jq empty "$REGISTRY" && pass "registry json valid" || fail "registry json valid"

"$SCRIPT" --registry "$REGISTRY" --check-paths --json >"$TMP/current.json"
assert_jq "$TMP/current.json" '.status == "pass" and .counted_portfolio_companies == 0 and .rows[0].slug == "mobile-eats" and .rows[0].counted_as_portfolio_company == false' "current registry passes with zero counted companies"

touch "$TMP/signed-owner.json" "$TMP/equity.json" "$TMP/customer.json" "$TMP/substrate.json"
cat >"$TMP/formed-pass.json" <<JSON
{
  "schema_version": "zeststream.portfolio_company_registry.v1",
  "generated_at": "2026-05-17T06:50:00Z",
  "owner": "ZestStream",
  "counted_portfolio_companies": 1,
  "companies": [
    {
      "slug": "fixture-co",
      "name": "Fixture Co",
      "portfolio_company_status": "formed",
      "counted_as_portfolio_company": true,
      "stage": "pour",
      "repo_path": null,
      "public_url": null,
      "gate_evidence": {
        "signed_owner_operator_receipt": "$TMP/signed-owner.json",
        "equity_receipt": "$TMP/equity.json",
        "first_paying_customer_receipt": "$TMP/customer.json",
        "substrate_share_receipt": "$TMP/substrate.json"
      },
      "evidence_refs": ["fixture://launch"]
    }
  ]
}
JSON
"$SCRIPT" --registry "$TMP/formed-pass.json" --check-paths --json >"$TMP/formed-pass.out.json"
assert_jq "$TMP/formed-pass.out.json" '.status == "pass" and .counted_portfolio_companies == 1' "formed company with receipts counts"

cat >"$TMP/missing-receipt.json" <<'JSON'
{
  "schema_version": "zeststream.portfolio_company_registry.v1",
  "generated_at": "2026-05-17T06:50:00Z",
  "owner": "ZestStream",
  "counted_portfolio_companies": 1,
  "companies": [
    {
      "slug": "bad-co",
      "name": "Bad Co",
      "portfolio_company_status": "formed",
      "counted_as_portfolio_company": true,
      "stage": "pour",
      "repo_path": null,
      "public_url": null,
      "gate_evidence": {
        "signed_owner_operator_receipt": null,
        "equity_receipt": "fixture://equity",
        "first_paying_customer_receipt": "fixture://customer",
        "substrate_share_receipt": "fixture://substrate"
      },
      "evidence_refs": []
    }
  ]
}
JSON
if "$SCRIPT" --registry "$TMP/missing-receipt.json" --json >"$TMP/missing-receipt.out.json" 2>/dev/null; then
  fail "formed company missing owner receipt rejected"
else
  assert_jq "$TMP/missing-receipt.out.json" '.status == "fail" and (.failures[] | select(.code == "schema_invalid"))' "formed company missing owner receipt rejected"
fi

cat >"$TMP/count-mismatch.json" <<JSON
$(jq '.counted_portfolio_companies = 2' "$TMP/formed-pass.json")
JSON
if "$SCRIPT" --registry "$TMP/count-mismatch.json" --json >"$TMP/count-mismatch.out.json" 2>/dev/null; then
  fail "count mismatch rejected"
else
  assert_jq "$TMP/count-mismatch.out.json" '.status == "fail" and (.failures[] | select(.code == "counted_portfolio_company_total_mismatch"))' "count mismatch rejected"
fi

printf 'RESULT pass=%d fail=%d\n' "$pass_count" "$fail_count"
exit "$fail_count"
