#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/peer-orch-respawn-permit.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/peer-orch-permit.XXXXXX")"
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

expect_rc() {
  local name="$1" want="$2"
  shift 2
  set +e
  "$@" >"$TMP/$name.out" 2>"$TMP/$name.err"
  local rc=$?
  set -e
  if [[ "$rc" == "$want" ]]; then
    pass "${name}_rc_${want}"
  else
    fail "${name}_rc got=$rc want=$want"
    cat "$TMP/$name.err" >&2 || true
  fi
}

cat >"$TMP/jsonl-append.sh" <<'SH'
fw_jsonl_append_validated() {
  local path="$1" row="$2"
  jq -e 'type == "object"' >/dev/null <<<"$row" || return 1
  mkdir -p "$(dirname "$path")"
  jq -c '.' <<<"$row" >>"$path"
}
SH

cat >"$TMP/topology.jsonl" <<'JSONL'
{"session":"flywheel","effective_at":"2026-05-05T04:00:00Z","human_pane":0,"orchestrator_pane":1,"callback_pane":1,"worker_panes":[2,3]}
{"session":"skillos","effective_at":"2026-05-05T04:00:00Z","human_pane":0,"orchestrator_pane":1,"callback_pane":1,"worker_panes":[2]}
{"session":"skillos","effective_at":"2026-05-05T04:05:00Z","human_pane":0,"orchestrator_pane":1,"callback_pane":1,"worker_panes":[2,3]}
{"session":"alpsinsurance","effective_at":"2026-05-05T04:00:00Z","human_pane":0,"orchestrator_pane":1,"callback_pane":1,"worker_panes":[2]}
{"session":"mobile-eats","effective_at":"2026-05-05T04:00:00Z","human_pane":0,"orchestrator_pane":1,"callback_pane":1,"worker_panes":[2]}
JSONL

common_env=(
  "PEER_ORCH_RECOVERY_TOPOLOGY=$TMP/topology.jsonl"
  "PEER_ORCH_RECOVERY_LEDGER=$TMP/ledger.jsonl"
  "PEER_ORCH_RECOVERY_CONTRACT_LEDGER=$TMP/contract.jsonl"
  "PEER_ORCH_RECOVERY_JSONL_APPEND_LIB=$TMP/jsonl-append.sh"
  "PEER_ORCH_RECOVERY_HASH_WINDOW_SEC=0"
  "PEER_ORCH_RECOVERY_NOW=2026-05-05T04:30:00Z"
)

bash -n "$SCRIPT" && pass "script_syntax" || fail "script_syntax"
"$SCRIPT" --info --json | jq -e '.name == "peer-orch-respawn-permit.sh"' >/dev/null && pass "info_json" || fail "info_json"
"$SCRIPT" --examples --json | jq -e '(.examples | length) >= 5' >/dev/null && pass "examples_json" || fail "examples_json"
"$SCRIPT" quickstart --json | jq -e '(.steps | length) >= 5' >/dev/null && pass "quickstart_json" || fail "quickstart_json"
"$SCRIPT" schema doctor --json | jq -e '.required | index("peer_orch_recovery_count_24h")' >/dev/null && pass "schema_json" || fail "schema_json"
"$SCRIPT" completion bash | rg -q 'peer-orch-respawn-permit' && pass "completion_bash" || fail "completion_bash"

expect_rc self_refuse 4 env "${common_env[@]}" PEER_ORCH_RECOVERY_SAMPLE1_TEXT='same' PEER_ORCH_RECOVERY_SAMPLE2_TEXT='same' \
  "$SCRIPT" --target-session flywheel --target-pane 1 --dry-run --json
assert_jq "$TMP/self_refuse.out" '.decision == "refuse" and .decision_reason == "self_orch_respawn_refused" and .ledger_written == false' "self_orch_refused"

expect_rc skillos_permit 0 env "${common_env[@]}" PEER_ORCH_RECOVERY_SAMPLE1_TEXT='frozen' PEER_ORCH_RECOVERY_SAMPLE2_TEXT='frozen' \
  "$SCRIPT" --target-session skillos --target-pane 1 --apply --json
assert_jq "$TMP/skillos_permit.out" '.decision == "permit" and .freeze_confirmed == true and .ledger_written == true' "skillos_peer_orch_permitted"
assert_jq "$TMP/ledger.jsonl" 'select(.target_session == "skillos" and .decision == "permit" and .success == true)' "apply_writes_permit_ledger"

expect_rc alps_refuse 4 env "${common_env[@]}" PEER_ORCH_RECOVERY_SAMPLE1_TEXT='frozen' PEER_ORCH_RECOVERY_SAMPLE2_TEXT='frozen' \
  "$SCRIPT" --target-session alpsinsurance --target-pane 1 --dry-run --json
assert_jq "$TMP/alps_refuse.out" '.decision == "refuse" and .decision_reason == "protected_session_refused"' "protected_alps_refused"

expect_rc worker_defer 4 env "${common_env[@]}" PEER_ORCH_RECOVERY_SAMPLE1_TEXT='frozen' PEER_ORCH_RECOVERY_SAMPLE2_TEXT='frozen' \
  "$SCRIPT" --target-session skillos --target-pane 2 --dry-run --json
assert_jq "$TMP/worker_defer.out" '.decision == "defer" and .decision_reason == "target_is_not_orchestrator_pane_use_worker_respawn_path"' "worker_pane_deferred"

expect_rc not_frozen 4 env "${common_env[@]}" PEER_ORCH_RECOVERY_SAMPLE1_TEXT='left' PEER_ORCH_RECOVERY_SAMPLE2_TEXT='right' \
  "$SCRIPT" --target-session skillos --target-pane 1 --dry-run --json
assert_jq "$TMP/not_frozen.out" '.decision == "refuse" and .decision_reason == "no_freeze_evidence" and .freeze_confirmed == false' "not_frozen_refused"

expect_rc cross_peer 4 env "${common_env[@]}" PEER_ORCH_RECOVERY_ACTOR_SESSION=mobile-eats PEER_ORCH_RECOVERY_ACTOR_PANE=1 PEER_ORCH_RECOVERY_SAMPLE1_TEXT='frozen' PEER_ORCH_RECOVERY_SAMPLE2_TEXT='frozen' \
  "$SCRIPT" --target-session skillos --target-pane 1 --dry-run --json
assert_jq "$TMP/cross_peer.out" '.decision == "refuse" and .decision_reason == "actor_not_flywheel_orchestrator"' "cross_peer_refused"

before_lines="$(wc -l <"$TMP/ledger.jsonl" | tr -d ' ')"
expect_rc dry_run_no_mutation 0 env "${common_env[@]}" PEER_ORCH_RECOVERY_SAMPLE1_TEXT='frozen' PEER_ORCH_RECOVERY_SAMPLE2_TEXT='frozen' \
  "$SCRIPT" --target-session skillos --target-pane 1 --dry-run --json
after_lines="$(wc -l <"$TMP/ledger.jsonl" | tr -d ' ')"
if [[ "$before_lines" == "$after_lines" ]]; then pass "dry_run_does_not_mutate"; else fail "dry_run_mutated_ledger"; fi

env "${common_env[@]}" "$SCRIPT" --doctor --json >"$TMP/doctor.out"
assert_jq "$TMP/doctor.out" '.schema_version == "peer-orch-recovery-permit.doctor.v1" and .peer_orch_recovery_count_24h == 1 and .substrate_loop_contract_self_row_action == "appended"' "doctor_fields_and_contract_row"
assert_jq "$TMP/contract.jsonl" 'select(.primitive_name == "peer-orch-respawn-permit" and .measurement_field == "peer_orch_recovery_count_24h")' "contract_self_row_written"

if [[ "$fail_count" -ne 0 ]]; then
  printf 'FAILED peer-orch-respawn-permit tests pass=%s fail=%s\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'OK peer-orch-respawn-permit tests pass=%s/6\n' "$pass_count"
