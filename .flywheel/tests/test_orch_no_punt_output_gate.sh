#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="${SCRIPT_UNDER_TEST:-$ROOT/.flywheel/scripts/orch-no-punt-output-gate.sh}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/orch-no-punt-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

WAITING="$TMP/waiting.json"
IDLE="$TMP/idle.json"
LEDGER="$TMP/orch-no-punt-log.jsonl"
PASS_COUNT=0

cat >"$WAITING" <<'JSON'
{"agents":[{"pane_idx":2,"state":"WAITING"},{"pane_idx":3,"state":"THINKING"}]}
JSON

cat >"$IDLE" <<'JSON'
{"agents":[{"pane_idx":2,"state":"THINKING"},{"pane_idx":3,"state":"CLOSED"}]}
JSON

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  printf 'ok %02d - %s\n' "$PASS_COUNT" "$1"
}

run_json_case() {
  local name="$1" mode="$2" activity="$3" expected_rc="$4" expected_decision="$5" expected_reason="$6" expected_blocker="${7:-}"
  local text="$8" out="$TMP/$name.out" err="$TMP/$name.err" rc
  set +e
  printf '%s' "$text" | ORCH_NO_PUNT_ACTIVITY_FILE="$activity" \
    FLYWHEEL_ORCH_NO_PUNT_LOG="$LEDGER" \
    bash "$SCRIPT" --mode "$mode" --text-stdin --json >"$out" 2>"$err"
  rc=$?
  set -e
  [[ "$rc" -eq "$expected_rc" ]] || fail "$name rc=$rc expected=$expected_rc stderr=$(cat "$err")"
  jq -e . "$out" >/dev/null || fail "$name emitted invalid JSON"
  jq -e --arg d "$expected_decision" --arg r "$expected_reason" '.decision == $d and .reason == $r' "$out" >/dev/null \
    || fail "$name decision/reason mismatch: $(cat "$out")"
  if [[ -n "$expected_blocker" ]]; then
    jq -e --arg b "$expected_blocker" '.blocker_class_matched == $b' "$out" >/dev/null \
      || fail "$name blocker mismatch: $(cat "$out")"
  fi
  pass "$name"
}

run_passthrough_case() {
  local name="$1" mode="$2" expected_rc="$3" expected_decision="$4" text="$5"
  local out="$TMP/$name.out" err="$TMP/$name.err" before after rc
  before="$(wc -l <"$LEDGER" 2>/dev/null || printf '0')"
  set +e
  printf '%s' "$text" | ORCH_NO_PUNT_ACTIVITY_FILE="$WAITING" \
    FLYWHEEL_ORCH_NO_PUNT_LOG="$LEDGER" \
    bash "$SCRIPT" --mode "$mode" --text-stdin >"$out" 2>"$err"
  rc=$?
  set -e
  [[ "$rc" -eq "$expected_rc" ]] || fail "$name rc=$rc expected=$expected_rc stderr=$(cat "$err")"
  [[ "$(cat "$out")" == "$text" ]] || fail "$name did not preserve stdout"
  after="$(wc -l <"$LEDGER")"
  [[ "$after" -gt "$before" ]] || fail "$name did not append ledger row"
  tail -n 1 "$LEDGER" | jq -e --arg d "$expected_decision" '.decision == $d' >/dev/null \
    || fail "$name ledger decision mismatch"
  if [[ "$mode" == "refuse" ]]; then
    grep -q "TRUE Joshua-blocker classes" "$err" || fail "$name stderr missing blocker-class guidance"
  fi
  pass "$name"
}

[[ -x "$SCRIPT" ]] || fail "script not executable"
bash "$SCRIPT" --info | jq -e '.schema_version == "orch-no-punt-decision/v2"' >/dev/null \
  || fail "--info schema mismatch"

run_json_case new_vendor refuse "$WAITING" 0 allow true_joshua_blocker \
  new-platform-or-vendor-not-in-mission-lock \
  "Should I deploy to Render even though this is a new vendor not in mission? /tmp/dispatch_vendor.md"

run_json_case secret_rotation refuse "$WAITING" 0 allow true_joshua_blocker \
  secret-rotation-or-new-credential-creation \
  "Do you want me to rotate the Vercel API key and create new token for flywheel-secret?"

run_json_case financial_commitment refuse "$WAITING" 0 allow true_joshua_blocker \
  financial-commitment-above-mission-budget \
  "options: upgrade to Supabase Pro plan for \$25 over mission budget; tests/budget.sh"

run_json_case legal_compliance refuse "$WAITING" 0 allow true_joshua_blocker \
  legal-or-compliance-decision \
  "my pick: accept the DPA and terms of service for flywheel-contract"

run_json_case destructive_shared_state refuse "$WAITING" 0 allow true_joshua_blocker \
  destructive-irreversible-on-shared-state \
  "Want me to drop production database and force push? .flywheel/scripts/drop.sh"

run_json_case paradigm_conflict refuse "$WAITING" 0 allow true_joshua_blocker \
  paradigm-conflict-with-active-mission \
  "my read: rewrite mission anchor; this is a paradigm conflict with active mission. flywheel-paradigm"

run_json_case punt_want_me refuse "$WAITING" 1 refuse punt_pattern_with_waiting_worker_and_fix_signal "" \
  "Want me to dispatch /tmp/dispatch_ship.md now."

run_json_case punt_should_i refuse "$WAITING" 1 refuse punt_pattern_with_waiting_worker_and_fix_signal "" \
  "Should I wire .flywheel/scripts/foo.sh next?"

run_json_case punt_do_you_want refuse "$WAITING" 1 refuse punt_pattern_with_waiting_worker_and_fix_signal "" \
  "Do you want me to close flywheel-abc after OK_gate?"

run_json_case punt_options refuse "$WAITING" 1 refuse punt_pattern_with_waiting_worker_and_fix_signal "" \
  "options: patch tests/foo.sh now"

run_json_case punt_my_pick refuse "$WAITING" 1 refuse punt_pattern_with_waiting_worker_and_fix_signal "" \
  "my pick: fix flywheel-abc"

run_json_case punt_my_read refuse "$WAITING" 1 refuse punt_pattern_with_waiting_worker_and_fix_signal "" \
  "my read: append .flywheel/tests/foo.sh"

run_json_case empty_input refuse "$WAITING" 0 allow no_punt_pattern "" ""

run_json_case no_waiting_pane refuse "$IDLE" 0 allow no_waiting_worker_pane "" \
  "Should I wire .flywheel/scripts/foo.sh next?"

run_json_case no_fix_signal refuse "$WAITING" 0 allow no_fix_signal "" \
  "Should I keep working on the problem?"

run_passthrough_case warn_mode_passes_through warn 0 warn \
  "Should I wire .flywheel/scripts/foo.sh next?"

run_passthrough_case refuse_mode_blocks_with_guidance refuse 1 refuse \
  "Should I wire .flywheel/scripts/foo.sh next?"

[[ "$PASS_COUNT" -eq 17 ]] || fail "expected 17 cases, saw $PASS_COUNT"
printf 'PASS: %d/17 orch-no-punt-output-gate cases\n' "$PASS_COUNT"
