#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/holding-company-founder-post-voice-validate.py"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/holding-company-founder-post-voice.schema.json"
LEDGER="$ROOT/state/holding-company-founder-post-voice.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/holding-company-founder-post.XXXXXX")"
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
assert_jq "$TMP/current.json" '.status == "pass" and .clear_count == 0 and .posts[0].founder_post_voice_gate_status == "blocked" and .posts[0].claim_fact_check_status == "fail"' "current founder post validates and blocks voice clear"

jq '
  .clear_count = 1
  | .posts[0].status = "clear"
  | .posts[0].holding_company_positioning_present = true
  | .posts[0].receipt_story_present = true
  | .posts[0].claim_fact_check_status = "pass"
  | .posts[0].proof_or_receipt_refs = ["urn:receipt:fact-checked-founder-post"]
  | .posts[0].builder_framing_hits = []
' "$LEDGER" >"$TMP/clear.json"
"$SCRIPT" --ledger "$TMP/clear.json" --json >"$TMP/clear.out.json"
assert_jq "$TMP/clear.out.json" '.status == "pass" and .clear_count == 1 and .posts[0].founder_post_voice_gate_status == "clear"' "fact-checked holding-company founder post clears"

jq '.posts[0].holding_company_positioning_present = false' "$TMP/clear.json" >"$TMP/no-positioning.json"
if "$SCRIPT" --ledger "$TMP/no-positioning.json" --json >"$TMP/no-positioning.out.json" 2>/dev/null; then
  fail "clear without holding-company positioning rejected"
else
  assert_jq "$TMP/no-positioning.out.json" '.status == "fail" and (.failures[] | select(.code == "founder_post_clear_without_holding_company_positioning"))' "clear without holding-company positioning rejected"
fi

jq '.posts[0].receipt_story_present = false' "$TMP/clear.json" >"$TMP/no-receipt-story.json"
if "$SCRIPT" --ledger "$TMP/no-receipt-story.json" --json >"$TMP/no-receipt-story.out.json" 2>/dev/null; then
  fail "clear without receipt story rejected"
else
  assert_jq "$TMP/no-receipt-story.out.json" '.status == "fail" and (.failures[] | select(.code == "founder_post_clear_without_receipt_story"))' "clear without receipt story rejected"
fi

jq '.posts[0].claim_fact_check_status = "fail"' "$TMP/clear.json" >"$TMP/fact-fail.json"
if "$SCRIPT" --ledger "$TMP/fact-fail.json" --json >"$TMP/fact-fail.out.json" 2>/dev/null; then
  fail "clear with failed fact-check rejected"
else
  assert_jq "$TMP/fact-fail.out.json" '.status == "fail" and (.failures[] | select(.code == "founder_post_clear_without_fact_check_pass"))' "clear with failed fact-check rejected"
fi

jq '.posts[0].proof_or_receipt_refs = []' "$TMP/clear.json" >"$TMP/no-proof.json"
if "$SCRIPT" --ledger "$TMP/no-proof.json" --json >"$TMP/no-proof.out.json" 2>/dev/null; then
  fail "clear without proof refs rejected"
else
  assert_jq "$TMP/no-proof.out.json" '.status == "fail" and (.failures[] | select(.code == "founder_post_clear_missing_proof_refs"))' "clear without proof refs rejected"
fi

jq '.posts[0].builder_framing_hits = [{"frame":"workflow_builder","path":"urn:post","line":1,"excerpt":"workflow builder"}]' "$TMP/clear.json" >"$TMP/builder-hit.json"
if "$SCRIPT" --ledger "$TMP/builder-hit.json" --json >"$TMP/builder-hit.out.json" 2>/dev/null; then
  fail "clear with builder framing rejected"
else
  assert_jq "$TMP/builder-hit.out.json" '.status == "fail" and (.failures[] | select(.code == "founder_post_clear_with_builder_framing"))' "clear with builder framing rejected"
fi

jq '.posts[0].human_ratification_required = false' "$TMP/clear.json" >"$TMP/no-human-gate.json"
if "$SCRIPT" --ledger "$TMP/no-human-gate.json" --json >"$TMP/no-human-gate.out.json" 2>/dev/null; then
  fail "clear without human ratification gate rejected"
else
  assert_jq "$TMP/no-human-gate.out.json" '.status == "fail" and (.failures[] | select(.code == "founder_post_clear_without_human_ratification_gate"))' "clear without human ratification gate rejected"
fi

jq '.posts[0].publisher_receipt_ref = null' "$TMP/clear.json" >"$TMP/no-publisher.json"
if "$SCRIPT" --ledger "$TMP/no-publisher.json" --json >"$TMP/no-publisher.out.json" 2>/dev/null; then
  fail "clear without publisher receipt rejected"
else
  assert_jq "$TMP/no-publisher.out.json" '.status == "fail" and (.failures[] | select(.code == "founder_post_clear_without_publisher_receipt"))' "clear without publisher receipt rejected"
fi

jq '.clear_count = 2' "$TMP/clear.json" >"$TMP/count-mismatch.json"
if "$SCRIPT" --ledger "$TMP/count-mismatch.json" --json >"$TMP/count-mismatch.out.json" 2>/dev/null; then
  fail "founder post clear count mismatch rejected"
else
  assert_jq "$TMP/count-mismatch.out.json" '.status == "fail" and (.failures[] | select(.code == "founder_post_clear_count_mismatch"))' "founder post clear count mismatch rejected"
fi

printf 'RESULT pass=%d fail=%d\n' "$pass_count" "$fail_count"
exit "$fail_count"
