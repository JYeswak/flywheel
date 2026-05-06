#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/dispatch-self-test-delivery-identity.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/dispatch-self-test-delivery.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
test_cases=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }
case_pass() { test_cases=$((test_cases + 1)); pass "$1"; }
case_fail() { test_cases=$((test_cases + 1)); fail "$1"; }
key_for() { printf '%s' "$1" | shasum -a 256 | awk '{print "sha256:" $1}'; }

write_packet() {
  local path="$1" task="$2" key="$3"
  {
    printf '# DISPATCH: %s\n\n' "$task"
    printf 'Task ID: %s\n' "$task"
    printf 'To: flywheel:3 codex\n'
    printf 'idempotency_key: %s\n' "$key"
  } >"$path"
}

append_dispatch() {
  local log="$1" key="$2" task="$3"
  jq -nc --arg ts "2026-05-06T16:00:00Z" --arg key "$key" --arg task "$task" \
    '{ts:$ts,task_id:$task,idempotency_key:$key,status:"DISPATCHED"}' >>"$log"
}

append_callback() {
  local log="$1" key="$2" task="$3" verified="$4"
  jq -nc --arg ts "2026-05-06T16:03:00Z" --arg key "$key" --arg task "$task" --argjson verified "$verified" \
    '{ts:$ts,event:"callback_received",task_id:$task,idempotency_key:$key,callback_delivery_verified:$verified}' >>"$log"
}

run_capture() {
  local name="$1" expected_rc="$2"; shift 2
  set +e
  "$@" >"$TMP/$name.json" 2>"$TMP/$name.err"
  local rc=$?
  set -e
  if [[ "$rc" == "$expected_rc" ]]; then
    pass "$name rc=$expected_rc"
  else
    fail "$name expected_rc=$expected_rc actual_rc=$rc"
    cat "$TMP/$name.err" >&2 || true
  fi
}

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    case_pass "$label"
  else
    case_fail "$label"
    jq . "$file" >&2 || true
  fi
}

bash -n "$SCRIPT" && pass "script_syntax" || fail "script_syntax"
"$SCRIPT" --help >/dev/null && pass "help_exits" || fail "help_exits"
"$SCRIPT" --info --json | jq -e '(.subcommands | length) == 3 and (.canonical_cli_flags | length) == 5' >/dev/null \
  && pass "info_lists_subcommands_and_cli_verbs" || fail "info_lists_subcommands_and_cli_verbs"
"$SCRIPT" --examples --json | jq -e '(.examples | length) == 3' >/dev/null && pass "examples_json" || fail "examples_json"

fresh_key="$(key_for fresh)"
fresh_packet="$TMP/fresh.md"
fresh_log="$TMP/fresh-log.jsonl"
write_packet "$fresh_packet" "fresh-task" "$fresh_key"
run_capture fresh 0 "$SCRIPT" pretest --packet "$fresh_packet" --dispatch-log "$fresh_log" --lock-dir "$TMP/fresh-locks" --json
assert_jq "$TMP/fresh.json" '.verdict == "proceed" and .prior_dispatch == null and .idempotency_key == "'"$fresh_key"'"' "fresh_key_proceeds"

inflight_key="$(key_for inflight)"
inflight_packet="$TMP/inflight.md"
inflight_log="$TMP/inflight-log.jsonl"
write_packet "$inflight_packet" "inflight-task" "$inflight_key"
append_dispatch "$inflight_log" "$inflight_key" "inflight-task"
run_capture inflight 1 "$SCRIPT" pretest --packet "$inflight_packet" --dispatch-log "$inflight_log" --lock-dir "$TMP/inflight-locks" --json
assert_jq "$TMP/inflight.json" '.verdict == "refuse_in_flight" and .prior_dispatch.callback_received_at == null' "duplicate_without_callback_refuses_in_flight"

unverified_key="$(key_for unverified)"
unverified_packet="$TMP/unverified.md"
unverified_log="$TMP/unverified-log.jsonl"
write_packet "$unverified_packet" "unverified-task" "$unverified_key"
append_dispatch "$unverified_log" "$unverified_key" "unverified-task"
append_callback "$unverified_log" "$unverified_key" "unverified-task" false
run_capture unverified 1 "$SCRIPT" pretest --packet "$unverified_packet" --dispatch-log "$unverified_log" --lock-dir "$TMP/unverified-locks" --json
assert_jq "$TMP/unverified.json" '.verdict == "refuse_in_flight" and .prior_dispatch.callback_received_at != null and .prior_dispatch.callback_delivery_verified == false' "callback_unverified_refuses_in_flight"

complete_key="$(key_for complete)"
complete_packet="$TMP/complete.md"
complete_log="$TMP/complete-log.jsonl"
write_packet "$complete_packet" "complete-task" "$complete_key"
append_dispatch "$complete_log" "$complete_key" "complete-task"
append_callback "$complete_log" "$complete_key" "complete-task" true
run_capture complete 1 "$SCRIPT" pretest --packet "$complete_packet" --dispatch-log "$complete_log" --lock-dir "$TMP/complete-locks" --json
assert_jq "$TMP/complete.json" '.verdict == "refuse_complete" and .prior_dispatch.callback_delivery_verified == true' "callback_verified_refuses_complete"

bad_packet="$TMP/bad.md"
printf 'no task identity here\n' >"$bad_packet"
run_capture malformed 2 "$SCRIPT" pretest --packet "$bad_packet" --dispatch-log "$TMP/malformed-log.jsonl" --lock-dir "$TMP/malformed-locks" --json
assert_jq "$TMP/malformed.json" '.verdict == "refuse_duplicate" and (.reason | test("malformed dispatch packet"))' "malformed_packet_fails_with_reason"

race_key="$(key_for race)"
race_packet="$TMP/race.md"
race_log="$TMP/race-log.jsonl"
race_locks="$TMP/race-locks"
write_packet "$race_packet" "race-task" "$race_key"
"$SCRIPT" pretest --packet "$race_packet" --dispatch-log "$race_log" --lock-dir "$race_locks" --json >"$TMP/race-a.json" &
pid_a=$!
"$SCRIPT" pretest --packet "$race_packet" --dispatch-log "$race_log" --lock-dir "$race_locks" --json >"$TMP/race-b.json" &
pid_b=$!
set +e
wait "$pid_a"; rc_a=$?
wait "$pid_b"; rc_b=$?
set -e
if [[ "$rc_a:$rc_b" == "0:1" || "$rc_a:$rc_b" == "1:0" ]] \
  && jq -s -e 'map(.verdict) | sort == ["proceed","refuse_in_flight"]' "$TMP/race-a.json" "$TMP/race-b.json" >/dev/null; then
  case_pass "concurrent_pretest_exactly_one_proceeds"
else
  case_fail "concurrent_pretest_exactly_one_proceeds"
  printf 'rc_a=%s rc_b=%s\n' "$rc_a" "$rc_b" >&2
  cat "$TMP/race-a.json" "$TMP/race-b.json" >&2 || true
fi

delivered_key="$(key_for delivered)"
delivered_ledger="$TMP/delivered-ledger.jsonl"
run_capture delivered_first 0 "$SCRIPT" mark-delivered --idempotency-key "$delivered_key" --ledger "$delivered_ledger" --lock-dir "$TMP/delivered-locks" --json
run_capture delivered_second 0 "$SCRIPT" mark-delivered --idempotency-key "$delivered_key" --ledger "$delivered_ledger" --lock-dir "$TMP/delivered-locks" --json
if [[ "$(wc -l <"$delivered_ledger" | tr -d ' ')" == "1" ]] \
  && jq -e '.ledger_written == true and .verdict == "proceed"' "$TMP/delivered_first.json" >/dev/null \
  && jq -e '.ledger_written == false and .verdict == "refuse_complete"' "$TMP/delivered_second.json" >/dev/null; then
  case_pass "mark_delivered_idempotent_single_record"
else
  case_fail "mark_delivered_idempotent_single_record"
  cat "$TMP/delivered_first.json" "$TMP/delivered_second.json" >&2 || true
fi

printf 'RESULT pass=%s fail=%s test_cases=%s\n' "$pass_count" "$fail_count" "$test_cases"
[[ "$test_cases" -ge 7 && "$fail_count" == "0" ]]
