#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TAILER="$ROOT/.flywheel/scripts/pane1-bridge-tailer.sh"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

pass=0
fail=0

ok() {
  local name="$1"
  shift
  if "$@"; then
    pass=$((pass + 1))
    printf 'ok %d - %s\n' "$pass" "$name"
  else
    fail=$((fail + 1))
    printf 'not ok %d - %s\n' "$((pass + fail))" "$name"
  fi
}

ok_jq() {
  local name="$1"
  local expr="$2"
  local file="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass=$((pass + 1))
    printf 'ok %d - %s\n' "$pass" "$name"
  else
    fail=$((fail + 1))
    printf 'not ok %d - %s\n' "$((pass + fail))" "$name"
  fi
}

ok_jq_slurp() {
  local name="$1"
  local expr="$2"
  local file="$3"
  if jq -s -e "$expr" "$file" >/dev/null; then
    pass=$((pass + 1))
    printf 'ok %d - %s\n' "$pass" "$name"
  else
    fail=$((fail + 1))
    printf 'not ok %d - %s\n' "$((pass + fail))" "$name"
  fi
}

make_fake_ntm() {
  local path="$1"
  cat >"$path" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
calls="${FAKE_NTM_CALLS:?}"
mode="${FAKE_NTM_MODE:?}"
count_file="${FAKE_NTM_COUNT:?}"
count=0
[[ -f "$count_file" ]] && count="$(cat "$count_file")"
count=$((count + 1))
printf '%s' "$count" >"$count_file"
printf '%s\n' "$*" >>"$calls"
case "$mode" in
  fail2)
    if [[ "$count" -lt 3 ]]; then
      printf 'fixture timeout attempt %s\n' "$count" >&2
      exit 1
    fi
    printf 'Sent to pane 1\n'
    ;;
  failall)
    printf 'fixture timeout attempt %s\n' "$count" >&2
    exit 1
    ;;
  *)
    printf 'unknown mode\n' >&2
    exit 2
    ;;
esac
SH
  chmod +x "$path"
}

write_callback() {
  local log="$1" task="$2" sprint="$3"
  printf '%s\n' "{\"schema_version\":\"callback-envelope/v1\",\"ts\":\"2026-05-19T15:00:00Z\",\"event\":\"worker_callback\",\"mode\":\"goal\",\"goal_id\":\"$sprint\",\"phase\":\"fixture\",\"task_id\":\"$task\",\"bead\":\"$task\",\"status\":\"DONE\",\"session\":\"flywheel\",\"sprint_id\":\"$sprint\",\"picks_completed\":1,\"beads_closed\":[\"$task\"],\"followup_beads\":[],\"total_work_time\":\"under-1m\",\"git_committed\":\"yes\",\"commit\":\"abcdef12\",\"tests\":\"PASS\",\"pane1_callback\":\"sent\",\"br_close_executed\":\"yes\",\"evidence\":\"tests/pane1-callback-bridge-retry.sh\"}" >>"$log"
}

# Retry then success.
case1="$TMPDIR/retry-success"
mkdir -p "$case1"
fake1="$case1/ntm"
make_fake_ntm "$fake1"
log1="$case1/dispatch-log.jsonl"
ledger1="$case1/bridge-ledger.jsonl"
queue1="$case1/escalation.jsonl"
flag1="$case1/failure.flag"
calls1="$case1/calls.txt"
count1="$case1/count"
out1="$case1/out.json"
touch "$log1"
write_callback "$log1" "retry-task" "retry-sprint"
FAKE_NTM_MODE=fail2 FAKE_NTM_CALLS="$calls1" FAKE_NTM_COUNT="$count1" "$TAILER" \
  --dispatch-log "$log1" \
  --ledger "$ledger1" \
  --escalation-queue "$queue1" \
  --failure-flag "$flag1" \
  --ntm "$fake1" \
  --retry-delays 0,0,0 \
  --once \
  --json >"$out1"

ok_jq "retry success summary passes" '.status == "pass" and .sent == 1 and .failed == 0' "$out1"
ok "retry success calls ntm three times" test "$(wc -l <"$calls1" | tr -d ' ')" -eq 3
ok "retry success writes three ledger attempts" test "$(wc -l <"$ledger1" | tr -d ' ')" -eq 3
ok_jq_slurp "retry success ledger attempt sequence" '[.[].attempt_n] == [1,2,3]' "$ledger1"
ok_jq "retry success final sent" 'select(.attempt_n == 3) | .status == "sent" and .retry_reason == "fixture timeout attempt 2"' "$ledger1"
ok "retry success no escalation queue" test ! -e "$queue1"
ok "retry success no failure flag" test ! -e "$flag1"

# Permanent failure escalates.
case2="$TMPDIR/retry-fail"
mkdir -p "$case2"
fake2="$case2/ntm"
make_fake_ntm "$fake2"
log2="$case2/dispatch-log.jsonl"
ledger2="$case2/bridge-ledger.jsonl"
queue2="$case2/escalation.jsonl"
flag2="$case2/failure.flag"
calls2="$case2/calls.txt"
count2="$case2/count"
out2="$case2/out.json"
dash2="$case2/dashboard.json"
touch "$log2"
write_callback "$log2" "fail-task" "fail-sprint"
FAKE_NTM_MODE=failall FAKE_NTM_CALLS="$calls2" FAKE_NTM_COUNT="$count2" "$TAILER" \
  --dispatch-log "$log2" \
  --ledger "$ledger2" \
  --escalation-queue "$queue2" \
  --failure-flag "$flag2" \
  --ntm "$fake2" \
  --retry-delays 0,0,0 \
  --once \
  --json >"$out2" && rc2=0 || rc2=$?

ok "permanent failure exits nonzero" test "$rc2" -eq 1
ok "permanent failure calls three attempts plus fallback" test "$(wc -l <"$calls2" | tr -d ' ')" -eq 4
ok "permanent failure writes attempt and fallback ledger rows" test "$(wc -l <"$ledger2" | tr -d ' ')" -eq 4
ok_jq_slurp "permanent failure attempts recorded" '[.[].attempt_n] == [1,2,3,4]' "$ledger2"
ok_jq "permanent failure fallback marked" 'select(.attempt_n == 4) | .fallback == true and .status == "failed"' "$ledger2"
ok_jq "permanent failure queue row written" '.schema_version == "bridge-escalation/v1" and .sprint_id == "fail-sprint" and .task_id == "fail-task" and .attempts == 3' "$queue2"
ok "permanent failure flag has row count" test "$(tr -d ' \n' <"$flag2")" = "1"
ok_jq "permanent failure summary surfaces pending count" '.bridge_failure_pending_count == 1 and (.dashboard_line | contains("1"))' "$out2"
"$TAILER" \
  --dispatch-log "$log2" \
  --ledger "$ledger2" \
  --escalation-queue "$queue2" \
  --failure-flag "$flag2" \
  --status-dashboard \
  --json >"$dash2" && dash_rc=0 || dash_rc=$?
ok "status dashboard exits nonzero with pending failure" test "$dash_rc" -eq 1
ok_jq "status dashboard surfaces pending count" '.schema_version == "pane1-bridge-dashboard/v1" and .bridge_failure_pending_count == 1 and .status == "warn"' "$dash2"

printf 'SUMMARY pass=%d fail=%d\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
