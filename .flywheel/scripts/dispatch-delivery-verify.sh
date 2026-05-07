#!/usr/bin/env bash
set -euo pipefail

VERSION="dispatch-delivery-verify/v1"
NTM="${DISPATCH_DELIVERY_VERIFY_NTM:-/Users/josh/.local/bin/ntm}"
LEDGER="${DISPATCH_DELIVERY_VERIFY_LEDGER:-$HOME/.local/state/flywheel/dispatch-delivery-verify-ledger.jsonl}"
FUCKUP_LOG="${DISPATCH_DELIVERY_VERIFY_FUCKUP_LOG:-$HOME/.local/state/flywheel/fuckup-log.jsonl}"
SESSION=""; PANE=""; TASK_ID=""; TIMEOUT_SEC=10; JSON_OUT=0

usage(){ printf '%s\n' \
  'Usage: dispatch-delivery-verify.sh --session NAME --pane N --task-id ID [--timeout-sec 10] [--json]' \
  'Verifies L91 delivery via ntm history + ntm activity; no scrollback capture.'; }
examples(){ printf '%s\n' 'dispatch-delivery-verify.sh --session flywheel --pane 2 --task-id ntm-wire-in-123 --json'; }
now_iso(){ date -u +%Y-%m-%dT%H:%M:%SZ; }
tail_text(){ printf '%s' "$1" | tail -c 2000; }

info(){
  jq -nc --arg schema "$VERSION" --arg ntm "$NTM" --arg ledger "$LEDGER" \
    '{schema_version:$schema,command:"dispatch-delivery-verify.sh",ntm:$ntm,ledger:$ledger,native_surfaces:["ntm changes --json","ntm conflicts --json","ntm history --json","ntm activity --json"],output_schema:".flywheel/validation-schema/v1/dispatch-delivery-verify.schema.json",exit_codes:{"0":"verified","1":"not verified / fail closed","2":"usage"}}'
}

append_jsonl(){ local path="$1" row="$2"; mkdir -p "$(dirname "$path")"; jq -e -c . <<<"$row" >>"$path"; }

log_fuckup_row(){
  local reason="$1" stderr="$2" row
  row="$(jq -nc --arg ts "$(now_iso)" --arg session "$SESSION" --argjson pane "$PANE" --arg task_id "$TASK_ID" --arg reason "$reason" --arg stderr "$stderr" \
    '{ts:$ts,trauma_class:"dispatch-delivery-verify-native-probe-failed",class:"dispatch-delivery-verify-native-probe-failed",severity:"high",session:$session,pane:$pane,task_id:$task_id,reason:$reason,what_happened:"dispatch delivery verification failed closed before native prompt visibility proof",stderr:$stderr}')"
  append_jsonl "$FUCKUP_LOG" "$row" 2>/dev/null || true
}

history_probe(){
  local out rc
  set +e; out="$("$NTM" history --session "$SESSION" --search "$TASK_ID" --json --limit 20 2>&1)"; rc=$?; set -e
  if [[ "$rc" -ne 0 ]]; then jq -nc --arg stderr "$out" --argjson rc "$rc" '{ok:false,reason:"history_failed",stderr:$stderr,ntm_rc:$rc}'; return; fi
  jq -c --arg task "$TASK_ID" --arg pane "$PANE" '
    def entries: if type=="array" then . elif (.entries? | type)=="array" then .entries else [] end;
    def body: .prompt // .text // .message // .body // "";
    def target_hit: ((.targets // .target_panes // [] | map(tostring) | index($pane)) != null) or ((.pane // null | tostring) == $pane);
    [entries[] | select((body | contains($task)))] as $hits
    | ($hits[0] // null) as $hit
    | if $hit == null then {ok:true,found:false,target_hit:false,transport_accepted:false,prompt:"",matched_at_line:null}
      else {ok:true,found:true,target_hit:($hit|target_hit),transport_accepted:(if ($hit|has("success")) then ($hit.success == true) else true end),prompt:($hit|body),matched_at_line:1} end
  ' <<<"$out" 2>/dev/null || jq -nc '{ok:false,reason:"history_parse_failed",stderr:"invalid history json",ntm_rc:0}'
}

activity_probe(){
  local out rc
  set +e; out="$("$NTM" activity "$SESSION" --pane "$PANE" --json 2>&1)"; rc=$?; set -e
  if [[ "$rc" -ne 0 ]]; then jq -nc --arg stderr "$out" --argjson rc "$rc" '{ok:false,reason:"activity_failed",stderr:$stderr,ntm_rc:$rc,state:"UNKNOWN",work_started:false}'; return; fi
  jq -c --arg pane "$PANE" '
    def agents: if (.agents? | type)=="array" then .agents elif type=="array" then . else [] end;
    [agents[] | select(((.pane // .pane_idx // .id // "") | tostring) == $pane)] as $hits
    | ($hits[0] // null) as $hit
    | ($hit.state // $hit.status // "UNKNOWN" | tostring | ascii_upcase) as $state
    | {ok:($hit != null),reason:(if $hit == null then "pane_not_found" else null end),stderr:null,ntm_rc:0,state:$state,work_started:($state | test("THINKING|GENERATING|RUNNING|WORKING"))}
  ' <<<"$out" 2>/dev/null || jq -nc '{ok:false,reason:"activity_parse_failed",stderr:"invalid activity json",ntm_rc:0,state:"UNKNOWN",work_started:false}'
}

changes_probe(){ "$NTM" changes "$SESSION" --json 2>/dev/null || printf 'null\n'; }
conflicts_probe(){ "$NTM" conflicts "$SESSION" --json --limit 50 2>/dev/null || printf 'null\n'; }

build_row(){
  local verified="$1" reason="$2" matched="$3" text="$4" attempts="$5" ntm_rc="$6" stderr="$7"
  local changes conflicts
  changes="$(changes_probe)"
  conflicts="$(conflicts_probe)"
  jq -nc --arg schema "$VERSION" --arg ts "$(now_iso)" --arg session "$SESSION" --arg task_id "$TASK_ID" --argjson pane "$PANE" \
    --argjson verified "$verified" --argjson matched_at_line "$matched" --argjson buffer_len "${#text}" --arg reason "$reason" \
    --arg buffer_tail "$(tail_text "$text")" --argjson timeout_sec "$TIMEOUT_SEC" --argjson attempts "$attempts" --argjson ntm_rc "$ntm_rc" --arg stderr "$stderr" \
    --argjson changes "$changes" --argjson conflicts "$conflicts" \
    '{schema_version:$schema,ts:$ts,session:$session,pane:$pane,task_id:$task_id,verified:$verified,matched_at_line:$matched_at_line,buffer_len:$buffer_len,reason:(if $reason=="" then null else $reason end),buffer_tail:(if $buffer_tail=="" then null else $buffer_tail end),timeout_sec:$timeout_sec,attempts:$attempts,ntm_rc:$ntm_rc,stderr:(if $stderr=="" then null else $stderr end),ntm_changes:$changes,ntm_conflicts:$conflicts}'
}

emit(){ [[ "$JSON_OUT" -eq 1 ]] && printf '%s\n' "$1" || jq -r '"verified=\(.verified) task_id=\(.task_id) session=\(.session) pane=\(.pane) reason=\(.reason // "none") matched_at_line=\(.matched_at_line // "none")"' <<<"$1"; }

verify(){
  local deadline attempts h a reason row prompt matched ntm_rc stderr
  deadline=$((SECONDS + TIMEOUT_SEC)); attempts=0
  while :; do
    attempts=$((attempts + 1)); h="$(history_probe)"; a="$(activity_probe)"
    if [[ "$(jq -r '.ok' <<<"$h")" != "true" ]]; then reason="$(jq -r '.reason' <<<"$h")"; ntm_rc="$(jq -r '.ntm_rc // 0' <<<"$h")"; stderr="$(jq -r '.stderr // ""' <<<"$h")"; row="$(build_row false "$reason" null "" "$attempts" "$ntm_rc" "$stderr")"; append_jsonl "$LEDGER" "$row"; log_fuckup_row "$reason" "$stderr"; emit "$row"; return 1; fi
    if [[ "$(jq -r '.ok' <<<"$a")" != "true" ]]; then reason="$(jq -r '.reason' <<<"$a")"; ntm_rc="$(jq -r '.ntm_rc // 0' <<<"$a")"; stderr="$(jq -r '.stderr // ""' <<<"$a")"; row="$(build_row false "$reason" null "$(jq -r '.prompt // ""' <<<"$h")" "$attempts" "$ntm_rc" "$stderr")"; append_jsonl "$LEDGER" "$row"; log_fuckup_row "$reason" "$stderr"; emit "$row"; return 1; fi
    prompt="$(jq -r '.prompt // ""' <<<"$h")"; matched="$(jq -r '.matched_at_line // "null"' <<<"$h")"
    if [[ "$(jq -r '.found' <<<"$h")" != "true" ]]; then reason="task_id_not_observed"
    elif [[ "$(jq -r '.transport_accepted' <<<"$h")" != "true" ]]; then reason="transport_not_accepted"
    elif [[ "$(jq -r '.target_hit' <<<"$h")" != "true" ]]; then reason="prompt_not_targeted_to_pane"
    elif [[ "$(jq -r '.work_started' <<<"$a")" != "true" ]]; then reason="work_not_started"
    else row="$(build_row true "" "$matched" "$prompt" "$attempts" 0 "")"; append_jsonl "$LEDGER" "$row"; emit "$row"; return 0; fi
    if [[ "$SECONDS" -ge "$deadline" ]]; then row="$(build_row false "$reason" "$matched" "$prompt" "$attempts" 0 "")"; append_jsonl "$LEDGER" "$row"; emit "$row"; return 1; fi
    sleep 1
  done
}

while [[ $# -gt 0 ]]; do case "$1" in
  --session) SESSION="${2:-}"; shift 2;; --session=*) SESSION="${1#*=}"; shift;; --pane) PANE="${2:-}"; shift 2;; --pane=*) PANE="${1#*=}"; shift;;
  --task-id) TASK_ID="${2:-}"; shift 2;; --task-id=*) TASK_ID="${1#*=}"; shift;; --timeout-sec) TIMEOUT_SEC="${2:-}"; shift 2;; --timeout-sec=*) TIMEOUT_SEC="${1#*=}"; shift;;
  --ntm) NTM="${2:-}"; shift 2;; --ntm=*) NTM="${1#*=}"; shift;; --ledger) LEDGER="${2:-}"; shift 2;; --ledger=*) LEDGER="${1#*=}"; shift;; --json) JSON_OUT=1; shift;;
  --help|-h) usage; exit 0;; --examples) examples; exit 0;; --info) info; exit 0;; *) echo "ERR: unknown argument: $1" >&2; usage >&2; exit 2;;
esac; done

[[ -n "$SESSION" && -n "$PANE" && -n "$TASK_ID" ]] || { usage >&2; exit 2; }
[[ "$PANE" =~ ^[0-9]+$ && "$TIMEOUT_SEC" =~ ^[0-9]+$ ]] || { echo "ERR: --pane and --timeout-sec must be integers" >&2; exit 2; }
verify
