#!/usr/bin/env bash
set -euo pipefail

VERSION="worker-auto-respawn-watchdog.v2.0.0"
SCHEMA="worker-auto-respawn-watchdog.v2"
STATE_DIR="${WORKER_AUTO_RESPAWN_STATE_DIR:-$HOME/.local/state/flywheel}"
TOPOLOGY="${WORKER_AUTO_RESPAWN_TOPOLOGY:-$STATE_DIR/session-topology.jsonl}"
ATTEMPTS="${WORKER_AUTO_RESPAWN_ATTEMPTS:-$STATE_DIR/auto-respawn-attempts.jsonl}"
NTM="${WORKER_AUTO_RESPAWN_NTM_BIN:-/Users/josh/.local/bin/ntm}"
MAX="${WORKER_AUTO_RESPAWN_MAX_ATTEMPTS_PER_HOUR:-3}"
TIMEOUT="${WORKER_AUTO_RESPAWN_WAIT_TIMEOUT:-1s}"
SESSION=""; PANE=""; APPLY=false; JSON=false; QUIET=false

usage() { printf 'usage: worker-auto-respawn-watchdog.sh [--dry-run|--apply] [--json] [--session NAME] [--pane N]\n'; }
now_epoch() { date +%s; }
now_iso() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
emit() { if $JSON; then jq -c . <<<"$1"; elif ! $QUIET; then jq -r '"worker-auto-respawn-watchdog status=\(.status) checked=\(.targets_checked) respawned=\(.auto_respawns_fired)"' <<<"$1"; fi; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) APPLY=true; shift ;;
    --dry-run) APPLY=false; shift ;;
    --json) JSON=true; shift ;;
    --quiet) QUIET=true; shift ;;
    --session) SESSION="${2:?}"; shift 2 ;;
    --session=*) SESSION="${1#*=}"; shift ;;
    --pane) PANE="${2:?}"; shift 2 ;;
    --pane=*) PANE="${1#*=}"; shift ;;
    --topology) TOPOLOGY="${2:?}"; shift 2 ;;
    --attempts) ATTEMPTS="${2:?}"; shift 2 ;;
    --ntm-bin) NTM="${2:?}"; shift 2 ;;
    --info) jq -nc --arg s "$SCHEMA" --arg v "$VERSION" --arg t "$TOPOLOGY" --arg a "$ATTEMPTS" --arg n "$NTM" --argjson m "$MAX" '{schema_version:$s,mode:"info",version:$v,worker_scope_only:true,native_commands:["ntm wait --condition=DEAD","ntm respawn"],topology_file:$t,attempts_file:$a,ntm_bin:$n,budget:{max_attempts_per_hour:$m},canonical_cli:{doctor_health_repair:"n/a wrapper delegates to ntm",validate_audit_why:"n/a wrapper emits receipts",json:true,dry_run_apply:true}}'; exit 0 ;;
    --examples) printf '%s\n' 'worker-auto-respawn-watchdog.sh --dry-run --json' 'worker-auto-respawn-watchdog.sh --apply --json --session flywheel --pane 2'; exit 0 ;;
    -h|--help|help) usage; exit 0 ;;
    *) printf 'unknown arg: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done

attempts() {
  local cutoff=$(( $(now_epoch) - 3600 ))
  [[ -s "$ATTEMPTS" ]] || { printf '0\n'; return; }
  jq -sr --arg s "$1" --arg p "$2" --argjson c "$cutoff" '[.[] | select(type=="object" and .action=="respawn_attempt" and .session==$s and (.pane|tostring)==$p and ((.epoch // 0) >= $c))] | length' "$ATTEMPTS"
}

append_attempt() {
  mkdir -p "$(dirname "$ATTEMPTS")"
  jq -nc --arg ts "$(now_iso)" --argjson e "$(now_epoch)" --arg s "$1" --arg p "$2" --argjson n "$3" '{ts:$ts,epoch:$e,action:"respawn_attempt",session:$s,pane:($p|tonumber? // $p),attempt_number:$n,reason:"native_ntm_wait_dead",source:"worker-auto-respawn-watchdog",actor:"watchdog",trauma_class:"dead_worker_pane",primitive_invoked:"ntm respawn"}' >>"$ATTEMPTS"
}

target_lines() {
  [[ -s "$TOPOLOGY" ]] || return 3
  jq -rs --arg sf "$SESSION" --arg pf "$PANE" 'map(select(type=="object" and .session)) | sort_by(.effective_at // .ts // "") | group_by(.session) | map(last)[] as $t | ($t.worker_panes // [])[] | {session:($t.session|tostring),pane:(.|tostring),role:"worker"} | select(($sf=="" or .session==$sf) and ($pf=="" or .pane==$pf)) | [.session,.pane,.role] | @tsv' "$TOPOLOGY"
}

wait_dead() {
  local out rc
  set +e; out="$("$NTM" wait "$1" --pane="$2" --condition=DEAD --timeout "$TIMEOUT" --json 2>&1)"; rc=$?; set -e
  [[ "$rc" -eq 0 ]] && jq -nc --arg o "$out" '{dead:true,rc:0,output:$o}' || jq -nc --arg o "$out" --argjson rc "$rc" '{dead:false,rc:$rc,output:$o}'
}

respawn() { "$NTM" respawn "$1" --panes="$2" --json >/dev/null; }

tmp="$(mktemp)"; trap 'rm -f "$tmp"' EXIT
set +e; targets="$(target_lines)"; target_rc=$?; set -e
if [[ "$target_rc" -ne 0 ]]; then
  emit '{"schema_version":"worker-auto-respawn-watchdog.v2","success":false,"status":"probe_error","reason":"topology_lookup_failed","targets_checked":0,"auto_respawns_fired":0,"results":[]}'
  exit 3
fi

while IFS=$'\t' read -r session pane role; do
  [[ -n "${session:-}" ]] || continue
  wait_json="$(wait_dead "$session" "$pane")"; dead="$(jq -r '.dead' <<<"$wait_json")"; count="$(attempts "$session" "$pane")"
  action="none"; reason="not_dead"; rc=0
  if [[ "$dead" == true && "$count" -ge "$MAX" ]]; then action="notify_fallback"; reason="auto_respawn_budget_exhausted"; fi
  if [[ "$dead" == true && "$count" -lt "$MAX" && "$APPLY" == true ]]; then action="auto_respawn_fired"; reason="native_ntm_wait_dead"; append_attempt "$session" "$pane" "$((count + 1))"; respawn "$session" "$pane" || rc=$?; fi
  if [[ "$dead" == true && "$count" -lt "$MAX" && "$APPLY" == false ]]; then action="would_auto_respawn"; reason="native_ntm_wait_dead"; fi
  jq -nc --arg s "$session" --arg p "$pane" --arg r "$role" --arg a "$action" --arg y "$reason" --argjson c "$count" --argjson rc "$rc" --argjson w "$wait_json" '{session:$s,pane:($p|tonumber? // $p),role:$r,action:$a,reason:$y,attempts_last_hour:$c,action_rc:$rc,wait:$w}' >>"$tmp"
done <<<"$targets"

payload="$(jq -s --arg s "$SCHEMA" --arg v "$VERSION" --arg t "$TOPOLOGY" --arg a "$ATTEMPTS" --argjson apply "$APPLY" '{schema_version:$s,version:$v,success:true,status:(if any(.[];.action=="auto_respawn_fired") then "auto_respawn_fired" elif any(.[];.action=="would_auto_respawn") then "dry_run_actions_planned" elif any(.[];.action=="notify_fallback") then "notify_fallback" else "no_action_needed" end),dry_run:($apply|not),apply:$apply,topology_file:$t,attempts_file:$a,targets_checked:length,workers_checked:length,auto_respawns_fired:([.[]|select(.action=="auto_respawn_fired")]|length),would_auto_respawns:([.[]|select(.action=="would_auto_respawn")]|length),notify_fallbacks_fired:([.[]|select(.action=="notify_fallback")]|length),results:.}' "$tmp")"
emit "$payload"
jq -e '.auto_respawns_fired > 0' >/dev/null <<<"$payload" && exit 1
jq -e '.notify_fallbacks_fired > 0' >/dev/null <<<"$payload" && exit 2
exit 0
