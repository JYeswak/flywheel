#!/usr/bin/env bash
set -uo pipefail
SESSION="${SESSION:-flywheel}"
LOG="${FLYWHEEL_DISPATCH_LOG:-/Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl}"
NTM="${FLYWHEEL_NTM_BIN:-${NTM:-/Users/josh/.local/bin/ntm}}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="${FLYWHEEL_REPO:-$(cd "$SCRIPT_DIR/../.." && pwd -P)}"
BUILD_DISPATCH_PACKET="${BUILD_DISPATCH_PACKET:-$SCRIPT_DIR/build-dispatch-packet.sh}"
PANE=""; TASK_FILE=""; TASK_ID=""; BEAD=""; CALLBACK_BY=""; PIPELINE=""; LANE=""
iso_from_epoch() {
  date -u -r "$1" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null ||
    date -u -d "@$1" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null
}
callback_expected_json() {
  local raw="$1" base_epoch="$2" amount unit seconds deadline
  if [[ -z "$raw" ]]; then
    jq -nc '{value:null,input:null,legacy_duration:null,parse_status:"empty"}'; return
  fi
  if [[ "$raw" =~ ^\+([0-9]+)(s|sec|secs|second|seconds|m|min|mins|minute|minutes|h|hr|hrs|hour|hours)$ ]]; then
    amount="${BASH_REMATCH[1]}"; unit="${BASH_REMATCH[2]}"
    case "$unit" in
      s|sec|secs|second|seconds) seconds="$amount" ;;
      m|min|mins|minute|minutes) seconds=$((amount * 60)) ;;
      h|hr|hrs|hour|hours) seconds=$((amount * 3600)) ;;
    esac
    if deadline="$(iso_from_epoch "$((base_epoch + seconds))")"; then
      jq -nc --arg value "$deadline" --arg input "$raw" '{value:$value,input:$input,legacy_duration:$input,parse_status:"duration"}'
    else
      jq -nc --arg input "$raw" '{value:null,input:$input,legacy_duration:$input,parse_status:"unknown"}'
    fi; return
  fi
  if [[ "$raw" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
    jq -nc --arg value "$raw" '{value:$value,input:$value,legacy_duration:null,parse_status:"absolute"}'; return
  fi
  jq -nc --arg input "$raw" '{value:null,input:$input,legacy_duration:null,parse_status:"unknown"}'
}
json_attempt() {
  local label="$1"; shift
  local out rc
  out="$("$@" 2>&1)"; rc=$?
  if [[ $rc -eq 0 ]] && jq -e . >/dev/null 2>&1 <<<"$out"; then
    jq -nc --arg label "$label" --argjson data "$(jq -c . <<<"$out")" '{command:$label,success:true,json:$data,raw:null,rc:0}'
  elif [[ $rc -eq 0 ]]; then
    jq -nc --arg label "$label" --arg raw "$out" '{command:$label,success:true,json:null,raw:$raw,rc:0}'
  else
    jq -nc --arg label "$label" --arg raw "$out" --argjson rc "$rc" '{command:$label,success:false,json:null,raw:$raw,rc:$rc}'
  fi
}
while [[ $# -gt 0 ]]; do
  case "$1" in
    --pane=*) PANE="${1#*=}" ;;
    --task-file=*) TASK_FILE="${1#*=}" ;;
    --task-id=*) TASK_ID="${1#*=}" ;;
    --bead=*) BEAD="${1#*=}" ;;
    --callback-by=*) CALLBACK_BY="${1#*=}" ;;
    --pipeline=*) PIPELINE="${1#*=}" ;;
    --lane=*) LANE="${1#*=}" ;;
    --session=*) SESSION="${1#*=}" ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac; shift
done
if [[ -z "$PANE" || -z "$TASK_FILE" || -z "$TASK_ID" ]]; then
  echo "required: --pane=N --task-file=PATH --task-id=ID" >&2
  exit 2
fi
[[ -f "$TASK_FILE" ]] || { echo "task file does not exist: $TASK_FILE" >&2; exit 3; }
TS_EPOCH="${FLYWHEEL_DISPATCH_AND_LOG_NOW_EPOCH:-$(date -u +%s)}"
TS="$(iso_from_epoch "$TS_EPOCH")" || { echo "could not compute dispatch timestamp" >&2; exit 5; }
CALLBACK_EXPECTED="$(callback_expected_json "$CALLBACK_BY" "$TS_EPOCH")"
SEND_FILE="$TASK_FILE"
PACKET_JSON="$(jq -nc '{status:"not_applicable",packet_path:null,packet_sha256:null,validation_status:null}')"
if [[ -n "$BEAD" ]]; then
  PACKET_OUT="$("$BUILD_DISPATCH_PACKET" --bead-id "$BEAD" --target-pane "$PANE" --target-session "$SESSION" --task-id "$TASK_ID" --apply --json 2>&1)"
  PACKET_RC=$?
  [[ $PACKET_RC -eq 0 ]] || { echo "build-dispatch-packet failed (rc=$PACKET_RC): $PACKET_OUT" >&2; exit 6; }
  jq -e '.validation_status == "pass" and (.packet_path | type == "string")' >/dev/null 2>&1 <<<"$PACKET_OUT" ||
    { echo "build-dispatch-packet returned invalid packet json: $PACKET_OUT" >&2; exit 7; }
  PACKET_JSON="$(jq -c . <<<"$PACKET_OUT")"
  SEND_FILE="$(jq -r '.packet_path' <<<"$PACKET_JSON")"
fi
if [[ -n "$BEAD" ]]; then
  ASSIGN_JSON="$(json_attempt "ntm assign" "$NTM" assign "$SESSION" --repo "$REPO" --pane="$PANE" --beads="$BEAD" --prompt="$TASK_ID" --dry-run --json)"
else
  ASSIGN_JSON="$(json_attempt "ntm assign" "$NTM" assign "$SESSION" --repo "$REPO" --dry-run --limit=1 --json)"
fi
SEND_JSON="$(json_attempt "ntm send" "$NTM" send "$SESSION" --pane="$PANE" --no-cass-check --file="$SEND_FILE" --json)"
if ! jq -e '.success == true' >/dev/null <<<"$SEND_JSON"; then
  echo "ntm send failed: $(jq -r '.raw' <<<"$SEND_JSON")" >&2
  exit 4
fi
HISTORY_JSON="$(json_attempt "ntm history" "$NTM" history --session="$SESSION" --search="$TASK_ID" --limit=5 --json)"
HISTORY_COUNT="$(jq -r 'if .success and (.json|type) == "array" then (.json|length) elif .success then 1 else 0 end' <<<"$HISTORY_JSON")"
ROW="$(jq -nc \
  --arg ts "$TS" --arg session "$SESSION" --arg task_id "$TASK_ID" --arg pane "$PANE" \
  --arg task_file "$TASK_FILE" --arg bead "$BEAD" --arg pipeline "$PIPELINE" --arg lane "$LANE" \
  --argjson callback "$CALLBACK_EXPECTED" --argjson packet "$PACKET_JSON" \
  --argjson assign "$ASSIGN_JSON" --argjson send "$SEND_JSON" --argjson history "$HISTORY_JSON" --argjson history_count "$HISTORY_COUNT" \
  '{ts:$ts,session:$session,task_id:$task_id,pane:($pane|tonumber),task_file:$task_file,channel:"ntm",pane_state_source:"ntm_send",pane_state:"sent",native_assignment:$assign,native_send:$send,native_history:$history,history_entry_count:$history_count,canonical_packet:$packet,packet_path:$packet.packet_path,packet_sha256:$packet.packet_sha256,packet_validation_status:$packet.validation_status,bead:(if $bead == "" then null else $bead end),callback_expected_by:$callback.value,callback_expected_by_input:$callback.input,callback_expected_by_legacy_duration:$callback.legacy_duration,callback_expected_by_parse_status:$callback.parse_status,pipeline_slug:(if $pipeline == "" then null else $pipeline end),lane:(if $lane == "" then null else $lane end)}')"
printf '%s\n' "$ROW" >>"$LOG"
BEAD_RESULT="skipped"
if [[ -n "$BEAD" ]]; then
  br update "$BEAD" --status=in_progress >/dev/null 2>&1 && BEAD_RESULT="in_progress" || BEAD_RESULT="claim_blocked"
fi
jq -nc \
  --arg ts "$TS" --arg task_id "$TASK_ID" --arg pane "$PANE" --arg bead_status "$BEAD_RESULT" \
  --argjson packet "$PACKET_JSON" --argjson assign "$ASSIGN_JSON" --argjson send "$SEND_JSON" \
  --argjson history "$HISTORY_JSON" --argjson history_count "$HISTORY_COUNT" \
  '{ts:$ts,task_id:$task_id,pane:($pane|tonumber),ntm_sent:($send.success == true),log_appended:true,bead_status:$bead_status,packet_path:$packet.packet_path,packet_validation_status:$packet.validation_status,native_assign_success:($assign.success == true),native_send_success:($send.success == true),native_history_success:($history.success == true),history_entry_count:$history_count}'
