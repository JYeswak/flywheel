#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/holding-company-candidate-fit-validate.py"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/holding-company-candidate-fit.schema.json"
LEDGER="$ROOT/state/holding-company-candidate-fit.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/holding-company-candidate-fit.XXXXXX")"
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
assert_jq "$TMP/current.json" '.status == "pass" and .clear_count == 0 and .candidates[0].candidate_fit_gate_status == "blocked"' "current ledger validates and blocks candidate fit"

jq 'del(.gate)' "$LEDGER" >"$TMP/schema-invalid.json"
if "$SCRIPT" --ledger "$TMP/schema-invalid.json" --json >"$TMP/schema-invalid.out.json" 2>/dev/null; then
  fail "schema-invalid candidate-fit ledger rejected"
else
  assert_jq "$TMP/schema-invalid.out.json" '.status == "fail" and (.failures[] | select(.code == "schema_invalid"))' "schema-invalid candidate-fit ledger rejected"
fi

jq '
  .clear_count = 1
  | .candidates[0].status = "candidate_clear"
  | .candidates[0].classification = "sharpen_legacy_smb"
  | .candidates[0].target_customer = "smb_owner_operator"
  | .candidates[0].smb_owner_operator_fit = true
  | .candidates[0].ai_transition_pain_present = true
  | .candidates[0].problem_statement = "Legacy SMB owner has an AI-transition operational pain."
  | .candidates[0].classification_ref = "urn:classification:legacy-smb"
  | .candidates[0].persona_ref = "urn:persona:smb-owner"
  | .candidates[0].problem_ref = "urn:problem:ai-transition"
  | .candidates[0].target_drift_flags = []
' "$LEDGER" >"$TMP/legacy-clear.json"
"$SCRIPT" --ledger "$TMP/legacy-clear.json" --json >"$TMP/legacy-clear.out.json"
assert_jq "$TMP/legacy-clear.out.json" '.status == "pass" and .clear_count == 1 and .candidates[0].candidate_fit_gate_status == "clear"' "legacy SMB sharpening candidate clears"

jq '.candidates[0].notes = ("sk-" + "NOTAREALSECRET")' "$TMP/legacy-clear.json" >"$TMP/secret-shaped-value.json"
if "$SCRIPT" --ledger "$TMP/secret-shaped-value.json" --json >"$TMP/secret-shaped-value.out.json" 2>/dev/null; then
  fail "secret-shaped candidate-fit value rejected"
else
  assert_jq "$TMP/secret-shaped-value.out.json" '.status == "fail" and (.failures[] | select(.code == "secret_or_raw_value_shape_detected"))' "secret-shaped candidate-fit value rejected"
fi

jq '
  .clear_count = 1
  | .candidates[0].status = "press_clear"
  | .candidates[0].classification = "incubate_ai_first"
  | .candidates[0].target_customer = "smb_owner_operator"
  | .candidates[0].smb_owner_operator_fit = true
  | .candidates[0].ai_first_opportunity_present = true
  | .candidates[0].problem_statement = "SMB owner needs an AI-native operating surface."
  | .candidates[0].classification_ref = "urn:classification:ai-first"
  | .candidates[0].persona_ref = "urn:persona:smb-owner"
  | .candidates[0].problem_ref = "urn:problem:ai-first"
  | .candidates[0].target_drift_flags = []
' "$LEDGER" >"$TMP/ai-first-clear.json"
"$SCRIPT" --ledger "$TMP/ai-first-clear.json" --json >"$TMP/ai-first-clear.out.json"
assert_jq "$TMP/ai-first-clear.out.json" '.status == "pass" and .clear_count == 1 and .candidates[0].candidate_fit_gate_status == "clear"' "AI-first incubation candidate clears"

jq '
  .clear_count = 1
  | .candidates[0].status = "candidate_clear"
  | .candidates[0].classification = "unknown"
  | .candidates[0].target_customer = "smb_owner_operator"
  | .candidates[0].smb_owner_operator_fit = true
  | .candidates[0].ai_transition_pain_present = true
  | .candidates[0].problem_statement = "Problem stated."
  | .candidates[0].classification_ref = "urn:classification:unknown"
  | .candidates[0].persona_ref = "urn:persona:smb-owner"
  | .candidates[0].problem_ref = "urn:problem:fixture"
  | .candidates[0].target_drift_flags = []
' "$LEDGER" >"$TMP/unknown-classification.json"
if "$SCRIPT" --ledger "$TMP/unknown-classification.json" --json >"$TMP/unknown-classification.out.json" 2>/dev/null; then
  fail "unknown classification rejected for clear status"
else
  assert_jq "$TMP/unknown-classification.out.json" '.status == "fail" and (.failures[] | select(.code == "candidate_fit_clear_without_classification"))' "unknown classification rejected for clear status"
fi

jq '
  .clear_count = 1
  | .candidates[0].status = "candidate_clear"
  | .candidates[0].classification = "sharpen_legacy_smb"
  | .candidates[0].target_customer = "enterprise_buyer"
  | .candidates[0].smb_owner_operator_fit = false
  | .candidates[0].ai_transition_pain_present = true
  | .candidates[0].problem_statement = "Problem stated."
  | .candidates[0].classification_ref = "urn:classification:legacy-smb"
  | .candidates[0].persona_ref = "urn:persona:enterprise"
  | .candidates[0].problem_ref = "urn:problem:fixture"
  | .candidates[0].target_drift_flags = []
' "$LEDGER" >"$TMP/not-owner.json"
if "$SCRIPT" --ledger "$TMP/not-owner.json" --json >"$TMP/not-owner.out.json" 2>/dev/null; then
  fail "non-owner-operator target rejected"
else
  assert_jq "$TMP/not-owner.out.json" '.status == "fail" and (.failures[] | select(.code == "candidate_fit_clear_without_smb_owner_operator"))' "non-owner-operator target rejected"
fi

jq '
  .clear_count = 1
  | .candidates[0].status = "candidate_clear"
  | .candidates[0].classification = "sharpen_legacy_smb"
  | .candidates[0].target_customer = "smb_owner_operator"
  | .candidates[0].smb_owner_operator_fit = true
  | .candidates[0].ai_transition_pain_present = false
  | .candidates[0].problem_statement = "Problem stated."
  | .candidates[0].classification_ref = "urn:classification:legacy-smb"
  | .candidates[0].persona_ref = "urn:persona:smb-owner"
  | .candidates[0].problem_ref = "urn:problem:fixture"
  | .candidates[0].target_drift_flags = []
' "$LEDGER" >"$TMP/no-ai-fit.json"
if "$SCRIPT" --ledger "$TMP/no-ai-fit.json" --json >"$TMP/no-ai-fit.out.json" 2>/dev/null; then
  fail "missing AI problem fit rejected"
else
  assert_jq "$TMP/no-ai-fit.out.json" '.status == "fail" and (.failures[] | select(.code == "candidate_fit_clear_without_ai_problem_fit"))' "missing AI problem fit rejected"
fi

jq '
  .clear_count = 1
  | .candidates[0].status = "formation_clear"
  | .candidates[0].classification = "sharpen_legacy_smb"
  | .candidates[0].target_customer = "smb_owner_operator"
  | .candidates[0].smb_owner_operator_fit = true
  | .candidates[0].ai_transition_pain_present = true
  | .candidates[0].problem_statement = "Problem stated."
  | .candidates[0].classification_ref = "urn:classification:legacy-smb"
  | .candidates[0].persona_ref = "urn:persona:smb-owner"
  | .candidates[0].problem_ref = "urn:problem:fixture"
  | .candidates[0].target_drift_flags = ["enterprise_saas_generic"]
' "$LEDGER" >"$TMP/target-drift.json"
if "$SCRIPT" --ledger "$TMP/target-drift.json" --json >"$TMP/target-drift.out.json" 2>/dev/null; then
  fail "target drift rejected for clear status"
else
  assert_jq "$TMP/target-drift.out.json" '.status == "fail" and (.failures[] | select(.code == "candidate_fit_clear_with_target_drift"))' "target drift rejected for clear status"
fi

jq '.candidates[0].evidence_refs = []' "$TMP/legacy-clear.json" >"$TMP/no-evidence-refs.json"
if "$SCRIPT" --ledger "$TMP/no-evidence-refs.json" --json >"$TMP/no-evidence-refs.out.json" 2>/dev/null; then
  fail "candidate clear without evidence refs rejected"
else
  assert_jq "$TMP/no-evidence-refs.out.json" '.status == "fail" and (.failures[] | select(.code == "candidate_fit_clear_without_evidence_refs"))' "candidate clear without evidence refs rejected"
fi

jq '.candidates[0].evidence_refs = ["state/no-such-candidate-fit-evidence.json"]' "$TMP/legacy-clear.json" >"$TMP/missing-evidence-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-evidence-ref.json" --check-paths --json >"$TMP/missing-evidence-ref.out.json" 2>/dev/null; then
  fail "missing candidate-fit evidence ref rejected"
else
  assert_jq "$TMP/missing-evidence-ref.out.json" '.status == "fail" and (.failures[] | select(.code == "evidence_ref_missing"))' "missing candidate-fit evidence ref rejected"
fi

jq '.clear_count = 2' "$TMP/legacy-clear.json" >"$TMP/mismatch.json"
if "$SCRIPT" --ledger "$TMP/mismatch.json" --json >"$TMP/mismatch.out.json" 2>/dev/null; then
  fail "clear count mismatch rejected"
else
  assert_jq "$TMP/mismatch.out.json" '.status == "fail" and (.failures[] | select(.code == "candidate_fit_clear_count_mismatch"))' "clear count mismatch rejected"
fi

printf 'RESULT pass=%d fail=%d\n' "$pass_count" "$fail_count"
exit "$fail_count"
