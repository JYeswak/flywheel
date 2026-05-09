#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
CONTRACT="team-pulse-heartbeat/v1"
STATE_DIR="${FLYWHEEL_TEAM_PULSE_STATE_DIR:-$HOME/.local/state/flywheel}"
ROSTER="${FLYWHEEL_TEAM_ROSTER:-$STATE_DIR/team-roster.jsonl}"
TOPOLOGY="${FLYWHEEL_SESSION_TOPOLOGY:-$STATE_DIR/session-topology.jsonl}"
PULSE="${FLYWHEEL_TEAM_PULSE:-$STATE_DIR/team-pulse.jsonl}"
LOCK_FILE="${FLYWHEEL_TEAM_PULSE_LOCK:-$STATE_DIR/team-pulse.lock}"
NTM_BIN="${FLYWHEEL_TEAM_PULSE_NTM_BIN:-/Users/josh/.local/bin/ntm}"
LABEL="${FLYWHEEL_TEAM_PULSE_LABEL:-ai.zeststream.team-pulse-heartbeat}"
SOURCE_PLIST="${FLYWHEEL_TEAM_PULSE_SOURCE_PLIST:-$ROOT/.flywheel/launchd/${LABEL}.plist}"
INSTALL_PLIST="${FLYWHEEL_TEAM_PULSE_INSTALL_PLIST:-$HOME/Library/LaunchAgents/${LABEL}.plist}"
DOMAIN="${FLYWHEEL_TEAM_PULSE_LAUNCHD_DOMAIN:-gui/$(id -u)}"
STALE_SECONDS="${FLYWHEEL_TEAM_PULSE_STALE_SECONDS:-900}"
CADENCE_SECONDS="${FLYWHEEL_TEAM_PULSE_CADENCE_SECONDS:-300}"
MODE="run"; JSON_OUT=0; APPLY=0; DRY_RUN=0; NOW_OVERRIDE=""; SCHEMA_TOPIC="pulse"; VALIDATE_TARGET="plist"

usage(){ cat <<'EOF'
Usage:
  team-pulse-heartbeat.sh run|doctor|status [--json]
  team-pulse-heartbeat.sh install|load|unload --dry-run|--apply [--json]
  team-pulse-heartbeat.sh validate plist [--json]
  team-pulse-heartbeat.sh schema [pulse|doctor|plist] [--json]
EOF
}
die(){ printf 'ERR: %s\n' "$*" >&2; exit 64; }
need_jq(){ command -v jq >/dev/null 2>&1 || { printf 'ERR: jq is required\n' >&2; exit 69; }; }
now_iso(){ [[ -n "$NOW_OVERRIDE" ]] && printf '%s\n' "$NOW_OVERRIDE" || date -u +%Y-%m-%dT%H:%M:%SZ; }
json_bool(){ [[ "$1" == true ]] && printf true || printf false; }
emit(){ [[ "$JSON_OUT" -eq 1 ]] && jq -cS . || jq .; }

parse_args(){
  [[ $# -gt 0 && "$1" =~ ^(run|doctor|status|health|install|load|unload|validate|schema)$ ]] && { MODE="$1"; shift; }
  while [[ $# -gt 0 ]]; do case "$1" in
    --json) JSON_OUT=1; shift;; --apply) APPLY=1; shift;; --dry-run) DRY_RUN=1; shift;;
    --now) NOW_OVERRIDE="${2:?}"; shift 2;; --now=*) NOW_OVERRIDE="${1#*=}"; shift;;
    --state-dir) STATE_DIR="${2:?}"; shift 2;; --state-dir=*) STATE_DIR="${1#*=}"; shift;;
    --roster) ROSTER="${2:?}"; shift 2;; --roster=*) ROSTER="${1#*=}"; shift;;
    --topology) TOPOLOGY="${2:?}"; shift 2;; --topology=*) TOPOLOGY="${1#*=}"; shift;;
    --pulse) PULSE="${2:?}"; shift 2;; --pulse=*) PULSE="${1#*=}"; shift;;
    --lock-file) LOCK_FILE="${2:?}"; shift 2;; --lock-file=*) LOCK_FILE="${1#*=}"; shift;;
    --ntm-bin) NTM_BIN="${2:?}"; shift 2;; --ntm-bin=*) NTM_BIN="${1#*=}"; shift;;
    --source-plist) SOURCE_PLIST="${2:?}"; shift 2;; --source-plist=*) SOURCE_PLIST="${1#*=}"; shift;;
    --install-plist) INSTALL_PLIST="${2:?}"; shift 2;; --install-plist=*) INSTALL_PLIST="${1#*=}"; shift;;
    --stale-seconds) STALE_SECONDS="${2:?}"; shift 2;; --stale-seconds=*) STALE_SECONDS="${1#*=}"; shift;;
    --cadence-seconds) CADENCE_SECONDS="${2:?}"; shift 2;; --cadence-seconds=*) CADENCE_SECONDS="${1#*=}"; shift;;
    pulse|doctor|plist) [[ "$MODE" == schema ]] && SCHEMA_TOPIC="$1" || { [[ "$MODE" == validate ]] && VALIDATE_TARGET="$1" || die "unexpected argument: $1"; }; shift;;
    --help|-h) usage; exit 0;; *) usage >&2; die "unknown argument: $1";; esac; done
  [[ "$STALE_SECONDS" =~ ^[0-9]+$ && "$CADENCE_SECONDS" =~ ^[0-9]+$ ]] || die "seconds values must be integers"
}

latest_json(){ local file="$1" key="$2"; [[ -s "$file" ]] && jq -s "group_by(.$key) | map(max_by(.ts // .effective_at // \"\"))" "$file" || printf '[]\n'; }
call_ntm(){ local verb="$1" session="$2" out rc; set +e; out="$("$NTM_BIN" "$verb" "$session" --json 2>&1)"; rc=$?; set -e
  if printf '%s' "$out" | jq -e . >/dev/null 2>&1; then jq -c --argjson exit_code "$rc" '. + {exit_code:$exit_code}' <<<"$out"
  else jq -nc --arg raw "$out" --argjson exit_code "$rc" '{parse_error:true,exit_code:$exit_code,raw:$raw}'; fi
}
latest_dispatch_ts(){ local log="$1/.flywheel/dispatch-log.jsonl"; [[ -s "$log" ]] && jq -rs '[.[] | (.ts? // .started_at? // empty)] | max // empty' "$log" 2>/dev/null || true; }
loop_json(){ local repo="$1" now="$2" last="$repo/.flywheel/runtime/flywheel-loop/last_run.json" tick="" dispatch=""
  [[ -s "$last" ]] || last="$repo/.flywheel/last_run.json"; [[ -s "$last" ]] && tick="$(jq -r '.ts // empty' "$last" 2>/dev/null || true)"
  [[ -n "$repo" && -d "$repo" ]] && dispatch="$(latest_dispatch_ts "$repo")"
  jq -nc --arg repo "$repo" --arg now "$now" --arg tick "$tick" --arg dispatch "$dispatch" 'def opt($v): if $v=="" then null else $v end; def age($ts): if $ts=="" then null else (try (($now|fromdateiso8601)-($ts|fromdateiso8601)|floor) catch null) | if .==null then null elif .<0 then 0 else . end end; {available:($repo!="" and ($repo|length)>0),repo_path:$repo,last_tick_ts:opt($tick),last_tick_age_seconds:age($tick),last_dispatch_ts:opt($dispatch),last_dispatch_age_seconds:age($dispatch)}'
}

pulse_row(){ local now="$1" roster="$2" topo="$3" health="$4" summary="$5" loop="$6"
  jq -nc --arg now "$now" --argjson r "$roster" --argjson t "$topo" --argjson h "$health" --argjson s "$summary" --argjson l "$loop" '
    def panes: if ($h.agents?|type)=="array" then $h.agents elif ($h.panes?|type)=="array" then $h.panes else [] end;
    def pid: .pane // .pane_idx // .id // null;
    def prow($p): [panes[] | select((pid|tostring)==($p|tostring))] | last;
    def bad: ((. // "")|tostring|ascii_downcase|test("error|exited|failed|dead|stuck|unhealthy|missing|not_found"));
    def alive($p): (prow($p)) as $x | if $x==null then false elif ($x.status|bad) or ($x.process_status|bad) or ($x.state|bad) then false else (($x.status//$x.process_status//$x.state//"")|tostring|length)>0 end;
    ($r.session) as $session | ($r.orchestrator.pane // $t.orchestrator_pane // null) as $orch
    | ((($r.workers // [])|map(.pane)) + ($r.worker_panes // []) + ($t.worker_panes // []) | unique) as $workers
    | {schema_version:"team-pulse/v1",ts:$now,event:"team_pulse",session:$session,source:"team-pulse-heartbeat",roster_ts:($r.ts//null),repo_path:($r.repo_path//$t.repo_path//null),orch_pane:$orch,orch_pane_alive:(if $orch==null then false else alive($orch) end),worker_panes_expected:$workers,worker_panes_alive:($workers|map(select(alive(.)))),worker_panes_dead:($workers|map(select(alive(.)|not))),loop_tick_freshness:$l,last_tick_ts:$l.last_tick_ts,last_tick_age_seconds:$l.last_tick_age_seconds,last_dispatch_ts:$l.last_dispatch_ts,last_dispatch_age_seconds:$l.last_dispatch_age_seconds,health_exit_code:($h.exit_code//0),health_status:($h.status//$h.overall_status//null),health_parse_error:($h.parse_error//false),summary_exit_code:($s.exit_code//0),summary_parse_error:($s.parse_error//false),summary_generated_at:($s.generated_at//null),summary_accomplishments_count:(($s.accomplishments//[])|length),summary_changes_count:(($s.changes//[])|length),summary_errors_count:(($s.errors//[])|length),summary_files_count:(($s.files//[])|length),summary_token_estimate:($s.token_estimate//null),confirmed_source:($r.joshua_confirmed_at//$r.registered_by//"session_active_roster_row")}'
}

append_rows(){ local f="$1" n; n="$(wc -l <"$f" | tr -d ' ')"; [[ "$DRY_RUN" -eq 1 ]] && { jq -nc --argjson n "$n" --arg p "$PULSE" '{status:"dry_run",appended:false,planned_rows:$n,pulse_path:$p}'; return; }
  mkdir -p "$(dirname "$PULSE")" "$(dirname "$LOCK_FILE")"; if command -v flock >/dev/null 2>&1; then exec 9>"$LOCK_FILE"; flock 9; cat "$f" >>"$PULSE"; else local d="${LOCK_FILE}.d"; until mkdir "$d" 2>/dev/null; do sleep 0.1; done; cat "$f" >>"$PULSE"; rmdir "$d"; fi; jq -nc --argjson n "$n" --arg p "$PULSE" '{status:"pass",appended:true,rows_appended:$n,pulse_path:$p}'
}
run_pulse(){ local now roster topo tmp count i rr session tr h s repo loop append; now="$(now_iso)"; roster="$(latest_json "$ROSTER" session | jq 'map(select(.event=="session_active"))')"; topo="$(latest_json "$TOPOLOGY" session)"; tmp="$(mktemp "${TMPDIR:-/tmp}/team-pulse.XXXXXX")"; trap 'rm -f "$tmp"' RETURN
  count="$(jq -r length <<<"$roster")"; for i in $(seq 0 $((count-1))); do rr="$(jq -c --argjson i "$i" '.[$i]' <<<"$roster")"; session="$(jq -r .session <<<"$rr")"; tr="$(jq -c --arg s "$session" 'map(select(.session==$s))|last//{}' <<<"$topo")"; h="$(call_ntm health "$session")"; s="$(call_ntm summary "$session")"; repo="$(jq -r --argjson t "$tr" '.repo_path//$t.repo_path//""' <<<"$rr")"; loop="$(loop_json "$repo" "$now")"; pulse_row "$now" "$rr" "$tr" "$h" "$s" "$loop" >>"$tmp"; done
  append="$(append_rows "$tmp")"; jq -nc --arg now "$now" --arg roster "$ROSTER" --arg topology "$TOPOLOGY" --arg pulse "$PULSE" --argjson count "$count" --argjson append "$append" --slurpfile rows "$tmp" '{schema_version:"team-pulse-heartbeat/v1.result",ts:$now,status:$append.status,roster_path:$roster,topology_path:$topology,pulse_path:$pulse,active_confirmed_session_count:$count,append:$append,rows:$rows}' | emit
}

doctor_json(){ local now roster; now="$(now_iso)"; roster="$(latest_json "$ROSTER" session | jq 'map(select(.event=="session_active"))')"
  if [[ ! -s "$PULSE" ]]; then jq -nc --arg now "$now" --arg pulse "$PULSE" --argjson r "$roster" --argjson stale "$STALE_SECONDS" '{schema_version:"team-pulse-doctor/v1",ts:$now,status:(if ($r|length)==0 then "pass" else "fail" end),pulse_path:$pulse,stale_seconds:$stale,active_confirmed_session_count:($r|length),pulse_session_status:($r|map({session,status:"DEAD",reason:"missing_pulse",pulse_age_seconds:null})),team_pulse_dead_session_count:($r|length),team_pulse_stale_session_count:0,team_pulse_missing_session_count:($r|length)}'; return; fi
  jq -cs --arg now "$now" --arg pulse "$PULSE" --argjson r "$roster" --argjson stale "$STALE_SECONDS" 'def age($ts): try (($now|fromdateiso8601)-($ts|fromdateiso8601)|floor) catch null; (group_by(.session)|map(max_by(.ts//""))) as $latest | ($r|map(.session as $session | ($latest|map(select(.session==$session))|last) as $p | if $p==null then {session:$session,status:"DEAD",reason:"missing_pulse",pulse_age_seconds:null,latest_pulse_ts:null,orch_pane_alive:false,worker_panes_dead:[]} else (age($p.ts)) as $a | {session:$session,status:(if ($a==null or $a>$stale) then "DEAD" elif ($p.orch_pane_alive!=true or (($p.worker_panes_dead//[])|length)>0) then "DEGRADED" else "LIVE" end),reason:(if $a==null then "invalid_pulse_ts" elif $a>$stale then "stale_pulse" elif $p.orch_pane_alive!=true then "orch_pane_dead" elif (($p.worker_panes_dead//[])|length)>0 then "worker_panes_dead" else "fresh" end),pulse_age_seconds:$a,latest_pulse_ts:$p.ts,orch_pane_alive:($p.orch_pane_alive//false),worker_panes_alive:($p.worker_panes_alive//[]),worker_panes_dead:($p.worker_panes_dead//[]),last_tick_age_seconds:($p.last_tick_age_seconds//null),last_dispatch_age_seconds:($p.last_dispatch_age_seconds//null)} end)) as $sessions | ($sessions|map(select(.status=="DEAD"))) as $dead | {schema_version:"team-pulse-doctor/v1",ts:$now,status:(if ($dead|length)>0 then "fail" elif ($sessions|any(.status=="DEGRADED")) then "warn" else "pass" end),pulse_path:$pulse,stale_seconds:$stale,active_confirmed_session_count:($r|length),pulse_session_status:$sessions,team_pulse_dead_session_count:($dead|length),team_pulse_stale_session_count:($sessions|map(select(.reason=="stale_pulse"))|length),team_pulse_missing_session_count:($sessions|map(select(.reason=="missing_pulse"))|length)}' "$PULSE"
}
status_json(){ local d source=false install=false loaded=false; d="$(doctor_json)"; [[ -f "$SOURCE_PLIST" ]] && source=true; [[ -f "$INSTALL_PLIST" ]] && install=true; command -v launchctl >/dev/null 2>&1 && launchctl print "$DOMAIN/$LABEL" >/dev/null 2>&1 && loaded=true
  jq -nc --argjson d "$d" --arg label "$LABEL" --arg domain "$DOMAIN" --arg source_plist "$SOURCE_PLIST" --arg install_plist "$INSTALL_PLIST" --argjson source "$(json_bool "$source")" --argjson install "$(json_bool "$install")" --argjson loaded "$(json_bool "$loaded")" --argjson cadence "$CADENCE_SECONDS" '{schema_version:"team-pulse-status/v1",status:$d.status,label:$label,launchd_domain:$domain,source_plist:$source_plist,install_plist:$install_plist,source_plist_exists:$source,install_plist_exists:$install,launchd_loaded:$loaded,cadence_seconds:$cadence,doctor:$d}'
}
schema_json(){ case "$SCHEMA_TOPIC" in pulse) jq -nc --argjson stale "$STALE_SECONDS" '{schema_version:"team-pulse.schema/v1",required:["schema_version","ts","event","session","orch_pane_alive","worker_panes_alive","worker_panes_dead","loop_tick_freshness"],stale_after_seconds:$stale}';; doctor) jq -nc '{schema_version:"team-pulse-doctor.schema/v1",required:["schema_version","ts","status","pulse_session_status","team_pulse_dead_session_count","team_pulse_stale_session_count"],dead_rule:"latest pulse older than stale_seconds is DEAD"}';; plist) jq -nc --arg label "$LABEL" --argjson cadence "$CADENCE_SECONDS" '{schema_version:"team-pulse-plist.schema/v1",label:$label,start_interval_seconds:$cadence,program_arguments:["team-pulse-heartbeat.sh","run","--json"]}';; *) die "unknown schema topic: $SCHEMA_TOPIC";; esac; }
validate_plist_json(){ [[ "$VALIDATE_TARGET" == plist ]] || die "only validate plist is supported"; local lint=false label=false cadence=false cmd=false status=pass; { command -v plutil >/dev/null 2>&1 && plutil -lint "$SOURCE_PLIST" >/dev/null 2>&1; } || grep -q '<plist version=' "$SOURCE_PLIST" 2>/dev/null && lint=true; grep -q "<string>${LABEL}</string>" "$SOURCE_PLIST" 2>/dev/null && label=true; grep -q "<integer>${CADENCE_SECONDS}</integer>" "$SOURCE_PLIST" 2>/dev/null && cadence=true; grep -q 'team-pulse-heartbeat.sh' "$SOURCE_PLIST" 2>/dev/null && grep -q '<string>run</string>' "$SOURCE_PLIST" 2>/dev/null && cmd=true; [[ "$lint" == true && "$label" == true && "$cadence" == true && "$cmd" == true ]] || status=fail
  jq -nc --arg status "$status" --arg source "$SOURCE_PLIST" --arg label "$LABEL" --argjson cadence "$CADENCE_SECONDS" --argjson lint "$(json_bool "$lint")" --argjson label_ok "$(json_bool "$label")" --argjson cadence_ok "$(json_bool "$cadence")" --argjson cmd "$(json_bool "$cmd")" '{schema_version:"team-pulse-plist-validation/v1",status:$status,source_plist:$source,label:$label,cadence_seconds:$cadence,lint_ok:$lint,label_ok:$label_ok,cadence_ok:$cadence_ok,helper_command_ok:$cmd}'
}
install_json(){ local applied=false installed=false; [[ "$APPLY" -eq 1 || "$DRY_RUN" -eq 1 ]] || die "install requires --dry-run or --apply"; [[ "$APPLY" -eq 1 ]] && { mkdir -p "$(dirname "$INSTALL_PLIST")"; cp "$SOURCE_PLIST" "$INSTALL_PLIST"; applied=true; installed=true; }
  jq -nc --arg label "$LABEL" --arg source "$SOURCE_PLIST" --arg install "$INSTALL_PLIST" --argjson applied "$(json_bool "$applied")" --argjson installed "$(json_bool "$installed")" '{schema_version:"team-pulse-install/v1",status:"pass",label:$label,source_plist:$source,install_plist:$install,applied:$applied,installed:$installed,planned_actions:[{action:"install_launchagent",source:$source,target:$install}]}'
}
load_json(){ local applied=false loaded=false rc=0; [[ "$APPLY" -eq 1 || "$DRY_RUN" -eq 1 ]] || die "$MODE requires --dry-run or --apply"; if [[ "$APPLY" -eq 1 ]]; then applied=true; if [[ "$MODE" == load ]]; then launchctl bootout "$DOMAIN/$LABEL" >/dev/null 2>&1 || true; launchctl bootstrap "$DOMAIN" "$INSTALL_PLIST" >/dev/null 2>&1 || rc=$?; launchctl kickstart -k "$DOMAIN/$LABEL" >/dev/null 2>&1 || true; else launchctl bootout "$DOMAIN/$LABEL" >/dev/null 2>&1 || rc=$?; fi; fi; command -v launchctl >/dev/null 2>&1 && launchctl print "$DOMAIN/$LABEL" >/dev/null 2>&1 && loaded=true
  jq -nc --arg action "$MODE" --arg label "$LABEL" --arg target "$DOMAIN/$LABEL" --argjson applied "$(json_bool "$applied")" --argjson loaded "$(json_bool "$loaded")" --argjson rc "$rc" '{schema_version:"team-pulse-launchd/v1",status:(if $rc==0 then "pass" else "fail" end),action:$action,label:$label,target:$target,applied:$applied,loaded:$loaded,launchctl_exit:$rc}'
}

parse_args "$@"; need_jq
case "$MODE" in run) run_pulse;; doctor) doctor_json | emit;; status|health) status_json | emit;; schema) schema_json | emit;; validate) validate_plist_json | emit;; install) install_json | emit;; load|unload) load_json | emit;; *) usage; exit 64;; esac
