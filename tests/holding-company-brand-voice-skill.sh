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

jq '.clear_count = 2' "$TMP/aligned.json" >"$TMP/count-mismatch.json"
if "$SCRIPT" --ledger "$TMP/count-mismatch.json" --json >"$TMP/count-mismatch.out.json" 2>/dev/null; then
  fail "brand voice clear count mismatch rejected"
else
  assert_jq "$TMP/count-mismatch.out.json" '.status == "fail" and (.failures[] | select(.code == "brand_voice_clear_count_mismatch"))' "brand voice clear count mismatch rejected"
fi

printf 'RESULT pass=%d fail=%d\n' "$pass_count" "$fail_count"
exit "$fail_count"
