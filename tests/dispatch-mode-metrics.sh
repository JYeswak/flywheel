#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/dispatch-mode-metrics.py"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/dispatch-mode-metrics.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

log="$TMP/dispatch-log.jsonl"
cat >"$log" <<'JSONL'
{"ts":"2026-05-18T00:00:00Z","event":"dispatch_sent","task_id":"old-no-mode"}
{"ts":"2026-05-18T00:10:00Z","event":"dispatch_sent","task_id":"loop-1","mode":"loop","origin_task_id":"loop-1","tick_id":"tick-1"}
{"ts":"2026-05-18T00:20:00Z","event":"bead_callback_received","task_id":"loop-1","status":"callback_received"}
{"ts":"2026-05-18T00:30:00Z","event":"dispatch_sent","task_id":"goal-1","mode":"goal","origin_task_id":"goal-1","goal_id":"goal-a","sprint_id":"sprint-a"}
{"ts":"2026-05-18T00:40:00Z","event":"bead_close_verified","task_id":"goal-1","status":"closed"}
{"ts":"2026-05-18T00:50:00Z","event":"dispatch_sent","task_id":"manual-1","mode":"manual","origin_task_id":"manual-1"}
JSONL

python3 -m py_compile "$SCRIPT" && pass "python syntax" || fail "python syntax"
"$SCRIPT" --log "$log" --json >"$TMP/out.json"

jq -e '.modes.unknown.pulse_count == 1 and .modes.unknown.productive_callback_count == 0' "$TMP/out.json" >/dev/null \
  && pass "old rows normalize to unknown" || fail "old rows normalize to unknown"
jq -e '.modes.loop.pulse_count == 1 and .modes.loop.productive_callback_count == 1 and .modes.loop.productive_callback_per_pulse == 1' "$TMP/out.json" >/dev/null \
  && pass "loop callback attribution fallback" || fail "loop callback attribution fallback"
jq -e '.modes.goal.pulse_count == 1 and .modes.goal.close_count == 1 and .modes.goal.bead_close_per_hour > 0' "$TMP/out.json" >/dev/null \
  && pass "goal close attribution fallback" || fail "goal close attribution fallback"
jq -e '.modes.manual.pulse_count == 1' "$TMP/out.json" >/dev/null \
  && pass "manual dispatch counted" || fail "manual dispatch counted"

"$SCRIPT" --log "$log" --since 2026-05-18T00:15:00Z --until 2026-05-18T00:45:00Z --json >"$TMP/window.json"
jq -e '
  .since == "2026-05-18T00:15:00Z"
  and .until == "2026-05-18T00:45:00Z"
  and .rows_considered == 3
  and .modes.unknown.pulse_count == 0
  and .modes.loop.productive_callback_count == 1
  and .modes.goal.pulse_count == 1
  and .modes.goal.close_count == 1
' "$TMP/window.json" >/dev/null \
  && pass "window bounds are surfaced and applied" || fail "window bounds are surfaced and applied"

seven_day_log="$TMP/seven-day-dispatch-log.jsonl"
cat >"$seven_day_log" <<'JSONL'
{"ts":"2026-06-01T00:10:00Z","event":"dispatch_sent","task_id":"loop-w1","mode":"loop","origin_task_id":"loop-w1","tick_id":"tick-w1"}
{"ts":"2026-06-01T00:20:00Z","event":"dispatch_sent","task_id":"goal-w1","mode":"goal","origin_task_id":"goal-w1","goal_id":"goal-w1","sprint_id":"sprint-w1"}
{"ts":"2026-06-08T00:10:00Z","event":"dispatch_sent","task_id":"loop-w2","mode":"loop","origin_task_id":"loop-w2","tick_id":"tick-w2"}
{"ts":"2026-06-08T00:20:00Z","event":"dispatch_sent","task_id":"goal-w2","mode":"goal","origin_task_id":"goal-w2","goal_id":"goal-w2","sprint_id":"sprint-w2"}
JSONL
"$SCRIPT" --log "$seven_day_log" --since 2026-06-01T00:00:00Z --until 2026-06-15T00:00:00Z --json >"$TMP/seven-day.json"
jq -e '
  (.seven_day_windows | length) == 2
  and all(.seven_day_windows[]; .loop_goal_harmony == true)
  and .seven_day_windows[0].pulse_counts.loop == 1
  and .seven_day_windows[1].pulse_counts.goal == 1
' "$TMP/seven-day.json" >/dev/null \
  && pass "seven-day harmony windows emitted" || fail "seven-day harmony windows emitted"

printf 'Summary: %d passed, %d failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
