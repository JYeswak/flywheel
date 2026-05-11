#!/usr/bin/env bash
# Regression test for flywheel-wdh08: --idempotency-key gate + per-(key, bead_id)
# replay on jeff-bead-285-divergence-capture.sh. Seventh and final 7axmt-followup.
# Reuses sister j0xpa's per-target-scope variant with scope=bead_id.
#
# The surface invokes `br close <bead-id>` against a real beads workspace.
# Tests focus on: gate behavior, --info/--help/--examples docs, dry-run path,
# replay-check semantics (audit-log seeded directly so no real br calls needed).

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/jeff-bead-285-divergence-capture.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/jeff-285-idem.XXXXXX")"
trap 'find "$TMP" -type f -delete 2>/dev/null; find "$TMP" -type d -depth -empty -delete 2>/dev/null; true' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

export JEFF_285_AUDIT_LOG="$TMP/audit.jsonl"

# Test 1: --apply without --idempotency-key returns rc=3 + refusal envelope
set +e
"$SCRIPT" sandbox-test-1 --apply --json >"$TMP/refused.json" 2>&1
rc=$?
set +e
if [[ "$rc" -eq 3 ]]; then pass "AG1.rc: --apply without --idempotency-key exits 3"
else fail "AG1.rc: expected rc=3, got $rc"; fi
if jq -e '.status == "refused" and (.reason | test("idempotency-key")) and .bead_id == "sandbox-test-1"' "$TMP/refused.json" >/dev/null 2>&1; then
  pass "AG1.envelope: refusal envelope shape + bead_id field"
else fail "AG1.envelope: refusal envelope malformed"; fi

# Test 2: --idempotency-key without value → rc=2
set +e
"$SCRIPT" sandbox-test-2 --apply --idempotency-key 2>/dev/null
rc=$?
set +e
if [[ "$rc" -eq 2 ]]; then pass "AG2: --idempotency-key without value exits 2"
else fail "AG2: expected rc=2, got $rc"; fi

# Test 3: --idempotency-key=VALUE equals form parses (dry-run path so no br needed)
"$SCRIPT" sandbox-test-3 --dry-run --idempotency-key=ag3-key --json >"$TMP/dry.json" 2>&1
if jq -e '.mode == "dry-run" and .bead_id == "sandbox-test-3"' "$TMP/dry.json" >/dev/null 2>&1; then
  pass "AG3: --idempotency-key=VALUE equals form + dry-run still works"
else fail "AG3: equals form or dry-run broken"; fi

# Test 4: --info documents apply_requires + audit_log + --idempotency-key in flags
if "$SCRIPT" --info 2>/dev/null | jq -e '.apply_requires == "--idempotency-key" and .audit_log and (.flags | contains(["--idempotency-key"]))' >/dev/null 2>&1; then
  pass "AG4: --info documents apply_requires + audit_log + --idempotency-key flag"
else fail "AG4: --info missing fields"; fi

# Test 5: --help shows --idempotency-key
if "$SCRIPT" --help 2>&1 | grep -q -- '--idempotency-key'; then
  pass "AG5: --help shows --idempotency-key"
else fail "AG5: --help missing --idempotency-key"; fi

# Test 6: --examples shows --idempotency-key usage
if "$SCRIPT" --examples 2>&1 | grep -q -- '--idempotency-key'; then
  pass "AG6: --examples shows --idempotency-key usage"
else fail "AG6: --examples missing --idempotency-key example"; fi

# Test 7: replay-check fires for (key, bead_id) match — seed audit log directly.
BEAD_FIXTURE="sandbox-ag7-bead"
cat >"$JEFF_285_AUDIT_LOG" <<JSON
{"schema_version":"jeff-bead-285-capture-receipt/v1","ts":"2026-05-10T20:00:00Z","status":"captured","bead_id":"$BEAD_FIXTURE","idempotency_key":"ag7-key","capture_dir":"$TMP/seeded-capture","manifest":"$TMP/seeded-manifest.json","close_exit_code":0,"pre_status":"healthy","post_status":"healthy","divergence_observed":false}
JSON
set +e
"$SCRIPT" "$BEAD_FIXTURE" --apply --idempotency-key=ag7-key --json >"$TMP/ag7.json" 2>&1
rc=$?
set +e
if [[ "$rc" -eq 0 ]] && jq -e '.status == "replay" and .replay == true and .replay_for_idempotency_key == "ag7-key" and .bead_id == "sandbox-ag7-bead"' "$TMP/ag7.json" >/dev/null 2>&1; then
  pass "AG7: replay-check fires for (key, bead_id) match, status=replay, exit 0"
else fail "AG7: replay-check failed (rc=$rc)"; fi

# Test 8: same key, DIFFERENT bead_id → does NOT replay (per-target scope)
# (will attempt to run, fail at br/capture stage with non-zero, but the receipt
# should NOT be replay-shape)
set +e
"$SCRIPT" different-bead-id --apply --idempotency-key=ag7-key --json >"$TMP/ag8.json" 2>&1
rc=$?
set +e
if ! jq -e '.status == "replay"' "$TMP/ag8.json" >/dev/null 2>&1; then
  pass "AG8: different bead_id under same key does NOT replay (per-target scope)"
else fail "AG8: per-target scope broken — replayed cross-bead"; fi

# Test 9: tolerant-parse — corrupt audit row doesn't break replay
cat >"$JEFF_285_AUDIT_LOG" <<JSON
{not valid json}
{"schema_version":"jeff-bead-285-capture-receipt/v1","ts":"2026-05-10T20:00:00Z","status":"captured","bead_id":"$BEAD_FIXTURE","idempotency_key":"ag9-key","capture_dir":"$TMP/c","manifest":"$TMP/m.json","close_exit_code":0,"pre_status":"healthy","post_status":"healthy","divergence_observed":false}
JSON
set +e
"$SCRIPT" "$BEAD_FIXTURE" --apply --idempotency-key=ag9-key --json >"$TMP/ag9.json" 2>&1
rc=$?
set +e
if [[ "$rc" -eq 0 ]] && jq -e '.status == "replay" and .replay == true' "$TMP/ag9.json" >/dev/null 2>&1; then
  pass "AG9: tolerant-parse survives corrupt audit row, replay still fires"
else fail "AG9: tolerant-parse broke (rc=$rc)"; fi

# Test 10: --schema still emits valid envelope (existing behavior preserved)
if "$SCRIPT" --schema 2>&1 | jq -e '.schema_version' >/dev/null 2>&1; then
  pass "AG10: --schema still emits valid envelope (existing behavior preserved)"
else fail "AG10: --schema broken"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
