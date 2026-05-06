#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/worker-auto-respawn-watchdog.sh"
INSTALLER="$ROOT/.flywheel/scripts/worker-auto-respawn-watchdog-install.sh"
BASE_FIXTURES="$ROOT/.flywheel/tests/fixtures/auto-respawn-watchdog"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/worker-auto-respawn-watchdog-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
CAPACITY_DIGEST="cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"

pass() { printf 'PASS %s\n' "$1" >&2; pass_count=$((pass_count + 1)); }
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

write_topology() {
  local path="$1" session="${2:-fixture}"
  jq -nc --arg session "$session" \
    '{session:$session,worker_panes:[2,3],worker_kinds:{"2":"codex","3":"codex"},
      orchestrator_pane:1,human_pane:0,callback_pane:4,effective_at:"2026-05-06T03:00:00Z"}' >"$path"
}

seed_attempt() {
  local path="$1" session="$2" pane="$3" epoch="$4" attempt="$5"
  local action="${6:-respawn_attempt}"
  jq -nc --arg ts "2026-05-06T03:00:00Z" --argjson epoch "$epoch" \
    --arg session "$session" --argjson pane "$pane" --argjson attempt "$attempt" --arg action "$action" \
    '{ts:$ts,epoch:$epoch,action:$action,session:$session,pane:$pane,
      attempt_number:$attempt,reason:"seed"}' >>"$path"
}

run_case() {
  local name="$1" expected_rc="$2" out rc
  out="$TMP/$name.out"
  shift 2
  set +e
  WORKER_AUTO_RESPAWN_NOW_EPOCH=1778036400 \
  WORKER_AUTO_RESPAWN_RESPAWN_CMD="$TMP/fake-respawn.sh" \
  WORKER_AUTO_RESPAWN_NTM_BIN="$TMP/fake-ntm.sh" \
  WORKER_AUTO_RESPAWN_NOTIFY_CMD="$TMP/fake-notify.sh" \
	  WORKER_AUTO_RESPAWN_CAPACITY_LEASE="$ROOT/.flywheel/scripts/capacity-halt-lease-primitive.sh" \
	  CAPACITY_HALT_AUTH_TOPOLOGY="${topology:-}" \
	  CAPACITY_HALT_AUTH_NOW_EPOCH=1778036400 \
	  CAPACITY_HALT_BUDGET_LEDGER="${attempts:-$TMP/capacity-budget.jsonl}" \
	  CAPACITY_HALT_BUDGET_NOW_EPOCH=1778036400 \
	  CAPACITY_HALT_AUTO_CONTINUE_NOTIFY_BIN="$TMP/fake-notify.sh" \
	  CAPACITY_HALT_AUTO_CONTINUE_FALLBACK_LEDGER="$TMP/capacity-fallback.jsonl" \
	  CAPACITY_HALT_AUTO_CONTINUE_SUCCESS_MEASUREMENT="$TMP/fake-success-measurement.sh" \
  CAPACITY_HALT_LEASE_LEDGER="$TMP/capacity-lease.jsonl" \
  CAPACITY_HALT_LEASE_NOW_EPOCH=1778036400 \
    "$SCRIPT" "$@" --json >"$out" 2>"$TMP/$name.err"
  rc=$?
  set -e
  if [[ "$rc" -eq "$expected_rc" ]]; then
    pass "$name rc=$expected_rc"
  else
    fail "$name rc expected=$expected_rc actual=$rc"
    cat "$TMP/$name.err" >&2 || true
    jq . "$out" >&2 || true
  fi
  printf '%s\n' "$out"
}

copy_fixture() {
  local fixture_dir="$1" session="$2" pane="$3" kind="$4"
  cp "$BASE_FIXTURES/$kind.json" "$fixture_dir/$session-$pane.json"
}

write_classifier_fixture() {
  local fixture_dir="$1" session="$2" pane="$3" subclass="$4"
  jq -nc --arg subclass "$subclass" --arg digest "$CAPACITY_DIGEST" '{subclass:$subclass, freeze_age_seconds:0, scrollback_digest:$digest}' >"$fixture_dir/$session-$pane.json"
}

cat >"$TMP/fake-respawn.sh" <<'SH'
#!/usr/bin/env bash
printf '%s:%s:%s\n' "$1" "$2" "$3" >>"${WORKER_AUTO_RESPAWN_RESPAWN_LOG:?}"
SH
chmod +x "$TMP/fake-respawn.sh"

cat >"$TMP/fake-notify.sh" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${WORKER_AUTO_RESPAWN_NOTIFY_LOG:?}"
SH
chmod +x "$TMP/fake-notify.sh"

cat >"$TMP/fake-ntm.sh" <<'SH'
#!/usr/bin/env bash
if [[ "${1:-}" == "send" ]]; then
  printf '%s\n' "$*" >>"${WORKER_AUTO_RESPAWN_NTM_LOG:?}"
  cat >/dev/null
  exit 0
fi
exit 0
SH
chmod +x "$TMP/fake-ntm.sh"

cat >"$TMP/fake-success-measurement.sh" <<'SH'
#!/usr/bin/env bash
jq -nc '{schema_version:"capacity-halt-success-measurement.result.v1",status:"success",verdict:"success",criteria:{output_delta:true,capacity_text_gone:true,activity_transition:false,velocity_positive:false},read_only:true}'
SH
chmod +x "$TMP/fake-success-measurement.sh"

export WORKER_AUTO_RESPAWN_RESPAWN_LOG="$TMP/respawn.log"
export WORKER_AUTO_RESPAWN_NOTIFY_LOG="$TMP/notify.log"
export WORKER_AUTO_RESPAWN_NTM_LOG="$TMP/ntm.log"

bash -n "$SCRIPT" && pass "watchdog_syntax" || fail "watchdog_syntax"
bash -n "$INSTALLER" && pass "installer_syntax" || fail "installer_syntax"
grep -F -- '[NTM, "send", "flywheel", "--pane=1", "--no-cass-check", msg]' "$SCRIPT" >/dev/null \
  && pass "fallback_respawn_no_cass_check_argv_order" || fail "fallback_respawn_no_cass_check_argv_order"
"$SCRIPT" --info --json | jq -e '.worker_scope_only == true and .budget.max_attempts_per_hour == 3 and .budget.max_auto_continue_per_hour == 5 and .recoveries.model_at_capacity_halt == "auto_continue" and .capacity_halt_recovery_fields == ["attempted","sent","recovered"] and .capacity_halt_authorization_fields == ["pane_role","authorization_outcome","topology_source_ts"] and .capacity_halt_budget_fields == ["per_pane_count_window","fleet_count_window","budget_outcome"]' >/dev/null && pass "info_json" || fail "info_json"
"$SCRIPT" --examples >/dev/null && pass "examples" || fail "examples"

topology="$TMP/topology.jsonl"
attempts="$TMP/attempts.jsonl"

fixtures="$TMP/fixtures-alive"; mkdir -p "$fixtures"; write_topology "$topology"
copy_fixture "$fixtures" fixture 2 alive
copy_fixture "$fixtures" fixture 3 alive
rm -f "$TMP/respawn.log" "$TMP/notify.log" "$attempts"
out="$(run_case all_alive 0 --apply --topology "$topology" --attempts "$attempts" --fixture-dir "$fixtures")"
assert_jq "$out" '.status=="no_action_needed" and .auto_respawns_fired==0 and .notify_fallbacks_fired==0' "all_alive_no_action"
[[ ! -s "$TMP/respawn.log" && ! -s "$TMP/notify.log" ]] && pass "all_alive_no_side_effects" || fail "all_alive_no_side_effects"

fixtures="$TMP/fixtures-dead0"; mkdir -p "$fixtures"; write_topology "$topology"
copy_fixture "$fixtures" fixture 2 truly_dead
copy_fixture "$fixtures" fixture 3 alive
rm -f "$TMP/respawn.log" "$TMP/notify.log" "$attempts"
out="$(run_case dead_attempt0 1 --apply --topology "$topology" --attempts "$attempts" --fixture-dir "$fixtures")"
assert_jq "$out" '.auto_respawns_fired==1 and .actions[0].attempts_last_hour==0 and .actions[0].action=="auto_respawn_fired"' "dead0_respawn_fired"
grep -q '^fixture:2:truly_dead_worker_auto_respawn$' "$TMP/respawn.log" && pass "dead0_respawn_log" || fail "dead0_respawn_log"
jq -e '.attempt_number==1 and .session=="fixture" and .pane==2' "$attempts" >/dev/null && pass "dead0_attempt_logged" || fail "dead0_attempt_logged"

fixtures="$TMP/fixtures-dead2"; mkdir -p "$fixtures"; write_topology "$topology"
copy_fixture "$fixtures" fixture 2 truly_dead
copy_fixture "$fixtures" fixture 3 alive
rm -f "$TMP/respawn.log" "$TMP/notify.log" "$attempts"
seed_attempt "$attempts" fixture 2 1778036300 1
seed_attempt "$attempts" fixture 2 1778036350 2
out="$(run_case dead_attempt2 1 --apply --topology "$topology" --attempts "$attempts" --fixture-dir "$fixtures")"
assert_jq "$out" '.auto_respawns_fired==1 and .actions[0].attempts_last_hour==2' "dead2_respawn_fired"
[[ "$(jq -s '[.[] | select(.session=="fixture" and .pane==2)] | length' "$attempts")" -eq 3 ]] && pass "dead2_attempt_count_now_3" || fail "dead2_attempt_count_now_3"

fixtures="$TMP/fixtures-dead3"; mkdir -p "$fixtures"; write_topology "$topology"
copy_fixture "$fixtures" fixture 2 truly_dead
copy_fixture "$fixtures" fixture 3 alive
rm -f "$TMP/respawn.log" "$TMP/notify.log" "$attempts"
seed_attempt "$attempts" fixture 2 1778036200 1
seed_attempt "$attempts" fixture 2 1778036300 2
seed_attempt "$attempts" fixture 2 1778036350 3
out="$(run_case dead_attempt3 2 --apply --topology "$topology" --attempts "$attempts" --fixture-dir "$fixtures")"
assert_jq "$out" '.notify_fallbacks_fired==1 and .auto_respawns_fired==0 and .actions[0].reason=="auto_respawn_budget_exhausted"' "dead3_notify_fallback"
[[ ! -s "$TMP/respawn.log" ]] && pass "dead3_no_respawn" || fail "dead3_no_respawn"
grep -q 'Auto-respawn budget exhausted' "$TMP/notify.log" && pass "dead3_notify_log" || fail "dead3_notify_log"

fixtures="$TMP/fixtures-recoverable"; mkdir -p "$fixtures"; write_topology "$topology"
copy_fixture "$fixtures" fixture 2 freeze_recoverable
copy_fixture "$fixtures" fixture 3 alive
rm -f "$TMP/respawn.log" "$TMP/notify.log" "$attempts"
out="$(run_case freeze_recoverable 0 --apply --topology "$topology" --attempts "$attempts" --fixture-dir "$fixtures")"
assert_jq "$out" '.status=="no_action_needed" and .auto_respawns_fired==0 and .notify_fallbacks_fired==0' "recoverable_no_action"

fixtures="$TMP/fixtures-capacity0"; mkdir -p "$fixtures"; write_topology "$topology"
write_classifier_fixture "$fixtures" fixture 2 model_at_capacity_halt
copy_fixture "$fixtures" fixture 3 alive
rm -f "$TMP/respawn.log" "$TMP/notify.log" "$TMP/ntm.log" "$TMP/capacity-lease.jsonl" "$attempts"
out="$(run_case capacity_attempt0 1 --apply --topology "$topology" --attempts "$attempts" --fixture-dir "$fixtures")"
assert_jq "$out" '.auto_continues_fired==1 and .auto_respawns_fired==0 and .capacity_halt_recovery_attempted==1 and .capacity_halt_recovery_sent==1 and .capacity_halt_recovery_recovered==1 and .actions[0].action=="auto_continue_fired" and .actions[0].reason=="model_at_capacity_halt_auto_continue" and .actions[0].auto_continue_attempts_last_hour==0 and .actions[0].classification.capacity_halt_recovery.pane_role=="worker_pane" and .actions[0].classification.capacity_halt_recovery.authorization_outcome=="authorized" and .actions[0].classification.capacity_halt_recovery.topology_source_ts=="2026-05-06T03:00:00Z" and .actions[0].classification.capacity_halt_recovery.per_pane_count_window==0 and .actions[0].classification.capacity_halt_recovery.fleet_count_window==0 and .actions[0].classification.capacity_halt_recovery.budget_outcome=="authorized"' "capacity0_auto_continue_fired"
grep -q '^send fixture --pane=2 --no-cass-check continue$' "$TMP/ntm.log" && pass "capacity0_ntm_continue" || fail "capacity0_ntm_continue"
[[ ! -s "$TMP/respawn.log" ]] && pass "capacity0_no_respawn" || fail "capacity0_no_respawn"
jq -e '.action=="auto_continue_attempt" and .recovery_attempted=="auto_continue" and .attempted==true and .sent==true and .recovered==true and .pane_role=="worker_pane" and .authorization_outcome=="authorized" and .topology_source_ts=="2026-05-06T03:00:00Z" and .per_pane_count_window==0 and .fleet_count_window==0 and .budget_outcome=="authorized" and .attempt_number==1 and .session=="fixture" and .pane==2' "$attempts" >/dev/null && pass "capacity0_attempt_logged" || fail "capacity0_attempt_logged"
jq -s -e 'map(select(.event=="acquire" or .event=="release")) | length == 2' "$TMP/capacity-lease.jsonl" >/dev/null && pass "capacity0_lease_acquire_release" || fail "capacity0_lease_acquire_release"

fixtures="$TMP/fixtures-capacity-lease"; mkdir -p "$fixtures"; write_topology "$topology"
write_classifier_fixture "$fixtures" fixture 2 model_at_capacity_halt
copy_fixture "$fixtures" fixture 3 alive
rm -f "$TMP/respawn.log" "$TMP/notify.log" "$TMP/ntm.log" "$TMP/capacity-lease.jsonl" "$attempts"
CAPACITY_HALT_LEASE_LEDGER="$TMP/capacity-lease.jsonl" CAPACITY_HALT_LEASE_NOW_EPOCH=1778036400 "$ROOT/.flywheel/scripts/capacity-halt-lease-primitive.sh" --acquire --session fixture --pane 2 --digest "$CAPACITY_DIGEST" --ttl 90 --json >/dev/null
out="$(run_case capacity_duplicate_lease 0 --apply --topology "$topology" --attempts "$attempts" --fixture-dir "$fixtures")"
assert_jq "$out" '.status=="auto_continue_lease_held" and .auto_continue_lease_refusals==1 and .auto_continues_fired==0 and .actions[0].reason=="capacity_halt_duplicate_lease_held"' "capacity_duplicate_lease_refused"
[[ ! -s "$TMP/ntm.log" && ! -s "$TMP/respawn.log" ]] && pass "capacity_duplicate_no_continue_or_respawn" || fail "capacity_duplicate_no_continue_or_respawn"

fixtures="$TMP/fixtures-capacity5"; mkdir -p "$fixtures"; write_topology "$topology"
write_classifier_fixture "$fixtures" fixture 2 model_at_capacity_halt
copy_fixture "$fixtures" fixture 3 alive
rm -f "$TMP/respawn.log" "$TMP/notify.log" "$TMP/ntm.log" "$TMP/capacity-lease.jsonl" "$attempts"
seed_attempt "$attempts" fixture 2 1778036200 1 auto_continue_attempt
seed_attempt "$attempts" fixture 2 1778036250 2 auto_continue_attempt
seed_attempt "$attempts" fixture 2 1778036300 3 auto_continue_attempt
seed_attempt "$attempts" fixture 2 1778036350 4 auto_continue_attempt
seed_attempt "$attempts" fixture 2 1778036380 5 auto_continue_attempt
out="$(run_case capacity_attempt5 2 --apply --topology "$topology" --attempts "$attempts" --fixture-dir "$fixtures")"
assert_jq "$out" '.notify_fallbacks_fired==1 and .auto_continues_fired==0 and .auto_respawns_fired==0 and .actions[0].reason=="auto_continue_budget_exhausted"' "capacity5_notify_fallback"
[[ ! -s "$TMP/respawn.log" && ! -s "$TMP/ntm.log" ]] && pass "capacity5_no_respawn_or_continue" || fail "capacity5_no_respawn_or_continue"
grep -q 'Auto-continue budget exhausted' "$TMP/notify.log" && pass "capacity5_notify_log" || fail "capacity5_notify_log"

fixtures="$TMP/fixtures-capacity-dry"; mkdir -p "$fixtures"; write_topology "$topology"
write_classifier_fixture "$fixtures" fixture 2 model_at_capacity_halt
copy_fixture "$fixtures" fixture 3 alive
rm -f "$TMP/respawn.log" "$TMP/notify.log" "$TMP/ntm.log" "$TMP/capacity-lease.jsonl" "$attempts"
out="$(run_case capacity_dryrun_excludes_respawn 0 --topology "$topology" --attempts "$attempts" --fixture-dir "$fixtures")"
assert_jq "$out" '.status=="dry_run_actions_planned" and .would_auto_continues==1 and .would_auto_respawns==0 and .auto_respawns_fired==0 and .actions[0].truly_dead==false and .actions[0].classification.classifier=="recoverable_halt"' "capacity_dryrun_excludes_true_dead_respawn"
[[ ! -s "$TMP/respawn.log" && ! -s "$TMP/ntm.log" ]] && pass "capacity_dryrun_no_side_effects" || fail "capacity_dryrun_no_side_effects"

fixtures="$TMP/fixtures-orch"; mkdir -p "$fixtures"; write_topology "$topology"
copy_fixture "$fixtures" fixture 1 truly_dead
copy_fixture "$fixtures" fixture 2 alive
copy_fixture "$fixtures" fixture 3 alive
rm -f "$TMP/respawn.log" "$TMP/notify.log" "$attempts"
out="$(run_case orchestrator_refused 2 --apply --topology "$topology" --attempts "$attempts" --fixture-dir "$fixtures")"
assert_jq "$out" '.protected_refusals==1 and .notify_fallbacks_fired==1 and .auto_respawns_fired==0 and any(.actions[]; .role=="orchestrator" and .reason=="orchestrator_pane_respawn_refused_worker_scope_only")' "orchestrator_notify_only"
[[ ! -s "$TMP/respawn.log" ]] && pass "orchestrator_no_respawn" || fail "orchestrator_no_respawn"

missing="$TMP/missing-topology.jsonl"
out_file="$TMP/topology_fail.out"
set +e
"$SCRIPT" --apply --json --topology "$missing" --attempts "$attempts" --fixture-dir "$fixtures" >"$out_file" 2>/dev/null
rc=$?
set -e
[[ "$rc" -eq 3 ]] && pass "topology_fail_rc3" || fail "topology_fail_rc3"
assert_jq "$out_file" '.success==false and .status=="probe_error"' "topology_fail_json"

cat >"$TMP/fake-launchctl.sh" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${WORKER_AUTO_RESPAWN_LAUNCHCTL_LOG:?}"
if [[ "${1:-}" == "print" ]]; then exit 0; fi
exit 0
SH
chmod +x "$TMP/fake-launchctl.sh"
export WORKER_AUTO_RESPAWN_LAUNCHCTL_LOG="$TMP/launchctl.log"
set +e
WORKER_AUTO_RESPAWN_LAUNCHCTL="$TMP/fake-launchctl.sh" \
WORKER_AUTO_RESPAWN_PLUTIL="/usr/bin/true" \
WORKER_AUTO_RESPAWN_LAUNCH_AGENTS_DIR="$TMP/LaunchAgents" \
WORKER_AUTO_RESPAWN_STATE_DIR="$TMP/state" \
  "$INSTALLER" --apply --json >"$TMP/install.out"
install_rc=$?
set -e
[[ "$install_rc" -eq 0 ]] && pass "installer_apply_rc0" || fail "installer_apply_rc0"
assert_jq "$TMP/install.out" '.gui_domain==true and .interval_seconds==60 and .loaded==true' "installer_gui_domain_json"
grep -q '^bootstrap gui/' "$TMP/launchctl.log" && pass "installer_bootstrap_gui_domain" || fail "installer_bootstrap_gui_domain"

printf 'Summary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
