#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/capacity-halt-auto-continue-primitive.sh"
LEASE="$ROOT/.flywheel/scripts/capacity-halt-lease-primitive.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/capacity-halt-auto-continue-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
topology="$TMP/topology.jsonl"

pass_count=0
fail_count=0
case_count=0
DIGEST_A="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
DIGEST_B="bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"

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

run_case() {
  local name="$1" expected_rc="$2" mode="$3" ledger="$4" out rc
  out="$TMP/$name.out"
  shift 4
  set +e
  CAPACITY_HALT_LEASE_LEDGER="$ledger" \
  CAPACITY_HALT_LEASE_NOW_EPOCH=1778037000 \
  CAPACITY_HALT_AUTH_TOPOLOGY="$topology" \
  CAPACITY_HALT_AUTH_NOW_EPOCH=1778037000 \
  CAPACITY_HALT_BUDGET_LEDGER="$TMP/$name.budget.jsonl" \
  CAPACITY_HALT_BUDGET_NOW_EPOCH=1778037000 \
  CAPACITY_HALT_AUTO_CONTINUE_SUCCESS_MEASUREMENT="$TMP/fake-success-measurement.sh" \
  CAPACITY_HALT_AUTO_CONTINUE_NOTIFY_BIN="$TMP/fake-notify.sh" \
  CAPACITY_HALT_AUTO_CONTINUE_FALLBACK_LEDGER="$TMP/$name.fallback.jsonl" \
  FAKE_NTM_LOG="$TMP/$name.ntm.log" \
  FAKE_NTM_MODE="$mode" \
    bash "$SCRIPT" --lease-bin "$LEASE" --ntm-bin "$TMP/fake-ntm.sh" "$@" --json >"$out" 2>"$TMP/$name.err"
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

cat >"$TMP/fake-ntm.sh" <<'SH'
#!/usr/bin/env bash
if [[ "${1:-}" == "send" ]]; then
  IFS= read -r answer || true
  printf '%s answer=%s\n' "$*" "$answer" >>"${FAKE_NTM_LOG:?}"
  case "${FAKE_NTM_MODE:-pass}" in
    pass) exit 0 ;;
    fail) exit 7 ;;
    hang) sleep 2; exit 0 ;;
  esac
  exit 9
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

bash -n "$SCRIPT" && pass "primitive_syntax" || fail "primitive_syntax"
"$SCRIPT" --info --json | jq -e '.default_timeout_seconds == 8 and (.verbs | length) == 8 and (.verbs | index("--apply"))' >/dev/null && pass "info_json" || fail "info_json"
"$SCRIPT" --examples --json | jq -e '.examples | length == 3' >/dev/null && pass "examples_json" || fail "examples_json"

case_count=$((case_count + 1))
grep -F '"--no-cass-check"' "$SCRIPT" >/dev/null && pass "no_cass_check_flag_present" || fail "no_cass_check_flag_present"

case_count=$((case_count + 1))
python3 - "$SCRIPT" <<'PY' && pass "argv_order_matches_ntm_send_shape" || fail "argv_order_matches_ntm_send_shape"
import ast
import sys

source = open(sys.argv[1], encoding="utf-8").read()
start = source.index("<<'PY'\n") + len("<<'PY'\n")
body = source[start:source.rindex("\nPY")]
tree = ast.parse(body)

def node_key(node):
    if isinstance(node, ast.Constant):
        return node.value
    if isinstance(node, ast.JoinedStr):
        parts = []
        for value in node.values:
            if isinstance(value, ast.Constant):
                parts.append(str(value.value))
            elif isinstance(value, ast.FormattedValue):
                parts.append("{expr}")
        return "".join(parts)
    if isinstance(node, ast.Attribute) and isinstance(node.value, ast.Name):
        return f"{node.value.id}.{node.attr}"
    return None

for item in tree.body:
    if isinstance(item, ast.FunctionDef) and item.name == "send_continue":
        call = item.body[0].value
        argv = [node_key(node) for node in call.args[0].elts]
        expected = ["args.ntm_bin", "send", "args.session", "--pane={expr}", "--no-cass-check", "continue"]
        raise SystemExit(0 if argv == expected else 1)
raise SystemExit(1)
PY

ledger="$TMP/dry-run-lease.jsonl"
run_case dry_run_valid 0 pass "$ledger" --session fixture --pane 2 --dry-run
out="$RUN_OUT"
assert_jq "$out" '.status=="dry_run" and .would_send==true and .apply==false and .transport_timeout_seconds==8' "dry_run_would_send"
[[ ! -e "$TMP/dry_run_valid.ntm.log" && ! -e "$ledger" ]] && pass "dry_run_no_side_effects" || fail "dry_run_no_side_effects"

ledger="$TMP/held-lease.jsonl"
CAPACITY_HALT_LEASE_LEDGER="$ledger" CAPACITY_HALT_LEASE_NOW_EPOCH=1778037000 \
  bash "$LEASE" --acquire --session fixture --pane 2 --digest "$DIGEST_A" --ttl 90 --json >/dev/null
run_case lease_held 2 pass "$ledger" --session fixture --pane 2 --digest "$DIGEST_A" --apply
out="$RUN_OUT"
assert_jq "$out" '.status=="lease_held_skipped" and .fired==false and .lease.rc==1' "lease_held_skipped"
[[ ! -e "$TMP/lease_held.ntm.log" ]] && pass "lease_held_no_send" || fail "lease_held_no_send"

ledger="$TMP/fresh-lease.jsonl"
run_case fresh_success 0 pass "$ledger" --session fixture --pane 2 --digest "$DIGEST_A" --apply
out="$RUN_OUT"
assert_jq "$out" '.status=="fired_success" and .fired==true and .sent==true and .recovered==true and .transport_rc==0 and .success_measurement.payload.verdict=="success" and .release.primary.payload.result=="success"' "fresh_success_payload"
grep -q '^send fixture --pane=2 --no-cass-check continue answer=y$' "$TMP/fresh_success.ntm.log" && pass "fresh_success_send" || fail "fresh_success_send"
jq -s -e 'length == 2 and .[0].event=="acquire" and .[1].event=="release" and .[1].result=="success"' "$ledger" >/dev/null && pass "fresh_success_lease_order" || fail "fresh_success_lease_order"

ledger="$TMP/fail-send-lease.jsonl"
run_case send_failure 1 fail "$ledger" --session fixture --pane 2 --digest "$DIGEST_A" --apply
out="$RUN_OUT"
assert_jq "$out" '.status=="fired_failed" and .fired==true and .transport_rc==7 and .release.primary.payload.result=="failure"' "send_failure_payload"
jq -s -e 'length == 2 and .[0].event=="acquire" and .[1].event=="release" and .[1].result=="failure"' "$ledger" >/dev/null && pass "send_failure_lease_release" || fail "send_failure_lease_release"

ledger="$TMP/timeout-lease.jsonl"
run_case transport_timeout 4 hang "$ledger" --session fixture --pane 2 --digest "$DIGEST_B" --timeout-seconds 1 --apply
out="$RUN_OUT"
assert_jq "$out" '.status=="transport_timeout" and .fired==false and .transport_timeout_seconds==1 and .release.requested_result=="timeout" and .release.fallback.payload.status=="released"' "timeout_payload"
jq -s -e 'length == 2 and .[0].event=="acquire" and .[1].event=="release" and .[1].result=="failure"' "$ledger" >/dev/null && pass "timeout_lease_released" || fail "timeout_lease_released"

ledger="$TMP/malformed-lease.jsonl"
run_case malformed 3 pass "$ledger" --session fixture --pane not-a-number --apply
out="$RUN_OUT"
assert_jq "$out" '.status=="malformed" and .fired==false' "malformed_payload"
[[ ! -e "$TMP/malformed.ntm.log" && ! -e "$ledger" ]] && pass "malformed_no_side_effects" || fail "malformed_no_side_effects"

printf 'Summary: %s cases, %s passed, %s failed\n' "$case_count" "$pass_count" "$fail_count"
[[ "$case_count" -eq 8 && "$fail_count" -eq 0 ]]
