#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/holding-company-anti-pitch-voice-validate.py"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/holding-company-anti-pitch-voice.schema.json"
LEDGER="$ROOT/state/holding-company-anti-pitch-voice.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/holding-company-anti-pitch.XXXXXX")"
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
assert_jq "$TMP/current.json" '.status == "pass" and .clear_count == 1 and .surfaces[0].voice_gate_status == "clear" and .surfaces[0].builder_framing_hit_count == 0' "current surface validates as voice clear"

jq '.clear_count = 1 | .surfaces[0].status = "clear" | .surfaces[0].holding_company_story_present = true | .surfaces[0].builder_framing_hits = []' "$LEDGER" >"$TMP/clear.json"
"$SCRIPT" --ledger "$TMP/clear.json" --json >"$TMP/clear.out.json"
assert_jq "$TMP/clear.out.json" '.status == "pass" and .clear_count == 1 and .surfaces[0].voice_gate_status == "clear"' "clear surface with holding-company story and no builder hits passes"

jq '
  .surfaces[0].status = "clear"
  | .surfaces[0].holding_company_story_present = true
  | .surfaces[0].builder_framing_hits = [{
      "frame": "workflow_builder",
      "path": "/tmp/synthetic-public-copy.txt",
      "line": 1,
      "excerpt": "workflow builder"
    }]
' "$LEDGER" >"$TMP/clear-with-hits.json"
if "$SCRIPT" --ledger "$TMP/clear-with-hits.json" --json >"$TMP/clear-with-hits.out.json" 2>/dev/null; then
  fail "clear status with builder hits rejected"
else
  assert_jq "$TMP/clear-with-hits.out.json" '.status == "fail" and (.failures[] | select(.code == "clear_status_with_builder_framing_hits"))' "clear status with builder hits rejected"
fi

jq '
  .surfaces[0].status = "clear"
  | .surfaces[0].holding_company_story_present = false
  | .surfaces[0].builder_framing_hits = []
' "$LEDGER" >"$TMP/clear-no-story.json"
if "$SCRIPT" --ledger "$TMP/clear-no-story.json" --json >"$TMP/clear-no-story.out.json" 2>/dev/null; then
  fail "clear status without holding-company story rejected"
else
  assert_jq "$TMP/clear-no-story.out.json" '.status == "fail" and (.failures[] | select(.code == "clear_status_without_holding_company_story"))' "clear status without holding-company story rejected"
fi

jq '.clear_count = 2 | .surfaces[0].status = "clear" | .surfaces[0].holding_company_story_present = true | .surfaces[0].builder_framing_hits = []' "$LEDGER" >"$TMP/count-mismatch.json"
if "$SCRIPT" --ledger "$TMP/count-mismatch.json" --json >"$TMP/count-mismatch.out.json" 2>/dev/null; then
  fail "voice clear count mismatch rejected"
else
  assert_jq "$TMP/count-mismatch.out.json" '.status == "fail" and (.failures[] | select(.code == "clear_count_mismatch"))' "voice clear count mismatch rejected"
fi

printf 'RESULT pass=%d fail=%d\n' "$pass_count" "$fail_count"
exit "$fail_count"
