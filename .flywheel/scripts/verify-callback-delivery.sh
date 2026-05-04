#!/usr/bin/env bash
set -euo pipefail

VERSION="worker-callback-delivery.v1"
NTM="${NTM:-/Users/josh/.local/bin/ntm}"
SESSION=""
PANE=""
TASK_ID=""
MESSAGE=""
MESSAGE_FILE=""
RETRIES="${VERIFY_CALLBACK_RETRIES:-3}"
WAIT_SECONDS="${VERIFY_CALLBACK_WAIT_SECONDS:-3}"
JSON=0
SEND=1
FAILED_PATH=""

usage() {
  printf '%s\n' "Usage: verify-callback-delivery.sh --session S --pane N --task-id ID (--message TEXT|--message-file PATH) [--json] [--no-send] [--retries N] [--wait-seconds N] [--ntm PATH]"
}

examples() {
  printf '%s\n' "Examples:"
  printf '%s\n' "  .flywheel/scripts/verify-callback-delivery.sh --session flywheel --pane 1 --task-id abc --message 'DONE abc evidence=/tmp/e.md callback_delivery_verified=pending' --json"
  printf '%s\n' "  .flywheel/scripts/verify-callback-delivery.sh --session flywheel --pane 1 --task-id abc --message-file /tmp/callback.txt --json"
}

schema() {
  jq -nc --arg version "$VERSION" '{
    schema:"flywheel.worker_callback_delivery.v1",
    version:$version,
    required_args:["session","pane","task_id","message|message_file"],
    output_fields:["status","callback_delivery_verified","attempts","failure_class","verify_method","failed_path"],
    exit_codes:{"0":"verified","1":"not_verified","2":"usage"}
  }'
}

info() {
  jq -nc --arg version "$VERSION" --arg ntm "$NTM" --arg retries "$RETRIES" --arg wait "$WAIT_SECONDS" \
    '{version:$version,ntm:$ntm,default_retries:($retries|tonumber),default_wait_seconds:($wait|tonumber)}'
}

json_string() {
  jq -Rn --arg value "$1" '$value'
}

load_message() {
  if [[ -n "$MESSAGE_FILE" ]]; then
    [[ -f "$MESSAGE_FILE" ]] || { echo "ERR: message file missing: $MESSAGE_FILE" >&2; exit 2; }
    MESSAGE="$(cat "$MESSAGE_FILE")"
  fi
  [[ -n "$MESSAGE" ]] || { echo "ERR: --message or --message-file required" >&2; exit 2; }
}

verify_in_text() {
  local text="$1"
  [[ "$text" == *"$TASK_ID"* ]] || return 1
  if [[ "$MESSAGE" == *"DONE"* && "$text" != *"DONE"* ]]; then
    return 1
  fi
  if [[ "$MESSAGE" == *"BLOCKED"* && "$text" != *"BLOCKED"* ]]; then
    return 1
  fi
  return 0
}

ntm_logs_text() {
  "$NTM" logs "$SESSION" --panes="$PANE" 2>/dev/null || true
}

ntm_copy_text() {
  local out="$1"
  "$NTM" copy "$SESSION:$PANE" -l 40 --redact redact --output "$out" --quiet 2>/dev/null || return 1
  cat "$out"
}

send_callback() {
  "$NTM" send "$SESSION" --pane="$PANE" --no-cass-check "$MESSAGE" >/dev/null 2>/dev/null
}

write_failure() {
  local reason="$1" logs="$2" copy_file="$3"
  FAILED_PATH="${FAILED_PATH:-/tmp/${TASK_ID}-callback-failed.md}"
  {
    printf '# Callback Delivery Verification Failed\n\n'
    printf 'task_id: %s\n' "$TASK_ID"
    printf 'session: %s\n' "$SESSION"
    printf 'pane: %s\n' "$PANE"
    printf 'failure_class: %s\n' "$reason"
    printf 'attempts: %s\n' "$RETRIES"
    printf 'callback_delivery_verified: false\n\n'
    printf '## Callback Message SHA256\n\n'
    printf '%s' "$MESSAGE" | shasum -a 256 | awk '{print $1}'
    printf '\n\n## Logs Probe\n\n```text\n%s\n```\n\n' "$logs"
    if [[ -f "$copy_file" ]]; then
      printf '## Copy Probe\n\n```text\n'
      cat "$copy_file"
      printf '\n```\n'
    fi
  } >"$FAILED_PATH"
}

emit_result() {
  local status="$1" verified="$2" attempts="$3" failure="$4" method="$5"
  jq -nc \
    --arg status "$status" \
    --argjson verified "$verified" \
    --argjson attempts "$attempts" \
    --arg failure "$failure" \
    --arg method "$method" \
    --arg failed_path "$FAILED_PATH" \
    '{status:$status,callback_delivery_verified:$verified,attempts:$attempts,failure_class:(if $failure == "" then null else $failure end),verify_method:(if $method == "" then null else $method end),failed_path:(if $failed_path == "" then null else $failed_path end)}'
}

verify_delivery() {
  local attempt logs copy_file copy_text send_rc=0
  copy_file="/tmp/${TASK_ID}-callback-verify.txt"
  for attempt in $(seq 1 "$RETRIES"); do
    if [[ "$SEND" -eq 1 ]]; then
      send_callback || send_rc=$?
      if [[ "$send_rc" -ne 0 ]]; then
        write_failure "ntm_send_failed" "" "$copy_file"
        emit_result "fail" false "$attempt" "ntm_send_failed" ""
        return 1
      fi
    fi
    sleep "$WAIT_SECONDS"
    logs="$(ntm_logs_text)"
    if verify_in_text "$logs"; then
      emit_result "pass" true "$attempt" "" "ntm_logs"
      return 0
    fi
    if copy_text="$(ntm_copy_text "$copy_file")"; then
      if verify_in_text "$copy_text"; then
        emit_result "pass" true "$attempt" "" "ntm_copy"
        return 0
      fi
    elif [[ "$attempt" -ge "$RETRIES" ]]; then
      write_failure "pane_disappeared" "$logs" "$copy_file"
      emit_result "fail" false "$attempt" "pane_disappeared" ""
      return 1
    fi
  done
  write_failure "callback_not_observed" "$(ntm_logs_text)" "$copy_file"
  emit_result "fail" false "$RETRIES" "callback_not_observed" ""
  return 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session) SESSION="${2:-}"; shift 2 ;;
    --pane) PANE="${2:-}"; shift 2 ;;
    --task-id) TASK_ID="${2:-}"; shift 2 ;;
    --message) MESSAGE="${2:-}"; shift 2 ;;
    --message-file) MESSAGE_FILE="${2:-}"; shift 2 ;;
    --retries) RETRIES="${2:-}"; shift 2 ;;
    --wait-seconds) WAIT_SECONDS="${2:-}"; shift 2 ;;
    --failed-path) FAILED_PATH="${2:-}"; shift 2 ;;
    --ntm) NTM="${2:-}"; shift 2 ;;
    --no-send) SEND=0; shift ;;
    --json) JSON=1; shift ;;
    --help|-h) usage; exit 0 ;;
    --examples) examples; exit 0 ;;
    --schema) schema; exit 0 ;;
    --info) info; exit 0 ;;
    *) echo "ERR: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$SESSION" && -n "$PANE" && -n "$TASK_ID" ]] || { usage >&2; exit 2; }
[[ "$RETRIES" =~ ^[0-9]+$ && "$RETRIES" -gt 0 ]] || { echo "ERR: --retries must be positive integer" >&2; exit 2; }
[[ "$WAIT_SECONDS" =~ ^[0-9]+$ ]] || { echo "ERR: --wait-seconds must be integer" >&2; exit 2; }
load_message

set +e
result="$(verify_delivery)"
rc=$?
set -e
if [[ "$JSON" -eq 1 ]]; then
  printf '%s\n' "$result"
else
  jq -r '"callback_delivery_verified=\(.callback_delivery_verified) status=\(.status) attempts=\(.attempts) failure_class=\(.failure_class // "none")"' <<<"$result"
fi
exit "$rc"
