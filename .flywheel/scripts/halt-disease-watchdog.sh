#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (partial -> passing per bead flywheel-k8gcv.6)
set -euo pipefail

VERSION="halt-disease-watchdog 1.2.0"
SCHEMA_VERSION="halt-disease-watchdog/v1"
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
  cat <<'EOF'
usage:
  halt-disease-watchdog.sh [--sessions a,b] [--repo-map a=/repo,b=/repo] [--window-minutes N] [--json] [--quiet]
  halt-disease-watchdog.sh --info --json
  halt-disease-watchdog.sh --schema --json
  halt-disease-watchdog.sh --examples [--json]
  halt-disease-watchdog.sh doctor --json
  halt-disease-watchdog.sh health --json
  halt-disease-watchdog.sh validate --json
  halt-disease-watchdog.sh audit --json [--limit N]
  halt-disease-watchdog.sh why [topic] [--json]
  halt-disease-watchdog.sh quickstart [--json]
  halt-disease-watchdog.sh repair --scope <ledger-prime> [--dry-run|--apply --idempotency-key KEY] [--json]
  halt-disease-watchdog.sh --help|-h|--version
EOF
}

# ---------- canonical-cli emitters (added by flywheel-k8gcv.6) ----------

emit_info() {
  jq -nc --arg sv "$SCHEMA_VERSION" --arg name "halt-disease-watchdog.sh" --arg version "$VERSION" \
    --arg ledger "$LEDGER" --arg ntm_bin "$NTM_BIN" --arg flywheel_loop "$FLYWHEEL_LOOP" \
    --arg sessions "$SESSIONS" --argjson window "$WINDOW_MINUTES" \
    '{
      schema_version:$sv,
      command:"info",
      name:$name,
      version:$version,
      ledger:$ledger,
      ntm_bin:$ntm_bin,
      flywheel_loop:$flywheel_loop,
      default_sessions:($sessions | split(",")),
      default_window_minutes:$window,
      purpose:"Probe fleet for halt-disease (fleet idle while ready work exists, yellow-without-permitted-work, red ignored, dispatch storms during doctor-yellow). Append signal to ledger and emit dashboard line.",
      subcommands:["doctor","health","validate","audit","why","repair","quickstart"],
      canonical_flags:["--info","--schema","--examples","--json","--apply","--dry-run","--idempotency-key","--sessions","--repo-map","--window-minutes","--quiet"],
      capabilities:["fleet-idle-with-ready-work-probe","yellow-contract-validation","red-ignored-detection","ntm-watch-and-grep-native","ledger-append","dashboard-line-emission"],
      apply_supported:true,
      dry_run_supported:true,
      idempotency_key_required_for_apply:true,
      mutates_state:true,
      env_vars:["FLYWHEEL_HALT_DISEASE_WATCHDOG_LEDGER","NTM_BIN","FLYWHEEL_LOOP","FLYWHEEL_HALT_WATCHDOG_TIMEOUT_SECONDS","FLYWHEEL_HALT_WATCHDOG_WATCH_TIMEOUT_SECONDS","FLYWHEEL_HALT_WATCHDOG_NOW_EPOCH","FLYWHEEL_HALT_WATCHDOG_NOW_ISO","TIMEOUT_BIN"],
      exit_codes:{"0":"healthy","1":"high-severity-violations","2":"critical-violations-or-error","3":"refused-apply-without-idempotency-key","64":"bad-args"}
    }'
}

emit_schema() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"schema",
    input_schema:{
      type:"object",
      properties:{
        sessions:{type:"string",description:"comma-separated session names"},
        repo_map:{type:"string",description:"comma-separated session=/repo entries"},
        window_minutes:{type:"integer",minimum:1,description:"idle-detection window"},
        json:{type:"boolean"},
        quiet:{type:"boolean"}
      }
    },
    output_schema:{
      type:"object",
      required:["schema_version","ts","status","session_rows","violations"],
      properties:{
        schema_version:{type:"string"},
        ts:{type:"string",format:"date-time"},
        status:{enum:["healthy","high","critical"]},
        fleet_idle_with_ready_work_count:{type:"integer"},
        joshua_mornings_with_idle_fleet_count:{type:"integer"},
        yellow_without_permitted_work_count:{type:"integer"},
        red_ignored_count:{type:"integer"},
        joshua_mornings_with_idle_fleet_risk:{type:"boolean"},
        session_rows:{type:"object"},
        violations:{type:"array"},
        dashboard_line:{type:"string"}
      }
    },
    exit_codes:{
      "0":"healthy",
      "1":"high-severity-violations",
      "2":"critical-violations-or-error",
      "3":"refused-apply-without-idempotency-key",
      "64":"bad-args"
    }
  }'
}

emit_examples() {
  if [[ "${1:-}" == "--json" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" '{
      schema_version:$sv,
      command:"examples",
      examples:[
        {name:"default-fleet-probe",invocation:"halt-disease-watchdog.sh --json",purpose:"probe default sessions (flywheel,skillos,mobile-eats,clutterfreespaces) for halt-disease signals"},
        {name:"custom-sessions",invocation:"halt-disease-watchdog.sh --sessions flywheel,skillos --window-minutes 15 --json",purpose:"probe a custom session list with a tighter idle window"},
        {name:"quiet-mode",invocation:"halt-disease-watchdog.sh --quiet",purpose:"emit nothing on stdout; use exit code (0=healthy,1=high,2=critical) — for cron"},
        {name:"doctor",invocation:"halt-disease-watchdog.sh doctor --json",purpose:"verify jq, ntm, flywheel-loop, ledger writable"},
        {name:"audit",invocation:"halt-disease-watchdog.sh audit --json",purpose:"tail recent halt-disease watchdog rows"}
      ]
    }'
  else
    cat <<'EOF'
examples:
  halt-disease-watchdog.sh --json
  halt-disease-watchdog.sh --sessions flywheel,skillos --window-minutes 15 --json
  halt-disease-watchdog.sh --quiet
  halt-disease-watchdog.sh doctor --json
  halt-disease-watchdog.sh audit --json
EOF
  fi
}

emit_doctor() {
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local jq_status="pass"; command -v jq >/dev/null 2>&1 || jq_status="fail"
  local ntm_status="pass"; [[ -x "$NTM_BIN" ]] || ntm_status="warn"
  local loop_status="pass"; [[ -x "$FLYWHEEL_LOOP" ]] || loop_status="warn"
  local ledger_dir; ledger_dir="$(dirname "$LEDGER")"
  local ledger_status="pass"
  if [[ -e "$LEDGER" ]]; then
    [[ -w "$LEDGER" ]] || ledger_status="fail"
  else
    [[ -d "$ledger_dir" ]] || ledger_status="warn"
  fi
  local timeout_status="pass"; [[ -n "$TIMEOUT_BIN" ]] || timeout_status="warn"
  local overall="pass"
  for s in "$jq_status" "$ntm_status" "$loop_status" "$ledger_status" "$timeout_status"; do
    case "$s" in
      fail) overall="fail" ;;
      warn) [[ "$overall" == "pass" ]] && overall="warn" ;;
    esac
  done
  jq -nc --arg sv "$SCHEMA_VERSION.doctor" --arg ts "$ts" --arg overall "$overall" \
    --arg jq_s "$jq_status" --arg ntm_s "$ntm_status" --arg ntm_path "$NTM_BIN" \
    --arg loop_s "$loop_status" --arg loop_path "$FLYWHEEL_LOOP" \
    --arg ledger_s "$ledger_status" --arg ledger "$LEDGER" \
    --arg timeout_s "$timeout_status" --arg timeout_path "${TIMEOUT_BIN:-}" \
    '{
      schema_version:$sv,
      command:"doctor",
      ts:$ts,
      status:$overall,
      checks:[
        {name:"jq",status:$jq_s,detail:"jq required for envelope emission"},
        {name:"ntm_bin",status:$ntm_s,path:$ntm_path,detail:"ntm binary for watch/grep/robot-activity probes"},
        {name:"flywheel_loop",status:$loop_s,path:$loop_path,detail:"flywheel-loop doctor probe (warn if missing)"},
        {name:"ledger_writable",status:$ledger_s,path:$ledger,detail:"append-only watchdog ledger"},
        {name:"timeout_bin",status:$timeout_s,path:$timeout_path,detail:"timeout binary for bounded child invocations (warn if missing — child commands run unbounded)"}
      ]
    }'
}

emit_health() {
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local row_count=0
  local last_status=""
  local last_ts=""
  if [[ -r "$LEDGER" ]]; then
    row_count="$(wc -l <"$LEDGER" 2>/dev/null | tr -d ' ')"
    [[ -z "$row_count" ]] && row_count=0
    if [[ "$row_count" -gt 0 ]]; then
      last_status="$(tail -n 1 "$LEDGER" 2>/dev/null | jq -r '.status // empty' 2>/dev/null || true)"
      last_ts="$(tail -n 1 "$LEDGER" 2>/dev/null | jq -r '.ts // empty' 2>/dev/null || true)"
    fi
  fi
  local status="pass"
  case "$last_status" in
    critical) status="fail" ;;
    high) status="warn" ;;
  esac
  jq -nc --arg sv "$SCHEMA_VERSION.health" --arg ts "$ts" --arg status "$status" \
    --arg ledger "$LEDGER" --argjson row_count "${row_count:-0}" \
    --arg last_status "${last_status:-}" --arg last_ts "${last_ts:-}" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,ledger:$ledger,ledger_row_count:$row_count,last_status:$last_status,last_audit_ts:$last_ts}'
}

emit_validate() {
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local rows=0 invalid=0
  if [[ -r "$LEDGER" ]]; then
    rows="$(wc -l <"$LEDGER" 2>/dev/null | tr -d ' ')"
    [[ -z "$rows" ]] && rows=0
    if [[ "$rows" -gt 0 ]]; then
      invalid="$(jq -c 'select((.schema_version // "") != "halt-disease-watchdog/v1" or (.status // "") == "")' "$LEDGER" 2>/dev/null | wc -l | tr -d ' ')"
      [[ -z "$invalid" ]] && invalid=0
    fi
  fi
  local status="pass"
  [[ "$invalid" -gt 0 ]] && status="violations"
  jq -nc --arg sv "$SCHEMA_VERSION.validate" --arg ts "$ts" --arg status "$status" \
    --argjson rows "${rows:-0}" --argjson invalid "${invalid:-0}" --arg ledger "$LEDGER" \
    '{schema_version:$sv,command:"validate",ts:$ts,status:$status,ledger:$ledger,row_count:$rows,invalid_row_count:$invalid,check:"every row has schema_version=halt-disease-watchdog/v1 and non-empty status"}'
}

emit_audit() {
  local limit="${1:-20}"
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [[ ! -r "$LEDGER" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION.audit" --arg ts "$ts" --arg ledger "$LEDGER" \
      '{schema_version:$sv,command:"audit",ts:$ts,status:"missing",ledger:$ledger,row_count:0,recent:[]}'
    return 0
  fi
  local row_count
  row_count="$(wc -l <"$LEDGER" 2>/dev/null | tr -d ' ')"
  [[ -z "$row_count" ]] && row_count=0
  local recent='[]'
  if [[ "$row_count" -gt 0 ]]; then
    recent="$(tail -n "$limit" "$LEDGER" 2>/dev/null | jq -cs '.' 2>/dev/null || printf '%s' '[]')"
    [[ -z "$recent" ]] && recent='[]'
  fi
  local status="pass"
  [[ "$row_count" -eq 0 ]] && status="empty"
  jq -nc --arg sv "$SCHEMA_VERSION.audit" --arg ts "$ts" --arg status "$status" \
    --arg ledger "$LEDGER" --argjson row_count "$row_count" --argjson recent "$recent" \
    '{schema_version:$sv,command:"audit",ts:$ts,status:$status,ledger:$ledger,row_count:$row_count,recent:$recent}'
}

emit_why() {
  local topic="${1:-}"
  local body=""
  case "$topic" in
    ""|halt-disease)
      body='Halt-disease is the class where the fleet shows green/healthy doctor status but actually stops dispatching work — joshua wakes up to ready beads + idle agents. The watchdog probes (idle_with_ready_work, yellow_without_permitted_work, red_ignored) catch this before joshua does.'
      ;;
    fleet-idle-with-ready-work)
      body='Critical signal: ready_count > 0 AND ≥1 agent has been WAITING/IDLE for >= window-minutes. The fleet is starving while work is in queue — this is the joshua-morning incident class. Emit critical severity, permitted_action=dispatch.ready_bead.'
      ;;
    yellow-without-permitted-work)
      body='Yellow doctor halt-contract MUST list permitted_actions OR no_safe_work_reason. If neither, the orchestrator has no graceful degradation path — the fleet idles instead of running safe plan/validate work. High severity.'
      ;;
    red-ignored)
      body='Red doctor halt-contract + recent dispatches > 0 in last 10min = orchestrator is dispatching despite a red halt. Critical severity: an orchestrator is ignoring a red contract and probably writing through a closed circuit breaker.'
      ;;
    *)
      body="unknown topic: $topic. known: halt-disease, fleet-idle-with-ready-work, yellow-without-permitted-work, red-ignored"
      ;;
  esac
  jq -nc --arg sv "$SCHEMA_VERSION" --arg topic "${topic:-halt-disease}" --arg body "$body" \
    '{schema_version:$sv,command:"why",topic:$topic,body:$body}'
}

emit_quickstart() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"quickstart",
    status:"ok",
    steps:[
      {step:1,action:"check-doctor",command:"halt-disease-watchdog.sh doctor --json"},
      {step:2,action:"probe-default-fleet",command:"halt-disease-watchdog.sh --json"},
      {step:3,action:"tail-recent-signals",command:"halt-disease-watchdog.sh audit --json"},
      {step:4,action:"why-on-fleet-idle",command:"halt-disease-watchdog.sh why fleet-idle-with-ready-work --json"}
    ],
    next_actions:["wire-to-launchd-cron-every-5m","escalate-on-fleet-idle-with-ready-work"]
  }'
}

emit_repair() {
  local scope="" mode="dry_run" idem_key=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --scope) scope="${2:-}"; shift 2 ;;
      --dry-run) mode="dry_run"; shift ;;
      --apply) mode="apply"; shift ;;
      --idempotency-key) idem_key="${2:-}"; shift 2 ;;
      --idempotency-key=*) idem_key="${1#--idempotency-key=}"; shift ;;
      --json) shift ;;
      --help|-h) printf 'repair --scope <ledger-prime> [--dry-run|--apply --idempotency-key KEY]\n'; exit 0 ;;
      "") shift ;;
      *) printf 'ERR: unknown repair arg %s\n' "$1" >&2; exit 2 ;;
    esac
  done
  if [[ -z "$scope" ]]; then
    printf '{"schema_version":"%s.repair","status":"refused","reason":"--scope required (ledger-prime)","exit_code":2}\n' "$SCHEMA_VERSION"
    exit 2
  fi
  if [[ "$mode" == "apply" && -z "$idem_key" ]]; then
    printf '{"schema_version":"%s.repair","status":"refused","mode":"apply","scope":"%s","reason":"--apply requires --idempotency-key","exit_code":3}\n' "$SCHEMA_VERSION" "$scope"
    exit 3
  fi
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  case "$scope" in
    ledger-prime)
      local ledger_dir present_before present_after
      ledger_dir="$(dirname "$LEDGER")"
      present_before="$([[ -f "$LEDGER" ]] && printf true || printf false)"
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$ledger_dir" 2>/dev/null || true
        [[ -f "$LEDGER" ]] || : > "$LEDGER"
      fi
      present_after="$([[ -f "$LEDGER" ]] && printf true || printf false)"
      jq -nc --arg sv "$SCHEMA_VERSION.repair" --arg ts "$ts" --arg scope "$scope" --arg mode "$mode" \
        --arg ledger "$LEDGER" --arg key "$idem_key" \
        --argjson before "$present_before" --argjson after "$present_after" \
        '{schema_version:$sv,command:"repair",ts:$ts,status:"pass",scope:$scope,mode:$mode,idempotency_key:$key,ledger:$ledger,ledger_present_before:$before,ledger_present_after:$after}'
      ;;
    *)
      printf '{"schema_version":"%s.repair","status":"refused","scope":"%s","reason":"unknown scope; known: ledger-prime","exit_code":2}\n' "$SCHEMA_VERSION" "$scope"
      exit 2
      ;;
  esac
}

# Canonical no-dash subcommand intercept BEFORE main watchdog body.
case "${1:-}" in
  --schema) emit_schema; exit 0 ;;
  doctor) shift; emit_doctor; exit 0 ;;
  health) shift; emit_health; exit 0 ;;
  validate) shift; emit_validate; exit 0 ;;
  audit)
    shift
    LIMIT=20
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --limit) LIMIT="${2:-20}"; shift 2 ;;
        --json) shift ;;
        "") shift ;;
        *) shift ;;
      esac
    done
    emit_audit "$LIMIT"
    exit 0
    ;;
  why)
    shift
    TOPIC=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --json) shift ;;
        "") shift ;;
        *) [[ -z "$TOPIC" ]] && TOPIC="$1"; shift ;;
      esac
    done
    emit_why "$TOPIC"
    exit 0
    ;;
  quickstart) shift; emit_quickstart; exit 0 ;;
  repair) shift; emit_repair "$@"; exit 0 ;;
esac

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sessions) SESSIONS="${2:?}"; shift 2 ;;
    --repo-map) REPO_MAP_ARG="${2:?}"; shift 2 ;;
    --window-minutes) WINDOW_MINUTES="${2:?}"; shift 2 ;;
    --json) JSON_OUT=1; shift ;;
    --quiet) QUIET=1; shift ;;
    --once) shift ;;
    --info) emit_info; exit 0 ;;
    --examples) shift; emit_examples "${1:-}"; exit 0 ;;
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
