#!/usr/bin/env bash
set -euo pipefail

SCHEMA="caam-rotate-and-respawn.result.v1"
CAAM="${CAAM_ROTATE_RESPAWN_CAAM_BIN:-$HOME/.local/bin/caam}"
NTM="${CAAM_ROTATE_RESPAWN_NTM_BIN:-$HOME/.local/bin/ntm}"
TOOL="${CAAM_ROTATE_RESPAWN_TOOL:-codex}"
DISPATCH_LOG="${CAAM_ROTATE_RESPAWN_DISPATCH_LOG:-.flywheel/dispatch-log.jsonl}"
LEDGER="${CAAM_ROTATE_RESPAWN_LEDGER:-$HOME/.local/state/flywheel/caam-rotate-and-respawn.jsonl}"
NOW="${CAAM_ROTATE_RESPAWN_NOW:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
SESSION=""; PANE=""; DIGEST=""; APPLY=0; JSON=0

usage(){ printf 'usage: caam-rotate-and-respawn.sh --session NAME --pane N [--apply|--dry-run] [--json]\n'; }
append(){ local p="$1" r="$2"; mkdir -p "$(dirname "$p")"; jq -e 'type=="object"' >/dev/null <<<"$r"; printf '%s\n' "$r" >>"$p"; }
emit(){ local status="$1" recovered="$2" current="$3" next="$4" task_file="$5" reason="${6:-}" applied=false; [[ "$APPLY" == 1 ]] && applied=true; jq -nc --arg schema "$SCHEMA" --arg status "$status" --argjson recovered "$recovered" --arg session "$SESSION" --argjson pane "${PANE:-0}" --arg current "$current" --arg next "$next" --arg task_file "$task_file" --arg reason "$reason" --arg ts "$NOW" --argjson applied "$applied" '{schema_version:$schema,ts:$ts,status:$status,recovered:$recovered,applied:$applied,session:$session,pane:$pane,current_profile:(if $current=="" then null else $current end),next_profile:(if $next=="" then null else $next end),redispatch_task_file:(if $task_file=="" then null else $task_file end),reason:(if $reason=="" then null else $reason end)}'; }

current_profile(){
  local out
  out="$("$CAAM" profile current 2>/dev/null || true)"
  awk -v tool="$TOOL" '
    $0 ~ tool "/" { n=split($0,a,"/"); print a[n]; found=1; exit }
    /^Current:/ { n=split($2,a,"/"); print a[n]; found=1; exit }
    END { if (!found) exit 1 }
  ' <<<"$out" 2>/dev/null && return 0
  "$CAAM" status "$TOOL" 2>/dev/null | awk -v tool="$TOOL" '$1==tool{print $2; found=1; exit} /^Current:/{n=split($2,a,"/"); print a[n]; found=1; exit} END{if(!found) exit 1}' || true
}

profiles(){
  if [[ -n "${CAAM_ROTATION_ROSTER:-}" ]]; then
    tr ',' '\n' <<<"$CAAM_ROTATION_ROSTER" | awk 'NF{gsub(/^[[:space:]]+|[[:space:]]+$/,""); print}'
    return
  fi
  "$CAAM" ls "$TOOL" 2>/dev/null | awk 'NR>1{p=$1; if (p=="*" || p=="-" || p=="●") p=$2; gsub(/^[^[:alnum:]_~-]+/,"",p); if (p != "" && p !~ /^_/) print p}'
}

next_profile(){
  local current="$1"
  profiles | awk -v current="$current" '$0 != current { print; exit }'
}

last_inflight_task(){
  [[ -s "$DISPATCH_LOG" ]] || return 0
  jq -sr --arg s "$SESSION" --argjson p "$PANE" '
    map(select((.session? // "") == $s and ((.pane? // .worker_pane? // 0) | tonumber) == $p and ((.callback_received_at? // null) == null)))
    | last
    | (.task_file? // .dispatch_file? // .prompt_file? // "")
  ' "$DISPATCH_LOG" 2>/dev/null || true
}

apply_rotation(){
  local next="$1" task_file="$2"
  "$CAAM" activate "$TOOL" "$next" >/dev/null
  "$NTM" send "$SESSION" --pane="$PANE" --no-cass-check $'\003' >/dev/null
  "$NTM" wait "$SESSION" --pane="$PANE" --until=healthy --timeout=20s --json >/dev/null 2>&1 || true
  "$NTM" respawn "$SESSION" --panes="$PANE" --json >/dev/null
  if [[ -n "$task_file" && -f "$task_file" ]]; then
    "$NTM" send "$SESSION" --pane="$PANE" --file "$task_file" --no-cass-check >/dev/null
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session) SESSION="${2:?}"; shift 2;;
    --session=*) SESSION="${1#*=}"; shift;;
    --pane) PANE="${2:?}"; shift 2;;
    --pane=*) PANE="${1#*=}"; shift;;
    --digest) DIGEST="${2:?}"; shift 2;;
    --digest=*) DIGEST="${1#*=}"; shift;;
    --caam-bin) CAAM="${2:?}"; shift 2;;
    --ntm-bin) NTM="${2:?}"; shift 2;;
    --dispatch-log) DISPATCH_LOG="${2:?}"; shift 2;;
    --ledger) LEDGER="${2:?}"; shift 2;;
    --tool) TOOL="${2:?}"; shift 2;;
    --apply) APPLY=1; shift;;
    --dry-run) APPLY=0; shift;;
    --json) JSON=1; shift;;
    -h|--help) usage; exit 0;;
    *) shift;;
  esac
done

if [[ -z "$SESSION" || -z "$PANE" || ! "$PANE" =~ ^[0-9]+$ ]]; then
  row="$(emit malformed false "" "" "" "session and numeric pane are required")"; printf '%s\n' "$row"; exit 3
fi

current="$(current_profile)"
next="$(next_profile "$current")"
task_file="$(last_inflight_task)"

if [[ -z "$current" ]]; then
  row="$(emit no_active_profile false "" "" "$task_file" "caam current profile unavailable")"; printf '%s\n' "$row"; exit 2
fi
if [[ -z "$next" ]]; then
  row="$(emit no_alternate_profile false "$current" "" "$task_file" "no alternate profile in rotation roster")"; printf '%s\n' "$row"; exit 2
fi

if [[ "$APPLY" == 1 ]]; then
  apply_rotation "$next" "$task_file"
  row="$(emit rotated true "$current" "$next" "$task_file")"
  append "$LEDGER" "$(jq -c --arg event caam_rotate_and_respawn --arg digest "$DIGEST" '. + {event:$event,digest:(if $digest=="" then null else $digest end)}' <<<"$row")"
else
  row="$(emit dry_run true "$current" "$next" "$task_file")"
fi

printf '%s\n' "$row"
