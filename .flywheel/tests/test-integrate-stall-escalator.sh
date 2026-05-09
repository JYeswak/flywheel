#!/usr/bin/env bash
# test-integrate-stall-escalator.sh
#
# flywheel-xp50r regression: assert integrate-stall-escalator.sh
# detects N consecutive worker_capacity_gate_failed Sub-shape B
# (ERROR-after-callback) emissions per (session, pane) and plans an
# L95 escalation; below threshold, no escalation is planned.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
ESCALATOR="${INTEGRATE_STALL_ESCALATOR_BIN:-$ROOT/.flywheel/scripts/integrate-stall-escalator.sh}"

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

if [[ ! -f "$ESCALATOR" ]]; then
  printf 'SKIP integrate-stall-escalator.sh missing at %s\n' "$ESCALATOR"
  exit 77
fi

FIXTURE_ROOT="$(mktemp -d -t integrate-stall-test.XXXXXX)"
trap 'rm -f "$FIXTURE_ROOT"/*.jsonl 2>/dev/null; rmdir "$FIXTURE_ROOT" 2>/dev/null' EXIT

# Build a fixture fuckup-log with timestamps within the lookback window
# (today minus 6h) so the detector includes them.
NOW_EPOCH=$(date -u +%s)
make_ts() {
  # arg: minutes ago
  local ago_minutes="$1"
  local ts_epoch=$((NOW_EPOCH - ago_minutes * 60))
  date -u -r "$ts_epoch" +'%Y-%m-%dT%H:%M:%SZ' 2>/dev/null \
    || date -u -d "@$ts_epoch" +'%Y-%m-%dT%H:%M:%SZ'
}

# Fixture A: 6 Sub-shape B rows for (mobile-eats, 1) → above threshold
FIXTURE_A="$FIXTURE_ROOT/fixture-a.jsonl"
for n in 1 2 3 4 5 6; do
  ts=$(make_ts $((360 - n * 10)))
  printf '{"ts":"%s","session":"mobile-eats","pane":1,"agent":"claude","trauma_class":"worker_capacity_gate_failed","severity":"medium","what_happened":"INTEGRATE tick aborted because pane 2 robot-activity was ERROR, not WAITING."}\n' "$ts"
done > "$FIXTURE_A"

# Fixture B: 2 Sub-shape B rows (below threshold) + 4 Sub-shape A rows (THINKING; should NOT count)
FIXTURE_B="$FIXTURE_ROOT/fixture-b.jsonl"
ts1=$(make_ts 60)
ts2=$(make_ts 50)
printf '{"ts":"%s","session":"alpsinsurance","pane":2,"trauma_class":"worker_capacity_gate_failed","severity":"medium","what_happened":"INTEGRATE tick aborted because pane 2 robot-activity was ERROR, not WAITING."}\n' "$ts1" > "$FIXTURE_B"
printf '{"ts":"%s","session":"alpsinsurance","pane":2,"trauma_class":"worker_capacity_gate_failed","severity":"medium","what_happened":"INTEGRATE tick aborted because pane 2 robot-activity was ERROR, not WAITING."}\n' "$ts2" >> "$FIXTURE_B"
# Sub-shape A rows: should NOT match because pattern is ERROR-only
for n in 1 2 3 4; do
  ts=$(make_ts $((40 - n * 5)))
  printf '{"ts":"%s","session":"alpsinsurance","pane":2,"trauma_class":"worker_capacity_gate_failed","severity":"low","what_happened":"INTEGRATE deferred reaping because pane 2 was THINKING."}\n' "$ts"
done >> "$FIXTURE_B"

# Fixture C: 4 rows for one pane and 4 for another → both above threshold
FIXTURE_C="$FIXTURE_ROOT/fixture-c.jsonl"
{
  for n in 1 2 3 4; do
    ts=$(make_ts $((300 - n * 5)))
    printf '{"ts":"%s","session":"vrtx","pane":2,"trauma_class":"worker_capacity_gate_failed","severity":"medium","what_happened":"INTEGRATE tick aborted because pane 2 robot-activity was ERROR, not WAITING."}\n' "$ts"
  done
  for n in 1 2 3 4; do
    ts=$(make_ts $((250 - n * 5)))
    printf '{"ts":"%s","session":"skillos","pane":3,"trauma_class":"worker_capacity_gate_failed","severity":"high","what_happened":"INTEGRATE tick aborted because pane 3 robot-activity was ERROR, not WAITING despite callback delivered."}\n' "$ts"
  done
} > "$FIXTURE_C"

LEDGER_A="$FIXTURE_ROOT/ledger-a.jsonl"
LEDGER_B="$FIXTURE_ROOT/ledger-b.jsonl"
LEDGER_C="$FIXTURE_ROOT/ledger-c.jsonl"

# T1: triad still works (no regression to introspection)
"$ESCALATOR" --info --json >/dev/null 2>&1 && pass "T1a --info rc=0" || fail "T1a --info regressed"
"$ESCALATOR" --schema --json >/dev/null 2>&1 && pass "T1b --schema rc=0" || fail "T1b --schema regressed"
"$ESCALATOR" --doctor --json >/dev/null 2>&1 && pass "T1c --doctor rc=0" || fail "T1c --doctor regressed"
"$ESCALATOR" --examples >/dev/null 2>&1 && pass "T1d --examples rc=0" || fail "T1d --examples regressed"

# T2: above-threshold fixture → 1 stalled pane planned
T2_OUT=$(INTEGRATE_STALL_FUCKUP_LOG="$FIXTURE_A" \
  INTEGRATE_STALL_LEDGER="$LEDGER_A" \
  INTEGRATE_STALL_LOOKBACK_HOURS=24 \
  "$ESCALATOR" --json 2>&1)
T2_PLANNED=$(printf '%s' "$T2_OUT" | jq -r '.escalations_planned')
T2_STALLED=$(printf '%s' "$T2_OUT" | jq -r '.stalled_panes | length')
T2_COUNT=$(printf '%s' "$T2_OUT" | jq -r '.stalled_panes[0].consecutive_count // 0')
[[ "$T2_PLANNED" == "1" ]] && pass "T2a above-threshold fixture plans 1 escalation" || fail "T2a planned=$T2_PLANNED (want 1)"
[[ "$T2_STALLED" == "1" ]] && pass "T2b above-threshold fixture finds 1 stalled pane" || fail "T2b stalled_panes=$T2_STALLED (want 1)"
[[ "$T2_COUNT" == "6" ]] && pass "T2c stalled pane consecutive_count=6" || fail "T2c count=$T2_COUNT (want 6)"

# T3: below-threshold fixture → 0 stalled panes (Sub-shape B count below 3, plus Sub-shape A filtered out)
T3_OUT=$(INTEGRATE_STALL_FUCKUP_LOG="$FIXTURE_B" \
  INTEGRATE_STALL_LEDGER="$LEDGER_B" \
  INTEGRATE_STALL_LOOKBACK_HOURS=24 \
  "$ESCALATOR" --json 2>&1)
T3_PLANNED=$(printf '%s' "$T3_OUT" | jq -r '.escalations_planned')
[[ "$T3_PLANNED" == "0" ]] && pass "T3 below-threshold fixture plans 0 escalations (sub-A filtered, sub-B count=2)" || fail "T3 planned=$T3_PLANNED (want 0): $T3_OUT"

# T4: multi-pane fixture → both panes above threshold
T4_OUT=$(INTEGRATE_STALL_FUCKUP_LOG="$FIXTURE_C" \
  INTEGRATE_STALL_LEDGER="$LEDGER_C" \
  INTEGRATE_STALL_LOOKBACK_HOURS=24 \
  "$ESCALATOR" --json 2>&1)
T4_PLANNED=$(printf '%s' "$T4_OUT" | jq -r '.escalations_planned')
T4_STALLED=$(printf '%s' "$T4_OUT" | jq -r '.stalled_panes | length')
[[ "$T4_PLANNED" == "2" ]] && pass "T4a multi-pane fixture plans 2 escalations" || fail "T4a planned=$T4_PLANNED (want 2)"
[[ "$T4_STALLED" == "2" ]] && pass "T4b multi-pane fixture finds 2 stalled panes" || fail "T4b stalled_panes=$T4_STALLED (want 2)"

# T5: idempotency — second --apply against same fixture+ledger should NOT plan again
LEDGER_D="$FIXTURE_ROOT/ledger-d.jsonl"
INTEGRATE_STALL_FUCKUP_LOG="$FIXTURE_A" \
  INTEGRATE_STALL_LEDGER="$LEDGER_D" \
  INTEGRATE_STALL_LOOKBACK_HOURS=24 \
  INTEGRATE_STALL_PROBE=/bin/true \
  "$ESCALATOR" --apply --json >/dev/null 2>&1

T5_OUT=$(INTEGRATE_STALL_FUCKUP_LOG="$FIXTURE_A" \
  INTEGRATE_STALL_LEDGER="$LEDGER_D" \
  INTEGRATE_STALL_LOOKBACK_HOURS=24 \
  INTEGRATE_STALL_PROBE=/bin/true \
  "$ESCALATOR" --apply --json 2>&1)
T5_PLANNED=$(printf '%s' "$T5_OUT" | jq -r '.escalations_planned')
T5_ALREADY=$(printf '%s' "$T5_OUT" | jq -r '.stalled_panes[0].already_escalated // false')
[[ "$T5_PLANNED" == "0" ]] && pass "T5a second --apply plans 0 (idempotent)" || fail "T5a re-plan=$T5_PLANNED (want 0)"
[[ "$T5_ALREADY" == "true" ]] && pass "T5b stalled pane marked already_escalated" || fail "T5b already=$T5_ALREADY (want true)"

# T6: schema_version is canonical
T6_SV=$("$ESCALATOR" --json 2>/dev/null | jq -r '.schema_version' 2>/dev/null)
[[ "$T6_SV" == "integrate-stall-escalator/v1" ]] && pass "T6 emits canonical schema_version" || fail "T6 schema_version=$T6_SV"

# T7: bash -n syntax check
bash -n "$ESCALATOR" && pass "T7 escalator passes bash -n" || fail "T7 escalator syntax error"

printf '\n=== test-integrate-stall-escalator.sh ===\n'
printf 'pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]] && exit 0 || exit 1
