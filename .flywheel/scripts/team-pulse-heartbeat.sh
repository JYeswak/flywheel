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
SAFE_PATH="${FLYWHEEL_TEAM_PULSE_SAFE_PATH:-/Users/josh/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin}"
MODE="run"
JSON_OUT=0
APPLY=0
DRY_RUN=0
NOW_OVERRIDE=""
SCHEMA_TOPIC="pulse"
VALIDATE_TARGET="plist"

usage() {
  cat <<'EOF'
Usage:
  team-pulse-heartbeat.sh run [--json]
  team-pulse-heartbeat.sh doctor [--json]
  team-pulse-heartbeat.sh status [--json]
  team-pulse-heartbeat.sh install --dry-run|--apply [--json]
  team-pulse-heartbeat.sh load --dry-run|--apply [--json]
  team-pulse-heartbeat.sh unload --dry-run|--apply [--json]
  team-pulse-heartbeat.sh validate plist [--json]
  team-pulse-heartbeat.sh schema [pulse|doctor|plist] [--json]

Writes team-pulse.jsonl rows for latest active roster sessions without
bootstrapping or mutating unconfirmed sessions.
EOF
}

require_jq() {
  command -v jq >/dev/null 2>&1 || {
    printf 'ERR: jq is required\n' >&2
    exit 69
  }
}

now_iso() {
  if [[ -n "$NOW_OVERRIDE" ]]; then
    printf '%s\n' "$NOW_OVERRIDE"
  else
    date -u +%Y-%m-%dT%H:%M:%SZ
  fi
}

json_bool() {
  [[ "$1" == true ]] && printf 'true\n' || printf 'false\n'
}

parse_args() {
  if [[ $# -gt 0 ]]; then
    case "$1" in
      run|doctor|status|health|install|load|unload|validate|schema)
        MODE="$1"
        shift
        ;;
    esac
  fi
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --json) JSON_OUT=1; shift ;;
      --apply) APPLY=1; shift ;;
      --dry-run) DRY_RUN=1; shift ;;
      --now) NOW_OVERRIDE="${2:?--now requires ISO timestamp}"; shift 2 ;;
      --now=*) NOW_OVERRIDE="${1#--now=}"; shift ;;
      --state-dir) STATE_DIR="${2:?--state-dir requires PATH}"; shift 2 ;;
      --state-dir=*) STATE_DIR="${1#--state-dir=}" ; shift ;;
      --roster) ROSTER="${2:?--roster requires PATH}"; shift 2 ;;
      --roster=*) ROSTER="${1#--roster=}" ; shift ;;
      --topology) TOPOLOGY="${2:?--topology requires PATH}"; shift 2 ;;
      --topology=*) TOPOLOGY="${1#--topology=}" ; shift ;;
      --pulse) PULSE="${2:?--pulse requires PATH}"; shift 2 ;;
      --pulse=*) PULSE="${1#--pulse=}" ; shift ;;
      --lock-file) LOCK_FILE="${2:?--lock-file requires PATH}"; shift 2 ;;
      --lock-file=*) LOCK_FILE="${1#--lock-file=}" ; shift ;;
      --ntm-bin) NTM_BIN="${2:?--ntm-bin requires PATH}"; shift 2 ;;
      --ntm-bin=*) NTM_BIN="${1#--ntm-bin=}" ; shift ;;
      --source-plist) SOURCE_PLIST="${2:?--source-plist requires PATH}"; shift 2 ;;
      --source-plist=*) SOURCE_PLIST="${1#--source-plist=}" ; shift ;;
      --install-plist) INSTALL_PLIST="${2:?--install-plist requires PATH}"; shift 2 ;;
      --install-plist=*) INSTALL_PLIST="${1#--install-plist=}" ; shift ;;
      --stale-seconds) STALE_SECONDS="${2:?--stale-seconds requires N}"; shift 2 ;;
      --stale-seconds=*) STALE_SECONDS="${1#--stale-seconds=}" ; shift ;;
      --cadence-seconds) CADENCE_SECONDS="${2:?--cadence-seconds requires N}"; shift 2 ;;
      --cadence-seconds=*) CADENCE_SECONDS="${1#--cadence-seconds=}" ; shift ;;
      pulse|doctor|plist)
        if [[ "$MODE" == schema ]]; then
          SCHEMA_TOPIC="$1"
        elif [[ "$MODE" == validate ]]; then
          VALIDATE_TARGET="$1"
        else
          printf 'ERR: unexpected argument: %s\n' "$1" >&2
          exit 64
        fi
        shift
        ;;
      --help|-h) usage; exit 0 ;;
      *) printf 'ERR: unknown argument: %s\n' "$1" >&2; usage >&2; exit 64 ;;
    esac
  done
  case "$STALE_SECONDS" in (*[!0-9]*|'') printf 'ERR: --stale-seconds must be an integer\n' >&2; exit 64 ;; esac
  case "$CADENCE_SECONDS" in (*[!0-9]*|'') printf 'ERR: --cadence-seconds must be an integer\n' >&2; exit 64 ;; esac
}

latest_roster_json() {
  if [[ ! -s "$ROSTER" ]]; then
    printf '[]\n'
    return 0
  fi
  jq -s 'group_by(.session) | map(max_by(.ts // "")) | map(select(.event == "session_active"))' "$ROSTER"
}

latest_topology_json() {
  if [[ ! -s "$TOPOLOGY" ]]; then
    printf '[]\n'
    return 0
  fi
  jq -s 'group_by(.session) | map(max_by(.effective_at // ""))' "$TOPOLOGY"
}

health_json() {
  local session="$1" out rc
  set +e
  out="$("$NTM_BIN" health "$session" --json 2>&1)"
  rc=$?
  set -e
  if printf '%s' "$out" | jq -e . >/dev/null 2>&1; then
    jq -c --argjson exit_code "$rc" '. + {exit_code:$exit_code}' <<<"$out"
  else
    jq -nc --arg raw "$out" --argjson exit_code "$rc" \
      '{success:false,parse_error:true,exit_code:$exit_code,raw:$raw}'
  fi
}

latest_dispatch_ts() {
  local repo="$1" log="$repo/.flywheel/dispatch-log.jsonl"
  [[ -s "$log" ]] || return 0
  jq -rs '[.[] | (.ts? // .started_at? // empty)] | max // empty' "$log" 2>/dev/null || true
}

loop_freshness_json() {
  local repo="$1" now="$2" last_run tick_ts dispatch_ts
  if [[ -z "$repo" || ! -d "$repo" ]]; then
    jq -nc --arg repo "$repo" '{available:false,repo_path:$repo,last_tick_ts:null,last_tick_age_seconds:null,last_dispatch_ts:null,last_dispatch_age_seconds:null}'
    return 0
  fi
  last_run="$repo/.flywheel/runtime/flywheel-loop/last_run.json"
  [[ -s "$last_run" ]] || last_run="$repo/.flywheel/last_run.json"
  tick_ts=""
  if [[ -s "$last_run" ]]; then
    tick_ts="$(jq -r '.ts // empty' "$last_run" 2>/dev/null || true)"
  fi
  dispatch_ts="$(latest_dispatch_ts "$repo")"
  jq -nc --arg repo "$repo" --arg now "$now" --arg tick_ts "$tick_ts" --arg dispatch_ts "$dispatch_ts" '
    def age($ts):
      if $ts == "" then null
      else (try (($now | fromdateiso8601) - ($ts | fromdateiso8601) | floor) catch null) as $age
      | if $age == null then null elif $age < 0 then 0 else $age end
      end;
    {
      available:true,
      repo_path:$repo,
      last_tick_ts:(if $tick_ts == "" then null else $tick_ts end),
      last_tick_age_seconds:age($tick_ts),
      last_dispatch_ts:(if $dispatch_ts == "" then null else $dispatch_ts end),
      last_dispatch_age_seconds:age($dispatch_ts)
    }'
}

pulse_row_json() {
  local now="$1" roster_row="$2" topology_row="$3" health="$4" loop="$5"
  jq -nc \
    --arg now "$now" \
    --argjson roster "$roster_row" \
    --argjson topology "$topology_row" \
    --argjson health "$health" \
    --argjson loop "$loop" '
      def health_panes:
        if ($health.panes? | type == "array") then $health.panes
        elif ($health.agents? | type == "array") then $health.agents
        else [] end;
      def pane_id: .pane // .pane_idx // .id // null;
      def pane_row($p): [health_panes[] | select((pane_id | tostring) == ($p | tostring))] | last;
      def bad_status($v): (($v // "") | tostring | ascii_downcase | test("error|exited|failed|dead|stuck|unhealthy|missing|not_found"));
      def pane_alive($p):
        (pane_row($p)) as $row
        | if $row == null then false
          elif bad_status($row.status) or bad_status($row.process_status) or bad_status($row.state) then false
          elif (($row.status // $row.process_status // $row.state // "") | tostring | length) == 0 then false
          else true end;
      ($roster.session) as $session
      | ($roster.orchestrator.pane // $topology.orchestrator_pane // null) as $orch
      | ((($roster.workers // []) | map(.pane)) + ($roster.worker_panes // []) + ($topology.worker_panes // []) | unique) as $workers
      | ($workers | map(select(pane_alive(.)))) as $alive
      | ($workers | map(select((pane_alive(.) | not)))) as $dead
      | {
          schema_version:"team-pulse/v1",
          ts:$now,
          event:"team_pulse",
          session:$session,
          source:"team-pulse-heartbeat",
          roster_ts:($roster.ts // null),
          repo_path:($roster.repo_path // $topology.repo_path // null),
          orch_pane:$orch,
          orch_pane_alive:(if $orch == null then false else pane_alive($orch) end),
          worker_panes_expected:$workers,
          worker_panes_alive:$alive,
          worker_panes_dead:$dead,
          loop_tick_freshness:$loop,
          last_tick_ts:$loop.last_tick_ts,
          last_tick_age_seconds:$loop.last_tick_age_seconds,
          last_dispatch_ts:$loop.last_dispatch_ts,
          last_dispatch_age_seconds:$loop.last_dispatch_age_seconds,
          health_exit_code:($health.exit_code // 0),
          health_status:($health.status // $health.overall_status // null),
          health_parse_error:($health.parse_error // false),
          confirmed_source:($roster.joshua_confirmed_at // $roster.registered_by // "session_active_roster_row")
        }'
}

append_rows() {
  local rows_file="$1" appended
  appended="$(wc -l <"$rows_file" | tr -d ' ')"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    jq -nc --argjson appended "$appended" --arg pulse "$PULSE" \
      '{status:"dry_run",appended:false,planned_rows:$appended,pulse_path:$pulse}'
    return 0
  fi
  mkdir -p "$(dirname "$PULSE")" "$(dirname "$LOCK_FILE")"
  if command -v flock >/dev/null 2>&1; then
    exec 9>"$LOCK_FILE"
    flock 9
    cat "$rows_file" >>"$PULSE"
  else
    local lock_dir="${LOCK_FILE}.d"
    until mkdir "$lock_dir" 2>/dev/null; do sleep 0.1; done
    trap 'rmdir "$lock_dir" 2>/dev/null || true' RETURN
    cat "$rows_file" >>"$PULSE"
  fi
  jq -nc --argjson appended "$appended" --arg pulse "$PULSE" \
    '{status:"pass",appended:true,rows_appended:$appended,pulse_path:$pulse}'
}

run_pulse() {
  require_jq
  local now roster topology tmp count session roster_row topology_row health loop repo result append_result
  now="$(now_iso)"
  roster="$(latest_roster_json)"
  topology="$(latest_topology_json)"
  tmp="$(mktemp "${TMPDIR:-/tmp}/team-pulse.XXXXXX")"
  trap 'rm -f "$tmp"' RETURN
  count="$(jq -r 'length' <<<"$roster")"
  for idx in $(seq 0 $((count - 1))); do
    roster_row="$(jq -c --argjson idx "$idx" '.[$idx]' <<<"$roster")"
    session="$(jq -r '.session' <<<"$roster_row")"
    topology_row="$(jq -c --arg session "$session" 'map(select(.session == $session)) | last // {}' <<<"$topology")"
    health="$(health_json "$session")"
    repo="$(jq -r --argjson topology "$topology_row" '.repo_path // $topology.repo_path // ""' <<<"$roster_row")"
    loop="$(loop_freshness_json "$repo" "$now")"
    pulse_row_json "$now" "$roster_row" "$topology_row" "$health" "$loop" >>"$tmp"
  done
  append_result="$(append_rows "$tmp")"
  result="$(jq -nc \
    --arg schema_version "$CONTRACT.result" \
    --arg now "$now" \
    --arg roster "$ROSTER" \
    --arg topology "$TOPOLOGY" \
    --arg pulse "$PULSE" \
    --argjson active_sessions "$count" \
    --argjson append "$append_result" \
    --slurpfile rows "$tmp" \
    '{schema_version:$schema_version,ts:$now,status:$append.status,roster_path:$roster,topology_path:$topology,pulse_path:$pulse,active_confirmed_session_count:$active_sessions,append:$append,rows:$rows}')"
  printf '%s\n' "$result" | emit_output
}

doctor_json() {
  require_jq
  local now roster
  now="$(now_iso)"
  roster="$(latest_roster_json)"
  if [[ ! -s "$PULSE" ]]; then
    jq -nc --arg now "$now" --arg pulse "$PULSE" --argjson roster "$roster" --argjson stale "$STALE_SECONDS" '
      {
        schema_version:"team-pulse-doctor/v1",
        ts:$now,
        status:(if ($roster | length) == 0 then "pass" else "fail" end),
        pulse_path:$pulse,
        stale_seconds:$stale,
        active_confirmed_session_count:($roster | length),
        pulse_session_status:($roster | map({session, status:"DEAD", reason:"missing_pulse", pulse_age_seconds:null})),
        team_pulse_dead_session_count:($roster | length),
        team_pulse_stale_session_count:0,
        team_pulse_missing_session_count:($roster | length)
      }'
    return 0
  fi
  jq -cs --arg now "$now" --arg pulse "$PULSE" --argjson roster "$roster" --argjson stale "$STALE_SECONDS" '
    def age($ts): try (($now | fromdateiso8601) - ($ts | fromdateiso8601) | floor) catch null;
    (. // []) as $pulses
    | ($pulses | group_by(.session) | map(max_by(.ts // ""))) as $latest
    | ($roster | map(
        .session as $session
        | ($latest | map(select(.session == $session)) | last) as $pulse
        | if $pulse == null then
            {session:$session,status:"DEAD",reason:"missing_pulse",pulse_age_seconds:null,latest_pulse_ts:null,orch_pane_alive:false,worker_panes_dead:[]}
          else
            (age($pulse.ts)) as $pulse_age
            | {
                session:$session,
                status:(if ($pulse_age == null or $pulse_age > $stale) then "DEAD" elif ($pulse.orch_pane_alive != true or (($pulse.worker_panes_dead // []) | length) > 0) then "DEGRADED" else "LIVE" end),
                reason:(if ($pulse_age == null) then "invalid_pulse_ts" elif ($pulse_age > $stale) then "stale_pulse" elif ($pulse.orch_pane_alive != true) then "orch_pane_dead" elif (($pulse.worker_panes_dead // []) | length) > 0 then "worker_panes_dead" else "fresh" end),
                pulse_age_seconds:$pulse_age,
                latest_pulse_ts:$pulse.ts,
                orch_pane_alive:($pulse.orch_pane_alive // false),
                worker_panes_alive:($pulse.worker_panes_alive // []),
                worker_panes_dead:($pulse.worker_panes_dead // []),
                last_tick_age_seconds:($pulse.last_tick_age_seconds // null),
                last_dispatch_age_seconds:($pulse.last_dispatch_age_seconds // null)
              }
          end
      )) as $sessions
    | ($sessions | map(select(.status == "DEAD"))) as $dead
    | {
        schema_version:"team-pulse-doctor/v1",
        ts:$now,
        status:(if ($dead | length) > 0 then "fail" elif ($sessions | any(.status == "DEGRADED")) then "warn" else "pass" end),
        pulse_path:$pulse,
        stale_seconds:$stale,
        active_confirmed_session_count:($roster | length),
        pulse_session_status:$sessions,
        team_pulse_dead_session_count:($dead | length),
        team_pulse_stale_session_count:($sessions | map(select(.reason == "stale_pulse")) | length),
        team_pulse_missing_session_count:($sessions | map(select(.reason == "missing_pulse")) | length)
      }' "$PULSE"
}

status_json() {
  local doctor source_exists install_exists loaded=false status
  doctor="$(doctor_json)"
  [[ -f "$SOURCE_PLIST" ]] && source_exists=true || source_exists=false
  [[ -f "$INSTALL_PLIST" ]] && install_exists=true || install_exists=false
  if command -v launchctl >/dev/null 2>&1 && launchctl print "$DOMAIN/$LABEL" >/dev/null 2>&1; then
    loaded=true
  fi
  status="$(jq -r '.status' <<<"$doctor")"
  jq -nc \
    --arg schema_version "team-pulse-status/v1" \
    --arg status "$status" \
    --arg source_plist "$SOURCE_PLIST" \
    --arg install_plist "$INSTALL_PLIST" \
    --arg label "$LABEL" \
    --arg domain "$DOMAIN" \
    --argjson source_exists "$(json_bool "$source_exists")" \
    --argjson install_exists "$(json_bool "$install_exists")" \
    --argjson loaded "$(json_bool "$loaded")" \
    --argjson cadence "$CADENCE_SECONDS" \
    --argjson doctor "$doctor" \
    '{schema_version:$schema_version,status:$status,label:$label,launchd_domain:$domain,source_plist:$source_plist,install_plist:$install_plist,source_plist_exists:$source_exists,install_plist_exists:$install_exists,launchd_loaded:$loaded,cadence_seconds:$cadence,doctor:$doctor}'
}

emit_output() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -cS .
  else
    jq .
  fi
}

schema_json() {
  case "$SCHEMA_TOPIC" in
    pulse)
      jq -nc '{schema_version:"team-pulse.schema/v1",required:["schema_version","ts","event","session","orch_pane_alive","worker_panes_alive","worker_panes_dead","loop_tick_freshness"],stale_after_seconds:900}' ;;
    doctor)
      jq -nc '{schema_version:"team-pulse-doctor.schema/v1",required:["schema_version","ts","status","pulse_session_status","team_pulse_dead_session_count","team_pulse_stale_session_count"],dead_rule:"latest pulse older than stale_seconds is DEAD"}' ;;
    plist)
      jq -nc --arg label "$LABEL" --argjson cadence "$CADENCE_SECONDS" '{schema_version:"team-pulse-plist.schema/v1",label:$label,start_interval_seconds:$cadence,program_arguments:["team-pulse-heartbeat.sh","run","--json"]}' ;;
    *) printf 'ERR: unknown schema topic: %s\n' "$SCHEMA_TOPIC" >&2; exit 64 ;;
  esac
}

validate_plist_json() {
  [[ "$VALIDATE_TARGET" == "plist" ]] || { printf 'ERR: only validate plist is supported\n' >&2; exit 64; }
  local lint_ok=false label_ok=false cadence_ok=false command_ok=false status="pass"
  if command -v plutil >/dev/null 2>&1 && plutil -lint "$SOURCE_PLIST" >/dev/null 2>&1; then
    lint_ok=true
  elif grep -q '<plist version=' "$SOURCE_PLIST" 2>/dev/null; then
    lint_ok=true
  fi
  grep -q "<string>${LABEL}</string>" "$SOURCE_PLIST" 2>/dev/null && label_ok=true
  grep -q "<integer>${CADENCE_SECONDS}</integer>" "$SOURCE_PLIST" 2>/dev/null && cadence_ok=true
  grep -q 'team-pulse-heartbeat.sh' "$SOURCE_PLIST" 2>/dev/null && grep -q '<string>run</string>' "$SOURCE_PLIST" 2>/dev/null && command_ok=true
  if [[ "$lint_ok" != true || "$label_ok" != true || "$cadence_ok" != true || "$command_ok" != true ]]; then
    status="fail"
  fi
  jq -nc \
    --arg status "$status" \
    --arg source_plist "$SOURCE_PLIST" \
    --arg label "$LABEL" \
    --argjson cadence "$CADENCE_SECONDS" \
    --argjson lint_ok "$(json_bool "$lint_ok")" \
    --argjson label_ok "$(json_bool "$label_ok")" \
    --argjson cadence_ok "$(json_bool "$cadence_ok")" \
    --argjson command_ok "$(json_bool "$command_ok")" \
    '{schema_version:"team-pulse-plist-validation/v1",status:$status,source_plist:$source_plist,label:$label,cadence_seconds:$cadence,lint_ok:$lint_ok,label_ok:$label_ok,cadence_ok:$cadence_ok,helper_command_ok:$command_ok}'
}

install_json() {
  local applied=false installed=false planned
  planned="$(jq -nc --arg source "$SOURCE_PLIST" --arg install "$INSTALL_PLIST" '{action:"install_launchagent",source:$source,target:$install}')"
  if [[ "$APPLY" -eq 1 ]]; then
    mkdir -p "$(dirname "$INSTALL_PLIST")"
    cp "$SOURCE_PLIST" "$INSTALL_PLIST"
    applied=true
    installed=true
  elif [[ "$DRY_RUN" -ne 1 ]]; then
    printf 'ERR: install requires --dry-run or --apply\n' >&2
    exit 64
  fi
  jq -nc --arg status "pass" --arg label "$LABEL" --arg source "$SOURCE_PLIST" --arg install "$INSTALL_PLIST" --argjson applied "$(json_bool "$applied")" --argjson installed "$(json_bool "$installed")" --argjson planned "$planned" \
    '{schema_version:"team-pulse-install/v1",status:$status,label:$label,source_plist:$source,install_plist:$install,applied:$applied,installed:$installed,planned_actions:[$planned]}'
}

load_json() {
  local applied=false loaded=false rc=0 action="$MODE"
  if [[ "$APPLY" -eq 1 ]]; then
    if [[ "$MODE" == "load" ]]; then
      launchctl bootout "$DOMAIN/$LABEL" >/dev/null 2>&1 || true
      launchctl bootstrap "$DOMAIN" "$INSTALL_PLIST" >/dev/null 2>&1 || rc=$?
      launchctl kickstart -k "$DOMAIN/$LABEL" >/dev/null 2>&1 || true
    else
      launchctl bootout "$DOMAIN/$LABEL" >/dev/null 2>&1 || rc=$?
    fi
    applied=true
  elif [[ "$DRY_RUN" -ne 1 ]]; then
    printf 'ERR: %s requires --dry-run or --apply\n' "$MODE" >&2
    exit 64
  fi
  if command -v launchctl >/dev/null 2>&1 && launchctl print "$DOMAIN/$LABEL" >/dev/null 2>&1; then
    loaded=true
  fi
  jq -nc --arg action "$action" --arg label "$LABEL" --arg target "$DOMAIN/$LABEL" --argjson applied "$(json_bool "$applied")" --argjson loaded "$(json_bool "$loaded")" --argjson rc "$rc" \
    '{schema_version:"team-pulse-launchd/v1",status:(if $rc == 0 then "pass" else "fail" end),action:$action,label:$label,target:$target,applied:$applied,loaded:$loaded,launchctl_exit:$rc}'
}

parse_args "$@"
require_jq

case "$MODE" in
  run) run_pulse ;;
  doctor) doctor_json | emit_output ;;
  status|health) status_json | emit_output ;;
  schema) schema_json | emit_output ;;
  validate) validate_plist_json | emit_output ;;
  install) install_json | emit_output ;;
  load|unload) load_json | emit_output ;;
  *) usage; exit 64 ;;
esac
