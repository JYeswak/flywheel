#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/holding-company-nonprofit-extension-validate.py"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/holding-company-nonprofit-extension.schema.json"
LEDGER="$ROOT/state/holding-company-nonprofit-extension.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/holding-company-nonprofit.XXXXXX")"
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
assert_jq "$TMP/current.json" '.status == "pass" and .clear_count == 0 and .initiatives[0].nonprofit_extension_gate_status == "blocked"' "current deferred initiative validates and blocks nonprofit readiness"

jq 'del(.gate)' "$LEDGER" >"$TMP/schema-invalid.json"
if "$SCRIPT" --ledger "$TMP/schema-invalid.json" --json >"$TMP/schema-invalid.out.json" 2>/dev/null; then
  fail "schema-invalid nonprofit ledger rejected"
else
  assert_jq "$TMP/schema-invalid.out.json" '.status == "fail" and (.failures[] | select(.code == "schema_invalid"))' "schema-invalid nonprofit ledger rejected"
fi

jq '
  .clear_count = 1
  | .initiatives[0].status = "ready"
  | .initiatives[0].social_cause_scope_ref = "urn:social-cause-scope:fixture"
  | .initiatives[0].nonprofit_legal_review_ref = "urn:nonprofit-legal-review:fixture"
  | .initiatives[0].governance_model_ref = "urn:nonprofit-governance:fixture"
  | .initiatives[0].operating_separation_ref = "urn:operating-separation:fixture"
  | .initiatives[0].funding_policy_ref = "urn:funding-policy:fixture"
  | .initiatives[0].public_story_ref = "urn:public-story:fixture"
' "$LEDGER" >"$TMP/ready.json"
"$SCRIPT" --ledger "$TMP/ready.json" --json >"$TMP/ready.out.json"
assert_jq "$TMP/ready.out.json" '.status == "pass" and .clear_count == 1 and .initiatives[0].nonprofit_extension_gate_status == "clear"' "complete nonprofit readiness refs clear"

jq '.initiatives[0].notes = ("sk-" + "NOTAREALSECRET")' "$TMP/ready.json" >"$TMP/secret-shaped-value.json"
if "$SCRIPT" --ledger "$TMP/secret-shaped-value.json" --json >"$TMP/secret-shaped-value.out.json" 2>/dev/null; then
  fail "secret-shaped nonprofit value rejected"
else
  assert_jq "$TMP/secret-shaped-value.out.json" '.status == "fail" and (.failures[] | select(.code == "secret_or_raw_value_shape_detected"))' "secret-shaped nonprofit value rejected"
fi

jq '.initiatives[0].status = "ready"' "$LEDGER" >"$TMP/ready-missing.json"
if "$SCRIPT" --ledger "$TMP/ready-missing.json" --json >"$TMP/ready-missing.out.json" 2>/dev/null; then
  fail "ready without refs rejected"
else
  assert_jq "$TMP/ready-missing.out.json" '.failures[] | select(.code == "nonprofit_ready_missing_refs")' "ready without refs rejected"
fi

jq '.initiatives[0].portfolio_company_counting_excluded = false' "$TMP/ready.json" >"$TMP/counted.json"
if "$SCRIPT" --ledger "$TMP/counted.json" --json >"$TMP/counted.out.json" 2>/dev/null; then
  fail "nonprofit counted as portfolio company rejected"
else
  assert_jq "$TMP/counted.out.json" '.failures[] | select(.code == "nonprofit_ready_counted_as_portfolio_company")' "nonprofit counted as portfolio company rejected"
fi

jq '.initiatives[0].commingled_owner_economics_detected = true' "$TMP/ready.json" >"$TMP/commingled.json"
if "$SCRIPT" --ledger "$TMP/commingled.json" --json >"$TMP/commingled.out.json" 2>/dev/null; then
  fail "commingled owner economics rejected"
else
  assert_jq "$TMP/commingled.out.json" '.failures[] | select(.code == "nonprofit_ready_with_commingled_owner_economics")' "commingled owner economics rejected"
fi

jq '.initiatives[0].social_cause_scope_ref = "state/no-such-nonprofit-scope.json"' "$TMP/ready.json" >"$TMP/missing-required-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-required-ref.json" --check-paths --json >"$TMP/missing-required-ref.out.json" 2>/dev/null; then
  fail "missing nonprofit required ref rejected"
else
  assert_jq "$TMP/missing-required-ref.out.json" '.status == "fail" and (.failures[] | select(.code == "required_ref_missing"))' "missing nonprofit required ref rejected"
fi

jq '.initiatives[0].evidence_refs = ["state/no-such-nonprofit-evidence.json"]' "$TMP/ready.json" >"$TMP/missing-evidence-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-evidence-ref.json" --check-paths --json >"$TMP/missing-evidence-ref.out.json" 2>/dev/null; then
  fail "missing nonprofit evidence ref rejected"
else
  assert_jq "$TMP/missing-evidence-ref.out.json" '.status == "fail" and (.failures[] | select(.code == "evidence_ref_missing"))' "missing nonprofit evidence ref rejected"
fi

jq '.clear_count = 1' "$LEDGER" >"$TMP/bad-count.json"
if "$SCRIPT" --ledger "$TMP/bad-count.json" --json >"$TMP/bad-count.out.json" 2>/dev/null; then
  fail "nonprofit clear count mismatch rejected"
else
  assert_jq "$TMP/bad-count.out.json" '.failures[] | select(.code == "clear_count_mismatch")' "nonprofit clear count mismatch rejected"
fi

if [[ "$fail_count" -ne 0 ]]; then
  printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
