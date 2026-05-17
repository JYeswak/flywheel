#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/holding-company-brand-voice-skill-validate.py"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/holding-company-brand-voice-skill.schema.json"
LEDGER="$ROOT/state/holding-company-brand-voice-skill.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/holding-company-brand-voice-skill.XXXXXX")"
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
assert_jq "$TMP/current.json" '.status == "pass" and .clear_count == 0 and .skills[0].brand_voice_skill_gate_status == "blocked" and (.skills[0].holding_company_canon_present == false)' "current skill validates and blocks alignment"

jq 'del(.gate)' "$LEDGER" >"$TMP/schema-invalid.json"
if "$SCRIPT" --ledger "$TMP/schema-invalid.json" --json >"$TMP/schema-invalid.out.json" 2>/dev/null; then
  fail "schema-invalid brand voice skill ledger rejected"
else
  assert_jq "$TMP/schema-invalid.out.json" '.status == "fail" and (.failures[] | select(.code == "schema_invalid"))' "schema-invalid brand voice skill ledger rejected"
fi

jq '
  .clear_count = 1
  | .skills[0].status = "aligned"
  | .skills[0].holding_company_canon_present = true
  | .skills[0].grounding_rules_present = true
  | .skills[0].builder_frame_rejection_present = true
  | .skills[0].approved_update_receipt = "urn:jsm-receipt:zeststream-brand-voice-holding-company"
  | .skills[0].current_primary_canon = "ZestStream sharpens legacy SMBs and incubates AI-first companies."
' "$LEDGER" >"$TMP/aligned.json"
"$SCRIPT" --ledger "$TMP/aligned.json" --json >"$TMP/aligned.out.json"
assert_jq "$TMP/aligned.out.json" '.status == "pass" and .clear_count == 1 and .skills[0].brand_voice_skill_gate_status == "clear"' "aligned skill with JSM receipt passes"

jq '.skills[0].notes = ("sk-" + "NOTAREALSECRET")' "$TMP/aligned.json" >"$TMP/secret-shaped-value.json"
if "$SCRIPT" --ledger "$TMP/secret-shaped-value.json" --json >"$TMP/secret-shaped-value.out.json" 2>/dev/null; then
  fail "secret-shaped brand voice skill value rejected"
else
  assert_jq "$TMP/secret-shaped-value.out.json" '.status == "fail" and (.failures[] | select(.code == "secret_or_raw_value_shape_detected"))' "secret-shaped brand voice skill value rejected"
fi

jq '.skills[0].jsm_managed = false' "$TMP/aligned.json" >"$TMP/not-jsm-managed.json"
if "$SCRIPT" --ledger "$TMP/not-jsm-managed.json" --json >"$TMP/not-jsm-managed.out.json" 2>/dev/null; then
  fail "clear without JSM management rejected"
else
  assert_jq "$TMP/not-jsm-managed.out.json" '.status == "fail" and (.failures[] | select(.code == "brand_voice_clear_without_jsm_management"))' "clear without JSM management rejected"
fi

jq '.skills[0].holding_company_canon_present = false' "$TMP/aligned.json" >"$TMP/missing-canon.json"
if "$SCRIPT" --ledger "$TMP/missing-canon.json" --json >"$TMP/missing-canon.out.json" 2>/dev/null; then
  fail "clear without holding-company canon rejected"
else
  assert_jq "$TMP/missing-canon.out.json" '.status == "fail" and (.failures[] | select(.code == "brand_voice_clear_without_holding_company_canon"))' "clear without holding-company canon rejected"
fi

jq '.skills[0].grounding_rules_present = false' "$TMP/aligned.json" >"$TMP/missing-grounding.json"
if "$SCRIPT" --ledger "$TMP/missing-grounding.json" --json >"$TMP/missing-grounding.out.json" 2>/dev/null; then
  fail "clear without grounding rules rejected"
else
  assert_jq "$TMP/missing-grounding.out.json" '.status == "fail" and (.failures[] | select(.code == "brand_voice_clear_without_grounding_rules"))' "clear without grounding rules rejected"
fi

jq '.skills[0].builder_frame_rejection_present = false' "$TMP/aligned.json" >"$TMP/missing-builder-rejection.json"
if "$SCRIPT" --ledger "$TMP/missing-builder-rejection.json" --json >"$TMP/missing-builder-rejection.out.json" 2>/dev/null; then
  fail "clear without builder-frame rejection rejected"
else
  assert_jq "$TMP/missing-builder-rejection.out.json" '.status == "fail" and (.failures[] | select(.code == "brand_voice_clear_without_builder_frame_rejection"))' "clear without builder-frame rejection rejected"
fi

jq '.skills[0].approved_update_receipt = null' "$TMP/aligned.json" >"$TMP/missing-receipt.json"
if "$SCRIPT" --ledger "$TMP/missing-receipt.json" --json >"$TMP/missing-receipt.out.json" 2>/dev/null; then
  fail "clear without JSM receipt rejected"
else
  assert_jq "$TMP/missing-receipt.out.json" '.status == "fail" and (.failures[] | select(.code == "brand_voice_clear_without_jsm_receipt"))' "clear without JSM receipt rejected"
fi

jq '.skills[0].required_positioning = "old_smb_time_back"' "$TMP/aligned.json" >"$TMP/positioning-mismatch.json"
if "$SCRIPT" --ledger "$TMP/positioning-mismatch.json" --json >"$TMP/positioning-mismatch.out.json" 2>/dev/null; then
  fail "required positioning mismatch rejected"
else
  assert_jq "$TMP/positioning-mismatch.out.json" '.status == "fail" and (.failures[] | select(.code == "brand_voice_clear_required_positioning_mismatch"))' "required positioning mismatch rejected"
fi

jq '.skills[0].skill_path = "state/no-such-brand-voice-skill.yaml"' "$TMP/aligned.json" >"$TMP/missing-skill-path.json"
if "$SCRIPT" --ledger "$TMP/missing-skill-path.json" --check-paths --json >"$TMP/missing-skill-path.out.json" 2>/dev/null; then
  fail "missing brand voice skill path rejected"
else
  assert_jq "$TMP/missing-skill-path.out.json" '.status == "fail" and (.failures[] | select(.code == "skill_path_missing"))' "missing brand voice skill path rejected"
fi

jq '.skills[0].approved_update_receipt = "state/no-such-brand-voice-jsm-receipt.json"' "$TMP/aligned.json" >"$TMP/missing-approved-receipt.json"
if "$SCRIPT" --ledger "$TMP/missing-approved-receipt.json" --check-paths --json >"$TMP/missing-approved-receipt.out.json" 2>/dev/null; then
  fail "missing approved brand voice JSM receipt rejected"
else
  assert_jq "$TMP/missing-approved-receipt.out.json" '.status == "fail" and (.failures[] | select(.code == "approved_update_receipt_missing"))' "missing approved brand voice JSM receipt rejected"
fi

jq '.skills[0].evidence_refs = ["state/no-such-brand-voice-evidence.json"]' "$TMP/aligned.json" >"$TMP/missing-evidence-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-evidence-ref.json" --check-paths --json >"$TMP/missing-evidence-ref.out.json" 2>/dev/null; then
  fail "missing brand voice evidence ref rejected"
else
  assert_jq "$TMP/missing-evidence-ref.out.json" '.status == "fail" and (.failures[] | select(.code == "evidence_ref_missing"))' "missing brand voice evidence ref rejected"
fi

jq '.clear_count = 2' "$TMP/aligned.json" >"$TMP/count-mismatch.json"
if "$SCRIPT" --ledger "$TMP/count-mismatch.json" --json >"$TMP/count-mismatch.out.json" 2>/dev/null; then
  fail "brand voice clear count mismatch rejected"
else
  assert_jq "$TMP/count-mismatch.out.json" '.status == "fail" and (.failures[] | select(.code == "brand_voice_clear_count_mismatch"))' "brand voice clear count mismatch rejected"
fi

printf 'RESULT pass=%d fail=%d\n' "$pass_count" "$fail_count"
exit "$fail_count"
