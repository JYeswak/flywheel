#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/holding-company-brand-naming-validate.py"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/holding-company-brand-naming.schema.json"
LEDGER="$ROOT/state/holding-company-brand-naming.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/holding-company-brand-naming.XXXXXX")"
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
assert_jq "$TMP/current.json" '.status == "pass" and .clear_count == 0 and .names[0].brand_naming_gate_status == "blocked"' "current ledger validates and blocks brand naming"

jq '
  .clear_count = 1
  | .names[0].status = "name_clear"
  | .names[0].own_brand_name = true
  | .names[0].owner_involved_in_name = true
  | .names[0].community_context_in_name = true
  | .names[0].owner_operator_ref = "urn:owner-operator:mobile-eats"
  | .names[0].community_context_ref = "urn:community-context:mobile-eats"
  | .names[0].naming_decision_ref = "urn:naming-decision:mobile-eats"
  | .names[0].prohibited_name_flags = []
' "$LEDGER" >"$TMP/name-clear.json"
"$SCRIPT" --ledger "$TMP/name-clear.json" --json >"$TMP/name-clear.out.json"
assert_jq "$TMP/name-clear.out.json" '.status == "pass" and .clear_count == 1 and .names[0].brand_naming_gate_status == "clear"' "owner and community name provenance clears"

jq '.names[0].status = "launch_clear"' "$TMP/name-clear.json" >"$TMP/launch-clear.json"
"$SCRIPT" --ledger "$TMP/launch-clear.json" --json >"$TMP/launch-clear.out.json"
assert_jq "$TMP/launch-clear.out.json" '.status == "pass" and .clear_count == 1 and .names[0].brand_naming_gate_status == "clear"' "launch clear accepts complete name provenance"

jq '.names[0].own_brand_name = false' "$TMP/name-clear.json" >"$TMP/not-own-brand.json"
if "$SCRIPT" --ledger "$TMP/not-own-brand.json" --json >"$TMP/not-own-brand.out.json" 2>/dev/null; then
  fail "non-own brand name rejected"
else
  assert_jq "$TMP/not-own-brand.out.json" '.status == "fail" and (.failures[] | select(.code == "brand_name_clear_without_own_brand"))' "non-own brand name rejected"
fi

jq '.names[0].owner_involved_in_name = false' "$TMP/name-clear.json" >"$TMP/no-owner.json"
if "$SCRIPT" --ledger "$TMP/no-owner.json" --json >"$TMP/no-owner.out.json" 2>/dev/null; then
  fail "name clear without owner involvement rejected"
else
  assert_jq "$TMP/no-owner.out.json" '.status == "fail" and (.failures[] | select(.code == "brand_name_clear_without_owner_involvement"))' "name clear without owner involvement rejected"
fi

jq '.names[0].community_context_in_name = false' "$TMP/name-clear.json" >"$TMP/no-community.json"
if "$SCRIPT" --ledger "$TMP/no-community.json" --json >"$TMP/no-community.out.json" 2>/dev/null; then
  fail "name clear without community context rejected"
else
  assert_jq "$TMP/no-community.out.json" '.status == "fail" and (.failures[] | select(.code == "brand_name_clear_without_community_context"))' "name clear without community context rejected"
fi

jq '.names[0].naming_decision_ref = null' "$TMP/name-clear.json" >"$TMP/no-decision.json"
if "$SCRIPT" --ledger "$TMP/no-decision.json" --json >"$TMP/no-decision.out.json" 2>/dev/null; then
  fail "name clear without naming decision ref rejected"
else
  assert_jq "$TMP/no-decision.out.json" '.status == "fail" and (.failures[] | select(.code == "brand_name_clear_missing_refs" and (.missing_refs | index("naming_decision_ref"))))' "name clear without naming decision ref rejected"
fi

jq '.names[0].prohibited_name_flags = ["zeststream_meta_brand"]' "$TMP/name-clear.json" >"$TMP/prohibited.json"
if "$SCRIPT" --ledger "$TMP/prohibited.json" --json >"$TMP/prohibited.out.json" 2>/dev/null; then
  fail "prohibited name flags rejected"
else
  assert_jq "$TMP/prohibited.out.json" '.status == "fail" and (.failures[] | select(.code == "brand_name_clear_with_prohibited_flags"))' "prohibited name flags rejected"
fi

jq '.clear_count = 2' "$TMP/name-clear.json" >"$TMP/mismatch.json"
if "$SCRIPT" --ledger "$TMP/mismatch.json" --json >"$TMP/mismatch.out.json" 2>/dev/null; then
  fail "clear count mismatch rejected"
else
  assert_jq "$TMP/mismatch.out.json" '.status == "fail" and (.failures[] | select(.code == "brand_naming_clear_count_mismatch"))' "clear count mismatch rejected"
fi

printf 'RESULT pass=%d fail=%d\n' "$pass_count" "$fail_count"
exit "$fail_count"
