#!/usr/bin/env bash
set -u

VERSION="worker-callback-delivery.v3"; NTM="${NTM:-/Users/josh/.local/bin/ntm}"
SESSION="flywheel"; PANE="1"; TASK_ID=""; MESSAGE=""; MESSAGE_FILE=""
RETRIES=6; WAIT_SECONDS=1; JSON=0; SEND=1; DOCTOR=0; FAILED_PATH=""
SPOOL_DIR="${FLYWHEEL_CALLBACK_SPOOL_DIR:-$HOME/.local/state/flywheel/callback-spool}"
SPOOL_PATH=""

usage(){ cat <<'USAGE'
Usage: verify-callback-delivery.sh --task-id ID (--message TEXT|--message-file PATH) [--json] [--no-send]
Options: --session NAME --pane N --retries N --wait-seconds N --failed-path PATH --ntm PATH
         --spool-dir PATH (default: $HOME/.local/state/flywheel/callback-spool)
         --doctor (read-only environment check)
         --schema --examples --info --help
Failure classes: ntm_send_failed, pane_not_in_input_mode, pane_disappeared, callback_not_observed
On pane_not_in_input_mode the callback body is spooled to <spool-dir>/<session>/<task-id>.json
for callback-spool-reap.sh to retry once the pane is back in input mode.
USAGE
}
jesc(){ python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'; }
emit(){
  if [[ "$JSON" == 1 ]]; then
    printf '{"schema_version":"%s","status":"%s","callback_delivery_verified":%s,"attempts":%s,"failure_class":"%s","verify_method":"%s","failed_path":%s,"spool_path":%s}\n' "$VERSION" "$1" "$2" "$3" "$4" "$5" "$(printf '%s' "$6" | jesc)" "$(printf '%s' "${SPOOL_PATH:-}" | jesc)"
  else
    printf '%s callback_delivery_verified=%s attempts=%s failure_class=%s verify_method=%s failed_path=%s spool_path=%s\n' "$1" "$2" "$3" "$4" "$5" "$6" "${SPOOL_PATH:-}"
  fi
}

emit_doctor(){
  local ntm_status="missing" spool_status="missing" status="fail"
  [[ -x "$NTM" ]] && ntm_status="present"
  if [[ -d "$SPOOL_DIR" || ( -d "$(dirname "$SPOOL_DIR")" && -w "$(dirname "$SPOOL_DIR")" ) ]]; then
    spool_status="available"
  fi
  [[ "$ntm_status" == "present" && "$spool_status" == "available" ]] && status="ok"
  jq -nc \
    --arg schema_version "worker-callback-delivery-doctor.v1" \
    --arg status "$status" \
    --arg version "$VERSION" \
    --arg ntm "$NTM" \
    --arg ntm_status "$ntm_status" \
    --arg session "$SESSION" \
    --arg pane "$PANE" \
    --arg spool_dir "$SPOOL_DIR" \
    --arg spool_status "$spool_status" \
    '{schema_version:$schema_version,status:$status,version:$version,checks:{ntm:{path:$ntm,status:$ntm_status},target:{session:$session,pane:$pane},spool:{path:$spool_dir,status:$spool_status}},mutates:false}'
}

write_spool(){
  local cls="$1" err="$2" sp now
  mkdir -p "$SPOOL_DIR/$SESSION" 2>/dev/null || return 0
  sp="$SPOOL_DIR/$SESSION/$TASK_ID.json"
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if command -v jq >/dev/null 2>&1; then
    jq -n --arg schema_version "callback-spool/v1" \
          --arg ts "$now" --arg session "$SESSION" --arg pane "$PANE" \
          --arg task_id "$TASK_ID" --arg failure_class "$cls" \
          --arg send_stderr "$err" --arg message "$MESSAGE" \
          '{schema_version:$schema_version,ts:$ts,session:$session,pane:$pane,task_id:$task_id,failure_class:$failure_class,send_stderr:$send_stderr,message:$message,status:"pending",attempts:0}' >"$sp" 2>/dev/null || return 0
  else
    {
      printf '{"schema_version":"callback-spool/v1","ts":"%s","session":"%s","pane":"%s","task_id":"%s","failure_class":"%s","status":"pending","attempts":0,"message":' "$now" "$SESSION" "$PANE" "$TASK_ID" "$cls"
      printf '%s' "$MESSAGE" | jesc
      printf ',"send_stderr":'
      printf '%s' "$err" | jesc
      printf '}\n'
    } >"$sp"
  fi
  SPOOL_PATH="$sp"
}

while [[ $# -gt 0 ]]; do case "$1" in
  --session) SESSION="$2"; shift 2;; --pane) PANE="$2"; shift 2;;
  --task-id) TASK_ID="$2"; shift 2;; --message) MESSAGE="$2"; shift 2;;
  --message-file) MESSAGE_FILE="$2"; shift 2;; --retries) RETRIES="$2"; shift 2;;
  --wait-seconds) WAIT_SECONDS="$2"; shift 2;; --failed-path) FAILED_PATH="$2"; shift 2;;
  --spool-dir) SPOOL_DIR="$2"; shift 2;;
  --ntm) NTM="$2"; shift 2;; --no-send) SEND=0; shift;; --json) JSON=1; shift;;
  --doctor) DOCTOR=1; shift;;
  --schema) printf '{"schema_version":"%s","fields":["status","callback_delivery_verified","attempts","failure_class","verify_method","failed_path","spool_path"],"doctor_schema":"worker-callback-delivery-doctor.v1"}\n' "$VERSION"; exit 0;;
  --examples|--help|-h) usage; exit 0;; --info) printf 'verify-callback-delivery %s uses ntm history --json; spools to %s on pane_not_in_input_mode\n' "$VERSION" "$SPOOL_DIR"; exit 0;;
  *) echo "unknown argument: $1" >&2; usage >&2; exit 2;;
esac; done

if [[ "$DOCTOR" == 1 ]]; then
  emit_doctor
  exit 0
fi

[[ -n "$MESSAGE_FILE" ]] && MESSAGE="$(cat "$MESSAGE_FILE")"
[[ -z "$TASK_ID" || -z "$MESSAGE" ]] && { usage >&2; exit 2; }
[[ -z "$FAILED_PATH" ]] && FAILED_PATH="/tmp/${TASK_ID}-callback-failed.md"

token(){
  case "$MESSAGE" in *DONE*) printf DONE;; *BLOCKED*) printf BLOCKED;; *DECLINED*) printf DECLINED;; *) printf '%s' "$TASK_ID";; esac
}
history_json(){ "$NTM" history "$SESSION" --json 2>/dev/null || "$NTM" history --json 2>/dev/null; }
matches(){ local want; want="$(token)"; [[ "$1" == *"$TASK_ID"* && "$1" == *"$want"* ]]; }
fail_artifact(){
  {
    printf '# Callback delivery verification failed\n\n'
    printf -- '- task_id: %s\n- session: %s\n- pane: %s\n- failure_class: %s\n- attempts: %s\n- verify_method: ntm_history\n\n' "$TASK_ID" "$SESSION" "$PANE" "$1" "$2"
    # shellcheck disable=SC2016 # Markdown code fences are literal output.
    printf '## Expected callback\n\n```text\n%s\n```\n\n## ntm history --json probe\n\n```json\n%s\n```\n' "$MESSAGE" "$3"
  } >"$FAILED_PATH"
}

if [[ "$SEND" == 1 ]]; then
  err_log="$(mktemp -t verify-callback-send-err.XXXXXX)"
  if ! "$NTM" send "$SESSION" --pane="$PANE" --no-cass-check "$MESSAGE" >/dev/null 2>"$err_log"; then
    err_text="$(cat "$err_log" 2>/dev/null || true)"
    rm -f "$err_log"
    if printf '%s' "$err_text" | grep -qiE 'not in a mode|pane.*(copy|view|visual).*mode|input mode unavailable'; then
      cls="pane_not_in_input_mode"
      write_spool "$cls" "$err_text"
    else
      cls="ntm_send_failed"
    fi
    fail_artifact "$cls" 1 "$err_text"
    emit fail false 1 "$cls" ntm_history "$FAILED_PATH"; exit 1
  fi
  rm -f "$err_log"
fi

last=""
for ((i=1; i<=RETRIES; i++)); do
  if ! last="$(history_json)"; then fail_artifact pane_disappeared "$i" ""; emit fail false "$i" pane_disappeared ntm_history "$FAILED_PATH"; exit 1; fi
  if matches "$last"; then emit ok true "$i" none ntm_history ""; exit 0; fi
  sleep "$WAIT_SECONDS"
done
fail_artifact callback_not_observed "$RETRIES" "$last"
emit fail false "$RETRIES" callback_not_observed ntm_history "$FAILED_PATH"; exit 1
