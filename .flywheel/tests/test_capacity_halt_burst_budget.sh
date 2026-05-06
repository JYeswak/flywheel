#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
BUDGET="$ROOT/.flywheel/scripts/capacity-halt-burst-budget.sh"
AUTO="$ROOT/.flywheel/scripts/capacity-halt-auto-continue-primitive.sh"
LEASE="$ROOT/.flywheel/scripts/capacity-halt-lease-primitive.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/capacity-halt-burst-budget-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
case_count=0
NOW=1778037000
DIGEST="eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"

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

row() {
  local ledger="$1" session="$2" pane="$3" epoch="$4"
  jq -nc --arg session "$session" --argjson pane "$pane" --argjson epoch "$epoch" \
    '{ts:"2026-05-06T03:00:00Z",epoch:$epoch,action:"auto_continue_attempt",recovery_attempted:"auto_continue",session:$session,pane:$pane,attempted:true,sent:true,recovered:true}' >>"$ledger"
}

run_budget() {
  local name="$1" expected_rc="$2" ledger="$3" out rc
  out="$TMP/$name.out"
  shift 3
  set +e
  CAPACITY_HALT_BUDGET_LEDGER="$ledger" CAPACITY_HALT_BUDGET_NOW_EPOCH="$NOW" \
    "$@" bash "$BUDGET" --session fixture --pane 2 --json >"$out" 2>"$TMP/$name.err"
  rc=$?
  set -e
  if [[ "$rc" -eq "$expected_rc" ]]; then
    pass "$name rc=$expected_rc"
  else
    fail "$name rc expected=$expected_rc actual=$rc"
    cat "$TMP/$name.err" >&2 || true
    jq . "$out" >&2 || true
  fi
  case_count=$((case_count + 1))
  RUN_OUT="$out"
}

run_auto_budget_exhausted() {
  local name="auto_integration_budget_exhausted" out="$TMP/auto-integration.out" ledger="$TMP/auto-budget.jsonl" lease="$TMP/auto-lease.jsonl" rc
  row "$ledger" fixture 2 $((NOW - 10)); row "$ledger" fixture 2 $((NOW - 20)); row "$ledger" fixture 2 $((NOW - 30))
  set +e
  CAPACITY_HALT_AUTH_TOPOLOGY="$TMP/topology.jsonl" \
  CAPACITY_HALT_AUTH_NOW_EPOCH="$NOW" \
  CAPACITY_HALT_BUDGET_LEDGER="$ledger" \
  CAPACITY_HALT_BUDGET_NOW_EPOCH="$NOW" \
  CAPACITY_HALT_LEASE_LEDGER="$lease" \
  CAPACITY_HALT_LEASE_NOW_EPOCH="$NOW" \
  CAPACITY_HALT_AUTO_CONTINUE_SUCCESS_MEASUREMENT="$TMP/fake-success-measurement.sh" \
  CAPACITY_HALT_AUTO_CONTINUE_NOTIFY_BIN="$TMP/fake-notify.sh" \
  CAPACITY_HALT_AUTO_CONTINUE_FALLBACK_LEDGER="$TMP/fallback.jsonl" \
  FAKE_NTM_LOG="$TMP/auto.ntm.log" \
    bash "$AUTO" --lease-bin "$LEASE" --ntm-bin "$TMP/fake-ntm.sh" --session fixture --pane 2 --digest "$DIGEST" --apply --json >"$out" 2>"$TMP/auto-integration.err"
  rc=$?
  set -e
  if [[ "$rc" -eq 8 ]]; then pass "$name rc=8"; else fail "$name rc expected=8 actual=$rc"; jq . "$out" >&2 || true; fi
  case_count=$((case_count + 1))
  RUN_OUT="$out"; RUN_LEASE="$lease"
}

cat >"$TMP/fake-ntm.sh" <<'SH'
#!/usr/bin/env bash
if [[ "${1:-}" == "send" ]]; then
  IFS= read -r answer || true
  printf '%s answer=%s\n' "$*" "$answer" >>"${FAKE_NTM_LOG:?}"
fi
SH
chmod +x "$TMP/fake-ntm.sh"

cat >"$TMP/fake-success-measurement.sh" <<'SH'
#!/usr/bin/env bash
jq -nc '{schema_version:"capacity-halt-success-measurement.result.v1",status:"success",verdict:"success",criteria:{output_delta:true,capacity_text_gone:true,activity_transition:false,velocity_positive:false},read_only:true}'
SH
chmod +x "$TMP/fake-success-measurement.sh"

cat >"$TMP/fake-notify.sh" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${FAKE_NOTIFY_LOG:?}"
SH
chmod +x "$TMP/fake-notify.sh"
export FAKE_NOTIFY_LOG="$TMP/notify.log"

jq -nc '{session:"fixture",worker_panes:[2,3],worker_kinds:{"2":"codex","3":"codex"},orchestrator_pane:1,human_pane:0,callback_pane:4,effective_at:"2026-05-06T03:00:00Z"}' >"$TMP/topology.jsonl"

bash -n "$BUDGET" && pass "budget_syntax" || fail "budget_syntax"
"$BUDGET" --info --json | jq -e '.name=="capacity-halt-burst-budget" and (.verbs == ["--info","--help","--examples","--json","--session","--pane","--quiet"]) and .defaults.per_pane_max==3 and .defaults.fleet_max==5' >/dev/null && pass "info_json" || fail "info_json"
"$BUDGET" --examples --json | jq -e '.examples | length == 2' >/dev/null && pass "examples_json" || fail "examples_json"

ledger="$TMP/zero.jsonl"; : >"$ledger"
run_budget per_pane_zero 0 "$ledger" env
assert_jq "$RUN_OUT" '.budget_outcome=="authorized" and .per_pane_count_window==0 and .fleet_count_window==0 and .read_only==true' "per_pane_zero_payload"

ledger="$TMP/per-pane-two.jsonl"; : >"$ledger"; row "$ledger" fixture 2 $((NOW - 10)); row "$ledger" fixture 2 $((NOW - 20))
run_budget per_pane_two 0 "$ledger" env
assert_jq "$RUN_OUT" '.per_pane_count_window==2 and .per_pane_authorized==true and .fleet_authorized==true' "per_pane_two_payload"

ledger="$TMP/per-pane-three.jsonl"; : >"$ledger"; row "$ledger" fixture 2 $((NOW - 10)); row "$ledger" fixture 2 $((NOW - 20)); row "$ledger" fixture 2 $((NOW - 30))
run_budget per_pane_three 1 "$ledger" env
assert_jq "$RUN_OUT" '.budget_outcome=="per_pane_exhausted" and .per_pane_count_window==3 and .per_pane_authorized==false' "per_pane_three_payload"

ledger="$TMP/per-pane-stale.jsonl"; : >"$ledger"; row "$ledger" fixture 2 $((NOW - 700)); row "$ledger" fixture 2 $((NOW - 800)); row "$ledger" fixture 2 $((NOW - 900))
run_budget per_pane_outside_window 0 "$ledger" env
assert_jq "$RUN_OUT" '.budget_outcome=="authorized" and .per_pane_count_window==0' "per_pane_outside_payload"

ledger="$TMP/fleet-four.jsonl"; : >"$ledger"; for pane in 2 3 4 5; do row "$ledger" "s$pane" "$pane" $((NOW - 10)); done
run_budget fleet_four 0 "$ledger" env
assert_jq "$RUN_OUT" '.budget_outcome=="authorized" and .fleet_count_window==4 and .fleet_authorized==true' "fleet_four_payload"

ledger="$TMP/fleet-five.jsonl"; : >"$ledger"; for pane in 2 3 4 5 6; do row "$ledger" "s$pane" "$pane" $((NOW - 10)); done
run_budget fleet_five 2 "$ledger" env
assert_jq "$RUN_OUT" '.budget_outcome=="fleet_exhausted" and .fleet_count_window==5 and .fleet_authorized==false' "fleet_five_payload"

ledger="$TMP/override.jsonl"; : >"$ledger"; row "$ledger" fixture 2 $((NOW - 10))
run_budget per_pane_override 1 "$ledger" env CAPACITY_HALT_PER_PANE_MAX=1
assert_jq "$RUN_OUT" '.budget_outcome=="per_pane_exhausted" and .per_pane_max==1' "per_pane_override_payload"

run_auto_budget_exhausted
assert_jq "$RUN_OUT" '.status=="budget_exhausted" and .budget.budget_outcome=="per_pane_exhausted" and .attempted==false and .sent==false and .recovered==false and .fired==false' "auto_budget_exhausted_payload"
[[ ! -e "$TMP/auto.ntm.log" && ! -e "$RUN_LEASE" ]] && pass "auto_budget_no_send_or_lease" || fail "auto_budget_no_send_or_lease"
jq -e '.class=="capacity-halt-budget-exhausted" and .budget_outcome=="per_pane_exhausted" and .session=="fixture" and .pane==2' "$TMP/fallback.jsonl" >/dev/null && pass "fallback_ledger_written" || fail "fallback_ledger_written"
grep -q 'Capacity halt budget exhausted' "$TMP/notify.log" && pass "notify_invoked" || fail "notify_invoked"

ledger="$TMP/malformed.jsonl"; printf '{bad json\n' >"$ledger"
run_budget malformed_ledger 4 "$ledger" env
assert_jq "$RUN_OUT" '.status=="ledger_read_error" and .budget_outcome=="ledger_read_error"' "malformed_ledger_payload"

printf 'Summary: %s cases, %s passed, %s failed\n' "$case_count" "$pass_count" "$fail_count"
[[ "$case_count" -eq 9 && "$fail_count" -eq 0 ]]
