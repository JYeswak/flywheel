#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/holding-company-recycle-loop-validate.py"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/holding-company-recycle-loop.schema.json"
LEDGER="$ROOT/state/holding-company-recycle-loop.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/holding-company-recycle-loop.XXXXXX")"
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
assert_jq "$TMP/current.json" '.status == "pass" and .clear_count == 0 and .friction_items[0].recycle_gate_status == "blocked"' "current ledger validates and blocks RECYCLE"

jq '
  .clear_count = 1
  | .friction_items[0].status = "propagated"
  | .friction_items[0].friction_receipt_ref = "urn:friction:mobile-eats"
  | .friction_items[0].skillos_capability_ref = "urn:skillos-capability:mobile-eats"
  | .friction_items[0].package_or_substrate_ref = "urn:zeststream-package:mobile-eats"
  | .friction_items[0].portfolio_propagation_ref = "urn:portfolio-propagation:mobile-eats"
  | .friction_items[0].propagation_window_days = 14
' "$LEDGER" >"$TMP/propagated.json"
"$SCRIPT" --ledger "$TMP/propagated.json" --json >"$TMP/propagated.out.json"
assert_jq "$TMP/propagated.out.json" '.status == "pass" and .clear_count == 1 and .friction_items[0].recycle_gate_status == "clear"' "propagated friction with capability and package refs clears"

jq '.friction_items[0].skillos_capability_ref = null | .clear_count = 0' "$TMP/propagated.json" >"$TMP/missing-capability.json"
if "$SCRIPT" --ledger "$TMP/missing-capability.json" --json >"$TMP/missing-capability.out.json" 2>/dev/null; then
  fail "propagated friction missing SkillOS capability rejected"
else
  assert_jq "$TMP/missing-capability.out.json" '.status == "fail" and (.failures[] | select(.code == "propagated_status_missing_refs" and (.missing_refs | index("skillos_capability_ref"))))' "propagated friction missing SkillOS capability rejected"
fi

jq '.friction_items[0].propagation_window_days = 45 | .clear_count = 0' "$TMP/propagated.json" >"$TMP/slow-propagation.json"
if "$SCRIPT" --ledger "$TMP/slow-propagation.json" --json >"$TMP/slow-propagation.out.json" 2>/dev/null; then
  fail "over-max propagation window rejected"
else
  assert_jq "$TMP/slow-propagation.out.json" '.status == "fail" and (.failures[] | select(.code == "propagation_window_missing_or_over_max"))' "over-max propagation window rejected"
fi

jq '.clear_count = 2' "$TMP/propagated.json" >"$TMP/count-mismatch.json"
if "$SCRIPT" --ledger "$TMP/count-mismatch.json" --json >"$TMP/count-mismatch.out.json" 2>/dev/null; then
  fail "RECYCLE clear count mismatch rejected"
else
  assert_jq "$TMP/count-mismatch.out.json" '.status == "fail" and (.failures[] | select(.code == "clear_count_mismatch"))' "RECYCLE clear count mismatch rejected"
fi

jq 'del(.gate)' "$LEDGER" >"$TMP/schema-invalid.json"
if "$SCRIPT" --ledger "$TMP/schema-invalid.json" --json >"$TMP/schema-invalid.out.json" 2>/dev/null; then
  fail "schema-invalid RECYCLE ledger rejected"
else
  assert_jq "$TMP/schema-invalid.out.json" '.status == "fail" and (.failures[] | select(.code == "schema_invalid"))' "schema-invalid RECYCLE ledger rejected"
fi

jq '
  .friction_items[0].status = "capability_landed"
  | .friction_items[0].friction_receipt_ref = null
  | .clear_count = 0
' "$TMP/propagated.json" >"$TMP/landed-missing-friction.json"
if "$SCRIPT" --ledger "$TMP/landed-missing-friction.json" --json >"$TMP/landed-missing-friction.out.json" 2>/dev/null; then
  fail "landed friction missing receipt rejected"
else
  assert_jq "$TMP/landed-missing-friction.out.json" '.status == "fail" and (.failures[] | select(.code == "landed_status_without_friction_receipt"))' "landed friction missing receipt rejected"
fi

jq '
  .friction_items[0].status = "package_landed"
  | .friction_items[0].skillos_capability_ref = null
  | .clear_count = 0
' "$TMP/propagated.json" >"$TMP/package-missing-capability.json"
if "$SCRIPT" --ledger "$TMP/package-missing-capability.json" --json >"$TMP/package-missing-capability.out.json" 2>/dev/null; then
  fail "package landed without SkillOS capability rejected"
else
  assert_jq "$TMP/package-missing-capability.out.json" '.status == "fail" and (.failures[] | select(.code == "package_landed_without_skillos_capability"))' "package landed without SkillOS capability rejected"
fi

jq '.friction_items[0].friction_receipt_ref = "state/does-not-exist-recycle-friction.json" | .clear_count = 0' "$TMP/propagated.json" >"$TMP/missing-required-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-required-ref.json" --check-paths --json >"$TMP/missing-required-ref.out.json" 2>/dev/null; then
  fail "missing RECYCLE required ref rejected"
else
  assert_jq "$TMP/missing-required-ref.out.json" '.status == "fail" and (.failures[] | select(.code == "required_ref_missing" and .field == "friction_receipt_ref"))' "missing RECYCLE required ref rejected"
fi

jq '.friction_items[0].evidence_refs = ["state/does-not-exist-recycle-evidence.json"] | .clear_count = 0' "$TMP/propagated.json" >"$TMP/missing-evidence-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-evidence-ref.json" --check-paths --json >"$TMP/missing-evidence-ref.out.json" 2>/dev/null; then
  fail "missing RECYCLE evidence ref rejected"
else
  assert_jq "$TMP/missing-evidence-ref.out.json" '.status == "fail" and (.failures[] | select(.code == "evidence_ref_missing"))' "missing RECYCLE evidence ref rejected"
fi

jq '.friction_items[0].notes = "fixture sk-TestSecret123 should be rejected" | .clear_count = 0' "$TMP/propagated.json" >"$TMP/secret-shape.json"
if "$SCRIPT" --ledger "$TMP/secret-shape.json" --json >"$TMP/secret-shape.out.json" 2>/dev/null; then
  fail "secret-shaped RECYCLE value rejected"
else
  assert_jq "$TMP/secret-shape.out.json" '.status == "fail" and (.failures[] | select(.code == "secret_or_raw_amount_shape_detected"))' "secret-shaped RECYCLE value rejected"
fi

printf 'RESULT pass=%d fail=%d\n' "$pass_count" "$fail_count"
exit "$fail_count"
