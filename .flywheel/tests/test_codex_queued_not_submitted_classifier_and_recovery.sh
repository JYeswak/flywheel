#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
DETECTOR="$ROOT/.flywheel/scripts/codex-template-stuck-detector.sh"
PRIMITIVE="$ROOT/.flywheel/scripts/codex-queued-not-submitted-bare-enter-primitive.sh"
LEASE="$ROOT/.flywheel/scripts/capacity-halt-lease-primitive.sh"
CAPACITY_T0="$ROOT/.flywheel/tests/fixtures/capacity-halt-validation/codex-pane-capacity-halt-t0.txt"
CAPACITY_T1="$ROOT/.flywheel/tests/fixtures/capacity-halt-validation/codex-pane-capacity-halt-t1.txt"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/codex-queued-not-submitted-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
case_count=0
DIGEST="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
NOW_EPOCH=1778068800

pass() { printf 'PASS %s\n' "$1" >&2; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }
begin_case() { case_count=$((case_count + 1)); printf 'CASE %02d %s\n' "$case_count" "$1" >&2; }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

assert_grep() {
  local pattern="$1" file="$2" label="$3"
  if grep -q -- "$pattern" "$file"; then pass "$label"; else fail "$label"; [[ -e "$file" ]] && cat "$file" >&2; fi
}

cat >"$TMP/jsonl-append.sh" <<'SH'
fw_jsonl_append_validated() {
  mkdir -p "$(dirname "$1")"
  printf '%s\n' "$2" >>"$1"
}
SH

cat >"$TMP/fake-bare-enter.sh" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${BARE_ENTER_LOG:?}"
jq -nc '{schema_version:"codex-queued-not-submitted-bare-enter.result.v1",status:"fired_success",fired:true,attempted:true,sent:true,recovered:true,body:""}'
SH
chmod +x "$TMP/fake-bare-enter.sh"

cat >"$TMP/fake-capacity-auto-continue.sh" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${CAPACITY_AUTO_LOG:?}"
jq -nc '{schema_version:"capacity-halt-auto-continue.result.v1",status:"fired_success",fired:true,attempted:true,sent:true,recovered:true}'
SH
chmod +x "$TMP/fake-capacity-auto-continue.sh"

cat >"$TMP/fake-ntm.sh" <<'SH'
#!/usr/bin/env bash
if [[ "${1:-}" == "send" ]]; then
  for arg in "$@"; do printf '<%s>' "$arg"; done >>"${FAKE_NTM_LOG:?}"
  printf '\n' >>"${FAKE_NTM_LOG:?}"
  exit "${FAKE_NTM_RC:-0}"
fi
exit 0
SH
chmod +x "$TMP/fake-ntm.sh"

cat >"$TMP/fake-success-measurement.sh" <<'SH'
#!/usr/bin/env bash
jq -nc '{schema_version:"capacity-halt-success-measurement.result.v1",status:"success",verdict:"success",criteria:{output_delta:true,capacity_text_gone:false,activity_transition:true,velocity_positive:false},read_only:true}'
SH
chmod +x "$TMP/fake-success-measurement.sh"

cat >"$TMP/fake-notify.sh" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${FAKE_NOTIFY_LOG:-/dev/null}"
SH
chmod +x "$TMP/fake-notify.sh"

topology="$TMP/topology.jsonl"
jq -nc '{session:"fixture",worker_panes:[2,3],worker_kinds:{"2":"codex","3":"codex"},orchestrator_pane:1,human_pane:0,callback_pane:4,effective_at:"2026-05-06T12:00:00Z"}' >"$topology"

make_fixture() {
  local name="$1" text="$2" path="$TMP/$name.json"
  jq -nc --arg session fixture --argjson pane 2 --arg t0 "$text" --arg t1 "$text" \
    '{schema_version:"codex-stuck-detector.fixture.v1",session:$session,pane:$pane,t0:$t0,t1:$t1}' >"$path"
  printf '%s\n' "$path"
}

run_detector() {
  local name="$1" expected_rc="$2" fixture="$3" rc
  shift 3
  RUN_OUT="$TMP/$name.out"
  BARE_ENTER_LOG="$TMP/$name.bare.log" \
  CAPACITY_AUTO_LOG="$TMP/$name.capacity.log" \
  CODEX_STUCK_DETECTOR_JSONL_APPEND_LIB="$TMP/jsonl-append.sh" \
  CODEX_STUCK_DETECTOR_LEDGER="$TMP/$name.ledger.jsonl" \
  CODEX_STUCK_DETECTOR_FUCKUP_LOG="$TMP/$name.fuckups.jsonl" \
  CODEX_STUCK_DETECTOR_QUEUED_BARE_ENTER="$TMP/fake-bare-enter.sh" \
  CODEX_STUCK_DETECTOR_CAPACITY_AUTO_CONTINUE="$TMP/fake-capacity-auto-continue.sh" \
    bash "$DETECTOR" --fixture "$fixture" --json "$@" >"$RUN_OUT" 2>"$TMP/$name.err" || rc=$?
  rc="${rc:-0}"
  if [[ "$rc" -eq "$expected_rc" ]]; then
    pass "$name rc=$expected_rc"
  else
    fail "$name rc expected=$expected_rc actual=$rc"
    cat "$TMP/$name.err" >&2 || true
    jq . "$RUN_OUT" >&2 || true
  fi
}

run_primitive() {
  local name="$1" expected_rc="$2" rc
  shift 2
  RUN_OUT="$TMP/$name.out"
  RUN_LEDGER="$TMP/$name.lease.jsonl"
  FAKE_NTM_LOG="$TMP/$name.ntm.log" \
  FAKE_NTM_RC=0 \
  CAPACITY_HALT_LEASE_LEDGER="$RUN_LEDGER" \
  CAPACITY_HALT_LEASE_NOW_EPOCH="$NOW_EPOCH" \
  CAPACITY_HALT_AUTH_TOPOLOGY="$topology" \
  CAPACITY_HALT_AUTH_NOW_EPOCH="$NOW_EPOCH" \
  CAPACITY_HALT_BUDGET_LEDGER="$TMP/$name.budget.jsonl" \
  CAPACITY_HALT_BUDGET_NOW_EPOCH="$NOW_EPOCH" \
  CODEX_QUEUED_BARE_ENTER_SUCCESS_MEASUREMENT="$TMP/fake-success-measurement.sh" \
  CODEX_QUEUED_BARE_ENTER_NOTIFY_BIN="$TMP/fake-notify.sh" \
  CODEX_QUEUED_BARE_ENTER_FALLBACK_LEDGER="$TMP/$name.fallback.jsonl" \
    bash "$PRIMITIVE" --lease-bin "$LEASE" --ntm-bin "$TMP/fake-ntm.sh" "$@" --json >"$RUN_OUT" 2>"$TMP/$name.err" || rc=$?
  rc="${rc:-0}"
  if [[ "$rc" -eq "$expected_rc" ]]; then
    pass "$name rc=$expected_rc"
  else
    fail "$name rc expected=$expected_rc actual=$rc"
    cat "$TMP/$name.err" >&2 || true
    jq . "$RUN_OUT" >&2 || true
  fi
}

queued_text=$'• Working (1m 40s • esc to interrupt) · 1 background terminal running\n› Run /review on my current changes\n  gpt-5.5 xhigh · ~/Developer/alpsinsurance'
post_callback_text=$'• Done.\n• Working (2m 05s • esc to interrupt) · 1 background terminal running\n› Run /review on my current changes\n  gpt-5.5 xhigh · ~/Developer/flywheel'
bare_chevron_text=$'›\n  gpt-5.5 xhigh · ~/Developer/flywheel'

begin_case "queued fixture classifies as codex_queued_not_submitted"
queued_fixture="$(make_fixture queued "$queued_text")"
run_detector queued 1 "$queued_fixture"
assert_jq "$RUN_OUT" '.panes[0].subclass=="codex_queued_not_submitted" and .panes[0].recommended_recovery=="bare_enter"' "queued_subclass_and_recovery"

begin_case "capacity halt remains capacity halt"
capacity_fixture="$TMP/capacity.json"
jq -nc --arg session fixture --argjson pane 2 --arg t0 "$(<"$CAPACITY_T0")" --arg t1 "$(<"$CAPACITY_T1")" \
  '{schema_version:"codex-stuck-detector.fixture.v1",session:$session,pane:$pane,t0:$t0,t1:$t1}' >"$capacity_fixture"
run_detector capacity 1 "$capacity_fixture"
assert_jq "$RUN_OUT" '.panes[0].subclass=="model_at_capacity_halt" and .panes[0].recommended_recovery=="auto_continue"' "capacity_halt_not_regressed"

begin_case "post callback reminder remains post callback"
post_fixture="$(make_fixture post_callback "$post_callback_text")"
run_detector post_callback 1 "$post_fixture"
assert_jq "$RUN_OUT" '.panes[0].subclass=="post_callback_reminder_template_with_stale_spinner"' "post_callback_not_regressed"

begin_case "bare chevron without text stays alive"
bare_fixture="$(make_fixture bare_chevron "$bare_chevron_text")"
run_detector bare_chevron 0 "$bare_fixture"
assert_jq "$RUN_OUT" '.panes[0].subclass=="alive" and .panes[0].recommended_recovery=="none"' "bare_chevron_alive"

begin_case "#12645 frozen-pane detector self-test remains green"
if bash "$ROOT/tests/frozen-pane-detector-self-test.sh" >"$TMP/frozen-self-test.out" 2>"$TMP/frozen-self-test.err"; then
  pass "frozen_pane_self_test"
else
  fail "frozen_pane_self_test"
  cat "$TMP/frozen-self-test.err" >&2
fi

begin_case "auto recover invokes bare enter primitive only"
rm -f "$TMP/auto.bare.log" "$TMP/auto.capacity.log"
run_detector auto 1 "$queued_fixture" --auto-recover --apply
assert_jq "$RUN_OUT" '.panes[0].subclass=="codex_queued_not_submitted" and .panes[0].recovery_attempted=="bare_enter" and .panes[0].recovery_succeeded==true' "auto_recover_bare_enter_payload"
assert_grep "--session fixture --pane 2" "$TMP/auto.bare.log" "bare_enter_primitive_invoked"
[[ ! -e "$TMP/auto.capacity.log" ]] && pass "capacity_primitive_not_invoked" || fail "capacity_primitive_not_invoked"

begin_case "live alps string classifies as codex_queued_not_submitted"
alps_fixture="$(make_fixture alps "$queued_text")"
run_detector alps 1 "$alps_fixture"
assert_jq "$RUN_OUT" '.panes[0].subclass=="codex_queued_not_submitted" and (.panes[0].evidence_lines | index("› Run /review on my current changes"))' "alps_live_string_match"

begin_case "bare enter primitive dry-run is side-effect free"
run_primitive dry_run 0 --session fixture --pane 2 --dry-run
assert_jq "$RUN_OUT" '.status=="dry_run" and .would_send==true and .body=="" and .apply==false' "primitive_dry_run_body_empty"
[[ ! -e "$TMP/dry_run.ntm.log" && ! -e "$RUN_LEDGER" ]] && pass "primitive_dry_run_no_send_or_lease" || fail "primitive_dry_run_no_send_or_lease"

begin_case "bare enter primitive apply sends empty body and releases lease"
run_primitive apply_worker 0 --session fixture --pane 2 --digest "$DIGEST" --apply
assert_jq "$RUN_OUT" '.status=="fired_success" and .sent==true and .recovered==true and .body=="" and .release.primary.payload.result=="success"' "primitive_apply_success_payload"
grep -q '^<send><fixture><--pane=2><--no-cass-check><>$' "$TMP/apply_worker.ntm.log" && pass "primitive_apply_empty_send" || fail "primitive_apply_empty_send"
jq -s -e 'length == 2 and .[0].event=="acquire" and .[1].event=="release" and .[1].result=="success"' "$RUN_LEDGER" >/dev/null && pass "primitive_apply_lease_order" || fail "primitive_apply_lease_order"

begin_case "bare enter primitive refuses orchestrator pane"
run_primitive protected 5 --session fixture --pane 1 --digest "$DIGEST" --apply
assert_jq "$RUN_OUT" '.status=="protected_refusal" and .fired==false and .pane_role=="orchestrator_pane"' "primitive_protected_refusal"
[[ ! -e "$TMP/protected.ntm.log" ]] && pass "protected_no_send" || fail "protected_no_send"

begin_case "bare enter primitive malformed input exits 3"
run_primitive malformed 3 --session fixture --pane not-a-number --apply
assert_jq "$RUN_OUT" '.status=="malformed" and .fired==false' "primitive_malformed_payload"
[[ ! -e "$TMP/malformed.ntm.log" && ! -e "$RUN_LEDGER" ]] && pass "malformed_no_side_effects" || fail "malformed_no_side_effects"

printf 'Summary: %s cases, %s passed, %s failed\n' "$case_count" "$pass_count" "$fail_count"
[[ "$case_count" -eq 11 && "$fail_count" -eq 0 ]]
