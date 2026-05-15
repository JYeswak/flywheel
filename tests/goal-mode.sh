#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
FIX="$ROOT/tests/fixtures/goal-mode"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/goal-mode.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# --- T1: receipt-schema validator -------------------------------------------
SCRIPT="$ROOT/scripts/validate_watch_log.py"
if python3 -m py_compile "$SCRIPT"; then pass "T1 syntax"; else fail "T1 syntax"; fi

# Validator on the live rolling log = pass.
if python3 "$SCRIPT" --file "$ROOT/.flywheel/evidence/watch-rolling-log.jsonl" --json >"$TMP/live.json" 2>"$TMP/live.err"; then
  if grep -q '"status": "pass"' "$TMP/live.json"; then pass "T1 live log valid"; else fail "T1 live log valid"; fi
else
  fail "T1 live log validator exit 0"
fi

# Validator on intentionally bad rows = fail with findings.
set +e
python3 "$SCRIPT" --file "$FIX/invalid-log-missing-fields.jsonl" --json >"$TMP/bad.json" 2>&1
rc=$?
set -e
if [[ "$rc" -eq 1 ]] && grep -q '"status": "fail"' "$TMP/bad.json"; then
  pass "T1 invalid log rejected (exit 1, status fail)"
else
  fail "T1 invalid log rejected (exit $rc)"
fi

# --- T2: goal-text linter ---------------------------------------------------
SCRIPT="$ROOT/scripts/validate_goal_text.py"
if python3 -m py_compile "$SCRIPT"; then pass "T2 syntax"; else fail "T2 syntax"; fi

# Valid goal text passes 11/11 checks.
if python3 "$SCRIPT" --file "$FIX/valid-goal.txt" --json >"$TMP/goal-valid.json" 2>&1; then
  if grep -q '"status": "pass"' "$TMP/goal-valid.json"; then pass "T2 valid goal passes"; else fail "T2 valid goal passes"; fi
else
  fail "T2 valid goal exit 0"
fi

# Invalid goal (missing anti-spin) fails.
set +e
python3 "$SCRIPT" --file "$FIX/invalid-goal-missing-anti-spin.txt" --json >"$TMP/goal-bad.json" 2>&1
rc=$?
set -e
if [[ "$rc" -eq 1 ]] && grep -q '"id": "anti_spin_clause"' "$TMP/goal-bad.json" && grep -q '"pass": false' "$TMP/goal-bad.json"; then
  pass "T2 missing-anti-spin caught"
else
  fail "T2 missing-anti-spin caught (exit $rc)"
fi

# --- T3 + T4: simulator + anti-spin assertion -------------------------------
SCRIPT="$ROOT/scripts/simulate_goal_cycles.py"
if python3 -m py_compile "$SCRIPT"; then pass "T3 syntax"; else fail "T3 syntax"; fi

# Simulator on anti-spin fixture: turn 3 must be STAND_DOWN.
if python3 "$SCRIPT" --events "$FIX/events-anti-spin-fire.jsonl" --verify-anti-spin-at 3 --out "$TMP/sim.jsonl" --json >"$TMP/sim.json" 2>&1; then
  if grep -q '"pass": true' "$TMP/sim.json"; then pass "T4 anti-spin fires at turn 3"; else fail "T4 anti-spin fires at turn 3"; fi
else
  fail "T4 simulator exit 0"
fi

# Wrong assertion turn must FAIL (sanity-check the assertion mechanism).
set +e
python3 "$SCRIPT" --events "$FIX/events-anti-spin-fire.jsonl" --verify-anti-spin-at 5 --out "$TMP/sim2.jsonl" --json >"$TMP/sim2.json" 2>&1
rc=$?
set -e
# Turn 5 has event=new_commit so cycle=ACT, NOT STAND_DOWN. Assertion must fail (exit 1).
if [[ "$rc" -eq 1 ]] && grep -q '"actual_cycle": "ACT"' "$TMP/sim2.json"; then
  pass "T4 assertion correctly rejects ACT-at-turn-5"
else
  fail "T4 assertion correctly rejects ACT-at-turn-5 (exit $rc)"
fi

# Simulator output passes T1 schema (round-trip property).
if python3 "$ROOT/scripts/validate_watch_log.py" --file "$TMP/sim.jsonl" --json >"$TMP/sim-validated.json" 2>&1; then
  if grep -q '"status": "pass"' "$TMP/sim-validated.json"; then pass "T3+T1 simulator output passes schema"; else fail "T3+T1 simulator output passes schema"; fi
else
  fail "T3+T1 simulator output passes schema (exit $?)"
fi

printf '\n%d passed, %d failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
