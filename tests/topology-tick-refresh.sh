#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/topology-tick-refresh.sh"
FIX="$ROOT/tests/fixtures/topology-tick-refresh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/topology-tick-refresh.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
NOW="2026-05-06T22:00:00Z"

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

run_refresh() {
  local label="$1" topology="$2" ledger="$3" mode="$4"; shift 4
  TOPOLOGY_REFRESH_FAKE_MODE="$mode" "$SCRIPT" \
    --topology "$topology" \
    --ntm-bin "$FIX/fake-ntm" \
    --ledger "$ledger" \
    --now "$NOW" \
    --json "$@" >"$TMP/$label.json"
}

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || cat "$file" >&2
  fi
}

assert_rc() {
  local want="$1" label="$2"; shift 2
  set +e
  "$@"
  local got=$?
  set -e
  [[ "$got" -eq "$want" ]] && pass "$label" || fail "$label rc=$got want=$want"
}

line_count() { wc -l <"$1" | tr -d ' '; }

chmod +x "$SCRIPT" "$FIX/fake-ntm"
bash -n "$SCRIPT" && pass "01_script_syntax" || fail "01_script_syntax"

top="$TMP/unchanged.jsonl"; ledger="$TMP/refresh-ledger.jsonl"
cp "$FIX/unchanged-shape.jsonl" "$top"
run_refresh refresh "$top" "$ledger" unchanged --apply
assert_jq "$TMP/refresh.json" '.status=="refreshed" and .refreshed_count==1 and .post_check.topology_rows_appended==1 and .max_age_sec_after==0' "02_stale_unchanged_shape_refreshes"

assert_jq "$ledger" '.status=="refreshed" and .run_id and .topology_shape_hash and .max_age_sec_before==7200 and .max_age_sec_after==0' "03_ledger_row_on_success_fire"

fresh="$TMP/fresh.jsonl"
jq -c --arg ts "$NOW" 'select(.session=="flywheel") | .effective_at=$ts' "$FIX/unchanged-shape.jsonl" | tail -n 1 >"$fresh"
run_refresh fresh "$fresh" "$TMP/fresh-ledger.jsonl" unchanged --apply
[[ "$(line_count "$fresh")" == "1" ]] && jq -e '.status=="already_fresh" and .already_fresh_count==1' "$TMP/fresh.json" >/dev/null \
  && pass "04_fresh_topology_already_fresh_no_duplicate" || fail "04_fresh_topology_already_fresh_no_duplicate"

missing="$TMP/missing-worker.jsonl"; cp "$FIX/unchanged-shape.jsonl" "$missing"
assert_rc 2 "05_missing_worker_pane_refuses" run_refresh missing "$missing" "$TMP/missing-ledger.jsonl" missing_worker --apply
jq -e '.status=="refused" and .refusal_reason=="worker_pane_missing" and .refreshed_count==0' "$TMP/missing.json" >/dev/null || fail "05_missing_worker_pane_refuses_detail"

extra="$TMP/extra.jsonl"; cp "$FIX/extra-agent-pane.jsonl" "$extra"
assert_rc 2 "06_extra_agent_pane_refuses" run_refresh extra "$extra" "$TMP/extra-ledger.jsonl" extra_agent --apply
jq -e '.refusal_reason=="extra_agent_pane" and .refreshed_count==0' "$TMP/extra.json" >/dev/null || fail "06_extra_agent_pane_refuses_detail"

kind="$TMP/kind.jsonl"; cp "$FIX/worker-kind-changed.jsonl" "$kind"
assert_rc 2 "07_worker_kind_changed_refuses" run_refresh kind "$kind" "$TMP/kind-ledger.jsonl" worker_kind_changed --apply
jq -e '.refusal_reason=="worker_kind_changed" and .refreshed_count==0' "$TMP/kind.json" >/dev/null || fail "07_worker_kind_changed_refuses_detail"

absent="$TMP/absent.jsonl"; cp "$FIX/missing-live-session.jsonl" "$absent"
assert_rc 2 "08_missing_live_session_refuses" run_refresh absent "$absent" "$TMP/absent-ledger.jsonl" missing_live_session --apply
jq -e '.refusal_reason=="missing_live_session" and .refreshed_count==0' "$TMP/absent.json" >/dev/null || fail "08_missing_live_session_refuses_detail"

empty="$TMP/empty.jsonl"; cp "$FIX/no-topology-row.jsonl" "$empty"
assert_rc 2 "09_no_topology_row_refuses" run_refresh no_topology "$empty" "$TMP/no-topology-ledger.jsonl" no_topology_row --apply
jq -e '.refusal_reason=="no_topology_row" and (.sessions[0].session=="orphan")' "$TMP/no_topology.json" >/dev/null || fail "09_no_topology_row_refuses_detail"

bad="$TMP/malformed.jsonl"; cp "$FIX/malformed.jsonl" "$bad"
assert_rc 2 "10_malformed_topology_row_refuses" run_refresh malformed "$bad" "$TMP/malformed-ledger.jsonl" unchanged --apply
jq -e '.status=="malformed" and .refusal_reason=="malformed_topology_row"' "$TMP/malformed.json" >/dev/null || fail "10_malformed_topology_row_refuses_detail"

locked="$TMP/locked.jsonl"; cp "$FIX/unchanged-shape.jsonl" "$locked"; lock="$locked.topology-refresh.lock"; ledger_lock="$TMP/lock-ledger.jsonl"
python3 - "$lock" "$SCRIPT" "$locked" "$FIX/fake-ntm" "$ledger_lock" "$NOW" "$TMP/locked.out" <<'PY'
import fcntl, subprocess, sys
lock, script, top, ntm, ledger, now, out = sys.argv[1:]
with open(lock, "a+") as handle:
    fcntl.flock(handle.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
    proc = subprocess.run([script, "--topology", top, "--ntm-bin", ntm, "--ledger", ledger, "--now", now, "--apply", "--json"], text=True, capture_output=True)
    open(out, "w", encoding="utf-8").write(proc.stdout)
    sys.exit(0 if proc.returncode != 0 else 9)
PY
jq -e '.status=="lock_held" and .post_check.ledger_row_written==true' "$TMP/locked.out" >/dev/null && [[ "$(line_count "$locked")" == "2" ]] \
  && pass "11_lock_held_nonzero_ledger_no_topology_append" || fail "11_lock_held_nonzero_ledger_no_topology_append"

auth_top="$TMP/auth.jsonl"; cp "$FIX/unchanged-shape.jsonl" "$auth_top"; auth_ledger="$TMP/auth-ledger.jsonl"
run_refresh auth "$auth_top" "$auth_ledger" unchanged --apply
env CAPACITY_HALT_AUTH_TOPOLOGY="$auth_top" CAPACITY_HALT_AUTH_NOW_EPOCH=1778104800 "$ROOT/.flywheel/scripts/capacity-halt-pane-authorization.sh" --session flywheel --pane 2 --json >"$TMP/auth-worker.json"
set +e
env CAPACITY_HALT_AUTH_TOPOLOGY="$auth_top" CAPACITY_HALT_AUTH_NOW_EPOCH=1778104800 "$ROOT/.flywheel/scripts/capacity-halt-pane-authorization.sh" --session flywheel --pane 1 --json >"$TMP/auth-orch.json"
auth_rc=$?
set -e
jq -e '.status=="authorized"' "$TMP/auth-worker.json" >/dev/null && jq -e '.status=="protected_refusal"' "$TMP/auth-orch.json" >/dev/null && [[ "$auth_rc" -eq 5 ]] \
  && pass "12_protected_pane_semantics_preserved" || fail "12_protected_pane_semantics_preserved"

dry="$TMP/dry.jsonl"; cp "$FIX/unchanged-shape.jsonl" "$dry"; before="$(line_count "$dry")"
run_refresh dry "$dry" "$TMP/dry-ledger.jsonl" unchanged
[[ "$(line_count "$dry")" == "$before" ]] && jq -e '.status=="skipped" and .dry_run==true and .post_check.ledger_row_written==true' "$TMP/dry.json" >/dev/null \
  && pass "13_dry_run_skips_topology_but_ledgers_fire" || fail "13_dry_run_skips_topology_but_ledgers_fire"

shape="$TMP/shape.jsonl"; cp "$FIX/shape-changed.jsonl" "$shape"
assert_rc 2 "14_pane_count_changed_refuses" run_refresh shape "$shape" "$TMP/shape-ledger.jsonl" shape_changed --apply
jq -e '.refusal_reason=="pane_count_changed" and .refreshed_count==0' "$TMP/shape.json" >/dev/null || fail "14_pane_count_changed_refuses_detail"

log_top="$TMP/logged.jsonl"; log_file="$TMP/fake-ntm.log"; cp "$FIX/unchanged-shape.jsonl" "$log_top"
TOPOLOGY_REFRESH_FAKE_LOG="$log_file" run_refresh logged "$log_top" "$TMP/logged-ledger.jsonl" unchanged --apply
grep -qx 'list --json' "$log_file" && grep -qx -- '--robot-activity=flywheel' "$log_file" \
  && pass "15_ntm_list_and_robot_activity_observed" || fail "15_ntm_list_and_robot_activity_observed"

jq -e '.schema_version=="topology-tick-refresh.result.v1" and .primitive_invoked=="topology-tick-refresh" and (.topology_shape_hash|type=="string" and length==64) and has("idempotency_key") and has("lock_path") and has("ledger_path") and has("post_check") and has("max_age_sec_before") and has("max_age_sec_after")' "$TMP/refresh.json" >/dev/null \
  && pass "16_shared_primitive_contract_fields_present" || fail "16_shared_primitive_contract_fields_present"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$pass_count" -eq 16 && "$fail_count" -eq 0 ]]
