#!/usr/bin/env bash
# tests/blocker-discipline-tick-chain.sh
# Integration regression for the per-tick orchestration chain that ties
# together the 4 blocker-discipline primitives:
#   - flywheel_replay_verify (5m9gp)
#   - blocker-ac-tick-cadence (e4ulf)
#   - blocker-auto-close (nbgp6)
#   - blocker-fail-escalator (ukbej)
#
# Bead: flywheel-yy9qi.
# Acceptance: simulates each branch (PASS auto-close, FAIL below threshold,
# FAIL at threshold) + verifies counter-reset semantics + idempotency on
# re-runs.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
CHAIN="$ROOT/.flywheel/scripts/blocker-discipline-tick-chain.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

TMPDIR_TEST="$(mktemp -d -t blocker-discipline-tick-chain.XXXXXX)"
trap '[[ -n "${TMPDIR_TEST:-}" ]] && find "$TMPDIR_TEST" -mindepth 1 -delete 2>/dev/null; rmdir "$TMPDIR_TEST" 2>/dev/null' EXIT

# All tests use --skip-agent-mail (via env) so they don't depend on a live
# agent-mail server.
export BLOCKER_DISCIPLINE_SKIP_AGENT_MAIL=1

setup_blockers() {
  local d="$1"
  mkdir -p "$d"
  cat > "$d/pass.json" <<'EOF'
{"blocker_id":"chain-test-pass","acceptance_condition":"echo PASS","status":"open","last_verified_at":"2026-05-09T00:00:00Z"}
EOF
  cat > "$d/below.json" <<'EOF'
{"blocker_id":"chain-test-below","acceptance_condition":"false","status":"open","last_verified_at":"2026-05-09T00:00:00Z"}
EOF
  cat > "$d/at.json" <<'EOF'
{"blocker_id":"chain-test-at","acceptance_condition":"false","status":"open","last_verified_at":"2026-05-09T00:00:00Z","ac_check_interval_ticks":1}
EOF
}

# Test 1: bash -n
if bash -n "$CHAIN" 2>/dev/null; then pass "chain syntax"; else fail "chain syntax"; fi

# Test 2: --info envelope
out="$("$CHAIN" --info 2>/dev/null)"
if printf '%s' "$out" | jq -e '
  .schema_version == "blocker-discipline-tick-chain/v1"
  and (.stages | length) == 3
  and (.modes | length) == 4
  and .threshold_n == 4
  and (.primitives | keys | length) == 4
' >/dev/null; then
  pass "--info: 3 stages, 4 modes, 4 primitives, threshold_n=4"
else fail "--info: $(printf '%s' "$out" | jq -c .)"; fi

# Test 3: --schema has envelope def with stages + summary
if "$CHAIN" --schema 2>/dev/null | jq -e '."$defs".envelope.properties.stages and ."$defs".envelope.properties.summary' >/dev/null; then
  pass "--schema defines stages + summary"
else fail "--schema"; fi

# Test 4: doctor on missing blocker dir → warn (not fail; absent dir is degradeable)
out="$("$CHAIN" doctor --blockers-dir "$TMPDIR_TEST/no-such" --json 2>/dev/null)"
# blockers_dir absent → warn; total status still ok if all 4 bins present
if printf '%s' "$out" | jq -e '.checks | map(select(.check == "blockers_dir")) | .[0].status == "warn"' >/dev/null; then
  pass "doctor: missing blockers_dir → warn (not fail)"
else fail "doctor: $(printf '%s' "$out" | jq -c .)"; fi

# Test 5: validate finds all 4 primitives
if "$CHAIN" validate --json 2>/dev/null | jq -e '.status == "ok" and .pass == 4 and .fail == 0' >/dev/null; then
  pass "validate: 4/4 primitives functional"
else fail "validate"; fi

# Test 6: tick on EMPTY blockers dir → clean, no actions
out="$("$CHAIN" tick \
  --blockers-dir "$TMPDIR_TEST/empty" \
  --escalations-log "$TMPDIR_TEST/empty-elog.jsonl" \
  --counter-dir "$TMPDIR_TEST/empty-counters" \
  --apply --json 2>/dev/null)"
if printf '%s' "$out" | jq -e '
  .status == "clean"
  and .summary.auto_closed == 0
  and .summary.escalated == 0
  and .summary.stages_failed == 0
' >/dev/null; then
  pass "tick on empty blockers: clean, 0 actions, 0 stages failed"
else fail "empty: $(printf '%s' "$out" | jq -c '.summary')"; fi

# === MAIN END-TO-END TEST ===
# 3 blockers: pass / fail-below / fail-at-threshold (n=1 so first fail escalates)
SCAN_DIR="$TMPDIR_TEST/scan1"
ELOG1="$TMPDIR_TEST/elog1.jsonl"
CDIR1="$TMPDIR_TEST/counters1"
setup_blockers "$SCAN_DIR"

out="$("$CHAIN" tick \
  --blockers-dir "$SCAN_DIR" \
  --escalations-log "$ELOG1" \
  --counter-dir "$CDIR1" \
  --threshold-n 4 \
  --apply --json 2>/dev/null)"

# Test 7: status clean + auto_closed=1 + escalated=1
if printf '%s' "$out" | jq -e '
  .status == "clean"
  and .summary.auto_closed == 1
  and .summary.escalated == 1
  and .summary.stages_failed == 0
' >/dev/null; then
  pass "tick all-3: 1 auto_closed + 1 escalated + 0 stages_failed"
else fail "tick all-3: $(printf '%s' "$out" | jq -c .summary)"; fi

# Test 8: pass blocker file mutated to status=closed with evidence
if jq -e '.status == "closed" and .live_probe_evidence.event == "blocker_auto_closed"' "$SCAN_DIR/pass.json" >/dev/null; then
  pass "pass blocker: status=closed + embedded auto-close evidence"
else fail "pass blocker mutation"; fi

# Test 9: below blocker UNCHANGED (still open, no evidence)
if jq -e '.status == "open" and (.live_probe_evidence == null)' "$SCAN_DIR/below.json" >/dev/null; then
  pass "below blocker: still open, no evidence"
else fail "below blocker"; fi

# Test 10: at-threshold blocker remains open (escalator records the escalation but doesn't close)
if jq -e '.status == "open"' "$SCAN_DIR/at.json" >/dev/null; then
  pass "at-threshold blocker: still open (escalator escalated, didn't close)"
else fail "at-threshold blocker status"; fi

# Test 11: escalations.jsonl has 2 rows (1 auto-close + 1 escalation)
if [[ -f "$ELOG1" ]] && [[ "$(wc -l < "$ELOG1" | tr -d ' ')" -eq 2 ]]; then
  pass "escalations.jsonl: exactly 2 rows (auto-close + escalation)"
else fail "escalations row count: $(wc -l < "$ELOG1" 2>/dev/null | tr -d ' ' || echo 0)"; fi

# Test 12: row events differentiate
events="$(jq -s 'map(.event) | sort' "$ELOG1" 2>/dev/null)"
if [[ "$events" == *'blocker_auto_closed'* ]] && [[ "$events" == *'blocker_ac_failed_escalated'* ]]; then
  pass "escalations.jsonl: contains both event types (auto_closed + ac_failed_escalated)"
else fail "events: $events"; fi

# Test 13: counter "effectively 0" on at-threshold blocker after escalation.
# For n=1 specifically, the counter file is never written (escalation
# happens on the first fail before write_counter runs). reset_counter
# is then a no-op because the file doesn't exist. Both states (file
# absent OR file with counter:0) are equivalent: next run starts fresh.
at_counter_file="$CDIR1/chain-test-at.json"
if [[ ! -e "$at_counter_file" ]]; then
  pass "at-threshold counter: effectively 0 (file absent — first fail at n=1 escalates without ever writing counter)"
elif [[ "$(jq -r '.counter' "$at_counter_file" 2>/dev/null)" == "0" ]]; then
  pass "at-threshold counter: explicitly reset to 0 in file"
else
  fail "at-threshold counter not effectively 0: file=$at_counter_file content=$(cat "$at_counter_file" 2>/dev/null)"
fi

# Test 14: below counter incremented to 1
below_counter="$(jq -r '.counter' "$CDIR1/chain-test-below.json" 2>/dev/null || echo missing)"
if [[ "$below_counter" == "1" ]]; then
  pass "below counter: incremented to 1 (under threshold=4)"
else fail "below counter: $below_counter"; fi

# Test 15: pass counter not created (auto-closed blocker; escalator's reset on PASS skipped because counter file never existed)
if [[ ! -e "$CDIR1/chain-test-pass.json" ]]; then
  pass "pass counter: not created (no fail to count)"
else fail "pass counter unexpectedly created"; fi

# === IDEMPOTENCY: re-run on same state ===
out="$("$CHAIN" tick \
  --blockers-dir "$SCAN_DIR" \
  --escalations-log "$ELOG1" \
  --counter-dir "$CDIR1" \
  --threshold-n 4 \
  --apply --json 2>/dev/null)"

# Test 16: 2nd run idempotent — pass blocker stays closed (auto-close skips already-closed)
if jq -e '.summary.auto_closed == 0' <<<"$out" >/dev/null; then
  pass "2nd run idempotent: 0 new auto-closes (already-closed skipped)"
else fail "2nd run auto_closed: $(jq -r '.summary.auto_closed' <<<"$out")"; fi

# Test 17: 2nd run — below blocker counter goes 1→2 (still under threshold=4)
below_counter2="$(jq -r '.counter' "$CDIR1/chain-test-below.json")"
if [[ "$below_counter2" == "2" ]]; then
  pass "2nd run: below counter advances 1->2"
else fail "2nd run below counter: $below_counter2"; fi

# Test 18: 2nd run — at-threshold blocker re-escalates (n=1 so any fail = at threshold, fresh streak)
re_escalation_count="$(jq -s 'map(select(.event == "blocker_ac_failed_escalated" and .blocker_id == "chain-test-at")) | length' "$ELOG1")"
if [[ "$re_escalation_count" == "2" ]]; then
  pass "2nd run: at-threshold re-escalates (fresh streak after counter reset)"
else fail "at-threshold re-escalation count: $re_escalation_count"; fi

# === --skip-stage tick-cadence ===
SCAN_DIR2="$TMPDIR_TEST/scan2"
ELOG2="$TMPDIR_TEST/elog2.jsonl"
CDIR2="$TMPDIR_TEST/counters2"
setup_blockers "$SCAN_DIR2"

out="$("$CHAIN" tick \
  --blockers-dir "$SCAN_DIR2" \
  --escalations-log "$ELOG2" \
  --counter-dir "$CDIR2" \
  --threshold-n 4 \
  --skip-stage tick-cadence \
  --apply --json 2>/dev/null)"

# Test 19: --skip-stage tick-cadence still runs auto-close + fail-escalator
if printf '%s' "$out" | jq -e '
  ."stages"."tick-cadence".skipped == true
  and .summary.auto_closed == 1
  and .summary.escalated == 1
' >/dev/null; then
  pass "--skip-stage tick-cadence: auto-close + escalator still run"
else fail "skip-stage: $(printf '%s' "$out" | jq -c '{stages: ."stages"."tick-cadence".skipped, summary}')"; fi

# === DRY-RUN ===
SCAN_DIR3="$TMPDIR_TEST/scan3"
ELOG3="$TMPDIR_TEST/elog3.jsonl"
CDIR3="$TMPDIR_TEST/counters3"
setup_blockers "$SCAN_DIR3"

"$CHAIN" tick \
  --blockers-dir "$SCAN_DIR3" \
  --escalations-log "$ELOG3" \
  --counter-dir "$CDIR3" \
  --threshold-n 4 \
  --json >/dev/null 2>&1

# Test 20: dry-run leaves no escalations.jsonl + no counter dir + blockers unchanged
if [[ ! -e "$ELOG3" ]] \
   && [[ ! -e "$CDIR3" ]] \
   && [[ "$(jq -r '.status' "$SCAN_DIR3/pass.json")" == "open" ]]; then
  pass "dry-run: no log, no counter dir, blockers unchanged"
else fail "dry-run mutated state"; fi

# === audit mode ===
out="$("$CHAIN" audit --escalations-log "$ELOG1" --tail 2 --json 2>/dev/null)"
if printf '%s' "$out" | jq -e '.mode == "audit" and (.rows | type == "array") and .row_count >= 2' >/dev/null; then
  pass "audit mode: tails escalations.jsonl"
else fail "audit: $(printf '%s' "$out" | jq -c .)"; fi

# === Empty blockers + --skip-stage of all 3 stages ===
out="$("$CHAIN" tick \
  --blockers-dir "$TMPDIR_TEST/no-blockers" \
  --escalations-log "$TMPDIR_TEST/none-elog.jsonl" \
  --counter-dir "$TMPDIR_TEST/none-counters" \
  --skip-stage tick-cadence \
  --skip-stage auto-close \
  --skip-stage fail-escalator \
  --json 2>/dev/null)"

# Test 22: skip-all stages → all stages skipped
if printf '%s' "$out" | jq -e '
  ."stages"."tick-cadence".skipped == true
  and ."stages"."auto-close".skipped == true
  and ."stages"."fail-escalator".skipped == true
' >/dev/null; then
  pass "--skip-stage all 3: all stages skipped, no work done"
else fail "skip-all: $(printf '%s' "$out" | jq -c '.stages | to_entries | map({(.key): .value.skipped})')"; fi

# === Stage failure resilience: missing primitive ===
out="$("$CHAIN" tick \
  --blockers-dir "$TMPDIR_TEST/scan2" \
  --escalations-log "$TMPDIR_TEST/missing-elog.jsonl" \
  --counter-dir "$TMPDIR_TEST/missing-counters" \
  --apply --json 2>&1)"
# Override one binary to a non-existent path via env
out="$(BLOCKER_DISCIPLINE_TICK_CADENCE_BIN=/no/such/binary "$CHAIN" tick \
  --blockers-dir "$SCAN_DIR2" \
  --escalations-log "$TMPDIR_TEST/elog-mb.jsonl" \
  --counter-dir "$TMPDIR_TEST/cdir-mb" \
  --apply --json 2>/dev/null)"
if printf '%s' "$out" | jq -e '
  .summary.stages_failed >= 1
  and (."stages"."tick-cadence".error == "binary missing" or
       ."stages"."tick-cadence".path != null)
' >/dev/null; then
  pass "missing primitive: chain records stage failure but doesn't halt"
else fail "missing primitive: $(printf '%s' "$out" | jq -c '{stages_failed: .summary.stages_failed, tc: ."stages"."tick-cadence"}')"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
