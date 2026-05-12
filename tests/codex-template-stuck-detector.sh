#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/codex-template-stuck-detector.sh"
CAPACITY_FIXTURES="$ROOT/.flywheel/tests/fixtures/capacity-halt-validation"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/codex-template-stuck-detector-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" || true
  fi
}

fixture() {
  local path="$1" session="$2" pane="$3" t0="$4" t1="$5" after="${6:-}" hint="${7:-}" send_ack="${8:-true}"
  jq -nc \
    --arg session "$session" \
    --argjson pane "$pane" \
    --arg t0 "$t0" \
    --arg t1 "$t1" \
    --arg after "$after" \
    --arg hint "$hint" \
    --argjson send_ack "$send_ack" \
    '{
      schema_version:"codex-stuck-detector.fixture.v1",
      session:$session,
      pane:$pane,
      t0:$t0,
      t1:$t1,
      send_ack:$send_ack
    }
    + (if $after != "" then {after_retry:$after} else {} end)
    + (if $hint != "" then {subclass_hint:$hint} else {} end)' >"$path"
}

export CODEX_STUCK_DETECTOR_LEDGER="$TMP/detector.jsonl"
export CODEX_STUCK_DETECTOR_CONTRACT_LEDGER="$TMP/contract.jsonl"
export CODEX_STUCK_DETECTOR_FUCKUP_LOG="$TMP/fuckup.jsonl"
export CODEX_STUCK_DETECTOR_NOW="2026-05-05T04:40:00Z"

cat >"$TMP/fake-capacity-auto-continue.sh" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${FAKE_CAPACITY_AUTO_CONTINUE_LOG:?}"
jq -nc '{schema_version:"capacity-halt-auto-continue.result.v1",status:"fired_success",fired:true,attempted:true,sent:true,recovered:true,transport_rc:0,success_measurement:{payload:{verdict:"success"}}}'
SH
chmod +x "$TMP/fake-capacity-auto-continue.sh"
export FAKE_CAPACITY_AUTO_CONTINUE_LOG="$TMP/capacity-auto-continue.log"

bash -n "$SCRIPT" && pass "detector_syntax" || fail "detector_syntax"
grep -F -- '[ntm_bin, "send", session, f"--pane={pane}", "--no-cass-check", "\n"]' "$SCRIPT" >/dev/null \
  && pass "detector_enter_retry_no_cass_check_argv_order" || fail "detector_enter_retry_no_cass_check_argv_order"

"$SCRIPT" --doctor --json >"$TMP/doctor.out"
assert_jq "$TMP/doctor.out" '.schema_version == "codex-stuck-detector.doctor.v1" and .codex_template_stuck_count_24h == 0 and .substrate_loop_contract_self_row_action == "appended"' "doctor_bootstraps_contract"
assert_jq "$CODEX_STUCK_DETECTOR_CONTRACT_LEDGER" '.primitive_name == "codex-stuck-detector" and .measurement_field == "codex_template_stuck_count_24h"' "contract_self_row_written"

fixture "$TMP/buffer.json" "flywheel" 2 $'› Implement {feature}\n  gpt-5.5 xhigh · ~/Developer/flywheel' $'› Implement {feature}\n  gpt-5.5 xhigh · ~/Developer/flywheel'
set +e
"$SCRIPT" --fixture "$TMP/buffer.json" --json >"$TMP/buffer.out"
buffer_rc=$?
set -e
[[ "$buffer_rc" -eq 1 ]] && pass "buffer_stuck_returns_1" || fail "buffer_stuck_returns_1"
assert_jq "$TMP/buffer.out" '.stuck_count == 1 and .panes[0].subclass == "buffer_stuck" and .panes[0].hash_stable == true and .panes[0].recommended_recovery == "enter_newline_then_respawn_if_still_stuck"' "buffer_stuck_classified"

capacity_t0="$(<"$CAPACITY_FIXTURES/codex-pane-capacity-halt-t0.txt")"
capacity_t1="$(<"$CAPACITY_FIXTURES/codex-pane-capacity-halt-t1.txt")"
fixture "$TMP/capacity-selected.json" "flywheel" 4 "$capacity_t0" "$capacity_t1"
set +e
"$SCRIPT" --fixture "$TMP/capacity-selected.json" --json >"$TMP/capacity-selected.out"
capacity_selected_rc=$?
set -e
[[ "$capacity_selected_rc" -eq 1 ]] && pass "capacity_selected_returns_1" || fail "capacity_selected_returns_1"
assert_jq "$TMP/capacity-selected.out" '.stuck_count == 1 and .panes[0].subclass == "model_at_capacity_halt" and .panes[0].hash_stable == true and .panes[0].recommended_recovery == "auto_continue"' "capacity_selected_classified"

set +e
CODEX_STUCK_DETECTOR_CAPACITY_AUTO_CONTINUE="$TMP/fake-capacity-auto-continue.sh" \
  "$SCRIPT" --fixture "$TMP/capacity-selected.json" --auto-recover --apply --json >"$TMP/capacity-recover.out"
capacity_recover_rc=$?
set -e
[[ "$capacity_recover_rc" -eq 1 ]] && pass "capacity_recover_returns_1" || fail "capacity_recover_returns_1"
assert_jq "$TMP/capacity-recover.out" '.panes[0].subclass == "model_at_capacity_halt" and .panes[0].recovery_attempted == "capacity_halt_auto_continue" and .panes[0].recovery_succeeded == true and .panes[0].recovery_payload.recovered == true' "capacity_auto_continue_invoked"
grep -q -- '--session flywheel --pane 4 --digest' "$FAKE_CAPACITY_AUTO_CONTINUE_LOG" && pass "capacity_auto_continue_args" || fail "capacity_auto_continue_args"

fixture "$TMP/capacity-try-different.json" "flywheel" 4 $'please try a different model.\n\n›\n\n  gpt-5.5 xhigh · ~/Developer/flywheel' $'please try a different model.\n\n›\n\n  gpt-5.5 xhigh · ~/Developer/flywheel'
set +e
"$SCRIPT" --fixture "$TMP/capacity-try-different.json" --json >"$TMP/capacity-try-different.out"
capacity_try_rc=$?
set -e
[[ "$capacity_try_rc" -eq 1 ]] && pass "capacity_try_different_returns_1" || fail "capacity_try_different_returns_1"
assert_jq "$TMP/capacity-try-different.out" '.panes[0].subclass == "model_at_capacity_halt" and .panes[0].recommended_recovery == "auto_continue"' "capacity_try_different_classified"

fixture "$TMP/chevron-alone.json" "flywheel" 4 $'›\n\n  gpt-5.5 xhigh · ~/Developer/flywheel' $'›\n\n  gpt-5.5 xhigh · ~/Developer/flywheel'
set +e
"$SCRIPT" --fixture "$TMP/chevron-alone.json" --json >"$TMP/chevron-alone.out"
chevron_alone_rc=$?
set -e
[[ "$chevron_alone_rc" -eq 0 ]] && pass "chevron_alone_alive_rc0" || fail "chevron_alone_alive_rc0"
assert_jq "$TMP/chevron-alone.out" '.panes[0].subclass != "model_at_capacity_halt" and .panes[0].subclass == "alive" and .panes[0].recommended_recovery == "none"' "chevron_alone_alive_not_capacity"

fixture "$TMP/post.json" "flywheel" 2 $'Working (14m 08s • esc to interrupt)\nfinished output' $'Working (14m 08s • esc to interrupt)\nfinished output'
set +e
"$SCRIPT" --fixture "$TMP/post.json" --auto-recover --apply --json >"$TMP/post.out"
post_rc=$?
set -e
[[ "$post_rc" -eq 1 ]] && pass "post_completion_returns_1" || fail "post_completion_returns_1"
assert_jq "$TMP/post.out" '.panes[0].subclass == "post_completion" and .panes[0].recovery_attempted == "none" and .panes[0].recommended_recovery == "/flywheel:respawn_after_snapshot"' "post_completion_no_auto_recover"

fixture "$TMP/alive.json" "flywheel" 2 "line one" "line two"
"$SCRIPT" --fixture "$TMP/alive.json" --apply --json >"$TMP/alive.out"
assert_jq "$TMP/alive.out" '.status == "ok" and .stuck_count == 0 and .panes[0].subclass == "alive" and .panes[0].hash_stable == false' "active_output_alive"

fixture "$TMP/deaf.json" "skillos" 1 $'› Use /skills to list available skills\n  gpt-5.5 xhigh · ~/Developer/skillos' $'› Use /skills to list available skills\n  gpt-5.5 xhigh · ~/Developer/skillos' $'› Use /skills to list available skills\n  gpt-5.5 xhigh · ~/Developer/skillos'
set +e
"$SCRIPT" --fixture "$TMP/deaf.json" --auto-recover --apply --json >"$TMP/deaf.out"
deaf_rc=$?
set -e
[[ "$deaf_rc" -eq 1 ]] && pass "input_deaf_returns_1" || fail "input_deaf_returns_1"
assert_jq "$TMP/deaf.out" '.panes[0].subclass == "input_deaf" and .panes[0].recovery_attempted == "enter_newline" and .panes[0].recovery_succeeded == false and .panes[0].recommended_recovery == "/flywheel:respawn_after_peer_orch_recovery_gate"' "input_deaf_after_failed_enter_retry"

if [[ "$(wc -l <"$CODEX_STUCK_DETECTOR_LEDGER" | tr -d ' ')" -eq 4 ]]; then
  pass "ledger_writes_for_apply_runs"
else
  fail "ledger_writes_for_apply_runs"
  cat "$CODEX_STUCK_DETECTOR_LEDGER" || true
fi

assert_jq "$CODEX_STUCK_DETECTOR_FUCKUP_LOG" '.class == "codex-input-deaf" and .bead == "flywheel-mk303"' "input_deaf_fuckup_logged"

"$SCRIPT" --doctor --json >"$TMP/doctor-after.out"
assert_jq "$TMP/doctor-after.out" '.codex_template_stuck_count_24h == 3 and .codex_stuck_subclass_top != null and .codex_stuck_top_session != null and (.codex_stuck_recovery_success_pct == 50)' "doctor_reports_four_fields"

"$SCRIPT" validate fixture --fixture "$TMP/buffer.json" --json >"$TMP/validate-fixture.out"
assert_jq "$TMP/validate-fixture.out" '.status == "ok" and .target == "fixture"' "fixture_validate_ok"

printf '\nFixture subclasses: 7/7 passed\n'
printf 'Summary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
