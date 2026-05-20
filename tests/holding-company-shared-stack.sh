#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/holding-company-shared-stack-validate.py"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/holding-company-shared-stack.schema.json"
LEDGER="$ROOT/state/holding-company-shared-stack.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/holding-company-shared-stack.XXXXXX")"
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
assert_jq "$TMP/current.json" '.status == "pass" and .clear_count == 0 and .companies[0].shared_stack_gate_status == "blocked"' "current ledger validates and blocks shared stack"

jq '
  .clear_count = 1
  | .companies[0].status = "shared_stack_clear"
  | .companies[0].components |= map(.status = "present" | .receipt_ref = ("urn:shared-stack:" + .component))
' "$LEDGER" >"$TMP/clear.json"
"$SCRIPT" --ledger "$TMP/clear.json" --json >"$TMP/clear.out.json"
assert_jq "$TMP/clear.out.json" '.status == "pass" and .clear_count == 1 and .companies[0].shared_stack_gate_status == "clear"' "all five shared-stack components clear"

jq 'del(.companies[0].components[] | select(.component == "jsm")) | .clear_count = 0' "$TMP/clear.json" >"$TMP/missing-jsm.json"
if "$SCRIPT" --ledger "$TMP/missing-jsm.json" --json >"$TMP/missing-jsm.out.json" 2>/dev/null; then
  fail "missing JSM component rejected"
else
  assert_jq "$TMP/missing-jsm.out.json" '.status == "fail" and (.failures[] | select(.code == "missing_required_components" and (.components | index("jsm"))))' "missing JSM component rejected"
  assert_jq "$TMP/missing-jsm.out.json" '.status == "fail" and (.failures[] | select(.code == "shared_stack_clear_missing_components" and (.components | index("jsm"))))' "shared-stack clear missing components rejected"
fi

jq '(.companies[0].components[] | select(.component == "brand_voice") | .status) = "partial" | .clear_count = 0' "$TMP/clear.json" >"$TMP/partial-brand.json"
if "$SCRIPT" --ledger "$TMP/partial-brand.json" --json >"$TMP/partial-brand.out.json" 2>/dev/null; then
  fail "shared-stack clear with partial brand voice rejected"
else
  assert_jq "$TMP/partial-brand.out.json" '.status == "fail" and (.failures[] | select(.code == "shared_stack_clear_component_not_present" and .component == "brand_voice"))' "shared-stack clear with partial brand voice rejected"
fi

jq '.clear_count = 2' "$TMP/clear.json" >"$TMP/count-mismatch.json"
if "$SCRIPT" --ledger "$TMP/count-mismatch.json" --json >"$TMP/count-mismatch.out.json" 2>/dev/null; then
  fail "shared-stack clear count mismatch rejected"
else
  assert_jq "$TMP/count-mismatch.out.json" '.status == "fail" and (.failures[] | select(.code == "clear_count_mismatch"))' "shared-stack clear count mismatch rejected"
fi

jq 'del(.gate)' "$LEDGER" >"$TMP/schema-invalid.json"
if "$SCRIPT" --ledger "$TMP/schema-invalid.json" --json >"$TMP/schema-invalid.out.json" 2>/dev/null; then
  fail "schema-invalid shared-stack ledger rejected"
else
  assert_jq "$TMP/schema-invalid.out.json" '.status == "fail" and (.failures[] | select(.code == "schema_invalid"))' "schema-invalid shared-stack ledger rejected"
fi

jq '.required_components = ["skillos", "flywheel", "jsm", "brand_voice", "brand_voice"]' "$LEDGER" >"$TMP/required-components-mismatch.json"
if "$SCRIPT" --ledger "$TMP/required-components-mismatch.json" --json >"$TMP/required-components-mismatch.out.json" 2>/dev/null; then
  fail "required shared-stack component manifest mismatch rejected"
else
  assert_jq "$TMP/required-components-mismatch.out.json" '.status == "fail" and (.failures[] | select(.code == "required_components_mismatch"))' "required shared-stack component manifest mismatch rejected"
fi

jq '.companies[0].components += [.companies[0].components[] | select(.component == "jsm")] | .clear_count = 0' "$TMP/clear.json" >"$TMP/duplicate-jsm.json"
if "$SCRIPT" --ledger "$TMP/duplicate-jsm.json" --json >"$TMP/duplicate-jsm.out.json" 2>/dev/null; then
  fail "duplicate shared-stack component rejected"
else
  assert_jq "$TMP/duplicate-jsm.out.json" '.status == "fail" and (.failures[] | select(.code == "duplicate_required_components" and (.components | index("jsm"))))' "duplicate shared-stack component rejected"
fi

jq '(.companies[0].components[] | select(.component == "jsm") | .receipt_ref) = null | .clear_count = 0' "$TMP/clear.json" >"$TMP/missing-component-receipt.json"
if "$SCRIPT" --ledger "$TMP/missing-component-receipt.json" --json >"$TMP/missing-component-receipt.out.json" 2>/dev/null; then
  fail "shared-stack clear missing component receipt rejected"
else
  assert_jq "$TMP/missing-component-receipt.out.json" '.status == "fail" and (.failures[] | select(.code == "shared_stack_clear_component_missing_receipt" and .component == "jsm"))' "shared-stack clear missing component receipt rejected"
fi

jq '(.companies[0].components[] | select(.component == "jsm") | .receipt_ref) = "state/does-not-exist-shared-stack-jsm-receipt.json" | .clear_count = 0' "$TMP/clear.json" >"$TMP/missing-receipt-path.json"
if "$SCRIPT" --ledger "$TMP/missing-receipt-path.json" --check-paths --json >"$TMP/missing-receipt-path.out.json" 2>/dev/null; then
  fail "missing shared-stack component receipt path rejected"
else
  assert_jq "$TMP/missing-receipt-path.out.json" '.status == "fail" and (.failures[] | select(.code == "component_receipt_missing" and .component == "jsm"))' "missing shared-stack component receipt path rejected"
fi

jq '(.companies[0].components[] | select(.component == "jsm") | .evidence_refs) = ["state/does-not-exist-shared-stack-jsm-evidence.json"] | .clear_count = 0' "$TMP/clear.json" >"$TMP/missing-component-evidence.json"
if "$SCRIPT" --ledger "$TMP/missing-component-evidence.json" --check-paths --json >"$TMP/missing-component-evidence.out.json" 2>/dev/null; then
  fail "missing shared-stack component evidence ref rejected"
else
  assert_jq "$TMP/missing-component-evidence.out.json" '.status == "fail" and (.failures[] | select(.code == "component_evidence_ref_missing" and .component == "jsm"))' "missing shared-stack component evidence ref rejected"
fi

jq '.companies[0].evidence_refs = ["state/does-not-exist-shared-stack-company-evidence.json"] | .clear_count = 0' "$TMP/clear.json" >"$TMP/missing-company-evidence.json"
if "$SCRIPT" --ledger "$TMP/missing-company-evidence.json" --check-paths --json >"$TMP/missing-company-evidence.out.json" 2>/dev/null; then
  fail "missing shared-stack company evidence ref rejected"
else
  assert_jq "$TMP/missing-company-evidence.out.json" '.status == "fail" and (.failures[] | select(.code == "company_evidence_ref_missing"))' "missing shared-stack company evidence ref rejected"
fi

jq '(.companies[0].components[] | select(.component == "jsm") | .notes) = "fixture sk-TestSecret123 should be rejected" | .clear_count = 0' "$TMP/clear.json" >"$TMP/secret-shape.json"
if "$SCRIPT" --ledger "$TMP/secret-shape.json" --json >"$TMP/secret-shape.out.json" 2>/dev/null; then
  fail "secret-shaped shared-stack component value rejected"
else
  assert_jq "$TMP/secret-shape.out.json" '.status == "fail" and (.failures[] | select(.code == "secret_or_raw_amount_shape_detected" and .component == "jsm"))' "secret-shaped shared-stack component value rejected"
fi

printf 'RESULT pass=%d fail=%d\n' "$pass_count" "$fail_count"
exit "$fail_count"
