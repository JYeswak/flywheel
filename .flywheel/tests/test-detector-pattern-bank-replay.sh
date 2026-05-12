#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/codex-template-stuck-detector.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/detector-pattern-bank-replay.XXXXXX")"
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

first_glob() {
  compgen -G "$1" | grep -v '\.detector\.json$' | sort | tail -1 || true
}

first_stale_spinner_glob() {
  local path
  while IFS= read -r path; do
    if jq -r '.panes["2"].lines[]?' "$path" 2>/dev/null | rg -q 'Working \(|Waiting for background terminal'; then
      printf '%s\n' "$path"
      return 0
    fi
  done < <(compgen -G "$1" | grep -v '\.detector\.json$' | sort -r)
  return 1
}

run_detector_allow_stuck() {
  local fixture="$1" out="$2" rc
  set +e
  CODEX_STUCK_DETECTOR_LEDGER="$TMP/detector.jsonl" \
  CODEX_STUCK_DETECTOR_CONTRACT_LEDGER="$TMP/contract.jsonl" \
  CODEX_STUCK_DETECTOR_FUCKUP_LOG="$TMP/fuckup.jsonl" \
  CODEX_STUCK_DETECTOR_SNAPSHOT_DIR="$TMP/snapshots" \
    "$SCRIPT" --fixture "$fixture" --json >"$out"
  rc=$?
  set -e
  [[ "$rc" -eq 1 ]]
}

fixture() {
  local path="$1" t0="$2" t1="$3" after="${4:-}" hint="${5:-}" send_ack="${6:-true}"
  jq -nc \
    --arg t0 "$t0" \
    --arg t1 "$t1" \
    --arg after "$after" \
    --arg hint "$hint" \
    --argjson send_ack "$send_ack" \
    '{schema_version:"codex-stuck-detector.fixture.v1",session:"fixture",pane:2,t0:$t0,t1:$t1,send_ack:$send_ack}
     + (if $after != "" then {after_retry:$after} else {} end)
     + (if $hint != "" then {subclass_hint:$hint} else {} end)' >"$path"
}

bash -n "$SCRIPT" && pass "detector_syntax" || fail "detector_syntax"

pane4="/tmp/golden-artifact-pane4-post-callback-reminder-stale-spinner-2026-05-05T23-19Z.json"
pane2="/tmp/golden-artifact-pane2-post-callback-reminder-stale-spinner-2026-05-05T23-30Z.json"
live_pane2="/tmp/flywheel-pane2-snapshot.20260505T235808Z.json"
live_pane3="/tmp/flywheel-pane3-snapshot.20260505T205900Z.json"
live_pane2_20260506="$(first_stale_spinner_glob '/tmp/flywheel-pane2-snapshot.20260506T*.json' || true)"
mobile_pane2_20260506="$(first_glob '/tmp/mobile-eats-pane2-snapshot.20260506T*.json')"
test -f "$pane4" && pass "pane4_fixture_present" || fail "pane4_fixture_present"
test -f "$pane2" && pass "pane2_fixture_present" || fail "pane2_fixture_present"
test -f "$live_pane2" && pass "live_pane2_snapshot_present" || fail "live_pane2_snapshot_present"
test -f "$live_pane3" && pass "live_pane3_snapshot_present" || fail "live_pane3_snapshot_present"
[[ -n "$live_pane2_20260506" ]] && pass "live_pane2_20260506_snapshot_present" || pass "live_pane2_20260506_snapshot_absent"
[[ -n "$mobile_pane2_20260506" ]] && pass "mobile_pane2_20260506_snapshot_present" || pass "mobile_pane2_20260506_snapshot_absent"

if run_detector_allow_stuck "$pane4" "$TMP/pane4.out"; then pass "pane4_returns_stuck"; else fail "pane4_returns_stuck"; fi
assert_jq "$TMP/pane4.out" '.panes[0].subclass != "unknown_stable" and .panes[0].subclass == "post_callback_reminder_template_with_stale_spinner" and .panes[0].auto_recover == true and .panes[0].recommended_recovery == "escape_then_reprompt_or_respawn" and .panes[0].buffer_signal == "stale_background_spinner_with_reminder_template"' "pane4_classified_post_callback_spinner"

if run_detector_allow_stuck "$pane2" "$TMP/pane2.out"; then pass "pane2_returns_stuck"; else fail "pane2_returns_stuck"; fi
assert_jq "$TMP/pane2.out" '.panes[0].subclass != "unknown_stable" and .panes[0].subclass == "post_callback_reminder_template_with_stale_spinner" and .panes[0].auto_recover == true and .panes[0].recommended_recovery == "escape_then_reprompt_or_respawn" and .panes[0].buffer_signal == "stale_background_spinner_with_reminder_template"' "pane2_classified_post_callback_spinner"

if run_detector_allow_stuck "$live_pane2" "$TMP/live-pane2.out"; then pass "live_pane2_returns_stuck"; else fail "live_pane2_returns_stuck"; fi
assert_jq "$TMP/live-pane2.out" '.panes[0].subclass == "post_callback_reminder_template_with_stale_spinner" and .panes[0].buffer_signal == "stale_background_spinner_with_reminder_template"' "live_pane2_truncated_spinner_classified"

if run_detector_allow_stuck "$live_pane3" "$TMP/live-pane3.out"; then pass "live_pane3_returns_stuck"; else fail "live_pane3_returns_stuck"; fi
assert_jq "$TMP/live-pane3.out" '.panes[0].subclass == "codex_queued_not_submitted" and .panes[0].recommended_recovery == "bare_enter" and .panes[0].buffer_signal == "stale_background_spinner_with_reminder_template"' "live_pane3_current_review_classified"

if [[ -n "$live_pane2_20260506" ]]; then
  if run_detector_allow_stuck "$live_pane2_20260506" "$TMP/live-pane2-20260506.out"; then pass "live_pane2_20260506_returns_stuck"; else fail "live_pane2_20260506_returns_stuck"; fi
  assert_jq "$TMP/live-pane2-20260506.out" '.panes[0].subclass == "post_callback_reminder_template_with_stale_spinner" and .panes[0].buffer_signal == "stale_background_spinner_with_reminder_template"' "live_pane2_20260506_classified"
fi

if [[ -n "$mobile_pane2_20260506" ]]; then
  if run_detector_allow_stuck "$mobile_pane2_20260506" "$TMP/mobile-pane2-20260506.out"; then pass "mobile_pane2_20260506_returns_stuck"; else fail "mobile_pane2_20260506_returns_stuck"; fi
  assert_jq "$TMP/mobile-pane2-20260506.out" '.panes[0].subclass == "codex_queued_not_submitted" and .panes[0].recommended_recovery == "bare_enter" and .panes[0].buffer_signal == "stale_background_spinner_with_reminder_template"' "mobile_pane2_20260506_classified"
fi

fixture "$TMP/buffer.json" $'› Implement {feature}\n  gpt-5.5 xhigh' $'› Implement {feature}\n  gpt-5.5 xhigh'
if run_detector_allow_stuck "$TMP/buffer.json" "$TMP/buffer.out"; then pass "buffer_returns_stuck"; else fail "buffer_returns_stuck"; fi
assert_jq "$TMP/buffer.out" '.panes[0].subclass == "buffer_stuck"' "existing_buffer_stuck_classified"

fixture "$TMP/post.json" $'Working (14m 08s • esc to interrupt)\nfinished output' $'Working (14m 08s • esc to interrupt)\nfinished output'
if run_detector_allow_stuck "$TMP/post.json" "$TMP/post.out"; then pass "post_returns_stuck"; else fail "post_returns_stuck"; fi
assert_jq "$TMP/post.out" '.panes[0].subclass == "post_completion"' "existing_post_completion_classified"

fixture "$TMP/deaf.json" $'› Use /skills to list available skills\n  gpt-5.5 xhigh' $'› Use /skills to list available skills\n  gpt-5.5 xhigh' $'› Use /skills to list available skills\n  gpt-5.5 xhigh'
set +e
CODEX_STUCK_DETECTOR_LEDGER="$TMP/detector.jsonl" \
CODEX_STUCK_DETECTOR_CONTRACT_LEDGER="$TMP/contract.jsonl" \
CODEX_STUCK_DETECTOR_FUCKUP_LOG="$TMP/fuckup.jsonl" \
  "$SCRIPT" --fixture "$TMP/deaf.json" --auto-recover --apply --json >"$TMP/deaf.out"
deaf_rc=$?
set -e
[[ "$deaf_rc" -eq 1 ]] && pass "input_deaf_returns_stuck" || fail "input_deaf_returns_stuck"
assert_jq "$TMP/deaf.out" '.panes[0].subclass == "input_deaf"' "existing_input_deaf_classified"

fixture "$TMP/alive.json" "line one" "line two"
CODEX_STUCK_DETECTOR_LEDGER="$TMP/detector.jsonl" "$SCRIPT" --fixture "$TMP/alive.json" --json >"$TMP/alive.out"
assert_jq "$TMP/alive.out" '.panes[0].subclass == "alive" and .stuck_count == 0' "existing_alive_classified"

fixture "$TMP/unknown.json" "stable but no known signal" "stable but no known signal"
set +e
CODEX_STUCK_DETECTOR_LEDGER="$TMP/detector.jsonl" "$SCRIPT" --fixture "$TMP/unknown.json" --json >"$TMP/unknown.out"
unknown_rc=$?
set -e
[[ "$unknown_rc" -eq 2 && -s "$TMP/unknown.out" ]] && pass "unknown_stable_returns_2_with_json" || fail "unknown_stable_returns_2_with_json"
assert_jq "$TMP/unknown.out" '.status == "unknown_stable" and .panes[0].subclass == "unknown_stable" and .stuck_count == 0 and .unknown_stable_count == 1' "existing_unknown_stable_preserved"

set +e
CODEX_STUCK_DETECTOR_LEDGER="$TMP/unknown-ledger.jsonl" \
CODEX_STUCK_DETECTOR_CONTRACT_LEDGER="$TMP/unknown-contract.jsonl" \
CODEX_STUCK_DETECTOR_FUCKUP_LOG="$TMP/unknown-fuckup.jsonl" \
CODEX_STUCK_DETECTOR_SNAPSHOT_DIR="$TMP/snapshots" \
  "$SCRIPT" --fixture "$TMP/unknown.json" --apply --json >"$TMP/unknown-apply.out"
unknown_apply_rc=$?
set -e
[[ "$unknown_apply_rc" -eq 2 && -s "$TMP/unknown-apply.out" ]] && pass "unknown_apply_returns_2_with_json" || fail "unknown_apply_returns_2_with_json"
assert_jq "$TMP/unknown-fuckup.jsonl" '.class == "detector_silent_exit2" and .bead == "flywheel-detector-silent-exit2-166f" and .parent_bead == "flywheel-2h3vs" and (.pane_capture_path | length > 0)' "unknown_stable_logs_detector_silent_exit2"
snapshot_path="$(jq -r '.pane_capture_path' "$TMP/unknown-fuckup.jsonl")"
test -f "$snapshot_path" && pass "unknown_stable_snapshot_written" || fail "unknown_stable_snapshot_written"

printf 'Summary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
