#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
DETECTOR="$ROOT/.flywheel/scripts/continuous-productivity-detector.sh"
INSTALL="$ROOT/.flywheel/scripts/continuous-productivity-detector-install.sh"
FIX="$ROOT/.flywheel/tests/fixtures/continuous-productivity"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/continuous-productivity-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
pass_count=0
fail_count=0
case_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }
assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}
run_case() {
  local name="$1" want="$2" out
  out="$TMP/$name.json"
  set +e
  "$DETECTOR" \
    --loops-dir "$FIX/$name/loops" \
    --topology "$FIX/$name/topology.jsonl" \
    --activity-dir "$FIX/$name/activity" \
    --ready-dir "$FIX/$name/ready" \
    --doctor-dir "$FIX/$name/doctor" \
    --now-epoch 500 \
    --json >"$out"
  local rc=$?
  set -e
  case_count=$((case_count + 1))
  if [[ "$rc" -eq "$want" ]]; then pass "$name rc=$want"; else fail "$name rc=$rc want=$want"; fi
  CASE_OUT="$out"
}
bash -n "$DETECTOR" && pass "detector_syntax"
bash -n "$INSTALL" && pass "install_syntax"
grep -F -- '"$NTM" send "$session" --pane="$pane" --no-cass-check --file "$prompt"' "$INSTALL" >/dev/null \
  && pass "installer_xpane_send_no_cass_check_argv_order" || fail "installer_xpane_send_no_cass_check_argv_order"
"$DETECTOR" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.read_only == true and .peer_repo_writes == false and (.canonical_cli | index("--quiet")) and (.joshua_notify_allowlist | index("substrate-corrupt"))' "info_contract"
"$DETECTOR" --examples --json >"$TMP/examples.json"
assert_jq "$TMP/examples.json" '(.examples | length) >= 3' "examples_contract"
run_case productive 0
out="$CASE_OUT"
assert_jq "$out" '.action_required_count == 0 and .sessions[0].productivity_state == "productive"' "productive_no_escalation"
run_case idle-findings 1
out="$CASE_OUT"
assert_jq "$out" '.idle_with_work_available_count == 1 and .sessions[0].planned_actions[0].type == "xpane_productivity_escalation"' "idle_escalation_action"
assert_jq "$out" '(.sessions[0].planned_actions[0].message | split("\n") | map(select(test("^[123]\\. "))) | length) == 3' "idle_escalation_three_instructions"
run_case workers-busy 0
out="$CASE_OUT"
assert_jq "$out" '.action_required_count == 0 and .sessions[0].workers_active == 1' "busy_workers_no_escalation"
run_case no-findings 0
out="$CASE_OUT"
assert_jq "$out" '.action_required_count == 0 and .sessions[0].findings_count == 0' "empty_findings_no_escalation"
run_case substrate-corrupt 1
out="$CASE_OUT"
assert_jq "$out" '.josh_notify_allowlisted_count == 1 and .sessions[0].planned_actions[0].type == "josh_notify" and .sessions[0].planned_actions[0].allowlist_class == "substrate-corrupt"' "substrate_corrupt_notify_allowlisted"
mkdir -p "$TMP/bin" "$TMP/home/Library/LaunchAgents" "$TMP/logs"
cat >"$TMP/bin/launchctl" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${FAKE_LAUNCHCTL_LOG:?}"
exit 0
SH
chmod +x "$TMP/bin/launchctl"
cat >"$TMP/bin/ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${FAKE_NTM_LOG:?}"
exit 0
SH
chmod +x "$TMP/bin/ntm"
cat >"$TMP/bin/notify" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${FAKE_NOTIFY_LOG:?}"
exit 0
SH
chmod +x "$TMP/bin/notify"
cat >"$TMP/bin/flywheel-watchers" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${FAKE_WATCHERS_LOG:?}"
exit 0
SH
chmod +x "$TMP/bin/flywheel-watchers"
FAKE_LAUNCHCTL_LOG="$TMP/launchctl.log" \
FAKE_WATCHERS_LOG="$TMP/watchers.log" \
CPD_LAUNCHCTL="$TMP/bin/launchctl" \
CPD_WATCHERS_BIN="$TMP/bin/flywheel-watchers" \
CPD_LAUNCH_AGENTS_DIR="$TMP/home/Library/LaunchAgents" \
CPD_LEDGER="$TMP/install-ledger.jsonl" \
  "$INSTALL" --apply --json >"$TMP/install.json"
assert_jq "$TMP/install.json" '.gui_domain == true and .would_bootstrap == true and .interval_seconds == 300' "installer_gui_domain"
grep -q "bootstrap gui/" "$TMP/launchctl.log" && pass "installer_bootstrap_gui" || fail "installer_bootstrap_gui"
grep -q "register --label ai.zeststream.continuous-productivity-detector" "$TMP/watchers.log" && pass "installer_registers_watcher" || fail "installer_registers_watcher"
FAKE_NTM_LOG="$TMP/ntm.log" \
FAKE_NOTIFY_LOG="$TMP/notify.log" \
PATH="$TMP/bin:$PATH" \
CPD_NTM="$TMP/bin/ntm" \
CPD_LEDGER="$TMP/run-ledger.jsonl" \
CPD_DETECTOR="$DETECTOR" \
CPD_LOOPS_DIR="$FIX/idle-findings/loops" \
CPD_TOPOLOGY="$FIX/idle-findings/topology.jsonl" \
CPD_ACTIVITY_DIR="$FIX/idle-findings/activity" \
CPD_READY_DIR="$FIX/idle-findings/ready" \
CPD_DOCTOR_DIR="$FIX/idle-findings/doctor" \
CPD_NOW_EPOCH=500 \
  "$INSTALL" --run-once --json --quiet || runner_rc=$?
runner_rc="${runner_rc:-0}"
[[ "$runner_rc" -eq 1 ]] && pass "runner_escalation_rc" || fail "runner_escalation_rc=$runner_rc"
assert_jq "$TMP/run-ledger.jsonl" 'select(.event == "continuous_productivity_action" and .action.type == "xpane_productivity_escalation" and .action.target_pane == 1)' "runner_ledger_xpane"
grep -q "send idlecase --pane=1" "$TMP/ntm.log" && pass "runner_sends_orchestrator_pane" || fail "runner_sends_orchestrator_pane"
grep -F -- "send idlecase --pane=1 --no-cass-check --file" "$TMP/ntm.log" >/dev/null \
  && pass "runner_xpane_send_bypasses_cass_before_file" || fail "runner_xpane_send_bypasses_cass_before_file"
if grep -q -- "--pane=2" "$TMP/ntm.log"; then fail "runner_sent_worker_pane"; else pass "runner_never_sends_worker_pane"; fi
if [[ "$case_count" -ne 5 ]]; then fail "case_count=$case_count"; fi
if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY cases=%d pass=%d fail=%d\n' "$case_count" "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'PASS cases=%d assertions=%d failures=0\n' "$case_count" "$pass_count"
