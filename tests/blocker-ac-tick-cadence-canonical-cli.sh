#!/usr/bin/env bash
# tests/blocker-ac-tick-cadence-canonical-cli.sh
# Canonical-cli + integration tests for blocker-ac-tick-cadence.sh (bead flywheel-e4ulf).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/blocker-ac-tick-cadence.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Fixtures: isolated TMP for counter + audit log + blocker glob
TEST_DIR="$(mktemp -d)"
TEST_COUNTER="$TEST_DIR/counter.json"
TEST_AUDIT="$TEST_DIR/audit.jsonl"
TEST_BLOCKER_DIR="$TEST_DIR/blockers"
mkdir -p "$TEST_BLOCKER_DIR"

run_isolated() {
  BLOCKER_AC_COUNTER_FILE="$TEST_COUNTER" \
  SCAFFOLD_AUDIT_LOG="$TEST_AUDIT" \
  BLOCKER_AC_BLOCKER_GLOB="$TEST_BLOCKER_DIR/*.json" \
  "$SCRIPT" "$@"
}

# Test 1: bash -n syntax
if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# Test 2: --info envelope
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.schema_version | test("^blocker-ac-tick-cadence/v[0-9]+$")' >/dev/null; then
  pass "--info schema_version matches <surface>/v1"
else fail "--info schema_version"; fi

# Test 3: --schema for tick surface
if "$SCRIPT" --schema tick 2>/dev/null | jq -e '.command == "schema" and .surface == "tick"' >/dev/null; then
  pass "--schema tick envelope"
else fail "--schema tick envelope"; fi

# Test 4: --examples
if "$SCRIPT" --examples --json 2>/dev/null | jq -e '.command == "examples"' >/dev/null; then
  pass "--examples envelope"
else fail "--examples envelope"; fi

# Test 5: doctor envelope
if "$SCRIPT" doctor --json 2>/dev/null | jq -e '.command == "doctor"' >/dev/null; then
  pass "doctor envelope"
else fail "doctor envelope"; fi

# Test 6: health envelope
if "$SCRIPT" health --json 2>/dev/null | jq -e '.command == "health"' >/dev/null; then
  pass "health envelope"
else fail "health envelope"; fi

# Test 7: repair --dry-run envelope (refused for unknown scope but envelope-shaped)
if "$SCRIPT" repair --scope none --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .mode == "dry_run"' >/dev/null; then
  pass "repair --dry-run envelope"
else fail "repair --dry-run envelope"; fi

# Test 8: repair --apply without --idempotency-key returns rc=3
"$SCRIPT" repair --scope audit_log_dir --apply --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 3 ]]; then
  pass "repair --apply without idempotency-key returns rc=3"
else
  fail "repair --apply rc=$rc (expected 3)"
fi

# Test 9: validate refused envelope (no subject)
if "$SCRIPT" validate --json 2>/dev/null | jq -e '.command == "validate"' >/dev/null; then
  pass "validate envelope"
else fail "validate envelope"; fi

# Test 10: audit envelope
if "$SCRIPT" audit --json 2>/dev/null | jq -e '.command == "audit"' >/dev/null; then
  pass "audit envelope"
else fail "audit envelope"; fi

# Test 11: why with id
if "$SCRIPT" why some-id 2>/dev/null | jq -e '.command == "why"' >/dev/null; then
  pass "why envelope"
else fail "why envelope"; fi

# Test 12: help <topic>
if "$SCRIPT" help tick 2>/dev/null | grep -q 'topic:'; then
  pass "help topic"
else fail "help topic"; fi

# Test 13: quickstart envelope
if "$SCRIPT" quickstart 2>/dev/null | jq -e '.command == "quickstart"' >/dev/null; then
  pass "quickstart envelope"
else fail "quickstart envelope"; fi

# ---- Per-surface fillin assertions ----

# Test 14: doctor returns concrete checks (>=5)
if "$SCRIPT" doctor --json 2>/dev/null \
    | jq -e '(.checks | length >= 5) and (.checks | all(.name and (.status | IN("pass","warn","fail"))))' >/dev/null; then
  pass "doctor returns >=5 concrete checks"
else fail "doctor concrete checks"; fi

# Test 15: doctor probes the load-bearing replay_verify_executable check
if "$SCRIPT" doctor --json 2>/dev/null | jq -e '.checks | any(.name == "replay_verify_executable")' >/dev/null; then
  pass "doctor probes replay_verify_executable"
else fail "doctor replay_verify_executable check missing"; fi

# Test 16: validate counter-state returns counter + fires_on_next_tick
if BLOCKER_AC_COUNTER_FILE="$TEST_COUNTER" "$SCRIPT" validate counter-state 2>/dev/null \
    | jq -e '(.subject == "counter-state") and has("counter") and has("default_n") and has("fires_on_next_tick")' >/dev/null; then
  pass "validate counter-state returns counter+default_n+fires_on_next_tick"
else fail "validate counter-state contract"; fi

# Test 17: validate blocker-file passes on a well-formed blocker
WELL_FORMED="$TEST_DIR/well-formed.json"
cat > "$WELL_FORMED" <<'BLK'
{"blocker_id":"x","last_verified_at":"2026-01-01T00:00:00Z","acceptance_condition":"true"}
BLK
if "$SCRIPT" validate blocker-file "$WELL_FORMED" 2>/dev/null \
    | jq -e '(.subject == "blocker-file") and (.status == "pass")' >/dev/null; then
  pass "validate blocker-file accepts well-formed blocker"
else fail "validate blocker-file well-formed"; fi
rm -f "$WELL_FORMED"

# Test 18: validate blocker-file fails on missing required fields
MISSING_FIELDS="$TEST_DIR/missing.json"
echo '{"id":"x"}' > "$MISSING_FIELDS"
"$SCRIPT" validate blocker-file "$MISSING_FIELDS" >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 1 ]]; then
  pass "validate blocker-file rejects missing required fields (rc=1)"
else
  fail "validate blocker-file missing fields rc=$rc (expected 1)"
fi
rm -f "$MISSING_FIELDS"

# Test 19: integration — Nth-tick gate (counter mod N == 0 fires AC)
# Reset isolated counter to 0
echo '{"counter":0}' > "$TEST_COUNTER"
# Stale blocker (last_verified_at >24h ago)
STALE_BLOCKER="$TEST_BLOCKER_DIR/stale.json"
cat > "$STALE_BLOCKER" <<'BLK'
{"blocker_id":"stale-test","last_verified_at":"2026-04-01T00:00:00Z","acceptance_condition":"true","ac_check_interval_ticks":4}
BLK
# Tick 3 times — should NOT fire (counter 1, 2, 3 mod 4 != 0)
for i in 1 2 3; do
  run_isolated --json >/dev/null 2>&1
done
# Tick 4 — should FIRE
TICK4_OUT="$(run_isolated --json 2>&1)"
TICK4_FIRED="$(jq -r '.fired // 0' <<<"$TICK4_OUT" 2>/dev/null)"
TICK4_VERDICT="$(jq -r '.per_blocker[0].verdict // "missing"' <<<"$TICK4_OUT" 2>/dev/null)"
if [[ "$TICK4_FIRED" -eq 1 && "$TICK4_VERDICT" == "fired" ]]; then
  pass "integration: 4th tick fires AC on stale blocker (counter mod N == 0)"
else
  fail "integration: 4th tick fired=$TICK4_FIRED verdict=$TICK4_VERDICT"
fi

# Test 20: integration — tick 1, 2, 3 skip with reason=not_nth_tick
echo '{"counter":0}' > "$TEST_COUNTER"
TICK1_OUT="$(run_isolated --json 2>&1)"
TICK1_REASON="$(jq -r '.per_blocker[0].reason // "missing"' <<<"$TICK1_OUT" 2>/dev/null)"
if [[ "$TICK1_REASON" == "not_nth_tick" ]]; then
  pass "integration: 1st tick skips with reason=not_nth_tick"
else
  fail "integration: 1st tick reason=$TICK1_REASON"
fi

# Test 21: integration — fresh blocker (last_verified_at <24h ago) skips even on Nth tick
echo '{"counter":3}' > "$TEST_COUNTER"  # next tick will be 4
FRESH_BLOCKER="$TEST_BLOCKER_DIR/fresh.json"
RECENT_TS="$(date -u -v-1H +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ)"
cat > "$FRESH_BLOCKER" <<BLK
{"blocker_id":"fresh-test","last_verified_at":"$RECENT_TS","acceptance_condition":"true","ac_check_interval_ticks":4}
BLK
rm -f "$STALE_BLOCKER"  # leave only fresh one
TICK4_FRESH_OUT="$(run_isolated --json 2>&1)"
SKIPPED_FRESH="$(jq -r '.skipped_fresh // 0' <<<"$TICK4_FRESH_OUT" 2>/dev/null)"
if [[ "$SKIPPED_FRESH" -eq 1 ]]; then
  pass "integration: 4th tick skips fresh blocker (last_verified <24h)"
else
  fail "integration: 4th tick skipped_fresh=$SKIPPED_FRESH"
fi

# Test 22: integration — counter increments monotonically
echo '{"counter":0}' > "$TEST_COUNTER"
run_isolated --json >/dev/null 2>&1
run_isolated --json >/dev/null 2>&1
COUNTER_AFTER_2="$(jq -r '.counter // 0' "$TEST_COUNTER" 2>/dev/null)"
if [[ "$COUNTER_AFTER_2" -eq 2 ]]; then
  pass "integration: counter increments monotonically (1, 2)"
else
  fail "integration: counter after 2 ticks = $COUNTER_AFTER_2 (expected 2)"
fi

# Cleanup
rm -rf "$TEST_DIR"


if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
