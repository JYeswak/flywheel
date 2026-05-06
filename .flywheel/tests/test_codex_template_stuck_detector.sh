#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/codex-template-stuck-detector.sh"
LIVE_FIXTURE="$ROOT/.flywheel/tests/fixtures/capacity-halt-live"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/codex-capacity-live-wrapper.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

write_fixture() {
  local path="$1" t0="$2" t1="$3"
  jq -nc --arg t0 "$t0" --arg t1 "$t1" \
    '{schema_version:"codex-stuck-detector.fixture.v1",session:"fixture",pane:1,t0:$t0,t1:$t1,send_ack:true}' >"$path"
}

"$ROOT/tests/codex-template-stuck-detector.sh"

set +e
"$SCRIPT" --fixture "$LIVE_FIXTURE" --dry-run --json >"$TMP/capacity-live-dir.out"
live_rc=$?
set -e
[[ "$live_rc" -eq 1 ]] && pass "capacity_live_dir_returns_1" || fail "capacity_live_dir_returns_1"
assert_jq "$TMP/capacity-live-dir.out" '.panes[0].subclass == "model_at_capacity_halt" and .panes[0].recommended_recovery == "auto_continue"' "capacity_live_dir_string_match"

write_fixture "$TMP/capacity-reminder.json" \
  $'⚠ Selected model is at capacity. Please try a different model.\n\n› Implement {feature}\n\n  gpt-5.5 xhigh · ~/Developer/flywheel' \
  $'⚠ Selected model is at capacity. Please try a different model.\n\n› Implement {feature}\n\n  gpt-5.5 xhigh · ~/Developer/flywheel'
set +e
"$SCRIPT" --fixture "$TMP/capacity-reminder.json" --dry-run --json >"$TMP/capacity-reminder.out"
reminder_rc=$?
set -e
[[ "$reminder_rc" -eq 1 ]] && pass "capacity_reminder_returns_1" || fail "capacity_reminder_returns_1"
assert_jq "$TMP/capacity-reminder.out" '.panes[0].subclass == "model_at_capacity_halt" and .panes[0].recommended_recovery == "auto_continue"' "capacity_reminder_string_match"

write_fixture "$TMP/capacity-alt.json" \
  $'Please try a different model.\n\n›\n\n  gpt-5.5 xhigh · ~/Developer/flywheel' \
  $'Please try a different model.\n\n›\n\n  gpt-5.5 xhigh · ~/Developer/flywheel'
set +e
"$SCRIPT" --fixture "$TMP/capacity-alt.json" --dry-run --json >"$TMP/capacity-alt.out"
alt_rc=$?
set -e
[[ "$alt_rc" -eq 1 ]] && pass "capacity_alt_returns_1" || fail "capacity_alt_returns_1"
assert_jq "$TMP/capacity-alt.out" '.panes[0].subclass == "model_at_capacity_halt" and .panes[0].recommended_recovery == "auto_continue"' "capacity_alt_string_match"

filler=""
for i in $(seq 1 70); do
  filler+=$'\nterminal transcript filler line'
done
write_fixture "$TMP/capacity-significant-tail.json" \
  $'⚠ Selected model is at capacity. Please try a different model.\n• Waiting for background terminal (1m 20s • esc to interrupt)\n› Use /skills to list available skills\n• Working (3m 04s • esc to interrupt)' \
  $'⚠ Selected model is at capacity. Please try a different model.'"$filler"$'\n• Waiting for background terminal (1m 20s • esc to interrupt)\n› Use /skills to list available skills\n• Working (3m 04s • esc to interrupt)'
set +e
"$SCRIPT" --fixture "$TMP/capacity-significant-tail.json" --dry-run --json >"$TMP/capacity-significant-tail.out"
tail_rc=$?
set -e
[[ "$tail_rc" -eq 1 ]] && pass "capacity_significant_tail_returns_1" || fail "capacity_significant_tail_returns_1"
assert_jq "$TMP/capacity-significant-tail.out" '.panes[0].subclass == "model_at_capacity_halt" and .panes[0].recommended_recovery == "auto_continue"' "capacity_significant_tail_string_match"

write_fixture "$TMP/chevron-negative.json" \
  $'Normal prompt text.\n\n› Implement {feature}\n\n  gpt-5.5 xhigh · ~/Developer/flywheel' \
  $'Normal prompt text.\n\n› Implement {feature}\n\n  gpt-5.5 xhigh · ~/Developer/flywheel'
set +e
"$SCRIPT" --fixture "$TMP/chevron-negative.json" --dry-run --json >"$TMP/chevron-negative.out"
negative_rc=$?
set -e
[[ "$negative_rc" -eq 1 ]] && pass "negative_existing_buffer_rc1" || fail "negative_existing_buffer_rc1"
assert_jq "$TMP/chevron-negative.out" '.panes[0].subclass != "model_at_capacity_halt"' "chevron_non_capacity_not_capacity"

printf 'Capacity wrapper summary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
