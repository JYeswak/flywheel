#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/l70-ticks-punted-counter.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/l70-ticks-punted-counter.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
edge_count=0

pass() {
  printf 'PASS %s\n' "$1"
  pass_count=$((pass_count + 1))
}

edge() {
  printf 'PASS edge:%s\n' "$1"
  edge_count=$((edge_count + 1))
}

fail() {
  printf 'FAIL %s\n' "$1" >&2
  exit 1
}

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    return 0
  fi
  jq . "$file" >&2 || cat "$file" >&2
  fail "$label"
}

cat >"$TMP/jsonl-append.sh" <<'EOF'
#!/usr/bin/env bash
fw_jsonl_append_validated() {
  local path="$1" row="$2"
  [[ -n "$row" ]] || return 1
  jq -e 'type == "object"' >/dev/null <<<"$row" || return 1
  mkdir -p "$(dirname "$path")"
  jq -c '.' <<<"$row" >>"$path"
}
EOF
chmod +x "$TMP/jsonl-append.sh"

write_case() {
  local name="$1" activity="$2" ready="$3" log="$4"
  printf '%s\n' "$activity" >"$TMP/$name.activity.json"
  printf '%s\n' "$ready" >"$TMP/$name.ready.json"
  printf '%s\n' "$log" >"$TMP/$name.dispatch-log.jsonl"
}

run_case() {
  local name="$1" expected="$2"
  env \
    FLYWHEEL_JSONL_APPEND_LIB="$TMP/jsonl-append.sh" \
    L70_TICKS_PUNTED_LEDGER="$TMP/$name-ledger.jsonl" \
    L70_TICKS_PUNTED_CONTRACT_LEDGER="$TMP/$name-contract.jsonl" \
    L70_TICKS_PUNTED_ROBOT_ACTIVITY_FILE="$TMP/$name.activity.json" \
    L70_TICKS_PUNTED_READY_FILE="$TMP/$name.ready.json" \
    L70_TICKS_PUNTED_DISPATCH_LOG="$TMP/$name.dispatch-log.jsonl" \
    "$SCRIPT" --tick-id "$name" --json >"$TMP/$name.out"
  assert_jq "$TMP/$name.out" ".punted == $expected and .dry_run == true and .ledger_written == false" "$name classification"
  pass "$name"
}

bash -n "$SCRIPT" && edge "script_syntax"
"$SCRIPT" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.schema_version == "l70-ticks-punted/v1"' "info schema"
edge "info_schema"
"$SCRIPT" schema doctor --json >"$TMP/schema-doctor.json"
assert_jq "$TMP/schema-doctor.json" '.required | index("l70_ticks_punted_24h")' "doctor schema"
edge "doctor_schema"

write_case \
  punt \
  '{"agents":[{"pane_idx":2,"state":"WAITING"}]}' \
  '{"issues":[{"id":"flywheel-p0","status":"open","priority":0}]}' \
  '{"tick_id":"punt","message":"want me to dispatch flywheel-p0?"}'
run_case punt true

env \
  FLYWHEEL_JSONL_APPEND_LIB="$TMP/jsonl-append.sh" \
  L70_TICKS_PUNTED_LEDGER="$TMP/punt-ledger.jsonl" \
  L70_TICKS_PUNTED_CONTRACT_LEDGER="$TMP/punt-contract.jsonl" \
  L70_TICKS_PUNTED_ROBOT_ACTIVITY_FILE="$TMP/punt.activity.json" \
  L70_TICKS_PUNTED_READY_FILE="$TMP/punt.ready.json" \
  L70_TICKS_PUNTED_DISPATCH_LOG="$TMP/punt.dispatch-log.jsonl" \
  "$SCRIPT" --tick-id punt --apply --json >"$TMP/punt-apply.out"
assert_jq "$TMP/punt-apply.out" '.punted == true and .dry_run == false and .ledger_written == true' "punt apply writes ledger"
test "$(wc -l <"$TMP/punt-ledger.jsonl" | tr -d ' ')" = "1" || fail "punt ledger append count"

write_case \
  idle_no_ready \
  '{"agents":[{"pane_idx":2,"state":"WAITING"}]}' \
  '{"issues":[]}' \
  '{"tick_id":"idle_no_ready","message":"want me to dispatch?"}'
run_case idle_no_ready false
assert_jq "$TMP/idle_no_ready.out" '.reason == "no_ready_p0_p1_work"' "idle no ready reason"

write_case \
  busy \
  '{"agents":[{"pane_idx":2,"state":"GENERATING"}]}' \
  '{"issues":[{"id":"flywheel-p0","status":"open","priority":0}]}' \
  '{"tick_id":"busy","message":"want me to dispatch flywheel-p0?"}'
run_case busy false
assert_jq "$TMP/busy.out" '.reason == "no_idle_worker_capacity"' "busy reason"

write_case \
  dispatched \
  '{"agents":[{"pane_idx":2,"state":"WAITING"}]}' \
  '{"issues":[{"id":"flywheel-p0","status":"open","priority":0}]}' \
  '{"tick_id":"dispatched","event":"idle_pane_auto_dispatch","action":"dispatched","delivery_receipt":{"transport_accepted":true}}'
run_case dispatched false
assert_jq "$TMP/dispatched.out" '.reason == "dispatch_recorded"' "dispatched reason"

write_case \
  joshua_blocker \
  '{"agents":[{"pane_idx":2,"state":"WAITING"}]}' \
  '{"issues":[{"id":"flywheel-p0","status":"open","priority":0}]}' \
  '{"tick_id":"joshua_blocker","message":"ask {operator}","true_joshua_blocker":true}'
run_case joshua_blocker false
assert_jq "$TMP/joshua_blocker.out" '.reason == "true_joshua_blocker_recorded"' "joshua blocker reason"

write_case \
  first_tick \
  '{"agents":[]}' \
  '{"issues":[{"id":"flywheel-p0","status":"open","priority":0}]}' \
  ''
env \
  FLYWHEEL_JSONL_APPEND_LIB="$TMP/jsonl-append.sh" \
  L70_TICKS_PUNTED_ROBOT_ACTIVITY_FILE="$TMP/first_tick.activity.json" \
  L70_TICKS_PUNTED_READY_FILE="$TMP/first_tick.ready.json" \
  L70_TICKS_PUNTED_DISPATCH_LOG="$TMP/first_tick.dispatch-log.jsonl" \
  "$SCRIPT" --tick-id first_tick --json >"$TMP/first_tick.out"
assert_jq "$TMP/first_tick.out" '.punted == false and .reason == "no_idle_worker_capacity"' "first tick no workers"
edge "first_tick_no_workers"

threshold_ledger="$TMP/threshold-ledger.jsonl"
for n in $(seq 1 10); do
  jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg n "$n" \
    '{ts:$ts,tick_id:("threshold-"+$n),punted:true,reason:"fixture",idle_panes:1,ready_p0_count:1,ready_p1_count:0,dispatched:0,orch_turn_signal:"want_me_to_dispatch"}' >>"$threshold_ledger"
done
set +e
env L70_TICKS_PUNTED_LEDGER="$threshold_ledger" "$SCRIPT" --doctor --json >"$TMP/threshold-doctor.json"
doctor_rc=$?
set -e
test "$doctor_rc" = "1" || fail "doctor threshold rc"
assert_jq "$TMP/threshold-doctor.json" '.status == "error" and .l70_ticks_punted_24h == 10 and .l70_ticks_punted_rate_pct == 100 and .l70_ticks_punted_top_signal == "want_me_to_dispatch"' "doctor threshold error"
edge "doctor_threshold_error"

contract_ledger="$TMP/contract.jsonl"
env FLYWHEEL_JSONL_APPEND_LIB="$TMP/jsonl-append.sh" L70_TICKS_PUNTED_CONTRACT_LEDGER="$contract_ledger" \
  "$SCRIPT" repair --scope substrate-contract --apply --json >"$TMP/contract-repair.json"
assert_jq "$TMP/contract-repair.json" '.contract_self_row_action == "appended"' "contract self-row appended"
jq -e 'select(.primitive_name == "l70-ticks-punted-counter" and .measurement_field == "l70_ticks_punted_24h")' "$contract_ledger" >/dev/null || fail "contract ledger row"
edge "contract_self_row"

printf 'RESULT pass=%s/5 edges=%s\n' "$pass_count" "$edge_count"
[[ "$pass_count" == "5" ]]
