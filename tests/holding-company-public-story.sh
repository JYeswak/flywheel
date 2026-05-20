#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/holding-company-public-story-validate.py"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/holding-company-public-story.schema.json"
LEDGER="$ROOT/state/holding-company-public-story.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/holding-company-public-story.XXXXXX")"
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
assert_jq "$TMP/current.json" '.status == "pass" and .clear_count == 1 and .surfaces[0].public_story_gate_status == "clear" and .surfaces[0].build_app_framing_hit_count == 0' "current ledger validates as public story clear"

jq 'del(.gate)' "$LEDGER" >"$TMP/schema-invalid.json"
if "$SCRIPT" --ledger "$TMP/schema-invalid.json" --json >"$TMP/schema-invalid.out.json" 2>/dev/null; then
  fail "schema-invalid public story ledger rejected"
else
  assert_jq "$TMP/schema-invalid.out.json" '.failures[] | select(.code == "schema_invalid")' "schema-invalid public story ledger rejected"
fi

jq '
  .clear_count = 1
  | .surfaces[0].status = "clear"
  | .surfaces[0].receipt_story_present = true
  | .surfaces[0].holding_company_positioning_present = true
  | .surfaces[0].proof_or_receipt_refs = ["urn:proof:portfolio-receipt-rail"]
  | .surfaces[0].build_app_framing_hits = []
' "$LEDGER" >"$TMP/clear.json"
"$SCRIPT" --ledger "$TMP/clear.json" --json >"$TMP/clear.out.json"
assert_jq "$TMP/clear.out.json" '.status == "pass" and .clear_count == 1 and .surfaces[0].public_story_gate_status == "clear"' "receipt-led public story clears"

jq '.surfaces[0].notes = ("sk-" + "NOTAREALSECRET")' "$TMP/clear.json" >"$TMP/secret-shaped-value.json"
if "$SCRIPT" --ledger "$TMP/secret-shaped-value.json" --json >"$TMP/secret-shaped-value.out.json" 2>/dev/null; then
  fail "secret-shaped public story value rejected"
else
  assert_jq "$TMP/secret-shaped-value.out.json" '.failures[] | select(.code == "secret_or_raw_value_shape_detected")' "secret-shaped public story value rejected"
fi

jq '
  .clear_count = 1
  | .next_action = "Rewrite public ZestStream surfaces around receipt/proof evidence before marking public-story clear."
  | .surfaces[0].status = "clear"
  | .surfaces[0].receipt_story_present = true
  | .surfaces[0].holding_company_positioning_present = true
  | .surfaces[0].proof_or_receipt_refs = ["urn:proof:portfolio-receipt-rail"]
  | .surfaces[0].build_app_framing_hits = []
' "$LEDGER" >"$TMP/stale-next-action.json"
if "$SCRIPT" --ledger "$TMP/stale-next-action.json" --json >"$TMP/stale-next-action.out.json" 2>/dev/null; then
  fail "clear with stale pre-clear next_action rejected"
else
  assert_jq "$TMP/stale-next-action.out.json" '.failures[] | select(.code == "stale_clear_next_action")' "clear with stale pre-clear next_action rejected"
fi

jq '
  .surfaces[0].status = "clear"
  | .surfaces[0].receipt_story_present = false
  | .surfaces[0].holding_company_positioning_present = true
  | .surfaces[0].proof_or_receipt_refs = ["urn:proof:x"]
  | .surfaces[0].build_app_framing_hits = []
' "$LEDGER" >"$TMP/no-receipt-story.json"
if "$SCRIPT" --ledger "$TMP/no-receipt-story.json" --json >"$TMP/no-receipt-story.out.json" 2>/dev/null; then
  fail "clear without receipt story rejected"
else
  assert_jq "$TMP/no-receipt-story.out.json" '.failures[] | select(.code == "public_story_clear_without_receipt_story")' "clear without receipt story rejected"
fi

jq '
  .surfaces[0].status = "clear"
  | .surfaces[0].receipt_story_present = true
  | .surfaces[0].holding_company_positioning_present = false
  | .surfaces[0].proof_or_receipt_refs = ["urn:proof:x"]
  | .surfaces[0].build_app_framing_hits = []
' "$LEDGER" >"$TMP/no-holding-positioning.json"
if "$SCRIPT" --ledger "$TMP/no-holding-positioning.json" --json >"$TMP/no-holding-positioning.out.json" 2>/dev/null; then
  fail "clear without holding-company positioning rejected"
else
  assert_jq "$TMP/no-holding-positioning.out.json" '.failures[] | select(.code == "public_story_clear_without_holding_company_positioning")' "clear without holding-company positioning rejected"
fi

jq '
  .surfaces[0].status = "clear"
  | .surfaces[0].receipt_story_present = true
  | .surfaces[0].holding_company_positioning_present = true
  | .surfaces[0].proof_or_receipt_refs = []
  | .surfaces[0].build_app_framing_hits = []
' "$LEDGER" >"$TMP/no-receipts.json"
if "$SCRIPT" --ledger "$TMP/no-receipts.json" --json >"$TMP/no-receipts.out.json" 2>/dev/null; then
  fail "clear without receipt refs rejected"
else
  assert_jq "$TMP/no-receipts.out.json" '.failures[] | select(.code == "public_story_clear_missing_receipt_refs")' "clear without receipt refs rejected"
fi

jq '
  .surfaces[0].status = "clear"
  | .surfaces[0].receipt_story_present = true
  | .surfaces[0].holding_company_positioning_present = true
  | .surfaces[0].proof_or_receipt_refs = ["urn:proof:x"]
  | .surfaces[0].build_app_framing_hits = [{
      "frame": "workflow_builder",
      "path": "/tmp/synthetic-public-copy.txt",
      "line": 1,
      "excerpt": "workflow builder"
    }]
' "$LEDGER" >"$TMP/with-builder.json"
if "$SCRIPT" --ledger "$TMP/with-builder.json" --json >"$TMP/with-builder.out.json" 2>/dev/null; then
  fail "clear with build-app framing rejected"
else
  assert_jq "$TMP/with-builder.out.json" '.failures[] | select(.code == "public_story_clear_with_build_app_framing")' "clear with build-app framing rejected"
fi

jq '.surfaces[0].proof_or_receipt_refs = ["state/no-such-public-story-proof.json"]' "$TMP/clear.json" >"$TMP/missing-proof-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-proof-ref.json" --check-paths --json >"$TMP/missing-proof-ref.out.json" 2>/dev/null; then
  fail "missing public story proof ref rejected"
else
  assert_jq "$TMP/missing-proof-ref.out.json" '.failures[] | select(.code == "proof_or_receipt_ref_missing")' "missing public story proof ref rejected"
fi

jq '.surfaces[0].evidence_refs = ["state/no-such-public-story-evidence.json"]' "$TMP/clear.json" >"$TMP/missing-evidence-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-evidence-ref.json" --check-paths --json >"$TMP/missing-evidence-ref.out.json" 2>/dev/null; then
  fail "missing public story evidence ref rejected"
else
  assert_jq "$TMP/missing-evidence-ref.out.json" '.failures[] | select(.code == "evidence_ref_missing")' "missing public story evidence ref rejected"
fi

jq '.clear_count = 0' "$LEDGER" >"$TMP/bad-count.json"
if "$SCRIPT" --ledger "$TMP/bad-count.json" --json >"$TMP/bad-count.out.json" 2>/dev/null; then
  fail "public story clear count mismatch rejected"
else
  assert_jq "$TMP/bad-count.out.json" '.failures[] | select(.code == "clear_count_mismatch")' "public story clear count mismatch rejected"
fi

if [[ "$fail_count" -ne 0 ]]; then
  printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
