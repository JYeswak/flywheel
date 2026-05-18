#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/dispatch-and-log.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/dispatch-and-log-ntm-gates.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

write_fake_ntm() {
  local mode="$1"
  cat >"$TMP/ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${FAKE_NTM_CALL_LOG:?}"
case "${1:-}" in
  preflight)
    if [[ "${FAKE_NTM_MODE:-clean}" == "preflight_error" ]]; then
      printf '{"error_count":1,"warning_count":0,"findings":[{"severity":"error","message":"fixture secret"}]}\n'
      exit 1
    fi
    printf '{"error_count":0,"warning_count":0,"findings":[]}\n'
    ;;
  send)
    printf '{"sent":true}\n'
    ;;
  wait)
    if [[ "${FAKE_NTM_MODE:-clean}" == "wait_timeout" ]]; then
      printf '{"status":"timeout"}\n'
      exit 1
    fi
    printf '{"status":"generating"}\n'
    ;;
  *)
    printf '{"ok":true}\n'
    ;;
esac
SH
  chmod +x "$TMP/ntm"
  printf '%s\n' "$mode" >"$TMP/mode"
}

task_file="$TMP/task.md"
printf 'fixture task\n' >"$task_file"

run_dispatch() {
  local mode="$1" task_id="$2" log="$3" out="$4"
  : >"$TMP/calls.log"
  write_fake_ntm "$mode"
  FAKE_NTM_MODE="$mode" \
  FAKE_NTM_CALL_LOG="$TMP/calls.log" \
  FLYWHEEL_DISPATCH_LOG="$log" \
  FLYWHEEL_DISPATCH_AND_LOG_NOW_EPOCH=1777850000 \
  NTM="$TMP/ntm" \
    "$SCRIPT" --session=fixture --pane=2 --task-file="$task_file" --task-id="$task_id" \
      --mode loop --origin-task-id "$task_id-origin" --tick-id "$task_id-tick" --goal-id "$task_id-goal" >"$out" 2>"$out.err"
}

log="$TMP/dispatch-log.jsonl"
out="$TMP/clean.out"
run_dispatch clean clean "$log" "$out"

preflight_line="$(grep -n '^preflight ' "$TMP/calls.log" | cut -d: -f1)"
send_line="$(grep -n '^send ' "$TMP/calls.log" | cut -d: -f1)"
wait_line="$(grep -n '^wait ' "$TMP/calls.log" | cut -d: -f1)"
if [[ "$preflight_line" -lt "$send_line" && "$send_line" -lt "$wait_line" ]]; then
  pass "ntm_preflight_before_send_and_wait_after_send"
else
  fail "ntm_preflight_before_send_and_wait_after_send"
  cat "$TMP/calls.log" >&2
fi

if jq -e '
  .task_id == "clean"
  and .preflight_status == "clean"
  and .preflight_errors == 0
  and .dispatch_status == "generating_verified"
  and .wait_generating_success == true
  and .mode == "loop"
  and .origin_task_id == "clean-origin"
  and .tick_id == "clean-tick"
  and .goal_id == "clean-goal"
' "$log" >/dev/null; then
  pass "dispatch_log_records_preflight_generating_wait_and_split_metadata"
else
  fail "dispatch_log_records_preflight_generating_wait_and_split_metadata"
  cat "$log" >&2
fi

blocked_log="$TMP/blocked-log.jsonl"
set +e
run_dispatch preflight_error blocked "$blocked_log" "$TMP/blocked.out"
rc=$?
set -e
if [[ "$rc" == "8" ]] && ! grep -q '^send ' "$TMP/calls.log"; then
  pass "preflight_error_blocks_before_send"
else
  fail "preflight_error_blocks_before_send rc=$rc"
  cat "$TMP/calls.log" >&2
fi

wait_log="$TMP/wait-log.jsonl"
set +e
run_dispatch wait_timeout wait-timeout "$wait_log" "$TMP/wait.out"
rc=$?
set -e
if [[ "$rc" == "9" ]] && jq -e '.dispatch_status == "generating_wait_failed"' "$wait_log" >/dev/null; then
  pass "wait_generating_failure_is_logged_and_blocks"
else
  fail "wait_generating_failure_is_logged_and_blocks rc=$rc"
  cat "$wait_log" >&2 || true
fi

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
[[ "$fail_count" == "0" ]]
