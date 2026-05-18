#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/loop-contract-efficacy-gate.py"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/loop-contract-efficacy-gate.XXXXXX")"
trap 'find "$TMP" -mindepth 1 -maxdepth 1 -type f -delete; rmdir "$TMP" 2>/dev/null || true' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

base_metrics() {
  jq -nc '{
    schema_version:"flywheel.dispatch_mode_metrics.v1",
    since:"2026-06-01T00:00:00Z",
    until:"2026-06-15T00:00:00Z",
    rows_considered:40,
    modes:{
      loop:{mode:"loop",pulse_count:4,bead_close_per_hour:3.6},
      goal:{mode:"goal",pulse_count:2,bead_close_per_hour:7.0}
    }
  }'
}

python3 -m py_compile "$SCRIPT" && pass "python syntax" || fail "python syntax"

base_metrics >"$TMP/pass.json"
if "$SCRIPT" --metrics "$TMP/pass.json" --json >"$TMP/pass.out"; then
  jq -e '.status == "pass" and .phase5_required == false and .observed.loop_to_goal_ratio > 0.5' "$TMP/pass.out" >/dev/null \
    && pass "passing metrics clear phase4 gate" || fail "passing metrics clear phase4 gate"
else
  fail "passing metrics should exit 0"
fi

base_metrics | jq '.modes.loop.bead_close_per_hour = 2.0' >"$TMP/low-rate.json"
if "$SCRIPT" --metrics "$TMP/low-rate.json" --json >"$TMP/low-rate.out"; then
  fail "low loop rate should exit nonzero"
else
  jq -e '.status == "fail" and .phase5_required == true and (.failure_codes | index("loop_close_rate")) and (.failure_codes | index("loop_goal_ratio"))' "$TMP/low-rate.out" >/dev/null \
    && pass "failed metrics require phase5" || fail "failed metrics require phase5"
fi

base_metrics | jq 'del(.since)' >"$TMP/unbounded.json"
if "$SCRIPT" --metrics "$TMP/unbounded.json" --json >"$TMP/unbounded.out"; then
  fail "unbounded metrics should exit nonzero"
else
  jq -e '.status == "fail" and (.failure_codes | index("bounded_window")) and (.failure_codes | index("post_soak_window"))' "$TMP/unbounded.out" >/dev/null \
    && pass "unbounded metrics rejected" || fail "unbounded metrics rejected"
fi

base_metrics | jq '.since = "2026-05-31T23:59:59Z" | .until = "2026-06-14T23:59:59Z"' >"$TMP/pre-soak.json"
if "$SCRIPT" --metrics "$TMP/pre-soak.json" --json >"$TMP/pre-soak.out"; then
  fail "pre-soak window should exit nonzero"
else
  jq -e '.status == "fail" and (.failure_codes | index("post_soak_window"))' "$TMP/pre-soak.out" >/dev/null \
    && pass "pre-soak window rejected" || fail "pre-soak window rejected"
fi

base_metrics | jq '.until = "2026-06-07T23:59:59Z"' >"$TMP/short-window.json"
if "$SCRIPT" --metrics "$TMP/short-window.json" --json >"$TMP/short-window.out"; then
  fail "short window should exit nonzero"
else
  jq -e '.status == "fail" and (.failure_codes | index("window_duration")) and .window.window_hours < 336' "$TMP/short-window.out" >/dev/null \
    && pass "short window rejected" || fail "short window rejected"
fi

base_metrics | jq '.modes.goal.pulse_count = 0' >"$TMP/no-goal-pulse.json"
if "$SCRIPT" --metrics "$TMP/no-goal-pulse.json" --json >"$TMP/no-goal-pulse.out"; then
  fail "zero goal pulse should exit nonzero"
else
  jq -e '.status == "fail" and (.failure_codes | index("goal_dispatch_count"))' "$TMP/no-goal-pulse.out" >/dev/null \
    && pass "two-mode harmony requires goal pulses" || fail "two-mode harmony requires goal pulses"
fi

printf 'Summary: %d passed, %d failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
