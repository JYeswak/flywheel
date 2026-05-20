#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
APPEND="$ROOT/.flywheel/scripts/append-safe-write.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/worker-pane1-bridge.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

repo="$TMP/repo"
mkdir -p "$repo/.flywheel"
log="$repo/.flywheel/dispatch-log.jsonl"
ledger="$repo/.flywheel/runtime/pane1-sprint-complete-bridge.jsonl"
calls="$TMP/ntm.calls"

cat >"$TMP/ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\t%s\n' "$(date -u +%s)" "$*" >>"${FAKE_NTM_CALLS:?}"
case "${1:-}" in
  preflight) printf '{"error_count":0,"warning_count":0,"findings":[]}\n' ;;
  assign) printf '{"assigned":true}\n' ;;
  send) printf '{"sent":true}\n' ;;
  wait) printf '{"status":"generating"}\n' ;;
  history) printf '[]\n' ;;
  *) printf '{"ok":true}\n' ;;
esac
SH
chmod +x "$TMP/ntm"

export FAKE_NTM_CALLS="$calls"
export FLYWHEEL_PANE1_SPRINT_CALLBACK_NTM="$TMP/ntm"
export FLYWHEEL_PANE1_SPRINT_CALLBACK_LEDGER="$ledger"
export FLYWHEEL_PANE1_SPRINT_CALLBACK_TIMEOUT_SECONDS=60

task_file="$TMP/noop-sprint.md"
printf 'No-op sandbox sprint fixture.\n' >"$task_file"
FLYWHEEL_DISPATCH_LOG="$log" \
NTM="$TMP/ntm" \
FLYWHEEL_DISPATCH_AND_LOG_NOW_EPOCH=1777850100 \
  "$ROOT/.flywheel/scripts/dispatch-and-log.sh" \
    --session=flywheel \
    --pane=2 \
    --task-file="$task_file" \
    --task-id=noop-sprint-fixture \
    --mode goal \
    --origin-task-id noop-sprint-fixture \
    --goal-id goal-fixture \
    --sprint-id sprint-fixture >"$TMP/dispatch.json"

jq -e '.ntm_sent == true and .pane == 2' "$TMP/dispatch.json" >/dev/null \
  && pass "sandbox_noop_sprint_dispatched_to_worker_pane" \
  || { fail "sandbox_noop_sprint_dispatched_to_worker_pane"; cat "$TMP/dispatch.json" >&2; }

if grep -q 'send flywheel --pane=1' "$calls"; then
  fail "dispatch_alone_does_not_notify_pane1"
else
  pass "dispatch_alone_does_not_notify_pane1"
fi

payload="$(jq -nc '{
  schema_version:"callback-envelope/v1",
  event:"worker_callback",
  mode:"goal",
  status:"DONE",
  session:"flywheel",
  task_id:"flywheel-tfwjz",
  sprint_id:"sprint-fixture",
  picks_completed:3,
  beads_closed:["flywheel-a","flywheel-b","flywheel-c"],
  followup_beads:["flywheel-follow1","flywheel-follow2"],
  total_work_time:"42m",
  commit:"abc1234",
  tests:"PASS",
  evidence:["/tmp/evidence-a.json","tests/fixture.sh"]
}')"

start="$(date -u +%s)"
printf '%s\n' "$payload" | "$APPEND" --target "$log" --idempotency-key bridge-fixture-1 --json >"$TMP/append.json"
end="$(date -u +%s)"

jq -e '.status == "ok" and (.post_append_hooks[0].status == "sent")' "$TMP/append.json" >/dev/null \
  && pass "append_reports_pane1_bridge_sent" || { fail "append_reports_pane1_bridge_sent"; cat "$TMP/append.json" >&2; }

if [[ $((end - start)) -le 60 ]]; then
  pass "pane1_summary_within_60s"
else
  fail "pane1_summary_within_60s elapsed=$((end - start))"
fi

send_count="$(grep -c 'send flywheel --pane=1 --no-cass-check' "$calls" || true)"
[[ "$send_count" == "1" ]] && pass "one_ntm_send_to_pane1" || { fail "one_ntm_send_to_pane1 count=$send_count"; cat "$calls" >&2; }

message="$(cut -f2- "$calls")"
for expected in \
  "SPRINT DONE:" \
  "sprint=sprint-fixture" \
  "picks_completed=3" \
  "beads_closed=flywheel-a,flywheel-b,flywheel-c" \
  "followups=flywheel-follow1,flywheel-follow2" \
  "total_work_time=42m" \
  "evidence=/tmp/evidence-a.json,tests/fixture.sh"; do
  grep -F "$expected" <<<"$message" >/dev/null \
    && pass "message_contains_${expected%%=*}" \
    || fail "message missing: $expected"
done

jq -e '.status == "sent" and .session == "flywheel" and .pane == "1" and .task_id == "flywheel-tfwjz"' "$ledger" >/dev/null \
  && pass "bridge_ledger_records_send" || { fail "bridge_ledger_records_send"; cat "$ledger" >&2; }

printf '%s\n' "$payload" | "$APPEND" --target "$log" --json >"$TMP/append-duplicate.json"
send_count="$(grep -c 'send flywheel --pane=1 --no-cass-check' "$calls" || true)"
[[ "$send_count" == "1" ]] && pass "duplicate_callback_key_not_resent" || fail "duplicate_callback_key_not_resent count=$send_count"
jq -e '.post_append_hooks[0].reason == "duplicate_callback_key"' "$TMP/append-duplicate.json" >/dev/null \
  && pass "duplicate_reports_skip_reason" || { fail "duplicate_reports_skip_reason"; cat "$TMP/append-duplicate.json" >&2; }

already_sent="$(jq -c '. + {pane1_callback:"sent"}' <<<"$payload")"
printf '%s\n' "$already_sent" | "$APPEND" --target "$log" --json >"$TMP/append-already-sent.json"
send_count="$(grep -c 'send flywheel --pane=1 --no-cass-check' "$calls" || true)"
[[ "$send_count" == "2" ]] && pass "pane1_callback_sent_field_still_triggers_auto_send" || fail "pane1_callback_sent_field_still_triggers_auto_send count=$send_count"
jq -e '.post_append_hooks[0].status == "sent"' "$TMP/append-already-sent.json" >/dev/null \
  && pass "pane1_callback_sent_reports_sent" || { fail "pane1_callback_sent_reports_sent"; cat "$TMP/append-already-sent.json" >&2; }

non_goal="$(jq -nc '{schema_version:"callback-envelope/v1",mode:"loop",status:"DONE",task_id:"loop-task"}')"
printf '%s\n' "$non_goal" | "$APPEND" --target "$log" --json >"$TMP/append-nongoal.json"
send_count="$(grep -c 'send flywheel --pane=1 --no-cass-check' "$calls" || true)"
[[ "$send_count" == "2" ]] && pass "non_goal_callback_not_sent" || fail "non_goal_callback_not_sent count=$send_count"
jq -e '.post_append_hooks == []' "$TMP/append-nongoal.json" >/dev/null \
  && pass "non_goal_has_no_hook" || { fail "non_goal_has_no_hook"; cat "$TMP/append-nongoal.json" >&2; }

printf 'SUMMARY pass=%s fail=%s\n' "$pass_count" "$fail_count"
[[ "$fail_count" == "0" ]]
