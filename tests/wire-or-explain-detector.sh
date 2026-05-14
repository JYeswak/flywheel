#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="$ROOT/.flywheel/scripts/wire-or-explain-detector.py"
FIXTURES="$ROOT/tests/fixtures/wire-or-explain-detector"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/wire-or-explain-detector.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" || true
  fi
}

bash -n "$0" && pass "test_syntax"
python3 -m py_compile "$BIN" && pass "detector_python_syntax"
"$BIN" --help >/dev/null && pass "help_exits"
"$BIN" --info | jq -e '.surface == "The Zest Pour"' >/dev/null && pass "info_surface"
"$BIN" --examples | jq -e '(.examples | length) >= 2' >/dev/null && pass "examples_surface"
"$BIN" schema | jq -e '.schema_version == "wire-or-explain-detector/schema/v1"' >/dev/null && pass "schema_surface"
"$BIN" quickstart | jq -e '.surface == "The Zest Pour"' >/dev/null && pass "quickstart_surface"
"$BIN" help detector | jq -e '.topic == "detector"' >/dev/null && pass "help_topic"
"$BIN" completion bash >"$TMP/completion.bash"
rg -q 'wire-or-explain-detector.py' "$TMP/completion.bash" && pass "completion_bash"

"$BIN" detect \
  --ledger "$FIXTURES/ledger.jsonl" \
  --relay-ledger "$FIXTURES/{capability-control-plane}-relay-ledger.jsonl" \
  --send-receipts "$FIXTURES/send-receipts.jsonl" \
  --schema-file "$TMP/missing.schema.json" \
  --now "2026-05-05T00:00:00Z" \
  --execute-probes \
  --json >"$TMP/detect.json"

assert_jq "$TMP/detect.json" '.schema_version == "wire-or-explain-detector/v1" and .surface == "The Zest Pour"' "detect_schema_surface"
assert_jq "$TMP/detect.json" '.summary.total == 9 and .summary.wired == 2 and .summary.deferred == 1 and .summary.unwired == 3 and .summary.questionably_wired == 1 and .summary.not_required == 1 and .summary.bypassed == 1' "all_state_counts"
assert_jq "$TMP/detect.json" '.rows[] | select(.row_id == "evt-wired-script" and .wire_state == "wired" and .reason_code == "runnable_consumer_probe_passed")' "wired_requires_runnable_probe"
assert_jq "$TMP/detect.json" '.rows[] | select(.row_id == "evt-readme-only" and .wire_state == "questionably_wired" and .reason_code == "readme_or_doctrine_only_reference")' "readme_only_questionable"
assert_jq "$TMP/detect.json" '.rows[] | select(.row_id == "evt-deferred-future" and .wire_state == "deferred" and .deferral_owner == "flywheel:1")' "future_deferral"
assert_jq "$TMP/detect.json" '.rows[] | select(.row_id == "evt-deferred-expired" and .wire_state == "unwired" and .reason_code == "deferral_overdue" and .overdue.overdue_days >= 30)' "expired_deferral_unwired"
assert_jq "$TMP/detect.json" '.rows[] | select(.row_id == "evt-not-required" and .wire_state == "not_required")' "not_required_state"
assert_jq "$TMP/detect.json" '.rows[] | select(.row_id == "evt-bypassed" and .wire_state == "bypassed")' "bypassed_state"
assert_jq "$TMP/detect.json" '.rows[] | select(.row_id == "evt-circular" and .wire_state == "unwired" and .reason_code == "circular_self_proof_refused" and .proof_refused == true)' "circular_self_proof_refused"
assert_jq "$TMP/detect.json" '.rows[] | select(.row_id == "evt-skill-relay" and .wire_state == "wired" and .consumer_id == "{capability-control-plane}-relay")' "skill_candidate_with_relay_wired"
assert_jq "$TMP/detect.json" '.rows[] | select(.row_id == "evt-skill-missing" and .wire_state == "unwired" and .reason_code == "skill_candidate_missing_relay" and .action_metadata.target_session == "{capability-control-plane}")' "skill_candidate_missing_relay_unwired"
assert_jq "$TMP/detect.json" 'all(.rows[]; (.consumer_id | test("\\.md:[0-9]+$") | not))' "stable_consumer_ids_not_path_line"
assert_jq "$TMP/detect.json" '.ranker_input.unresolved | length == 4' "feeds_ranker_unresolved"
assert_jq "$TMP/detect.json" '.doctor_actions | length == 4' "feeds_doctor_actions"
assert_jq "$TMP/detect.json" '.schema_validation_status == "deferred_missing_schema"' "schema_validation_deferred_when_b1_missing"

LIVE_SCHEMA="$ROOT/.flywheel/validation-schema/v1/wire-or-explain-ledger.schema.json"
if [[ -f "$LIVE_SCHEMA" ]]; then
  "$BIN" detect \
    --ledger "$FIXTURES/ledger.jsonl" \
    --relay-ledger "$FIXTURES/{capability-control-plane}-relay-ledger.jsonl" \
    --send-receipts "$FIXTURES/send-receipts.jsonl" \
    --schema-file "$LIVE_SCHEMA" \
    --now "2026-05-05T00:00:00Z" \
    --execute-probes \
    --json >"$TMP/live-detect.json"
  assert_jq "$TMP/live-detect.json" '.schema_validation.status == "passed" and .schema_validation.validated_row_count == 9 and (.ledger_rows | length) == 9' "output_validates_against_live_b1_schema"
  jq -c '.ledger_rows[]' "$TMP/live-detect.json" >"$TMP/live-ledger-rows.jsonl"
  python3 -c 'import json, sys, jsonschema; schema=json.load(open(sys.argv[1])); validator=jsonschema.Draft202012Validator(schema); rows=[json.loads(line) for line in open(sys.argv[2]) if line.strip()]; [validator.validate(row) for row in rows]; print(len(rows))' "$LIVE_SCHEMA" "$TMP/live-ledger-rows.jsonl" >"$TMP/live-schema-row-count"
  if [[ "$(cat "$TMP/live-schema-row-count")" == "9" ]]; then pass "each_detector_ledger_row_validates_against_b1_schema"; else fail "each_detector_ledger_row_validates_against_b1_schema"; fi
else
  pass "live_b1_schema_deferred_pending"
fi

"$BIN" why evt-skill-missing \
  --ledger "$FIXTURES/ledger.jsonl" \
  --relay-ledger "$FIXTURES/{capability-control-plane}-relay-ledger.jsonl" \
  --send-receipts "$FIXTURES/send-receipts.jsonl" \
  --now "2026-05-05T00:00:00Z" \
  --execute-probes \
  --json >"$TMP/why.json"
assert_jq "$TMP/why.json" '.found == true and .row.reason_code == "skill_candidate_missing_relay"' "why_row"

"$BIN" health \
  --ledger "$FIXTURES/ledger.jsonl" \
  --relay-ledger "$FIXTURES/{capability-control-plane}-relay-ledger.jsonl" \
  --send-receipts "$FIXTURES/send-receipts.jsonl" \
  --now "2026-05-05T00:00:00Z" \
  --execute-probes \
  --json >"$TMP/health.json"
assert_jq "$TMP/health.json" '.command == "health" and .status == "degraded"' "health_surface"

printf 'Summary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
