#!/usr/bin/env bash
# Regression test for flywheel-y0ft6: --idempotency-key gate + per-(key, target_beads_sha)
# whole-run replay on bcv-task-harness.sh. Sixth 7axmt-followup.
# Reuses sister j0xpa's per-target-set variant — scope = sha256 of sorted TARGET_BEADS.
#
# The harness requires real Beads + br + python3 + skill scripts to run all phases.
# Tests focus on: gate behavior, --info/--help/--examples docs, dry-run path,
# and replay-check semantics (audit-log seeded directly, surface refuses --apply
# without key and replays when (key, target_beads_sha) matches).

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/bcv-task-harness.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/bcv-idem.XXXXXX")"
trap 'find "$TMP" -type f -delete 2>/dev/null; find "$TMP" -type d -depth -empty -delete 2>/dev/null; true' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

export BCV_TASK_HARNESS_AUDIT_LOG="$TMP/audit.jsonl"
REPO="$TMP/repo"
mkdir -p "$REPO/.beads"  # surface requires .beads/ subdir

# Test 1: --apply without --idempotency-key returns rc=3 + refusal envelope
set +e
"$SCRIPT" --repo "$REPO" --beads bd-test1,bd-test2 --apply --json >"$TMP/refused.json" 2>&1
rc=$?
set +e
if [[ "$rc" -eq 3 ]]; then pass "AG1.rc: --apply without --idempotency-key exits 3"
else fail "AG1.rc: expected rc=3, got $rc"; fi
if jq -e '.tool == "bcv-task-harness.sh" and .status == "refused" and (.reason | test("idempotency-key"))' "$TMP/refused.json" >/dev/null 2>&1; then
  pass "AG1.envelope: refusal envelope shape correct"
else fail "AG1.envelope: refusal envelope malformed"; fi

# Test 2: --idempotency-key without value → rc=2
set +e
"$SCRIPT" --apply --idempotency-key 2>/dev/null
rc=$?
set +e
if [[ "$rc" -eq 2 ]]; then pass "AG2: --idempotency-key without value exits 2"
else fail "AG2: expected rc=2, got $rc"; fi

# Test 3: --idempotency-key=VALUE equals form parses (still rejects without --apply→never refused gate)
set +e
"$SCRIPT" --repo "$REPO" --beads bd-test1 --idempotency-key=ag3-key --json >"$TMP/dry-key.json" 2>&1
rc=$?
set +e
# Default mode is dry-run; without --apply, surface emits dry_run receipt (success)
if [[ "$rc" -eq 0 ]] && jq -e '.status == "dry_run"' "$TMP/dry-key.json" >/dev/null 2>&1; then
  pass "AG3: --idempotency-key=VALUE equals form parses + dry-run still works without --apply"
else fail "AG3: equals form or dry-run broken (rc=$rc)"; fi

# Test 4: --info documents apply_requires + audit_log + exit 3
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.apply_requires == "--idempotency-key" and .audit_log and (.exit_codes | has("3"))' >/dev/null 2>&1; then
  pass "AG4: --info documents apply_requires + audit_log + exit 3"
else fail "AG4: --info missing fields"; fi

# Test 5: --help documents --idempotency-key + rc=3
if "$SCRIPT" --help 2>&1 | grep -q -- '--idempotency-key' && "$SCRIPT" --help 2>&1 | grep -qE '^  3  '; then
  pass "AG5: --help documents --idempotency-key + exit code 3"
else fail "AG5: --help missing docs"; fi

# Test 6: --examples shows --idempotency-key example
if "$SCRIPT" --examples 2>&1 | grep -q -- '--idempotency-key'; then
  pass "AG6: --examples shows --idempotency-key usage"
else fail "AG6: --examples missing idempotency-key example"; fi

# Test 7: replay no-op semantics — seed audit log directly to verify the surface
# detects a prior matching row and emits replay status before running phases.
# Need to compute the same target_beads_sha the surface would compute.
TARGET_BEADS_SHA="$(printf '%s\n' bd-test1 bd-test2 | sort | shasum -a 256 | awk '{print $1}')"
# Seed audit log: a "complete" row matching (key=ag7-key, target_beads_sha=...).
cat >"$BCV_TASK_HARNESS_AUDIT_LOG" <<JSON
{"tool":"bcv-task-harness.sh","version":"bcv-task-harness/v1","ts":"2026-05-10T20:00:00Z","status":"complete","repo":"$REPO","idempotency_key":"ag7-key","target_beads_sha":"$TARGET_BEADS_SHA","target_beads":["bd-test1","bd-test2"],"validation_passed":true,"deterministic_banner_present":false,"report_path":"$TMP/seeded-report.md"}
JSON
# Now invoke --apply with the same key + same target beads → should replay (no phases run).
set +e
"$SCRIPT" --repo "$REPO" --beads bd-test1,bd-test2 --apply --idempotency-key=ag7-key --json >"$TMP/ag7.json" 2>&1
rc=$?
set +e
if [[ "$rc" -eq 0 ]] && jq -e '.status == "replay" and .replay == true and .replay_for_idempotency_key == "ag7-key"' "$TMP/ag7.json" >/dev/null 2>&1; then
  pass "AG7: replay-check fires for (key, target_beads_sha) match, status=replay, exit 0"
else fail "AG7: replay-check failed (rc=$rc)"; fi

# Test 8: same key, DIFFERENT bead set → different target_beads_sha → does NOT replay
# (and we don't have a real skill dir, so it'll fail substrate checks early — but
# importantly it should NOT replay)
set +e
"$SCRIPT" --repo "$REPO" --beads bd-different --apply --idempotency-key=ag7-key --json >"$TMP/ag8.json" 2>&1
rc=$?
set +e
# Surface fails at substrate check (no skill dir, no real beads). What matters: NOT replay.
if ! jq -e '.status == "replay"' "$TMP/ag8.json" >/dev/null 2>&1; then
  pass "AG8: different bead set (different sha) → does NOT replay (substrate check fires)"
else fail "AG8: per-target-set scope broken — replayed cross-set"; fi

# Test 9: tolerant-parse — corrupt audit-log row doesn't break replay
cat >"$BCV_TASK_HARNESS_AUDIT_LOG" <<JSON
{not valid json should be tolerated}
{"tool":"bcv-task-harness.sh","version":"bcv-task-harness/v1","ts":"2026-05-10T20:00:00Z","status":"complete","repo":"$REPO","idempotency_key":"ag9-key","target_beads_sha":"$TARGET_BEADS_SHA","target_beads":["bd-test1","bd-test2"],"validation_passed":true,"deterministic_banner_present":false,"report_path":"$TMP/seeded.md"}
JSON
set +e
"$SCRIPT" --repo "$REPO" --beads bd-test1,bd-test2 --apply --idempotency-key=ag9-key --json >"$TMP/ag9.json" 2>&1
rc=$?
set +e
if [[ "$rc" -eq 0 ]] && jq -e '.status == "replay" and .replay == true' "$TMP/ag9.json" >/dev/null 2>&1; then
  pass "AG9: tolerant-parse survives corrupt audit row, replay still fires"
else fail "AG9: tolerant-parse broke (rc=$rc)"; fi

# Test 10: schema emits expected shape (existing behavior preserved)
if "$SCRIPT" --schema 2>&1 | jq -e '.tool == "bcv-task-harness.sh"' >/dev/null 2>&1; then
  pass "AG10: --schema still emits valid envelope (existing behavior preserved)"
else fail "AG10: --schema broken"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
