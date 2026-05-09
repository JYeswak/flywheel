#!/usr/bin/env bash
set -euo pipefail

NTM_BIN="${NTM_BIN:-/Users/josh/.local/bin/ntm}"
OUT_FILE="${NTM_FLEET_HEALTH_OUT:-$HOME/.local/state/flywheel/ntm-fleet-health.jsonl}"
LOCK_FILE="${NTM_FLEET_HEALTH_LOCK:-$HOME/.local/state/flywheel/ntm-fleet-health.lock}"
JSONL_APPEND_LIB="${FLYWHEEL_JSONL_APPEND_LIB:-$HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh}"
TOPOLOGY_FILE="${NTM_SESSION_TOPOLOGY:-$HOME/.local/state/flywheel/session-topology.jsonl}"
THRESHOLD="${NTM_HEALTH_THRESHOLD:-10m}"
AUTO_RESTART_STUCK=0; APPLY=0; JSON_OUT=0

usage(){ printf '%s\n' \
  'Usage: ntm-fleet-health.sh [--auto-restart-stuck] [--apply] [--json]' \
  'Delegates to ntm health. Restart behavior is preview-only unless --apply is passed.'; }

while [[ $# -gt 0 ]]; do case "$1" in
  --auto-restart-stuck) AUTO_RESTART_STUCK=1; shift;; --apply) APPLY=1; shift;; --json) JSON_OUT=1; shift;;
  --threshold) THRESHOLD="${2:?--threshold requires value}"; shift 2;; --threshold=*) THRESHOLD="${1#*=}"; shift;;
  --out-file) OUT_FILE="${2:?--out-file requires path}"; shift 2;; --out-file=*) OUT_FILE="${1#*=}"; shift;;
  --ntm-bin) NTM_BIN="${2:?--ntm-bin requires path}"; shift 2;; --ntm-bin=*) NTM_BIN="${1#*=}"; shift;;
  --topology-file) TOPOLOGY_FILE="${2:?--topology-file requires path}"; shift 2;; --topology-file=*) TOPOLOGY_FILE="${1#*=}"; shift;;
  --help|-h) usage; exit 0;; *) printf 'ERR: unknown argument: %s\n' "$1" >&2; usage >&2; exit 64;;
esac; done

[[ "$AUTO_RESTART_STUCK" -eq 1 && "$APPLY" -ne 1 ]] && printf 'WARNING: --auto-restart-stuck is preview-only; pass --apply to execute ntm health mutations.\n' >&2

wrap_json(){ local raw="$1" rc="$2"; if jq -ce . >/dev/null 2>&1 <<<"$raw"; then jq -c . <<<"$raw"; else jq -cn --arg raw "$raw" --argjson exit_code "$rc" '{success:false,parse_error:true,exit_code:$exit_code,raw:$raw}'; fi; }

append_row(){
  local row="$1" label="$2" rc; [[ "${NTM_FLEET_HEALTH_FORCE_EMPTY_ROW:-0}" == "1" ]] && row=""
  if [[ ! -f "$JSONL_APPEND_LIB" ]]; then printf 'WARN: skipped %s append; JSONL primitive unavailable: %s\n' "$label" "$JSONL_APPEND_LIB" >&2; return 0; fi
  # shellcheck source=/dev/null
  source "$JSONL_APPEND_LIB"; set +e; fw_jsonl_append_validated "$OUT_FILE" "$row"; rc=$?; set -e
  [[ "$rc" -eq 0 ]] || printf 'WARN: failed to append %s row to %s rc=%s\n' "$label" "$OUT_FILE" "$rc" >&2
}

emit(){ [[ "$JSON_OUT" -eq 1 ]] && jq -cn --argjson row "$1" --argjson auto_restart "$2" '{schema_version:"ntm-fleet-health/result/v1",ledger_row:$row,auto_restart:$auto_restart}'; }

auto_preview(){
  local session="$1" health="$2"
  if [[ "$AUTO_RESTART_STUCK" -ne 1 ]]; then jq -cn '{enabled:false,apply:false,action:"none"}'
  elif [[ "$APPLY" -eq 1 ]]; then jq -cn --arg session "$session" '{enabled:true,apply:true,action:"restart_invoked",session:$session}'
  else jq -cn --arg session "$session" --argjson health "$health" '[($health.stuck_panes // $health.stuck // [])[]? | select((.stuck // .needs_restart // false) == true) | (.pane // .pane_idx // .id)] as $panes | {enabled:true,apply:false,action:"would_restart",session:$session,pane:($panes[0] // null),panes:$panes,reason:"pass --apply to run ntm health --auto-restart-stuck"}'
  fi
}

role_split(){
  jq -cn --argjson t "$1" --argjson h "$2" 'def panes:$h.panes//$h.agents//[]; def pid:.pane//.pane_idx//.id//null; def bad:((.status//.process_status//"unknown")|tostring|ascii_downcase|test("error|exited|failed|dead|stuck|unhealthy")); def role:(pid|tostring) as $p | ((.agent_type//.type//"")|tostring|ascii_downcase) as $k | if (($t.human_pane//null)!=null and $p==($t.human_pane|tostring)) or $k=="user" then "user" elif (($t.orchestrator_pane//null)!=null and $p==($t.orchestrator_pane|tostring)) or (($t.callback_pane//null)!=null and $p==($t.callback_pane|tostring)) or (($t.worker_panes//[]|map(tostring)|index($p))!=null) or ($k|test("^(cod|codex|cc|claude)$")) then "agent" else "other" end; def source:(pid|tostring) as $p | ((.agent_type//.type//"")|tostring|ascii_downcase) as $k | if (($t.human_pane//null)!=null and $p==($t.human_pane|tostring)) then "topology.human_pane" elif $k=="user" then "ntm.agent_type" elif (($t.orchestrator_pane//null)!=null and $p==($t.orchestrator_pane|tostring)) then "topology.orchestrator_pane" elif (($t.callback_pane//null)!=null and $p==($t.callback_pane|tostring)) then "topology.callback_pane" elif (($t.worker_panes//[]|map(tostring)|index($p))!=null) then "topology.worker_panes" elif ($k|test("^(cod|codex|cc|claude)$")) then "ntm.agent_type" else "unknown" end; def deco:panes[]|{pane:pid,role:role,role_source:source,status:(.status//.process_status//"unknown"),process_status:(.process_status//null),agent_type:(.agent_type//.type//null),activity:(.activity//.state//null),unhealthy:bad}; def summary($r):[deco|select(.role==$r)] as $rows|($rows|map(select(.unhealthy))) as $bad|{status:(if ($rows|length)==0 then "unknown" elif ($bad|length)>0 then "error" else "ok" end),total:($rows|length),unhealthy_count:($bad|length),panes:$rows}; {schema_version:"ntm-health-role-split/v1",agent_pane_health:summary("agent"),user_pane_health:summary("user"),other_pane_health:summary("other")}'
}

mkdir -p "$(dirname "$OUT_FILE")" "$(dirname "$LOCK_FILE")"
if command -v flock >/dev/null 2>&1; then exec 9>"$LOCK_FILE"; flock -n 9 || { echo "another instance running"; exit 0; }
else if ! mkdir "$LOCK_FILE" 2>/dev/null; then echo "another instance running"; exit 0; fi; trap 'rmdir "$LOCK_FILE" 2>/dev/null || true' EXIT INT TERM; fi
NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

set +e; LIST_OUT="$("$NTM_BIN" list --json 2>&1)"; LIST_RC=$?; set -e
if [[ "$LIST_RC" -ne 0 ]]; then LIST_JSON="$(wrap_json "$LIST_OUT" "$LIST_RC")"; ROW="$(jq -cn --arg ts "$NOW" --argjson list "$LIST_JSON" '{ts:$ts,event:"session_discovery_failed",list:$list}')"; append_row "$ROW" "session_discovery_failed"; emit "$ROW" "$(jq -cn '{enabled:false,apply:false,action:"none"}')"; exit 0; fi

SESSIONS="$(jq -r 'if type=="array" then .[]? | (.name // .session // empty) elif (.sessions? | type)=="array" then .sessions[]? | (.name // .session // empty) else .name // .session // empty end' <<<"$LIST_OUT" 2>/dev/null || true)"
if [[ -z "$SESSIONS" ]]; then ROW="$(jq -cn --arg ts "$NOW" '{ts:$ts,event:"no_sessions_discovered"}')"; append_row "$ROW" "no_sessions_discovered"; emit "$ROW" "$(jq -cn '{enabled:false,apply:false,action:"none"}')"; exit 0; fi

while IFS= read -r SESSION; do
  [[ -z "$SESSION" ]] && continue
  TOPO="null"; [[ -r "$TOPOLOGY_FILE" ]] && TOPO="$(jq -sc --arg s "$SESSION" 'map(select(.session == $s)) | sort_by(.effective_at // "") | last // null' "$TOPOLOGY_FILE" 2>/dev/null || printf 'null')"
  HEALTH_ARGS=(health "$SESSION" --json --threshold "$THRESHOLD"); [[ "$AUTO_RESTART_STUCK" -eq 1 && "$APPLY" -eq 1 ]] && HEALTH_ARGS+=(--auto-restart-stuck)
  set +e; HEALTH_OUT="$("$NTM_BIN" "${HEALTH_ARGS[@]}" 2>&1)"; HEALTH_RC=$?; set -e
  HEALTH="$(wrap_json "$HEALTH_OUT" "$HEALTH_RC")"; ROLE_SPLIT="$(role_split "$TOPO" "$HEALTH")"
  ROW="$(jq -cn --arg ts "$NOW" --arg session "$SESSION" --arg threshold "$THRESHOLD" --argjson health "$HEALTH" --argjson role "$ROLE_SPLIT" '{ts:$ts,session:$session,threshold:$threshold,health:$health,agent_pane_health:$role.agent_pane_health,user_pane_health:$role.user_pane_health,other_pane_health:$role.other_pane_health,health_role_split:$role}')"
  AUTO="$(auto_preview "$SESSION" "$HEALTH")"; append_row "$ROW" "health"; emit "$ROW" "$AUTO"
done <<<"$SESSIONS"
