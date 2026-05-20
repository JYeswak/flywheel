#!/usr/bin/env bash
set -euo pipefail

SCHEMA_VERSION="peer-orch-freeze-monitor.v2"
PRIMITIVE="peer-orch-freeze-monitor"
STATE_DIR="${PEER_ORCH_MONITOR_STATE_DIR:-$HOME/.local/state/flywheel}"
LEDGER="${PEER_ORCH_MONITOR_LEDGER:-$STATE_DIR/peer-orch-freeze-monitor.jsonl}"
CONTRACT_LEDGER="${PEER_ORCH_MONITOR_CONTRACT_LEDGER:-$STATE_DIR/peer-orch-freeze-monitor-contract.jsonl}"
FUCKUP_LOG="${PEER_ORCH_MONITOR_FUCKUP_LOG:-$STATE_DIR/fuckup-log.jsonl}"
TOPOLOGY="${PEER_ORCH_MONITOR_TOPOLOGY:-${NTM_TOPOLOGY:-$STATE_DIR/session-topology.jsonl}}"
FIXTURE_DIR="${PEER_ORCH_MONITOR_FIXTURE_DIR:-}"
ACTIVITY_DIR="${PEER_ORCH_MONITOR_ACTIVITY_DIR:-}"
NTM_BIN="${PEER_ORCH_MONITOR_NTM_BIN:-ntm}"
PERMIT_GATE="${PEER_ORCH_MONITOR_PERMIT_GATE:-.flywheel/scripts/peer-orch-respawn-permit.sh}"
RESPAWN_CMD="${PEER_ORCH_MONITOR_RESPAWN_CMD:-$NTM_BIN respawn}"
JSONL_APPEND_LIB="${PEER_ORCH_MONITOR_JSONL_APPEND_LIB:-.flywheel/scripts/jsonl-append-validated.sh}"
PLIST_PATH="${PEER_ORCH_MONITOR_PLIST:-$HOME/Library/LaunchAgents/ai.zeststream.peer-orch-freeze-monitor.plist}"
NOW_OVERRIDE="${PEER_ORCH_MONITOR_NOW:-}"
ACTOR_SESSION="${NTM_SESSION:-flywheel}"
ACTOR_PANE="${NTM_PANE:-1}"
AUTO_RESPAWN="${PEER_ORCH_AUTO_RESPAWN:-0}"
INTERVAL_SEC="${PEER_ORCH_MONITOR_INTERVAL_SEC:-300}"
MODE="cycle"; APPLY=0; JSON=0; SCOPE=""

usage(){ printf 'Usage: peer-orch-freeze-monitor.sh [cycle|doctor|health|repair|validate|audit|why|schema|install|uninstall|quickstart|completion] [--apply] [--json]\n'; }
now_iso(){ [[ -n "$NOW_OVERRIDE" ]] && printf '%s\n' "$NOW_OVERRIDE" || date -u +%Y-%m-%dT%H:%M:%SZ; }
epoch_utc(){ date -j -u -f "%Y-%m-%dT%H:%M:%SZ" "$1" +%s 2>/dev/null || printf '0\n'; }
rows_json(){ [[ -f "$1" ]] && jq -cs 'map(select(type=="object"))' "$1" 2>/dev/null || printf '[]\n'; }
jsonl_append(){ local p="$1" r="$2"; mkdir -p "$(dirname "$p")"; if [[ -f "$JSONL_APPEND_LIB" ]]; then source "$JSONL_APPEND_LIB" 2>/dev/null || true; declare -F fw_jsonl_append_validated >/dev/null && { fw_jsonl_append_validated "$p" "$r"; return; }; fi; printf '%s\n' "$r" >> "$p"; }
watch_json(){ "$NTM_BIN" watch --help >/dev/null 2>&1 && jq -nc '{command:"ntm watch",available:true}' || jq -nc '{command:"ntm watch",available:false}'; }

targets(){
  [[ -f "$TOPOLOGY" ]] || return 0
  jq -rc 'map(select(type=="object" and .session?))|sort_by(.session)|group_by(.session)|map(last)|sort_by(.session)|.[]|{session:.session,pane:((.orchestrator_pane//1)|tostring)}' \
    < <(jq -cs 'map(select(type=="object"))' "$TOPOLOGY" 2>/dev/null || printf '[]\n')
}

protected_session(){
  case "$1" in alpsinsurance|picoz|terra-title) return 0;; esac
  [[ -n "${PEER_ORCH_RECOVERY_KILL_RECOVER_DRILL:-}" && -f "${PEER_ORCH_RECOVERY_KILL_RECOVER_DRILL:-}" ]] &&
    rg -q "(^|[ (])$1([ )]|$)" "$PEER_ORCH_RECOVERY_KILL_RECOVER_DRILL" 2>/dev/null
}

activity_json(){
  local s="$1" p="$2" f="$FIXTURE_DIR/$s-$p.json" a="$ACTIVITY_DIR/$s.json" out
  if [[ -n "$ACTIVITY_DIR" && -f "$a" ]]; then cat "$a"
  elif [[ -n "$FIXTURE_DIR" && -f "$f" ]]; then
    jq -c --arg s "$s" --arg p "$p" '{success:true,session:$s,agents:[{pane:($p|tonumber),state:(if .t0==.t1 then "ERROR" else "ACTIVE" end),velocity:(if .t0==.t1 then 0 else 1 end),fixture_legacy:true,t0:.t0,t1:.t1,state_since:(.timestamp//null)}]}' "$f"
  elif out="$("$NTM_BIN" activity "$s" --json 2>/dev/null)" && jq -e . >/dev/null 2>&1 <<<"$out"; then printf '%s\n' "$out"
  else jq -nc --arg s "$s" '{success:false,session:$s,agents:[]}'; fi
}

result_json(){
  jq -nc --arg s "$1" --arg p "$2" --argjson a "$3" '
    def pn:($p|tonumber);
    def ag:($a.agents[]?|select((.pane//.pane_idx//.index//-1)==pn))//($a.agents[]?|select(((.pane//.pane_idx//.index//"")|tostring)==$p))//{};
    def bad:((ag.state//ag.activity//""|tostring|ascii_downcase) as $x|["error","unknown","stalled","stuck","deaf","dead","failed","unresponsive"]|index($x)!=null);
    {session:$s,pane:$p,stuck:(bad or ((ag.velocity//1)==0 and (ag.fixture_legacy//false))),activity_state:(ag.state//null),native_activity:"ntm activity --json",native_watch:"ntm watch",evidence:{state:(ag.state//null),velocity:(ag.velocity//null),fixture_legacy:(ag.fixture_legacy//false)}}'
}

permit_json(){
  PEER_ORCH_RECOVERY_TOPOLOGY="$TOPOLOGY" PEER_ORCH_RECOVERY_ACTIVITY_JSON="$3" \
    "$PERMIT_GATE" --target-session "$1" --target-pane "$2" --actor-session "$ACTOR_SESSION" --actor-pane "$ACTOR_PANE" --reason peer-orch-freeze-monitor --dry-run
}

recover(){ if [[ "$RESPAWN_CMD" == "$NTM_BIN respawn" ]]; then "$NTM_BIN" respawn "$1" --panes="$2" --force --json >/dev/null; else "$RESPAWN_CMD" "$1" "$2" >/dev/null; fi; }

cycle_one(){
  local s="$1" p="$2" a r permit decision reason recovered blocked
  a="$(activity_json "$s" "$p")"; r="$(result_json "$s" "$p" "$a")"
  permit="$(jq -nc '{decision:null,reason:null}')"; recovered=false; blocked=null
  if [[ "$ACTOR_SESSION:$ACTOR_PANE" == "$s:$p" ]]; then decision=refuse; reason=self_orch_respawn_refused
  elif protected_session "$s" && [[ "$s" != skillos ]]; then permit="$(jq -nc '{decision:"refuse",reason:"protected_session_refused"}')"; decision=refuse; reason=protected_session_refused
  elif [[ "$(jq -r '.stuck' <<<"$r")" == true ]]; then permit="$(permit_json "$s" "$p" "$a")"; decision="$(jq -r '.decision' <<<"$permit")"; reason="$(jq -r '.reason' <<<"$permit")"
  else decision=refuse; reason=peer_not_frozen; fi
  if [[ "$decision" == permit ]]; then
    if [[ "$APPLY" == 1 && "$AUTO_RESPAWN" == 1 ]]; then recover "$s" "$p"; recovered=true
    elif [[ "$AUTO_RESPAWN" != 1 ]]; then blocked='"auto_respawn_disabled"'
    else blocked='"dry_run"'; fi
  fi
  jq -nc --argjson b "$r" --argjson pmt "$permit" --arg d "$decision" --arg rs "$reason" --argjson rec "$recovered" --argjson blk "$blocked" \
    '$b+{permit_invoked:($pmt.decision!=null),permit_decision:$d,permit_reason:$rs,decision_reason:$rs,recovery_applied:$rec,recovery_blocked_reason:$blk}'
}

run_cycle(){
  local now out results rec row; now="$(now_iso)"
  out="$({ while IFS= read -r t; do [[ -n "$t" ]] && cycle_one "$(jq -r .session<<<"$t")" "$(jq -r .pane<<<"$t")"; done < <(targets); } || true)"
  results="$(printf '%s\n' "$out" | jq -cs 'map(select(type=="object"))')"
  rec="$(jq '[.[]|select(.recovery_applied==true)]|length' <<<"$results")"
  row="$(jq -nc --arg now "$now" --arg schema "$SCHEMA_VERSION" --arg primitive "$PRIMITIVE" --argjson rs "$results" --argjson rec "$rec" --argjson w "$(watch_json)" '{schema_version:$schema,primitive:$primitive,status:"ok",ts:$now,native_watch:$w,native_activity:"ntm activity --json",target_results:$rs,recoveries_count:$rec}')"
  [[ "$APPLY" == 1 ]] && jsonl_append "$LEDGER" "$row"; printf '%s\n' "$row"
}

stale_log(){
  local last="$1" n l age row; [[ "$APPLY" == 1 && -n "$last" && "$last" != null ]] || return 0
  n="$(epoch_utc "$(now_iso)")"; l="$(epoch_utc "$last")"; age=$((n-l))
  if (( age > INTERVAL_SEC*2 )); then row="$(jq -nc --arg ts "$(now_iso)" --arg last "$last" '{ts:$ts,trauma_class:"peer-orch-monitor-stale",severity:"medium",what_happened:"peer orchestrator freeze monitor stale",last_fire_ts:$last}')"; jsonl_append "$FUCKUP_LOG" "$row"; fi
}

run_doctor(){
  local rows last now since rows24 rec refuse falsec alive
  rows="$(rows_json "$LEDGER")"; last="$(jq -r 'map(.ts)|max//null' <<<"$rows")"; stale_log "$last"
  now="$(epoch_utc "$(now_iso)")"; since=$((now-86400))
  rows24="$(jq -c --argjson since "$since" 'map(select((.ts|fromdateiso8601? // 0)>=$since))' <<<"$rows")"
  rec="$(jq '[.[].target_results[]?|select(.recovery_applied==true)]|length' <<<"$rows24")"
  refuse="$(jq '[.[].target_results[]?|select(.permit_invoked==true and .permit_decision=="refuse")]|length' <<<"$rows24")"
  falsec="$(jq '[.[].target_results[]?|select(.stuck==false and .recovery_applied==true)]|length' <<<"$rows24")"
  alive=false; [[ "$last" != null ]] && alive="$(jq -n --argjson n "$now" --argjson l "$(epoch_utc "$last")" --argjson i "$INTERVAL_SEC" '($n-$l)<=($i*2)')"
  jq -nc --arg now "$(now_iso)" --arg schema "$SCHEMA_VERSION" --arg last "$last" --argjson alive "$alive" --argjson rec "$rec" --argjson refuse "$refuse" --argjson falsec "$falsec" --argjson w "$(watch_json)" \
    '{schema_version:$schema,primitive:"peer-orch-freeze-monitor",status:"ok",ts:$now,monitor_alive:$alive,monitor_last_fire_ts:(if $last=="null" then null else $last end),recoveries_24h:$rec,permit_gate_refusals_24h:$refuse,false_recovery_count_24h:$falsec,native_watch:$w,native_activity:"ntm activity --json"}'
}

write_plist(){
  mkdir -p "$(dirname "$PLIST_PATH")"
  cat > "$PLIST_PATH" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>Label</key><string>ai.zeststream.peer-orch-freeze-monitor</string><key>Disabled</key><true/><key>ProgramArguments</key><array><string>$PWD/.flywheel/scripts/peer-orch-freeze-monitor.sh</string><string>cycle</string><string>--apply</string><string>--json</string></array><key>StartInterval</key><integer>$INTERVAL_SEC</integer></dict></plist>
PLIST
}

run_install(){ [[ "$APPLY" == 1 ]] && write_plist; jq -nc --arg p "$PLIST_PATH" '{status:"ok",plist:$p,disabled_by_default:true,launchctl_mutated:false,native_watch:"ntm watch",native_activity:"ntm activity --json"}'; }
run_uninstall(){ [[ "$APPLY" == 1 && -e "$PLIST_PATH" ]] && mv "$PLIST_PATH" "$PLIST_PATH.removed.$(date -u +%Y%m%dT%H%M%SZ)"; jq -nc --arg p "$PLIST_PATH" '{status:"ok",plist:$p,removed:true,launchctl_mutated:false}'; }
run_validate(){ if [[ "$SCOPE" == plist ]]; then [[ -f "$PLIST_PATH" ]] && rg -q '<key>Disabled</key>' "$PLIST_PATH" && jq -nc '{status:"pass",scope:"plist"}' || jq -nc '{status:"fail",scope:"plist"}'; else jq -nc --argjson w "$(watch_json)" '{status:"pass",scope:"default",native_watch:$w,native_activity:"ntm activity --json"}'; fi; }
run_info(){ jq -nc --arg s "$SCHEMA_VERSION" --arg p "$PRIMITIVE" --arg l "$LEDGER" --argjson w "$(watch_json)" '{schema_version:$s,primitive:$p,ledger:$l,auto_respawn_default_enabled:false,native_watch:$w,native_activity:"ntm activity --json",target_ntm_commands:["ntm watch","ntm activity --json"]}'; }
run_why(){ jq -nc '{why:"ntm owns watch/activity substrate; this wrapper keeps Flywheel permit and audit semantics"}'; }
run_schema(){ jq -nc --arg s "$SCHEMA_VERSION" '{schema_version:$s,commands:["cycle","doctor","install","uninstall"],target_results:["session","pane","stuck","permit_decision","recovery_applied"]}'; }
run_examples(){ printf '%s\n' "peer-orch-freeze-monitor.sh cycle --json" "peer-orch-freeze-monitor.sh cycle --apply --json" "peer-orch-freeze-monitor.sh doctor --json" "peer-orch-freeze-monitor.sh install --apply --json"; }
run_quickstart(){ printf '%s\n' "Run cycle --json to inspect peers; set PEER_ORCH_AUTO_RESPAWN=1 with --apply to recover permitted frozen peers."; }
run_completion(){ printf '%s\n' cycle doctor health repair validate audit why schema install uninstall quickstart completion --apply --json --scope; }
run_repair(){ mkdir -p "$(dirname "$LEDGER")" "$(dirname "$CONTRACT_LEDGER")"; : > "$LEDGER"; : > "$CONTRACT_LEDGER"; jq -nc '{status:"repaired"}'; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    cycle|doctor|health|repair|validate|audit|why|schema|install|uninstall|quickstart|completion) MODE="$1"; shift;;
    --info) MODE=info; shift;; --examples|examples) MODE=examples; shift;;
    --apply) APPLY=1; shift;; --json) JSON=1; shift;; --scope) SCOPE="$2"; shift 2;;
    -h|--help) usage; exit 0;; *) printf 'unknown argument: %s\n' "$1" >&2; usage >&2; exit 2;;
  esac
done

case "$MODE" in
  cycle) run_cycle;; doctor|health) run_doctor;; repair) run_repair;; validate|audit) run_validate;; why) run_why;; schema) run_schema;;
  install) run_install;; uninstall) run_uninstall;; info) run_info;; examples) run_examples;; quickstart) run_quickstart;; completion) run_completion;;
esac

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-20-cross-orch-handoff.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-63-phase-tick-bounded-action.md`
