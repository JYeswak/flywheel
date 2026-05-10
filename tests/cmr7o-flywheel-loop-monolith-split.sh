#!/usr/bin/env bash
# tests/cmr7o-flywheel-loop-monolith-split.sh
# Bead flywheel-cmr7o: regression for the bin/flywheel-loop monolith
# split (extracted flywheel_step4i_coherence_json to lib/step4i-coherence.sh).
#
# Pre-fix: bin/flywheel-loop was 814 lines (over 500 threshold);
# doctor returned action=split_flywheel_loop_dispatcher.
# Post-fix: 345 lines; monolith_size_regression.status=pass;
# action=split_flywheel_loop_dispatcher signal gone.
#
# This regression asserts:
# - bin/flywheel-loop ≤ 500 lines
# - lib/step4i-coherence.sh exists with the extracted function
# - module loop sources step4i-coherence
# - bash -n clean on both files
# - doctor's monolith_size_regression.status=pass
# - portable_tick still receives the step4i field (function callable)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
DISPATCHER="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
LIB_STEP4I="${LIB_STEP4I:-$HOME/.claude/skills/.flywheel/lib/step4i-coherence.sh}"
MAX_LINES="${FLYWHEEL_LOOP_MONOLITH_MAX_LINES:-500}"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: bin/flywheel-loop exists and is ≤ 500 lines
if [[ -x "$DISPATCHER" ]]; then
  LINES="$(wc -l <"$DISPATCHER" | tr -d '[:space:]')"
  if [[ "$LINES" -le "$MAX_LINES" ]]; then
    pass "bin/flywheel-loop is $LINES lines (≤ $MAX_LINES threshold)"
  else
    fail "bin/flywheel-loop is $LINES lines, OVER $MAX_LINES threshold (regression)"
  fi
else
  fail "bin/flywheel-loop missing at $DISPATCHER"
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

# Test 2: bin/flywheel-loop bash -n is clean
if bash -n "$DISPATCHER" 2>/dev/null; then
  pass "bin/flywheel-loop bash -n clean"
else
  fail "bin/flywheel-loop has bash syntax errors"
fi

# Test 3: extracted lib file exists with the canonical function
if [[ -f "$LIB_STEP4I" ]] \
  && grep -qE '^flywheel_step4i_coherence_json\(\) \{' "$LIB_STEP4I" \
  && grep -q "flywheel-cmr7o" "$LIB_STEP4I"; then
  pass "lib/step4i-coherence.sh exists with extracted function + flywheel-cmr7o citation"
else
  fail "lib/step4i-coherence.sh missing or function not found at $LIB_STEP4I"
fi

# Test 4: lib/step4i-coherence.sh bash -n clean
if bash -n "$LIB_STEP4I" 2>/dev/null; then
  pass "lib/step4i-coherence.sh bash -n clean"
else
  fail "lib/step4i-coherence.sh has bash syntax errors"
fi

# Test 5: bin/flywheel-loop module list now includes step4i-coherence
if grep -qE 'session print portable skill-discovery step4i-coherence' "$DISPATCHER"; then
  pass "bin/flywheel-loop module list sources step4i-coherence"
else
  fail "step4i-coherence not in module list (function won't be loaded)"
fi

# Test 6: bin/flywheel-loop NO LONGER defines flywheel_step4i_coherence_json
# (function was extracted; defining it both places would be a duplicate
# definition trauma).
if ! grep -qE '^flywheel_step4i_coherence_json\(\) \{' "$DISPATCHER"; then
  pass "bin/flywheel-loop no longer defines flywheel_step4i_coherence_json (extraction clean)"
else
  fail "bin/flywheel-loop still defines flywheel_step4i_coherence_json (double-definition risk)"
fi

# Test 7: bin/flywheel-loop CALLS flywheel_step4i_coherence_json
# (caller is portable_tick; must still invoke the lib-defined function)
if grep -qE 'flywheel_step4i_coherence_json "\$REPO_ABS"' "$DISPATCHER"; then
  pass "bin/flywheel-loop calls flywheel_step4i_coherence_json from portable_tick"
else
  fail "caller invocation regressed"
fi

# Test 8: doctor's monolith_size_regression.status=pass (cached call)
DOCTOR_JSON="$(timeout 150 "$DISPATCHER" doctor --repo "$ROOT" --json 2>/dev/null || true)"
if [[ -n "$DOCTOR_JSON" ]] \
  && jq -e '.monolith_size_regression.status == "pass"' >/dev/null 2>&1 <<<"$DOCTOR_JSON"; then
  pass "doctor monolith_size_regression.status=pass (was fail pre-extract)"
else
  fail "doctor monolith_size_regression.status not pass; got: $(jq -c '.monolith_size_regression // {}' <<<"$DOCTOR_JSON" 2>/dev/null || echo "$DOCTOR_JSON" | head -c 200)"
fi

# Test 9: doctor action is no longer split_flywheel_loop_dispatcher
if [[ -n "$DOCTOR_JSON" ]]; then
  ACTION="$(jq -r '.action // ""' <<<"$DOCTOR_JSON")"
  if [[ "$ACTION" != "split_flywheel_loop_dispatcher" ]]; then
    pass "doctor action no longer split_flywheel_loop_dispatcher (got: $ACTION)"
  else
    fail "doctor action still split_flywheel_loop_dispatcher — extraction did not flip the signal"
  fi
fi

# Test 10: portable_tick still receives a step4i packet (function callable
# via the module-loop source). The dry-run tick may fail other gates
# (worktree, mission, etc.) but the step4i field should be present.
TICK_JSON="$(timeout 90 "$DISPATCHER" tick --repo "$ROOT" --dry-run --json 2>/dev/null || true)"
if [[ -n "$TICK_JSON" ]] \
  && jq -e '.fleet_coherence_step4i_status' >/dev/null 2>&1 <<<"$TICK_JSON"; then
  pass "portable_tick still emits fleet_coherence_step4i_status (function callable post-extract)"
else
  fail "portable_tick missing step4i field — function not loaded?"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
