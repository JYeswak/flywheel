#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/holding-company-owner-search-phasing-validate.py"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/holding-company-owner-search-phasing.schema.json"
LEDGER="$ROOT/state/holding-company-owner-search-phasing.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/holding-company-owner-search.XXXXXX")"
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
assert_jq "$TMP/current.json" '.status == "pass" and .phasing_clear_count == 0 and .searches[0].phasing_gate_status == "blocked"' "current ledger validates and blocks owner search"

jq 'del(.gate)' "$LEDGER" >"$TMP/schema-invalid.json"
if "$SCRIPT" --ledger "$TMP/schema-invalid.json" --json >"$TMP/schema-invalid.out.json" 2>/dev/null; then
  fail "schema-invalid owner search ledger rejected"
else
  assert_jq "$TMP/schema-invalid.out.json" '.status == "fail" and (.failures[] | select(.code == "schema_invalid"))' "schema-invalid owner search ledger rejected"
fi

jq '.phasing_clear_count = 1 | .searches[0].search_status = "allowed" | .searches[0].sourcing_channel = "warm_network"' "$LEDGER" >"$TMP/warm-allowed.json"
"$SCRIPT" --ledger "$TMP/warm-allowed.json" --json >"$TMP/warm-allowed.out.json"
assert_jq "$TMP/warm-allowed.out.json" '.status == "pass" and .phasing_clear_count == 1 and .searches[0].phasing_gate_status == "clear"' "warm network clears sub 1"

jq '.searches[0].notes = ("sk-" + "NOTAREALSECRET")' "$TMP/warm-allowed.json" >"$TMP/secret-shaped-value.json"
if "$SCRIPT" --ledger "$TMP/secret-shaped-value.json" --json >"$TMP/secret-shaped-value.out.json" 2>/dev/null; then
  fail "secret-shaped owner search value rejected"
else
  assert_jq "$TMP/secret-shaped-value.out.json" '.status == "fail" and (.failures[] | select(.code == "secret_or_raw_amount_shape_detected"))' "secret-shaped owner search value rejected"
fi

jq '.phasing_clear_count = 1 | .searches[0].search_status = "allowed" | .searches[0].sourcing_channel = "public_open_call" | .searches[0].public_open_call_active = true' "$LEDGER" >"$TMP/public-sub1.json"
if "$SCRIPT" --ledger "$TMP/public-sub1.json" --json >"$TMP/public-sub1.out.json" 2>/dev/null; then
  fail "public open call before sub 3 rejected"
else
  assert_jq "$TMP/public-sub1.out.json" '.status == "fail" and (.failures[] | select(.code == "public_or_cold_sourcing_before_sub_3"))' "public open call before sub 3 rejected"
fi

jq '.searches[0].search_status = "signed_owner" | .searches[0].sourcing_channel = "unknown"' "$LEDGER" >"$TMP/signed-unknown.json"
if "$SCRIPT" --ledger "$TMP/signed-unknown.json" --json >"$TMP/signed-unknown.out.json" 2>/dev/null; then
  fail "signed owner without phasing clear rejected"
else
  assert_jq "$TMP/signed-unknown.out.json" '.status == "fail" and (.failures[] | select(.code == "search_status_without_phasing_clear"))' "signed owner without phasing clear rejected"
fi

jq '.phasing_clear_count = 1 | .searches[0].sequence = 3 | .searches[0].search_status = "allowed" | .searches[0].sourcing_channel = "public_open_call" | .searches[0].public_open_call_active = true' "$LEDGER" >"$TMP/public-sub3.json"
"$SCRIPT" --ledger "$TMP/public-sub3.json" --json >"$TMP/public-sub3.out.json"
assert_jq "$TMP/public-sub3.out.json" '.status == "pass" and .phasing_clear_count == 1 and .searches[0].phasing_gate_status == "clear"' "public open call allowed from sub 3"

jq '.searches[0].evidence_refs = ["state/no-such-owner-search-evidence.json"]' "$TMP/warm-allowed.json" >"$TMP/missing-evidence-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-evidence-ref.json" --check-paths --json >"$TMP/missing-evidence-ref.out.json" 2>/dev/null; then
  fail "missing owner search evidence ref rejected"
else
  assert_jq "$TMP/missing-evidence-ref.out.json" '.status == "fail" and (.failures[] | select(.code == "evidence_ref_missing"))' "missing owner search evidence ref rejected"
fi

jq '.phasing_clear_count = 2 | .searches[0].search_status = "allowed" | .searches[0].sourcing_channel = "warm_network"' "$LEDGER" >"$TMP/mismatch.json"
if "$SCRIPT" --ledger "$TMP/mismatch.json" --json >"$TMP/mismatch.out.json" 2>/dev/null; then
  fail "clear count mismatch rejected"
else
  assert_jq "$TMP/mismatch.out.json" '.status == "fail" and (.failures[] | select(.code == "phasing_clear_count_mismatch"))' "clear count mismatch rejected"
fi

printf 'RESULT pass=%d fail=%d\n' "$pass_count" "$fail_count"
exit "$fail_count"
