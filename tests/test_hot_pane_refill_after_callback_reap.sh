#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/auto-refill-decision-log.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/hot-pane-refill.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0

pass() {
  printf 'PASS %s\n' "$1"
  pass_count=$((pass_count + 1))
}

fail() {
  printf 'FAIL %s\n' "$1" >&2
  exit 1
}

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
    return 0
  fi
  jq . "$file" >&2 || cat "$file" >&2
  fail "$label"
}

write_activity_waiting() {
  printf '%s\n' '{"agents":[{"pane_idx":4,"state":"WAITING","role":"codex"}]}' >"$1"
}

write_ready_one() {
  printf '%s\n' '{"issues":[{"id":"flywheel-next","status":"open","priority":1,"role":"codex"}]}' >"$1"
}

bash -n "$SCRIPT"
pass "script syntax"

# Fixture 1: callback lands, pane is WAITING, capacity exists, ready work exists.
# The refill decision must dispatch in the same tick and write an auto-refill row.
write_activity_waiting "$TMP/activity-dispatch.json"
write_ready_one "$TMP/ready-dispatch.json"
printf '%s\n' '{"max_in_flight_dispatches":4,"current_in_flight_dispatches":1}' >"$TMP/capacity-dispatch.json"
printf '%s\n' '{"event":"callback_reaped","ts":"2026-05-07T19:00:00Z","pane":4,"task_id":"flywheel-done"}' >"$TMP/dispatch-log-dispatch.jsonl"

AUTO_REFILL_ACTIVITY_FILE="$TMP/activity-dispatch.json" \
AUTO_REFILL_READY_FILE="$TMP/ready-dispatch.json" \
AUTO_REFILL_CAPACITY_FILE="$TMP/capacity-dispatch.json" \
AUTO_REFILL_DISPATCH_LOG="$TMP/dispatch-log-dispatch.jsonl" \
AUTO_REFILL_LEDGER="$TMP/ledger-dispatch.jsonl" \
AUTO_REFILL_NOW="2026-05-07T19:00:10Z" \
  "$SCRIPT" --repo "$TMP" --session flywheel --pane 4 --role codex --callback-task-id flywheel-done --apply --json >"$TMP/dispatch.out"

assert_jq "$TMP/dispatch.out" '.decision == "dispatched" and .reason == null and .next_bead_id == "flywheel-next" and .ledger_written == true' "callback_reap_dispatches_same_tick"
jq -e 'select(.event == "auto_refill_after_reap" and .decision == "dispatched" and .next_bead_id == "flywheel-next" and .pane == 4)' "$TMP/ledger-dispatch.jsonl" >/dev/null \
  && pass "dispatch ledger row" || fail "dispatch ledger row"

# Fixture 2: callback lands, pane is WAITING, but capacity is full.
# The helper must skip and preserve the capacity_exceeded reason.
write_activity_waiting "$TMP/activity-capacity.json"
write_ready_one "$TMP/ready-capacity.json"
printf '%s\n' '{"max_in_flight_dispatches":2,"current_in_flight_dispatches":2}' >"$TMP/capacity-full.json"
printf '%s\n' '{"event":"callback_reaped","ts":"2026-05-07T19:05:00Z","pane":4,"task_id":"flywheel-done"}' >"$TMP/dispatch-log-capacity.jsonl"

AUTO_REFILL_ACTIVITY_FILE="$TMP/activity-capacity.json" \
AUTO_REFILL_READY_FILE="$TMP/ready-capacity.json" \
AUTO_REFILL_CAPACITY_FILE="$TMP/capacity-full.json" \
AUTO_REFILL_DISPATCH_LOG="$TMP/dispatch-log-capacity.jsonl" \
AUTO_REFILL_LEDGER="$TMP/ledger-capacity.jsonl" \
AUTO_REFILL_NOW="2026-05-07T19:05:10Z" \
  "$SCRIPT" --repo "$TMP" --session flywheel --pane 4 --role codex --callback-task-id flywheel-done --apply --json >"$TMP/capacity.out"

assert_jq "$TMP/capacity.out" '.decision == "skipped" and .reason == "capacity_exceeded" and .next_bead_id == null and .ledger_written == true' "capacity_exceeded_skip"
jq -e 'select(.event == "auto_refill_after_reap" and .decision == "skipped" and .reason == "capacity_exceeded")' "$TMP/ledger-capacity.jsonl" >/dev/null \
  && pass "capacity skip ledger row" || fail "capacity skip ledger row"

# Fixture 3: callback lands and capacity exists, but there is no role-matched ready work.
# The helper must skip with no_ready_beads_for_role.
write_activity_waiting "$TMP/activity-empty.json"
printf '%s\n' '{"issues":[]}' >"$TMP/ready-empty.json"
printf '%s\n' '{"max_in_flight_dispatches":4,"current_in_flight_dispatches":0}' >"$TMP/capacity-empty.json"
printf '%s\n' '{"event":"callback_reaped","ts":"2026-05-07T19:10:00Z","pane":4,"task_id":"flywheel-done"}' >"$TMP/dispatch-log-empty.jsonl"

AUTO_REFILL_ACTIVITY_FILE="$TMP/activity-empty.json" \
AUTO_REFILL_READY_FILE="$TMP/ready-empty.json" \
AUTO_REFILL_CAPACITY_FILE="$TMP/capacity-empty.json" \
AUTO_REFILL_DISPATCH_LOG="$TMP/dispatch-log-empty.jsonl" \
AUTO_REFILL_LEDGER="$TMP/ledger-empty.jsonl" \
AUTO_REFILL_NOW="2026-05-07T19:10:10Z" \
  "$SCRIPT" --repo "$TMP" --session flywheel --pane 4 --role codex --callback-task-id flywheel-done --apply --json >"$TMP/empty.out"

assert_jq "$TMP/empty.out" '.decision == "skipped" and .reason == "no_ready_beads_for_role" and .ledger_written == true' "no_ready_beads_skip"
jq -e 'select(.event == "auto_refill_after_reap" and .decision == "skipped" and .reason == "no_ready_beads_for_role")' "$TMP/ledger-empty.jsonl" >/dev/null \
  && pass "no ready skip ledger row" || fail "no ready skip ledger row"

# Metric fixture: with ready beads present, a callback-to-dispatch gap over two
# minutes is visible to doctor consumers.
printf '%s\n' '{"issues":[{"id":"flywheel-next","status":"open","priority":1}]}' >"$TMP/ready-metric.json"
cat >"$TMP/dispatch-log-metric.jsonl" <<'JSONL'
{"event":"callback_reaped","ts":"2026-05-07T19:00:00Z","pane":4}
{"event":"dispatch_sent","ts":"2026-05-07T19:03:00Z","pane":4,"task_id":"flywheel-next"}
JSONL
AUTO_REFILL_READY_FILE="$TMP/ready-metric.json" \
AUTO_REFILL_DISPATCH_LOG="$TMP/dispatch-log-metric.jsonl" \
  "$SCRIPT" --repo "$TMP" --idle-window-metric --now "2026-05-07T19:03:30Z" --json >"$TMP/metric.out" || true
assert_jq "$TMP/metric.out" '.status == "WARN" and .idle_pane_windows_over_2min_count == 1' "idle_window_metric_warns"

printf 'RESULT pass=%s/8\n' "$pass_count"
[[ "$pass_count" == "8" ]]
