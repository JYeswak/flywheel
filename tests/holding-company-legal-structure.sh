#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/holding-company-legal-structure-validate.py"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/holding-company-legal-structure.schema.json"
LEDGER="$ROOT/state/holding-company-legal-structure.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/holding-company-legal.XXXXXX")"
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
assert_jq "$TMP/current.json" '.status == "pass" and .clear_count == 0 and .sub_2_owner_signing_gate_status == "blocked"' "current scaffold validates and blocks sub 2 signing"

jq 'del(.gate)' "$LEDGER" >"$TMP/schema-invalid.json"
if "$SCRIPT" --ledger "$TMP/schema-invalid.json" --json >"$TMP/schema-invalid.out.json" 2>/dev/null; then
  fail "schema-invalid legal structure ledger rejected"
else
  assert_jq "$TMP/schema-invalid.out.json" '.status == "fail" and (.failures[] | select(.code == "schema_invalid"))' "schema-invalid legal structure ledger rejected"
fi

jq '
  .clear_count = 6
  | .requirements |= map(
      .status = "cleared"
      | .binding_artifact_ref = "urn:legal-binding:" + .requirement_id
      | .attorney_review_ref = "urn:attorney-review:" + .requirement_id
      | .cpa_review_ref = "urn:cpa-review:" + .requirement_id
    )
' "$LEDGER" >"$TMP/cleared.json"
"$SCRIPT" --ledger "$TMP/cleared.json" --json >"$TMP/cleared.out.json"
assert_jq "$TMP/cleared.out.json" '.status == "pass" and .clear_count == 6 and .sub_2_owner_signing_gate_status == "clear"' "all reviewed legal rows clear sub 2 gate"

jq '.requirements[0].notes = ("sk-" + "NOTAREALSECRET")' "$TMP/cleared.json" >"$TMP/secret-shaped-value.json"
if "$SCRIPT" --ledger "$TMP/secret-shaped-value.json" --json >"$TMP/secret-shaped-value.out.json" 2>/dev/null; then
  fail "secret-shaped legal value rejected"
else
  assert_jq "$TMP/secret-shaped-value.out.json" '.status == "fail" and (.failures[] | select(.code == "secret_or_raw_amount_shape_detected"))' "secret-shaped legal value rejected"
fi

jq '.requirements[0].status = "cleared" | .requirements[0].binding_artifact_ref = null' "$LEDGER" >"$TMP/cleared-missing-ref.json"
if "$SCRIPT" --ledger "$TMP/cleared-missing-ref.json" --json >"$TMP/cleared-missing-ref.out.json" 2>/dev/null; then
  fail "cleared status without refs rejected"
else
  assert_jq "$TMP/cleared-missing-ref.out.json" '.status == "fail" and (.failures[] | select(.code == "cleared_status_without_binding_and_review_refs"))' "cleared status without refs rejected"
fi

jq '.requirements[0].status = "attorney_reviewed" | .requirements[0].binding_artifact_ref = null | .requirements[0].attorney_review_ref = "urn:attorney-review:fixture"' "$LEDGER" >"$TMP/review-without-binding.json"
if "$SCRIPT" --ledger "$TMP/review-without-binding.json" --json >"$TMP/review-without-binding.out.json" 2>/dev/null; then
  fail "review status without binding artifact rejected"
else
  assert_jq "$TMP/review-without-binding.out.json" '.status == "fail" and (.failures[] | select(.code == "review_status_without_binding_artifact_ref"))' "review status without binding artifact rejected"
fi

jq 'del(.requirements[] | select(.requirement_id == "peer_coach_equity_pathway"))' "$LEDGER" >"$TMP/missing-required.json"
if "$SCRIPT" --ledger "$TMP/missing-required.json" --json >"$TMP/missing-required.out.json" 2>/dev/null; then
  fail "missing required legal row rejected"
else
  assert_jq "$TMP/missing-required.out.json" '.status == "fail" and (.failures[] | select(.code == "missing_required_legal_structure_requirement"))' "missing required legal row rejected"
fi

jq '.requirements[0].binding_artifact_ref = "state/no-such-legal-binding.json"' "$TMP/cleared.json" >"$TMP/missing-required-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-required-ref.json" --check-paths --json >"$TMP/missing-required-ref.out.json" 2>/dev/null; then
  fail "missing legal required ref rejected"
else
  assert_jq "$TMP/missing-required-ref.out.json" '.status == "fail" and (.failures[] | select(.code == "required_ref_missing"))' "missing legal required ref rejected"
fi

jq '.requirements[0].evidence_refs = ["state/no-such-legal-evidence.json"]' "$TMP/cleared.json" >"$TMP/missing-evidence-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-evidence-ref.json" --check-paths --json >"$TMP/missing-evidence-ref.out.json" 2>/dev/null; then
  fail "missing legal evidence ref rejected"
else
  assert_jq "$TMP/missing-evidence-ref.out.json" '.status == "fail" and (.failures[] | select(.code == "evidence_ref_missing"))' "missing legal evidence ref rejected"
fi

jq '.clear_count = 1' "$TMP/cleared.json" >"$TMP/count-mismatch.json"
if "$SCRIPT" --ledger "$TMP/count-mismatch.json" --json >"$TMP/count-mismatch.out.json" 2>/dev/null; then
  fail "clear count mismatch rejected"
else
  assert_jq "$TMP/count-mismatch.out.json" '.status == "fail" and (.failures[] | select(.code == "clear_count_mismatch"))' "clear count mismatch rejected"
fi

printf 'RESULT pass=%d fail=%d\n' "$pass_count" "$fail_count"
exit "$fail_count"
