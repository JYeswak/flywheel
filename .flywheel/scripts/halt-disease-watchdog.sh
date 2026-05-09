#!/usr/bin/env bash
set -euo pipefail

VERSION="halt-disease-watchdog 1.1.0"
SESSIONS="flywheel,skillos,mobile-eats,clutterfreespaces"
WINDOW_MINUTES=30
JSON_OUT=0
QUIET=0
REPO_MAP_ARG=""
LEDGER="${FLYWHEEL_HALT_DISEASE_WATCHDOG_LEDGER:-$HOME/.local/state/flywheel/halt-disease-watchdog.jsonl}"
NTM_BIN="${NTM_BIN:-/Users/josh/.local/bin/ntm}"
FLYWHEEL_LOOP="${FLYWHEEL_LOOP:-/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop}"
TIMEOUT_SECONDS="${FLYWHEEL_HALT_WATCHDOG_TIMEOUT_SECONDS:-10}"
WATCH_TIMEOUT_SECONDS="${FLYWHEEL_HALT_WATCHDOG_WATCH_TIMEOUT_SECONDS:-1}"
NOW_EPOCH="${FLYWHEEL_HALT_WATCHDOG_NOW_EPOCH:-$(date -u +%s)}"
NOW_ISO="${FLYWHEEL_HALT_WATCHDOG_NOW_ISO:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
TIMEOUT_BIN="${TIMEOUT_BIN:-$(command -v timeout || true)}"

usage() {
  printf '%s\n' "usage: halt-disease-watchdog.sh [--sessions a,b] [--repo-map a=/repo,b=/repo] [--window-minutes N] [--json] [--quiet]"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sessions) SESSIONS="${2:?}"; shift 2 ;;
    --repo-map) REPO_MAP_ARG="${2:?}"; shift 2 ;;
    --window-minutes) WINDOW_MINUTES="${2:?}"; shift 2 ;;
    --json) JSON_OUT=1; shift ;;
    --quiet) QUIET=1; shift ;;
    --once) shift ;;
    --help|-h) usage; exit 0 ;;
    --version) printf '%s\n' "$VERSION"; exit 0 ;;
    *) printf 'ERR: unknown argument: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done

need() { command -v "$1" >/dev/null 2>&1 || { printf 'ERR: missing %s\n' "$1" >&2; exit 127; }; }
need jq

repo_for() {
  local session="$1" item key val
  IFS=',' read -ra items <<<"$REPO_MAP_ARG"
  for item in "${items[@]}"; do
    key="${item%%=*}"; val="${item#*=}"
    [[ "$key" == "$session" && "$val" != "$item" ]] && { printf '%s\n' "$val"; return; }
  done
  case "$session" in
    flywheel) printf '%s\n' "/Users/josh/Developer/flywheel" ;;
    skillos) printf '%s\n' "/Users/josh/Developer/skillos" ;;
    mobile-eats) printf '%s\n' "/Users/josh/Developer/mobile-eats" ;;
    clutterfreespaces) printf '%s\n' "/Users/josh/Developer/clutterfreespaces" ;;
    *) printf '/Users/josh/Developer/%s\n' "$session" ;;
  esac
}

run_json() {
  local label="$1"; shift
  local out err rc
  out="$(mktemp)"; err="$(mktemp)"
  set +e
  if [[ -n "$TIMEOUT_BIN" ]]; then "$TIMEOUT_BIN" "$TIMEOUT_SECONDS" "$@" >"$out" 2>"$err"; else "$@" >"$out" 2>"$err"; fi
  rc=$?
  set -e
  if [[ "$rc" -eq 0 ]] && jq -e . "$out" >/dev/null 2>&1; then
    jq -nc --arg label "$label" --slurpfile data "$out" '{ok:true,label:$label,exit_code:0,data:$data[0]}'
  else
    jq -nc --arg label "$label" --arg error "$(head -c 500 "$err")" --arg stdout_head "$(head -c 500 "$out")" --argjson rc "$rc" \
      '{ok:false,label:$label,exit_code:$rc,error:$error,stdout_head:$stdout_head}'
  fi
  rm -f "$out" "$err"
}

run_watch() {
  local session="$1" out err rc
  out="$(mktemp)"; err="$(mktemp)"
  set +e
  if [[ -n "$TIMEOUT_BIN" ]]; then "$TIMEOUT_BIN" "$WATCH_TIMEOUT_SECONDS" "$NTM_BIN" watch "$session" --json --tail=1 --interval=1s >"$out" 2>"$err"; else "$NTM_BIN" watch "$session" --json --tail=1 --interval=1s >"$out" 2>"$err"; fi
  rc=$?
  set -e
  jq -nc --arg session "$session" --arg stdout_head "$(head -c 500 "$out")" --arg stderr_head "$(head -c 500 "$err")" --argjson rc "$rc" \
    '{ok:($rc == 0 or $rc == 124),session:$session,exit_code:$rc,native_command:"ntm watch --json --tail=1",stdout_head:$stdout_head,stderr_head:$stderr_head}'
  rm -f "$out" "$err"
}

jsonl_filter() {
  local path="$1" filter="$2"
  [[ -f "$path" ]] || { printf '0\n'; return; }
  jq -Rc 'fromjson? | select(type=="object")' "$path" | jq -s "$filter"
}

ready_count() {
  jsonl_filter "$1/.beads/issues.jsonl" '[.[] | select(((.status // "") | ascii_downcase) as $s | ($s == "open" or $s == "ready")) | select((.priority // 99) <= 1) | select(((.dependencies // []) | length) == 0)] | length'
}

dispatch_count() {
  local repo="$1" since="$2"
  local path="$repo/.flywheel/dispatch-log.jsonl"
  [[ -f "$path" ]] || { printf '0\n'; return; }
  jq -Rc 'fromjson? | select(type=="object")' "$path" \
    | jq -s --argjson now "$NOW_EPOCH" --argjson since "$since" \
      '[.[] | select((.event == "ntm_dispatch_sent") or (.dispatch_status == "sent")) | select(($now - ((.ts // .created_at // "") | fromdateiso8601? // $now)) <= $since)] | length'
}

contracts_json() {
  jq -c '
    if .ok != true then [] else
      .data as $d
      | ([($d.halt_contract? // empty)]
        + ($d.halt_contracts? // [] | map(select(type=="object")))
        + ($d.routing? // {} | to_entries | map(.value | select(type=="object" and .schema_version == "halt-contract/v1")))) as $contracts
      | if ($contracts | length) > 0 then $contracts else
          (($d.status // "unknown") | ascii_downcase) as $s
          | if ["fail","error","red"] | index($s) then [{
              schema_version:"halt-contract/v1-inferred", severity:"red",
              blocked_actions:["unknown.unscoped_doctor_fail"], permitted_actions:[],
              reason:"plain doctor status inferred conservatively"
            }]
            elif ["warn","warning","yellow"] | index($s) then [{
              schema_version:"halt-contract/v1-inferred", severity:"yellow",
              blocked_actions:["unknown.scoped_doctor_warning"],
              permitted_actions:["docs.plan","read.audit","dispatch.non_dangerous"],
              reason:"plain doctor warn inferred with safe plan/validate work"
            }]
            else [] end
        end
    end'
}

tmp="$(mktemp -d "${TMPDIR:-/tmp}/halt-disease-watchdog.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT
: >"$tmp/violations.jsonl"; : >"$tmp/sessions.jsonl"
window_seconds=$((WINDOW_MINUTES * 60))

IFS=',' read -ra session_list <<<"$SESSIONS"
for raw_session in "${session_list[@]}"; do
  session="$(printf '%s' "$raw_session" | xargs)"
  [[ -n "$session" ]] || continue
  repo="$(repo_for "$session")"
  ready="$(ready_count "$repo")"
  dispatch_window="$(dispatch_count "$repo" "$window_seconds")"
  dispatch_10m="$(dispatch_count "$repo" 600)"
  activity="$(run_json activity "$NTM_BIN" --robot-activity="$session" --activity-type=codex,claude --json)"
  doctor="$(FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 run_json doctor "$FLYWHEEL_LOOP" doctor --repo "$repo" --json)"
  watch="$(run_watch "$session")"
  grep_halt="$(run_json grep "$NTM_BIN" grep "HALT|halt|blocked|stopped" "$session" --json -i -n 200)"
  contracts="$(printf '%s\n' "$doctor" | contracts_json)"
  idle_agents="$(jq -c --argjson now "$NOW_EPOCH" --argjson window "$window_seconds" '
    if .ok then [.data.agents[]? | (.state // .activity // "" | ascii_upcase) as $state
      | select($state == "WAITING" or $state == "IDLE")
      | (($now - ((.state_since // "") | fromdateiso8601? // $now)) | if . < 0 then 0 else . end) as $age
      | {pane:(.pane_idx // .pane // null),state:$state,age_seconds:$age}
      | select(.age_seconds >= $window)] else [] end' <<<"$activity")"

  if (( ready > 0 )) && [[ "$(jq 'length > 0' <<<"$idle_agents")" == "true" ]]; then
    jq -nc --arg session "$session" --arg repo "$repo" --argjson idle "$idle_agents" \
      '{session:$session,repo:$repo,signal:"fleet_idle_with_ready_work",severity:"critical",blocked_actions:[],permitted_actions:["dispatch.ready_bead"],evidence:{idle_panes:$idle}}' >>"$tmp/violations.jsonl"
  fi
  jq -c --arg session "$session" --arg repo "$repo" 'select(.ok != true) | {session:$session,repo:$repo,signal:"activity_probe_failed",severity:"high",blocked_actions:[],permitted_actions:["probe.retry","read.audit"],evidence:{error:.}}' <<<"$activity" >>"$tmp/violations.jsonl"
  jq -c --arg session "$session" --arg repo "$repo" 'select(.ok != true) | {session:$session,repo:$repo,signal:"doctor_probe_failed",severity:"high",blocked_actions:[],permitted_actions:["probe.retry","read.audit"],evidence:{error:.}}' <<<"$doctor" >>"$tmp/violations.jsonl"
  jq -c --arg session "$session" --arg repo "$repo" --argjson dispatch_10m "$dispatch_10m" '
    .[] | select((.severity // "" | ascii_downcase) == "yellow") as $c
    | (if $dispatch_10m == 0 then {session:$session,repo:$repo,signal:"yellow_without_permitted_work",severity:"high",blocked_actions:($c.blocked_actions // []),permitted_actions:($c.permitted_actions // []),evidence:{reason:($c.reason // "yellow"),recent_dispatches_10m:$dispatch_10m}} else empty end),
      (if (($c.permitted_actions // []) | length) == 0 and (($c.no_safe_work_reason // "") | length) == 0 then {session:$session,repo:$repo,signal:"unscoped_yellow_halt",severity:"high",blocked_actions:($c.blocked_actions // []),permitted_actions:[],evidence:{reason:"yellow contract lacks permitted_actions and no_safe_work_reason"}} else empty end)' <<<"$contracts" >>"$tmp/violations.jsonl"
  jq -c --arg session "$session" --arg repo "$repo" --argjson dispatch_10m "$dispatch_10m" '
    .[] | select((.severity // "" | ascii_downcase) == "red" and $dispatch_10m > 0)
    | {session:$session,repo:$repo,signal:"red_ignored",severity:"critical",blocked_actions:(.blocked_actions // []),permitted_actions:(.permitted_actions // []),evidence:{reason:(.reason // "red"),recent_dispatches_10m:$dispatch_10m}}' <<<"$contracts" >>"$tmp/violations.jsonl"
  jq -nc --arg session "$session" --arg repo "$repo" --argjson ready "$ready" --argjson dispatch_window "$dispatch_window" --argjson dispatch_10m "$dispatch_10m" \
    --argjson idle "$idle_agents" --argjson contracts "$contracts" --argjson activity "$activity" --argjson doctor "$doctor" --argjson watch "$watch" --argjson grep "$grep_halt" \
    '{key:$session,value:{repo:$repo,ready_count:$ready,recent_dispatches_window:$dispatch_window,recent_dispatches_10m:$dispatch_10m,idle_agents:$idle,contracts:$contracts,activity_ok:$activity.ok,doctor_ok:$doctor.ok,native_watch:$watch,native_grep:{ok:$grep.ok,match_count:($grep.data.match_count // 0)}}}' >>"$tmp/sessions.jsonl"
done

violations="$(jq -s '.' "$tmp/violations.jsonl")"
session_rows="$(jq -s 'from_entries' "$tmp/sessions.jsonl")"
row="$(jq -nc --arg schema "halt-disease-watchdog/v1" --arg ts "$NOW_ISO" --argjson violations "$violations" --argjson sessions "$session_rows" '
  ($violations | map(select(.severity == "critical")) | length) as $critical
  | ($violations | map(select(.severity == "high")) | length) as $high
  | {schema_version:$schema,ts:$ts,status:(if $critical > 0 then "critical" elif $high > 0 then "high" else "healthy" end),
     fleet_idle_with_ready_work_count:($violations | map(select(.signal == "fleet_idle_with_ready_work")) | length),
     joshua_mornings_with_idle_fleet_count:($violations | map(select(.signal == "fleet_idle_with_ready_work")) | length),
     yellow_without_permitted_work_count:($violations | map(select(.signal == "yellow_without_permitted_work" or .signal == "unscoped_yellow_halt")) | length),
     red_ignored_count:($violations | map(select(.signal == "red_ignored")) | length),
     joshua_mornings_with_idle_fleet_risk:(($violations | map(select(.signal == "fleet_idle_with_ready_work")) | length) >= 2),
     dispatches_continued_per_doctor_yellow:($sessions | with_entries(.value = .value.recent_dispatches_10m)),
     time_between_yellow_signal_and_halt_propagation_seconds:(if ($violations | any(.signal == "yellow_without_permitted_work" or .signal == "unscoped_yellow_halt")) then null else 0 end),
     native_surfaces:["ntm watch","ntm grep --json"],
     session_rows:$sessions,violations:$violations}
     | .dashboard_line = "halt_disease status=\(.status) idle_ready=\(.fleet_idle_with_ready_work_count) yellow_no_work=\(.yellow_without_permitted_work_count) red_ignored=\(.red_ignored_count) joshua_morning_risk=\(.joshua_mornings_with_idle_fleet_risk)"')"

mkdir -p "$(dirname "$LEDGER")"
printf '%s\n' "$row" >>"$LEDGER"
if [[ "$JSON_OUT" -eq 1 ]]; then printf '%s\n' "$row"; elif [[ "$QUIET" -eq 0 ]]; then jq -r '.dashboard_line' <<<"$row"; fi
jq -e '.status == "healthy"' <<<"$row" >/dev/null && exit 0
jq -e '.status == "high"' <<<"$row" >/dev/null && exit 1
exit 2
