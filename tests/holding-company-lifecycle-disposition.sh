#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/holding-company-lifecycle-disposition-validate.py"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/holding-company-lifecycle-disposition.schema.json"
LEDGER="$ROOT/state/holding-company-lifecycle-disposition.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/holding-company-lifecycle.XXXXXX")"
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
assert_jq "$TMP/current.json" '.status == "pass" and .clear_count == 0 and .dispositions[0].lifecycle_disposition_gate_status == "blocked"' "current tracking row validates and blocks disposition clear"

jq 'del(.gate)' "$LEDGER" >"$TMP/schema-invalid.json"
if "$SCRIPT" --ledger "$TMP/schema-invalid.json" --json >"$TMP/schema-invalid.out.json" 2>/dev/null; then
  fail "schema-invalid lifecycle ledger rejected"
else
  assert_jq "$TMP/schema-invalid.out.json" '.status == "fail" and (.failures[] | select(.code == "schema_invalid"))' "schema-invalid lifecycle ledger rejected"
fi

jq '
  .clear_count = 1
  | .dispositions[0].disposition_type = "closed"
  | .dispositions[0].status = "disposition_clear"
  | .dispositions[0].owner_operator_ref = "urn:owner:mobile-eats"
  | .dispositions[0].customer_obligation_disposition_ref = "urn:customer-obligations:mobile-eats"
  | .dispositions[0].financial_disposition_ref = "urn:financial-disposition:mobile-eats"
  | .dispositions[0].substrate_retention_ref = "urn:substrate-retention:mobile-eats"
  | .dispositions[0].brand_public_update_ref = "urn:brand-update:mobile-eats"
' "$LEDGER" >"$TMP/closed.json"
"$SCRIPT" --ledger "$TMP/closed.json" --json >"$TMP/closed.out.json"
assert_jq "$TMP/closed.out.json" '.status == "pass" and .clear_count == 1 and .dispositions[0].lifecycle_disposition_gate_status == "clear"' "closed disposition refs clear"

jq '.dispositions[0].notes = ("sk-" + "NOTAREALSECRET")' "$TMP/closed.json" >"$TMP/secret-shaped-value.json"
if "$SCRIPT" --ledger "$TMP/secret-shaped-value.json" --json >"$TMP/secret-shaped-value.out.json" 2>/dev/null; then
  fail "secret-shaped lifecycle value rejected"
else
  assert_jq "$TMP/secret-shaped-value.out.json" '.status == "fail" and (.failures[] | select(.code == "secret_or_raw_value_shape_detected"))' "secret-shaped lifecycle value rejected"
fi

jq '.clear_count = 1 | .dispositions[0].disposition_type = "pivot" | .dispositions[0].status = "disposition_clear" | .dispositions[0].owner_operator_ref = "urn:owner:x" | .dispositions[0].customer_obligation_disposition_ref = "urn:customers:x" | .dispositions[0].financial_disposition_ref = "urn:financial:x" | .dispositions[0].substrate_retention_ref = "urn:substrate:x" | .dispositions[0].brand_public_update_ref = "urn:brand:x" | .dispositions[0].pivot_scope_ref = "urn:pivot-scope:x"' "$LEDGER" >"$TMP/pivot.json"
"$SCRIPT" --ledger "$TMP/pivot.json" --json >"$TMP/pivot.out.json"
assert_jq "$TMP/pivot.out.json" '.status == "pass" and .clear_count == 1 and .dispositions[0].lifecycle_disposition_gate_status == "clear"' "pivot scope clears pivot disposition"

jq '.dispositions[0].status = "disposition_clear"' "$LEDGER" >"$TMP/missing.json"
if "$SCRIPT" --ledger "$TMP/missing.json" --json >"$TMP/missing.out.json" 2>/dev/null; then
  fail "disposition clear missing refs rejected"
else
  assert_jq "$TMP/missing.out.json" '.failures[] | select(.code == "active_tracking_cannot_be_disposition_clear")' "active tracking clear rejected"
  assert_jq "$TMP/missing.out.json" '.failures[] | select(.code == "disposition_clear_missing_refs")' "disposition clear missing refs rejected"
fi

jq '.dispositions[0].holding_plane_continues = false' "$TMP/closed.json" >"$TMP/no-continuity.json"
if "$SCRIPT" --ledger "$TMP/no-continuity.json" --json >"$TMP/no-continuity.out.json" 2>/dev/null; then
  fail "disposition without holding-plane continuity rejected"
else
  assert_jq "$TMP/no-continuity.out.json" '.failures[] | select(.code == "disposition_clear_without_holding_plane_continuity")' "disposition without holding-plane continuity rejected"
fi

jq '.dispositions[0].owner_operator_ref = "state/no-such-lifecycle-owner.json"' "$TMP/closed.json" >"$TMP/missing-required-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-required-ref.json" --check-paths --json >"$TMP/missing-required-ref.out.json" 2>/dev/null; then
  fail "missing lifecycle required ref rejected"
else
  assert_jq "$TMP/missing-required-ref.out.json" '.status == "fail" and (.failures[] | select(.code == "required_ref_missing"))' "missing lifecycle required ref rejected"
fi

jq '.dispositions[0].evidence_refs = ["state/no-such-lifecycle-evidence.json"]' "$TMP/closed.json" >"$TMP/missing-evidence-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-evidence-ref.json" --check-paths --json >"$TMP/missing-evidence-ref.out.json" 2>/dev/null; then
  fail "missing lifecycle evidence ref rejected"
else
  assert_jq "$TMP/missing-evidence-ref.out.json" '.status == "fail" and (.failures[] | select(.code == "evidence_ref_missing"))' "missing lifecycle evidence ref rejected"
fi

jq '.clear_count = 1' "$LEDGER" >"$TMP/bad-count.json"
if "$SCRIPT" --ledger "$TMP/bad-count.json" --json >"$TMP/bad-count.out.json" 2>/dev/null; then
  fail "lifecycle clear count mismatch rejected"
else
  assert_jq "$TMP/bad-count.out.json" '.failures[] | select(.code == "clear_count_mismatch")' "lifecycle clear count mismatch rejected"
fi

if [[ "$fail_count" -ne 0 ]]; then
  printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
