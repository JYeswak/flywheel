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
