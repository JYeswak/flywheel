#!/usr/bin/env bash
set -euo pipefail

VERSION="dispatch-delivery-verify/v1"
NTM="${DISPATCH_DELIVERY_VERIFY_NTM:-/Users/josh/.local/bin/ntm}"
LEDGER="${DISPATCH_DELIVERY_VERIFY_LEDGER:-$HOME/.local/state/flywheel/dispatch-delivery-verify-ledger.jsonl}"
FUCKUP_LOG="${DISPATCH_DELIVERY_VERIFY_FUCKUP_LOG:-$HOME/.local/state/flywheel/fuckup-log.jsonl}"
SESSION=""
PANE=""
TASK_ID=""
TIMEOUT_SEC=10
JSON_OUT=0

usage() {
  cat <<'USAGE'
Usage:
  dispatch-delivery-verify.sh --session NAME --pane N --task-id ID [--timeout-sec 10] [--json]
  dispatch-delivery-verify.sh --info|--help|--examples

Verifies that a just-sent dispatch task_id is visible in the target pane buffer.
USAGE
}

examples() {
  cat <<'EXAMPLES'
dispatch-delivery-verify.sh --session flywheel --pane 2 --task-id abc123 --json
dispatch-delivery-verify.sh --session skillos --pane 3 --task-id skillos_dispatch_42 --timeout-sec 3
DISPATCH_DELIVERY_VERIFY_NTM=/tmp/fake-ntm dispatch-delivery-verify.sh --session fixture --pane 2 --task-id fixture --json
EXAMPLES
}

info() {
  jq -nc \
    --arg schema_version "$VERSION" \
    --arg ntm "$NTM" \
    --arg ledger "$LEDGER" \
    --argjson timeout_sec "$TIMEOUT_SEC" \
    '{
      schema_version:$schema_version,
      command:"dispatch-delivery-verify.sh",
      ntm:$ntm,
      ledger:$ledger,
      default_timeout_sec:$timeout_sec,
      output_schema:".flywheel/validation-schema/v1/dispatch-delivery-verify.schema.json",
      exit_codes:{"0":"verified","1":"not verified / fail closed","2":"usage"}
    }'
}

now_iso() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

json_string_or_null_arg() {
  local value="$1"
  if [[ -z "$value" ]]; then
    printf 'null'
  else
    jq -nc --arg value "$value" '$value'
  fi
}

tail_text() {
  local text="$1"
  printf '%s' "$text" | tail -c 2000
}

extract_capture() {
  local capture="$1"
  jq -c --arg pane "$PANE" '
    def object_text($p):
      if ($p.text? != null) then ($p.text | tostring)
      elif ($p.content? != null) then ($p.content | tostring)
      elif ($p.capture? != null) then ($p.capture | tostring)
      elif ($p.output? != null) then ($p.output | tostring)
      elif (($p.lines? // null) | type) == "array" then ($p.lines | map(tostring) | join("\n"))
      else "" end;
    def text_of($p):
      if ($p | type) == "object" then object_text($p)
      elif ($p | type) == "array" then ($p | map(tostring) | join("\n"))
      elif $p == null then ""
      else ($p | tostring) end;
    (.panes // null) as $panes
    | (
        if ($panes | type) == "array" then
          [$panes[]
            | select((((.pane // .pane_idx // .index // .id // "") | tostring) == $pane)
                or (($panes | length) == 1))]
          | .[0] // null
        elif ($panes | type) == "object" then
          ($panes[$pane] // null)
        else
          null
        end
      ) as $target
    | {
        capture_success:(.success // true),
        pane_found:($target != null),
        text:text_of($target),
        pane_state:(if ($target | type) == "object" then (($target.state // $target.status // $target.activity_state // null) | tostring) else null end),
        source_health:(.source_health // {})
      }
  ' <<<"$capture"
}

capture_once() {
  local tmp err rc
  tmp="$(mktemp "${TMPDIR:-/tmp}/dispatch-delivery-tail.XXXXXX")"
  err="$(mktemp "${TMPDIR:-/tmp}/dispatch-delivery-tail-err.XXXXXX")"
  set +e
  "$NTM" --robot-tail="$SESSION" --panes="$PANE" --lines=80 >"$tmp" 2>"$err"
  rc=$?
  set -e
  if [[ "$rc" -ne 0 ]]; then
    jq -nc --arg err "$(cat "$err")" --argjson rc "$rc" \
      '{ok:false,reason:"capture_failed",ntm_rc:$rc,stderr:$err,text:"",pane_state:null,source_health:{}}'
    rm -f "$tmp" "$err"
    return 0
  fi
  if ! jq -e . "$tmp" >/dev/null 2>&1; then
    jq -nc --arg body "$(cat "$tmp")" \
      '{ok:false,reason:"capture_failed",ntm_rc:0,stderr:"invalid robot-tail json",text:$body,pane_state:null,source_health:{}}'
    rm -f "$tmp" "$err"
    return 0
  fi

  local extracted
  extracted="$(extract_capture "$(cat "$tmp")" 2>/dev/null || true)"
  rm -f "$tmp" "$err"
  if [[ -z "$extracted" ]] || ! jq -e . >/dev/null 2>&1 <<<"$extracted"; then
    jq -nc '{ok:false,reason:"capture_failed",ntm_rc:0,stderr:"capture parse failed",text:"",pane_state:null,source_health:{}}'
    return 0
  fi
  jq -c '
    . as $e
    | ($e.source_health.status // $e.source_health.tmux.status // null) as $health_status
    | ($e.pane_state // "") as $pane_state
    | if (($e.capture_success | not)
          or ($e.pane_found | not)) then
        {ok:false,reason:"capture_failed",ntm_rc:0,stderr:"pane missing or capture unsuccessful",text:($e.text // ""),pane_state:$pane_state,source_health:($e.source_health // {})}
      elif ((($pane_state | ascii_upcase) | IN("ERROR","DEAD","CLOSED","UNRESPONSIVE"))
            or (($health_status // "" | tostring | ascii_downcase) == "error")) then
        {ok:false,reason:"pane_unhealthy",ntm_rc:0,stderr:"pane unhealthy",text:($e.text // ""),pane_state:$pane_state,source_health:($e.source_health // {})}
      else
        {ok:true,reason:null,ntm_rc:0,stderr:null,text:($e.text // ""),pane_state:$pane_state,source_health:($e.source_health // {})}
      end
  ' <<<"$extracted"
}

matched_line() {
  local text="$1"
  awk -v pat="$TASK_ID" 'index($0, pat) { print NR; exit }' <<<"$text"
}

build_row() {
  local verified="$1" reason="$2" matched="$3" text="$4" timeout="$5" attempts="$6" ntm_rc="$7" stderr="$8"
  local tail buffer_len matched_json reason_json tail_json stderr_json
  tail="$(tail_text "$text")"
  buffer_len="${#text}"
  if [[ -z "$matched" ]]; then matched_json="null"; else matched_json="$matched"; fi
  reason_json="$(json_string_or_null_arg "$reason")"
  tail_json="$(json_string_or_null_arg "$tail")"
  stderr_json="$(json_string_or_null_arg "$stderr")"
  jq -nc \
    --arg schema_version "$VERSION" \
    --arg ts "$(now_iso)" \
    --arg session "$SESSION" \
    --arg task_id "$TASK_ID" \
    --argjson pane "$PANE" \
    --argjson verified "$verified" \
    --argjson matched_at_line "$matched_json" \
    --argjson buffer_len "$buffer_len" \
    --argjson reason "$reason_json" \
    --argjson buffer_tail "$tail_json" \
    --argjson timeout_sec "$timeout" \
    --argjson attempts "$attempts" \
    --argjson ntm_rc "$ntm_rc" \
    --argjson stderr "$stderr_json" \
    '{
      schema_version:$schema_version,
      ts:$ts,
      session:$session,
      pane:$pane,
      task_id:$task_id,
      verified:$verified,
      matched_at_line:$matched_at_line,
      buffer_len:$buffer_len,
      reason:$reason,
      buffer_tail:$buffer_tail,
      timeout_sec:$timeout_sec,
      attempts:$attempts,
      ntm_rc:$ntm_rc,
      stderr:$stderr
    }'
}

append_jsonl() {
  local path="$1" row="$2"
  mkdir -p "$(dirname "$path")"
  jq -e -c . <<<"$row" >>"$path"
}

log_fuckup_row() {
  local reason="$1" stderr="$2"
  local row
  row="$(jq -nc \
    --arg ts "$(now_iso)" \
    --arg trauma_class "dispatch-delivery-verify-capture-failed" \
    --arg severity "high" \
    --arg session "$SESSION" \
    --argjson pane "$PANE" \
    --arg task_id "$TASK_ID" \
    --arg reason "$reason" \
    --arg stderr "$stderr" \
    '{ts:$ts,trauma_class:$trauma_class,class:$trauma_class,severity:$severity,session:$session,pane:$pane,task_id:$task_id,reason:$reason,what_happened:"dispatch delivery verification failed closed before prompt visibility proof",stderr:$stderr}')"
  append_jsonl "$FUCKUP_LOG" "$row" 2>/dev/null || true
}

emit() {
  local row="$1"
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '%s\n' "$row"
  else
    jq -r '"verified=\(.verified) task_id=\(.task_id) session=\(.session) pane=\(.pane) reason=\(.reason // "none") matched_at_line=\(.matched_at_line // "none")"' <<<"$row"
  fi
}

verify() {
  local deadline attempts capture ok reason text match row ntm_rc stderr
  deadline=$((SECONDS + TIMEOUT_SEC))
  attempts=0
  while :; do
    attempts=$((attempts + 1))
    capture="$(capture_once)"
    ok="$(jq -r '.ok' <<<"$capture")"
    reason="$(jq -r '.reason // ""' <<<"$capture")"
    text="$(jq -r '.text // ""' <<<"$capture")"
    ntm_rc="$(jq -r '.ntm_rc // 0' <<<"$capture")"
    stderr="$(jq -r '.stderr // ""' <<<"$capture")"

    if [[ "$ok" != "true" ]]; then
      row="$(build_row false "$reason" "" "$text" "$TIMEOUT_SEC" "$attempts" "$ntm_rc" "$stderr")"
      append_jsonl "$LEDGER" "$row" || return 1
      if [[ "$reason" == "capture_failed" ]]; then
        log_fuckup_row "$reason" "$stderr"
      fi
      emit "$row"
      return 1
    fi

    match="$(matched_line "$text")"
    if [[ -n "$match" ]]; then
      row="$(build_row true "" "$match" "$text" "$TIMEOUT_SEC" "$attempts" 0 "")"
      append_jsonl "$LEDGER" "$row" || return 1
      emit "$row"
      return 0
    fi

    if [[ "$SECONDS" -ge "$deadline" ]]; then
      row="$(build_row false "task_id_not_observed" "" "$text" "$TIMEOUT_SEC" "$attempts" 0 "")"
      append_jsonl "$LEDGER" "$row" || return 1
      emit "$row"
      return 1
    fi
    sleep 1
  done
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session) SESSION="${2:-}"; shift 2 ;;
    --session=*) SESSION="${1#*=}"; shift ;;
    --pane) PANE="${2:-}"; shift 2 ;;
    --pane=*) PANE="${1#*=}"; shift ;;
    --task-id) TASK_ID="${2:-}"; shift 2 ;;
    --task-id=*) TASK_ID="${1#*=}"; shift ;;
    --timeout-sec) TIMEOUT_SEC="${2:-}"; shift 2 ;;
    --timeout-sec=*) TIMEOUT_SEC="${1#*=}"; shift ;;
    --ntm) NTM="${2:-}"; shift 2 ;;
    --ntm=*) NTM="${1#*=}"; shift ;;
    --ledger) LEDGER="${2:-}"; shift 2 ;;
    --ledger=*) LEDGER="${1#*=}"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --help|-h) usage; exit 0 ;;
    --examples) examples; exit 0 ;;
    --info) info; exit 0 ;;
    *) echo "ERR: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$SESSION" && -n "$PANE" && -n "$TASK_ID" ]] || { usage >&2; exit 2; }
[[ "$PANE" =~ ^[0-9]+$ ]] || { echo "ERR: --pane must be an integer" >&2; exit 2; }
[[ "$TIMEOUT_SEC" =~ ^[0-9]+$ ]] || { echo "ERR: --timeout-sec must be an integer" >&2; exit 2; }

verify
