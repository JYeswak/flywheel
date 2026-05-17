#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/holding-company-owner-voice-validate.py"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/holding-company-owner-voice.schema.json"
LEDGER="$ROOT/state/holding-company-owner-voice.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/holding-company-owner-voice.XXXXXX")"
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
assert_jq "$TMP/current.json" '.status == "pass" and .clear_count == 0 and .surfaces[0].owner_voice_gate_status == "blocked"' "current ledger validates and blocks owner voice"

jq '
  .clear_count = 1
  | .surfaces[0].status = "clear"
  | .surfaces[0].owner_operator_ref = "urn:owner-operator:mobile-eats"
  | .surfaces[0].owner_voice_ref = "urn:owner-voice:mobile-eats"
  | .surfaces[0].community_context_ref = "urn:community-context:mobile-eats"
  | .surfaces[0].yuzu_review_ref = "urn:yuzu-review:mobile-eats"
  | .surfaces[0].owner_voice_present = true
  | .surfaces[0].community_context_present = true
  | .surfaces[0].zeststream_meta_voice_detected = false
' "$LEDGER" >"$TMP/clear.json"
"$SCRIPT" --ledger "$TMP/clear.json" --json >"$TMP/clear.out.json"
assert_jq "$TMP/clear.out.json" '.status == "pass" and .clear_count == 1 and .surfaces[0].owner_voice_gate_status == "clear"' "owner and community voice clear"

jq '.surfaces[0].owner_voice_ref = null | .clear_count = 0' "$TMP/clear.json" >"$TMP/missing-owner-voice.json"
if "$SCRIPT" --ledger "$TMP/missing-owner-voice.json" --json >"$TMP/missing-owner-voice.out.json" 2>/dev/null; then
  fail "clear without owner voice ref rejected"
else
  assert_jq "$TMP/missing-owner-voice.out.json" '.status == "fail" and (.failures[] | select(.code == "owner_voice_clear_missing_refs" and (.missing_refs | index("owner_voice_ref"))))' "clear without owner voice ref rejected"
fi

jq '.surfaces[0].zeststream_meta_voice_detected = true | .clear_count = 0' "$TMP/clear.json" >"$TMP/meta-voice.json"
if "$SCRIPT" --ledger "$TMP/meta-voice.json" --json >"$TMP/meta-voice.out.json" 2>/dev/null; then
  fail "clear with ZestStream meta voice rejected"
else
  assert_jq "$TMP/meta-voice.out.json" '.status == "fail" and (.failures[] | select(.code == "owner_voice_clear_with_zeststream_meta_voice"))' "clear with ZestStream meta voice rejected"
fi

jq '.clear_count = 2' "$TMP/clear.json" >"$TMP/count-mismatch.json"
if "$SCRIPT" --ledger "$TMP/count-mismatch.json" --json >"$TMP/count-mismatch.out.json" 2>/dev/null; then
  fail "owner voice clear count mismatch rejected"
else
  assert_jq "$TMP/count-mismatch.out.json" '.status == "fail" and (.failures[] | select(.code == "clear_count_mismatch"))' "owner voice clear count mismatch rejected"
fi

jq 'del(.gate)' "$LEDGER" >"$TMP/schema-invalid.json"
if "$SCRIPT" --ledger "$TMP/schema-invalid.json" --json >"$TMP/schema-invalid.out.json" 2>/dev/null; then
  fail "schema-invalid owner voice ledger rejected"
else
  assert_jq "$TMP/schema-invalid.out.json" '.status == "fail" and (.failures[] | select(.code == "schema_invalid"))' "schema-invalid owner voice ledger rejected"
fi

jq '.surfaces[0].owner_voice_present = false | .clear_count = 0' "$TMP/clear.json" >"$TMP/without-owner-voice.json"
if "$SCRIPT" --ledger "$TMP/without-owner-voice.json" --json >"$TMP/without-owner-voice.out.json" 2>/dev/null; then
  fail "clear without owner voice evidence rejected"
else
  assert_jq "$TMP/without-owner-voice.out.json" '.status == "fail" and (.failures[] | select(.code == "owner_voice_clear_without_owner_voice"))' "clear without owner voice evidence rejected"
fi

jq '.surfaces[0].community_context_present = false | .clear_count = 0' "$TMP/clear.json" >"$TMP/without-community-context.json"
if "$SCRIPT" --ledger "$TMP/without-community-context.json" --json >"$TMP/without-community-context.out.json" 2>/dev/null; then
  fail "clear without community context rejected"
else
  assert_jq "$TMP/without-community-context.out.json" '.status == "fail" and (.failures[] | select(.code == "owner_voice_clear_without_community_context"))' "clear without community context rejected"
fi

jq '.surfaces[0].notes = "fixture sk-TestSecret123 should be rejected" | .clear_count = 0' "$TMP/clear.json" >"$TMP/secret-shape.json"
if "$SCRIPT" --ledger "$TMP/secret-shape.json" --json >"$TMP/secret-shape.out.json" 2>/dev/null; then
  fail "secret-shaped owner voice value rejected"
else
  assert_jq "$TMP/secret-shape.out.json" '.status == "fail" and (.failures[] | select(.code == "secret_or_raw_amount_shape_detected"))' "secret-shaped owner voice value rejected"
fi

jq '.surfaces[0].owner_operator_ref = "state/does-not-exist-owner-operator.json" | .clear_count = 0' "$TMP/clear.json" >"$TMP/missing-required-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-required-ref.json" --check-paths --json >"$TMP/missing-required-ref.out.json" 2>/dev/null; then
  fail "missing required owner voice ref rejected"
else
  assert_jq "$TMP/missing-required-ref.out.json" '.status == "fail" and (.failures[] | select(.code == "required_ref_missing" and .field == "owner_operator_ref"))' "missing required owner voice ref rejected"
fi

jq '.surfaces[0].evidence_refs = ["state/does-not-exist-owner-voice-evidence.json"] | .clear_count = 0' "$TMP/clear.json" >"$TMP/missing-evidence-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-evidence-ref.json" --check-paths --json >"$TMP/missing-evidence-ref.out.json" 2>/dev/null; then
  fail "missing owner voice evidence ref rejected"
else
  assert_jq "$TMP/missing-evidence-ref.out.json" '.status == "fail" and (.failures[] | select(.code == "evidence_ref_missing"))' "missing owner voice evidence ref rejected"
fi

printf 'RESULT pass=%d fail=%d\n' "$pass_count" "$fail_count"
exit "$fail_count"
