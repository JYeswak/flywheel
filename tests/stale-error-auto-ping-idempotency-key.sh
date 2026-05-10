#!/usr/bin/env bash
# Regression test for flywheel-1o9fa: --idempotency-key gate + per-pane replay-check
# on stale-error-auto-ping.sh. Second 7axmt-followup; reuses sister 8sx9w pair-pattern.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/stale-error-auto-ping.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/stale-error-idem.XXXXXX")"
trap 'find "$TMP" -type f -delete 2>/dev/null; rmdir "$TMP" 2>/dev/null || true' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Isolated audit log per test (don't contaminate real state).
export STALE_ERROR_AUDIT_LOG="$TMP/audit.jsonl"

# Synthetic agents fixture: 3 panes (2, 3, 4) all reporting codex_chevron_prompt + failed pattern.
# Uses .agents[] shape (mapped by candidates_filter); .errors[] is raw passthrough and not exercised here.
cat >"$TMP/errors.json" <<'JSON'
{"agents":[
  {"pane_idx":2,"agent_type":"codex","detected_patterns":["codex_chevron_prompt","failed_text"],"capture_provenance":"live","state":"ERROR","capture_collected_at":"2026-05-10T22:00:00Z"},
  {"pane_idx":3,"agent_type":"codex","detected_patterns":["codex_chevron_prompt","api_error"],"capture_provenance":"live","state":"ERROR","capture_collected_at":"2026-05-10T22:00:01Z"},
  {"pane_idx":4,"agent_type":"codex","detected_patterns":["codex_chevron_prompt","failed_text"],"capture_provenance":"live","state":"ERROR","capture_collected_at":"2026-05-10T22:00:02Z"}
]}
JSON

# Test 1: --apply without --idempotency-key returns rc=3 + refusal envelope
set +e
"$SCRIPT" --apply --errors-file "$TMP/errors.json" --json >"$TMP/refused.json" 2>&1
rc=$?
set -e
if [[ "$rc" -eq 3 ]]; then pass "AG1.rc: --apply without --idempotency-key exits 3"
else fail "AG1.rc: expected rc=3, got $rc"; fi
if jq -e '.status == "refused" and (.reason | test("idempotency-key"))' "$TMP/refused.json" >/dev/null 2>&1; then
  pass "AG1.envelope: refusal shape correct"
else fail "AG1.envelope: refusal envelope malformed"; fi

# Test 2: --idempotency-key without value → rc=2
set +e
"$SCRIPT" --apply --idempotency-key 2>"$TMP/no-value.err"
rc=$?
set -e
if [[ "$rc" -eq 2 ]]; then pass "AG2: --idempotency-key without value exits 2"
else fail "AG2: expected rc=2, got $rc"; fi

# Test 3: --idempotency-key=VALUE equals form parses
"$SCRIPT" --idempotency-key=ag3-test-key --info --json >"$TMP/info.json" 2>&1
if jq -e '.mode == "info"' "$TMP/info.json" >/dev/null 2>&1; then
  pass "AG3: --idempotency-key=VALUE equals form parses"
else fail "AG3: equals form not parsed"; fi

# Test 4: dry-run with NO idempotency-key works (no gate fires for non-apply)
"$SCRIPT" --errors-file "$TMP/errors.json" --json >"$TMP/dry.json" 2>&1
if jq -e '.dry_run == true and .stale_error_candidate_count == 3' "$TMP/dry.json" >/dev/null 2>&1; then
  pass "AG4: dry-run still works without key (3 candidates from fixture)"
else fail "AG4: dry-run broken or candidate count wrong"; fi

# Test 5: --info documents --idempotency-key + audit_log + apply_requires
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.apply_requires == "--idempotency-key" and .audit_log and (.flags | contains(["--idempotency-key"]))' >/dev/null 2>&1; then
  pass "AG5: --info documents --idempotency-key + audit_log + flags"
else fail "AG5: --info missing fields"; fi

# Test 6: --help documents --idempotency-key + rc=3
if "$SCRIPT" --help 2>&1 | grep -q -- '--idempotency-key' && "$SCRIPT" --help 2>&1 | grep -q 'rc=3'; then
  pass "AG6: --help documents --idempotency-key + rc=3"
else fail "AG6: --help missing docs"; fi

# Test 7: receipt envelope carries idempotency_key + replay fields (dry-run with key)
"$SCRIPT" --errors-file "$TMP/errors.json" --idempotency-key=ag7-key --json >"$TMP/dry-with-key.json" 2>&1
if jq -e '.idempotency_key == "ag7-key" and (.replay_skipped_panes | type == "array") and (.replay_skipped_count | type == "number") and (.eligible_candidate_count | type == "number")' "$TMP/dry-with-key.json" >/dev/null 2>&1; then
  pass "AG7: receipt carries idempotency_key + replay_skipped_panes + eligible_candidate_count"
else fail "AG7: receipt missing pair-pattern fields"; fi

# Test 8: planned_actions == eligible (since audit log is empty, no panes skipped yet)
if jq -e '(.planned_actions | length) == 3 and (.replay_skipped_count == 0)' "$TMP/dry-with-key.json" >/dev/null 2>&1; then
  pass "AG8: empty audit log → 0 skipped, 3 planned"
else fail "AG8: planned_actions/skip count wrong"; fi

# Test 9: SEED the audit log with a prior ping for pane 2 + same key, verify replay skips pane 2
cat >"$STALE_ERROR_AUDIT_LOG" <<JSON
{"schema_version":"stale-error-auto-ping.v1","ts":"2026-05-10T21:00:00Z","action":"ntm_send_ping","idempotency_key":"ag9-replay-key","session":"flywheel","pane":2,"ping_text":"prior"}
JSON
"$SCRIPT" --errors-file "$TMP/errors.json" --idempotency-key=ag9-replay-key --json >"$TMP/replay.json" 2>&1
if jq -e '.replay_skipped_panes == [2] and .replay_skipped_count == 1 and (.eligible_candidate_count == 2)' "$TMP/replay.json" >/dev/null 2>&1; then
  pass "AG9: prior ping in audit log → pane 2 skipped, 2 eligible"
else fail "AG9: replay-check did not filter pane 2"; fi

# Test 10: planned_actions should NOT include the skipped pane
if jq -e '[.planned_actions[].pane] | (contains([2]) | not) and . == [3,4]' "$TMP/replay.json" >/dev/null 2>&1; then
  pass "AG10: planned_actions excludes replay-skipped pane 2"
else fail "AG10: planned_actions still includes skipped pane"; fi

# Test 11: different key does NOT replay-skip (per-pane replay scoped to key)
cat >"$STALE_ERROR_AUDIT_LOG" <<JSON
{"schema_version":"stale-error-auto-ping.v1","ts":"2026-05-10T21:00:00Z","action":"ntm_send_ping","idempotency_key":"different-key","session":"flywheel","pane":2,"ping_text":"prior"}
JSON
"$SCRIPT" --errors-file "$TMP/errors.json" --idempotency-key=ag11-fresh-key --json >"$TMP/fresh.json" 2>&1
if jq -e '.replay_skipped_count == 0 and .eligible_candidate_count == 3' "$TMP/fresh.json" >/dev/null 2>&1; then
  pass "AG11: different key does not replay-skip"
else fail "AG11: replay-check incorrectly filtered cross-key"; fi

# Test 12: tolerant-parse — corrupt row in audit log doesn't break replay
cat >"$STALE_ERROR_AUDIT_LOG" <<JSON
{"schema_version":"stale-error-auto-ping.v1","ts":"2026-05-10T21:00:00Z","action":"ntm_send_ping","idempotency_key":"ag12-corrupt-survive","session":"flywheel","pane":3,"ping_text":"prior"}
{this is not valid json but should not break the replay-check}
{"schema_version":"stale-error-auto-ping.v1","ts":"2026-05-10T21:00:01Z","action":"ntm_send_ping","idempotency_key":"ag12-corrupt-survive","session":"flywheel","pane":4,"ping_text":"prior"}
JSON
"$SCRIPT" --errors-file "$TMP/errors.json" --idempotency-key=ag12-corrupt-survive --json >"$TMP/tolerant.json" 2>&1
if jq -e '.replay_skipped_count == 2 and (.replay_skipped_panes | sort) == [3,4]' "$TMP/tolerant.json" >/dev/null 2>&1; then
  pass "AG12: tolerant-parse skips corrupt rows, finds 2 valid replay rows"
else fail "AG12: tolerant-parse broke or wrong panes filtered"; fi

# Test 13: when all candidates are replay-skipped, status is "all_replay_skipped"
cat >"$STALE_ERROR_AUDIT_LOG" <<JSON
{"schema_version":"stale-error-auto-ping.v1","ts":"2026-05-10T21:00:00Z","action":"ntm_send_ping","idempotency_key":"ag13-all-skipped","session":"flywheel","pane":2,"ping_text":"prior"}
{"schema_version":"stale-error-auto-ping.v1","ts":"2026-05-10T21:00:01Z","action":"ntm_send_ping","idempotency_key":"ag13-all-skipped","session":"flywheel","pane":3,"ping_text":"prior"}
{"schema_version":"stale-error-auto-ping.v1","ts":"2026-05-10T21:00:02Z","action":"ntm_send_ping","idempotency_key":"ag13-all-skipped","session":"flywheel","pane":4,"ping_text":"prior"}
JSON
"$SCRIPT" --errors-file "$TMP/errors.json" --idempotency-key=ag13-all-skipped --json >"$TMP/all-skipped.json" 2>&1
if jq -e '.status == "all_replay_skipped" and .replay_skipped_count == 3 and .eligible_candidate_count == 0' "$TMP/all-skipped.json" >/dev/null 2>&1; then
  pass "AG13: all-replay-skipped status when every pane was pinged"
else fail "AG13: all-skipped status not set or counts wrong"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
