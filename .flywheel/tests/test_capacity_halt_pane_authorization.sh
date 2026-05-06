#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
AUTH="$ROOT/.flywheel/scripts/capacity-halt-pane-authorization.sh"
AUTO="$ROOT/.flywheel/scripts/capacity-halt-auto-continue-primitive.sh"
LEASE="$ROOT/.flywheel/scripts/capacity-halt-lease-primitive.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/capacity-halt-pane-authorization-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
case_count=0
DIGEST="dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"
topology="$TMP/topology.jsonl"
stale_topology="$TMP/stale-topology.jsonl"

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

run_auth() {
  local name="$1" expected_rc="$2" topo="$3" session="$4" pane="$5" out rc
  out="$TMP/$name.out"
  set +e
  CAPACITY_HALT_AUTH_TOPOLOGY="$topo" CAPACITY_HALT_AUTH_NOW_EPOCH=1778037000 \
    bash "$AUTH" --session "$session" --pane "$pane" --json >"$out" 2>"$TMP/$name.err"
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

run_auto() {
  local name="$1" expected_rc="$2" topo="$3" pane="$4" out rc
  local ledger="$TMP/$name.lease.jsonl"
  out="$TMP/$name.out"
  set +e
  CAPACITY_HALT_AUTH_TOPOLOGY="$topo" \
  CAPACITY_HALT_AUTH_NOW_EPOCH=1778037000 \
  CAPACITY_HALT_LEASE_LEDGER="$ledger" \
  CAPACITY_HALT_LEASE_NOW_EPOCH=1778037000 \
  CAPACITY_HALT_BUDGET_LEDGER="$TMP/$name.budget.jsonl" \
  CAPACITY_HALT_BUDGET_NOW_EPOCH=1778037000 \
  CAPACITY_HALT_AUTO_CONTINUE_SUCCESS_MEASUREMENT="$TMP/fake-success-measurement.sh" \
  CAPACITY_HALT_AUTO_CONTINUE_NOTIFY_BIN="$TMP/fake-notify.sh" \
  CAPACITY_HALT_AUTO_CONTINUE_FALLBACK_LEDGER="$TMP/$name.fallback.jsonl" \
  FAKE_NTM_LOG="$TMP/$name.ntm.log" \
    bash "$AUTO" --lease-bin "$LEASE" --ntm-bin "$TMP/fake-ntm.sh" --session fixture --pane "$pane" --digest "$DIGEST" --apply --json >"$out" 2>"$TMP/$name.err"
  rc=$?
  set -e
  if [[ "$rc" -eq "$expected_rc" ]]; then
    pass "$name rc=$expected_rc"
  else
    fail "$name rc expected=$expected_rc actual=$rc"
    cat "$TMP/$name.err" >&2 || true
    jq . "$out" >&2 || true
  fi
  RUN_OUT="$out"
  RUN_LEDGER="$ledger"
}

cat >"$TMP/fake-ntm.sh" <<'SH'
#!/usr/bin/env bash
if [[ "${1:-}" == "send" ]]; then
  IFS= read -r answer || true
  printf '%s answer=%s\n' "$*" "$answer" >>"${FAKE_NTM_LOG:?}"
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

cat >"$TMP/fake-notify.sh" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${FAKE_NOTIFY_LOG:-/dev/null}"
SH
chmod +x "$TMP/fake-notify.sh"

jq -nc '{session:"fixture",worker_panes:[2,3],worker_kinds:{"2":"codex","3":"codex"},orchestrator_pane:1,human_pane:0,callback_pane:4,effective_at:"2026-05-06T03:00:00Z"}' >"$topology"
jq -nc '{session:"peer",worker_panes:[2],worker_kinds:{"2":"codex"},orchestrator_pane:1,human_pane:0,callback_pane:4,effective_at:"2026-05-06T03:00:00Z"}' >>"$topology"
jq -nc '{session:"fixture",worker_panes:[2,3],worker_kinds:{"2":"codex","3":"codex"},orchestrator_pane:1,human_pane:0,callback_pane:4,effective_at:"2026-05-06T02:00:00Z"}' >"$stale_topology"

bash -n "$AUTH" && pass "auth_syntax" || fail "auth_syntax"
bash -n "$AUTO" && pass "auto_syntax" || fail "auto_syntax"
"$AUTH" --info --json | jq -e '.name=="capacity-halt-pane-authorization" and (.verbs == ["--info","--help","--examples","--json","--session","--pane","--quiet"]) and .exit_codes."5"=="protected-refusal"' >/dev/null && pass "info_json" || fail "info_json"
"$AUTH" --examples --json | jq -e '.examples | length == 2' >/dev/null && pass "examples_json" || fail "examples_json"

before_hash="$(shasum -a 256 "$topology" | awk '{print $1}')"
run_auth worker_authorized 0 "$topology" fixture 2
out="$RUN_OUT"
assert_jq "$out" '.authorized==true and .role=="worker_pane" and .authorization_outcome=="authorized" and .topology_source_ts=="2026-05-06T03:00:00Z" and .ledger_row.authorized==true and .read_only==true' "worker_authorized_payload"
after_hash="$(shasum -a 256 "$topology" | awk '{print $1}')"
[[ "$before_hash" == "$after_hash" ]] && pass "worker_authorized_no_topology_mutation" || fail "worker_authorized_no_topology_mutation"

run_auth orchestrator_refused 5 "$topology" fixture 1
assert_jq "$RUN_OUT" '.authorized==false and .role=="orchestrator_pane" and .refusal_reason=="protected" and .authorization_outcome=="protected_refusal"' "orchestrator_refused_payload"
set +e
CAPACITY_HALT_AUTH_TOPOLOGY="$topology" CAPACITY_HALT_AUTH_NOW_EPOCH=1778037000 bash "$AUTH" --session peer --pane 1 --json >"$TMP/peer-orchestrator.out"
peer_rc=$?
set -e
[[ "$peer_rc" -eq 5 ]] && pass "peer_orchestrator_context_rc5" || fail "peer_orchestrator_context_rc5"
assert_jq "$TMP/peer-orchestrator.out" '.authorized==false and .role=="orchestrator_pane" and .authorization_outcome=="protected_refusal"' "peer_orchestrator_context_refused"

run_auth human_refused 5 "$topology" fixture 0
assert_jq "$RUN_OUT" '.authorized==false and .role=="human_pane" and .refusal_reason=="protected"' "human_refused_payload"

run_auth callback_refused 5 "$topology" fixture 4
assert_jq "$RUN_OUT" '.authorized==false and .role=="callback_pane" and .refusal_reason=="protected"' "callback_refused_payload"

run_auth unknown_refused 6 "$topology" fixture 9
assert_jq "$RUN_OUT" '.authorized==false and .role=="unknown" and .authorization_outcome=="unknown_pane" and .refusal_reason=="unknown_pane"' "unknown_refused_payload"

run_auth stale_refused 7 "$stale_topology" fixture 2
assert_jq "$RUN_OUT" '.authorized==false and .role=="unknown" and .authorization_outcome=="topology_stale" and .topology_age_sec > 3600' "stale_refused_payload"

run_auth malformed_input 3 "$topology" fixture not-a-pane
assert_jq "$RUN_OUT" '.status=="malformed" and .role=="unknown" and .authorized==false' "malformed_payload"

case_count=$((case_count + 1))
run_auto integration_worker 0 "$topology" 2
assert_jq "$RUN_OUT" '.status=="fired_success" and .pane_role=="worker_pane" and .authorization_outcome=="authorized" and .attempted==true and .sent==true and .recovered==true and .authorization.rc==0' "integration_worker_authorized_send"
grep -q '^send fixture --pane=2 --no-cass-check continue answer=y$' "$TMP/integration_worker.ntm.log" && pass "integration_worker_send_logged" || fail "integration_worker_send_logged"
jq -s -e 'length == 2 and .[0].event=="acquire" and .[1].event=="release"' "$RUN_LEDGER" >/dev/null && pass "integration_worker_lease_used" || fail "integration_worker_lease_used"

run_auto integration_protected 5 "$topology" 1
assert_jq "$RUN_OUT" '.status=="protected_refusal" and .pane_role=="orchestrator_pane" and .attempted==false and .sent==false and .recovered==false' "integration_protected_refused"
[[ ! -e "$TMP/integration_protected.ntm.log" && ! -e "$RUN_LEDGER" ]] && pass "integration_protected_no_send_or_lease" || fail "integration_protected_no_send_or_lease"

run_auto integration_unknown 6 "$topology" 9
assert_jq "$RUN_OUT" '.status=="unknown_pane" and .pane_role=="unknown" and .attempted==false and .sent==false and .recovered==false' "integration_unknown_refused"
[[ ! -e "$TMP/integration_unknown.ntm.log" && ! -e "$RUN_LEDGER" ]] && pass "integration_unknown_no_send_or_lease" || fail "integration_unknown_no_send_or_lease"

run_auto integration_stale 7 "$stale_topology" 2
assert_jq "$RUN_OUT" '.status=="topology_stale" and .pane_role=="unknown" and .attempted==false and .sent==false and .recovered==false' "integration_stale_refused"
[[ ! -e "$TMP/integration_stale.ntm.log" && ! -e "$RUN_LEDGER" ]] && pass "integration_stale_no_send_or_lease" || fail "integration_stale_no_send_or_lease"

printf 'Summary: %s cases, %s passed, %s failed\n' "$case_count" "$pass_count" "$fail_count"
[[ "$case_count" -eq 8 && "$fail_count" -eq 0 ]]
