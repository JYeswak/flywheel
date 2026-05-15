#!/usr/bin/env bash
# shellcheck disable=SC2034
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (partial -> passing per bead flywheel-k8gcv.7)
set -euo pipefail

VERSION="idle-state-probe.v1.1.0"
SCHEMA_VERSION="idle-state-probe/v1"
LEDGER="${FLYWHEEL_IDLE_STATE_LEDGER:-$HOME/.local/state/flywheel/idle-state-probe-ledger.jsonl}"
SESSION="flywheel"
REPO="/Users/josh/Developer/flywheel"
BR_BIN="${FLYWHEEL_BR_BIN:-${BR_BIN:-/Users/josh/.cargo/bin/br}}"
ACTIVITY_FIXTURE="${FLYWHEEL_IDLE_STATE_ACTIVITY_FIXTURE:-}"
READY_FIXTURE="${FLYWHEEL_IDLE_STATE_READY_FIXTURE:-}"
MISSION_FIXTURE="${FLYWHEEL_IDLE_STATE_MISSION_FIXTURE:-}"
CONFIG_PATH="${FLYWHEEL_IDLE_STATE_CONFIG:-}"
PANE_LAST_FIRED="${FLYWHEEL_IDLE_STATE_PANE_LAST_FIRED:-/tmp/idle-pane-last-fired}"
BEAD_FIRED="${FLYWHEEL_IDLE_STATE_BEAD_FIRED:-/tmp/watcher-bead-fired}"
NOW_EPOCH="${FLYWHEEL_IDLE_STATE_NOW_EPOCH:-$(date +%s)}"
JSON_OUT=0
DOCTOR=0
INCLUDE_NON_WAITING=0

usage() {
  cat <<'EOF'
usage:
  idle-state-probe.sh --json [--session flywheel] [--repo PATH] [--activity-fixture PATH] [--ready-fixture PATH] [--mission-fixture PATH] [--config PATH]
  idle-state-probe.sh --doctor --json [--session NAME]
  idle-state-probe.sh --info --json
  idle-state-probe.sh --schema --json
  idle-state-probe.sh --examples [--json]
  idle-state-probe.sh doctor --json
  idle-state-probe.sh health --json
  idle-state-probe.sh validate --json
  idle-state-probe.sh audit --json [--limit N]
  idle-state-probe.sh why [topic] [--json]
  idle-state-probe.sh quickstart [--json]
  idle-state-probe.sh repair --scope <ledger-prime> [--dry-run|--apply --idempotency-key KEY] [--json]
  idle-state-probe.sh --help|-h|--version
EOF
}

info() {
  jq -nc --arg sv "$SCHEMA_VERSION" --arg name "idle-state-probe.sh" --arg version "$VERSION" \
    --arg br "$BR_BIN" --arg ledger "$LEDGER" '{
    schema_version:$sv,
    command:"info",
    name:$name,
    version:$version,
    purpose:"Classify idle worker panes for doctor and watcher consumption",
    states:["dispatching","cooldown","light_queue","saturated","disabled_class","not_waiting"],
    dependencies:{br:$br},
    ledger:$ledger,
    canonical_paths:[".flywheel/scripts/idle-state-probe.sh",".flywheel/validation-schema/v1/idle-state-config.schema.json"],
    subcommands:["doctor","health","validate","audit","why","repair","quickstart"],
    canonical_flags:["--info","--schema","--examples","--json","--apply","--dry-run","--idempotency-key","--session","--repo","--doctor","--include-non-waiting","--activity-fixture","--ready-fixture","--mission-fixture","--config","--now-epoch","--pane-last-fired","--bead-fired"],
    capabilities:[
      "idle-state-classification",
      "ready-bead-counting-via-br",
      "fixture-driven-testing",
      "per-session-class-allowlist",
      "dispatching-staleness-threshold",
      "pane-cooldown-tracking",
      "bead-dedupe-cooldown"
    ],
    apply_supported:true,
    dry_run_supported:true,
    idempotency_key_required_for_apply:true,
    mutates_state:false,
    env_vars:["FLYWHEEL_BR_BIN","BR_BIN","FLYWHEEL_IDLE_STATE_ACTIVITY_FIXTURE","FLYWHEEL_IDLE_STATE_READY_FIXTURE","FLYWHEEL_IDLE_STATE_MISSION_FIXTURE","FLYWHEEL_IDLE_STATE_CONFIG","FLYWHEEL_IDLE_STATE_PANE_LAST_FIRED","FLYWHEEL_IDLE_STATE_BEAD_FIRED","FLYWHEEL_IDLE_STATE_NOW_EPOCH","FLYWHEEL_IDLE_STATE_LEDGER"],
    exit_codes:{"0":"probe-ok","2":"probe-error","3":"refused-apply-without-idempotency-key","64":"bad-args"}
  }'
}

emit_schema() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"schema",
    input_schema:{
      type:"object",
      properties:{
        session:{type:"string"},
        repo:{type:"string"},
        activity_fixture:{type:"string"},
        ready_fixture:{type:"string"},
        mission_fixture:{type:"string"},
        config:{type:"string"},
        include_non_waiting:{type:"boolean"},
        doctor:{type:"boolean"}
      }
    },
    output_schema:{
      type:"object",
      required:["schema_version","status","session","repo"],
      properties:{
        schema_version:{type:"string"},
        status:{enum:["pass","fail","unknown"]},
        session:{type:"string"},
        repo:{type:"string"},
        br_ready_count:{type:"integer"},
        br_ready_p0_p1_count:{type:"integer"},
        br_ready_source:{type:["string","null"]},
        idle_state_class:{type:"array"},
        idle_state_summary:{
          type:"object",
          properties:{
            dispatching:{type:"integer"},
            cooldown:{type:"integer"},
            light_queue:{type:"integer"},
            saturated:{type:"integer"},
            disabled_class:{type:"integer"},
            not_waiting:{type:"integer"}
          }
        },
        idle_dispatching_over_threshold_count:{type:"integer"},
        idle_dispatching_threshold_seconds:{type:"integer"}
      }
    },
    exit_codes:{"0":"probe-ok","2":"probe-error","3":"refused-apply-without-idempotency-key","64":"bad-args"}
  }'
}

emit_examples_json() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"examples",
    examples:[
      {name:"default-probe",invocation:"idle-state-probe.sh --json",purpose:"probe idle state for default session (flywheel) using live br ready-bead count"},
      {name:"doctor-flag",invocation:"idle-state-probe.sh --doctor --json --session flywheel",purpose:"doctor-mode envelope: status + summary counts (existing flag-style)"},
      {name:"doctor-positional",invocation:"idle-state-probe.sh doctor --json",purpose:"canonical doctor subcommand"},
      {name:"fixture-driven",invocation:"FLYWHEEL_IDLE_STATE_ACTIVITY_FIXTURE=/tmp/activity.json idle-state-probe.sh --json",purpose:"override activity probe with a JSON fixture (for tests)"},
      {name:"audit",invocation:"idle-state-probe.sh audit --json",purpose:"tail recent probe ledger rows"}
    ]
  }'
}

emit_doctor() {
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local jq_status="pass"; command -v jq >/dev/null 2>&1 || jq_status="fail"
  local br_status="pass"; [[ -x "$BR_BIN" ]] || br_status="warn"
  local ledger_dir; ledger_dir="$(dirname "$LEDGER")"
  local ledger_status="pass"
  if [[ -e "$LEDGER" ]]; then
    [[ -w "$LEDGER" ]] || ledger_status="fail"
  else
    [[ -d "$ledger_dir" ]] || ledger_status="warn"
  fi
  local config_schema="$REPO/.flywheel/validation-schema/v1/idle-state-config.schema.json"
  local schema_status="pass"
  [[ -f "$config_schema" ]] || schema_status="warn"
  local overall="pass"
  for s in "$jq_status" "$br_status" "$ledger_status" "$schema_status"; do
    case "$s" in
      fail) overall="fail" ;;
      warn) [[ "$overall" == "pass" ]] && overall="warn" ;;
    esac
  done
  jq -nc --arg sv "$SCHEMA_VERSION.doctor" --arg ts "$ts" --arg overall "$overall" \
    --arg jq_s "$jq_status" --arg br_s "$br_status" --arg br_path "$BR_BIN" \
    --arg ledger_s "$ledger_status" --arg ledger "$LEDGER" \
    --arg schema_s "$schema_status" --arg schema "$config_schema" \
    '{
      schema_version:$sv,
      command:"doctor",
      ts:$ts,
      status:$overall,
      checks:[
        {name:"jq",status:$jq_s,detail:"jq required for envelope emission"},
        {name:"br_binary",status:$br_s,path:$br_path,detail:"br CLI for ready-bead probe (warn if missing — uses 0)"},
        {name:"ledger_writable",status:$ledger_s,path:$ledger,detail:"append-only probe ledger"},
        {name:"config_schema",status:$schema_s,path:$schema,detail:"idle-state-config schema for --config validation"}
      ]
    }'
}

emit_health() {
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local row_count=0
  local last_status=""
  if [[ -r "$LEDGER" ]]; then
    row_count="$(wc -l <"$LEDGER" 2>/dev/null | tr -d ' ')"
    [[ -z "$row_count" ]] && row_count=0
    if [[ "$row_count" -gt 0 ]]; then
      last_status="$(tail -n 1 "$LEDGER" 2>/dev/null | jq -r '.status // empty' 2>/dev/null || true)"
    fi
  fi
  local status="pass"
  [[ "$last_status" == "fail" ]] && status="warn"
  jq -nc --arg sv "$SCHEMA_VERSION.health" --arg ts "$ts" --arg status "$status" \
    --arg ledger "$LEDGER" --argjson row_count "${row_count:-0}" --arg last_status "${last_status:-}" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,ledger:$ledger,ledger_row_count:$row_count,last_probe_status:$last_status}'
}

emit_validate() {
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local rows=0 invalid=0
  if [[ -r "$LEDGER" ]]; then
    rows="$(wc -l <"$LEDGER" 2>/dev/null | tr -d ' ')"
    [[ -z "$rows" ]] && rows=0
    if [[ "$rows" -gt 0 ]]; then
      invalid="$(jq -c 'select((.schema_version // "") != "idle-state-probe/v1")' "$LEDGER" 2>/dev/null | wc -l | tr -d ' ')"
      [[ -z "$invalid" ]] && invalid=0
    fi
  fi
  local status="pass"
  [[ "$invalid" -gt 0 ]] && status="violations"
  jq -nc --arg sv "$SCHEMA_VERSION.validate" --arg ts "$ts" --arg status "$status" \
    --argjson rows "${rows:-0}" --argjson invalid "${invalid:-0}" --arg ledger "$LEDGER" \
    '{schema_version:$sv,command:"validate",ts:$ts,status:$status,ledger:$ledger,row_count:$rows,invalid_row_count:$invalid,check:"every row has schema_version=idle-state-probe/v1"}'
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
    ""|idle-state-classification)
      body='Six states classify a WAITING/IDLE pane: dispatching (work in flight, age vs threshold), cooldown (recently fired), light_queue (ready_count below threshold), saturated (queue depth above threshold), disabled_class (session has this class disabled in config), not_waiting (pane is active). Classification feeds doctor halt-contracts and watcher dispatch decisions.'
      ;;
    dispatching-threshold)
      body='dispatching_fail_seconds (default 300s) — if a pane has been WAITING longer than threshold while a dispatch is recorded as in-flight, the pane is reported in idle_dispatching_over_threshold_count. This catches transport-deaf or hung workers.'
      ;;
    per-session-config)
      body='mobile-eats and skillos default to ["dispatching","light_queue"] classes only. All other sessions default to the full set ["dispatching","cooldown","light_queue","saturated"]. Override via --config <path> to idle-state-config.json that validates against .flywheel/validation-schema/v1/idle-state-config.schema.json.'
      ;;
    *)
      body="unknown topic: $topic. known: idle-state-classification, dispatching-threshold, per-session-config"
      ;;
  esac
  jq -nc --arg sv "$SCHEMA_VERSION" --arg topic "${topic:-idle-state-classification}" --arg body "$body" \
    '{schema_version:$sv,command:"why",topic:$topic,body:$body}'
}

emit_quickstart() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"quickstart",
    status:"ok",
    steps:[
      {step:1,action:"check-doctor",command:"idle-state-probe.sh doctor --json"},
      {step:2,action:"probe-default-session",command:"idle-state-probe.sh --json"},
      {step:3,action:"doctor-mode-summary",command:"idle-state-probe.sh --doctor --json --session flywheel"},
      {step:4,action:"tail-recent-probes",command:"idle-state-probe.sh audit --json"}
    ],
    next_actions:["wire-to-flywheel-loop-tick","feed-watcher-dispatch-decisions"]
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

normalize_ready_json() {
  jq -c '
    if type == "array" then .
    elif type == "object" then (.issues // .items // .ready // .beads // [])
    else [] end
    | if type == "array" then . else [] end
  ' 2>/dev/null || printf '[]'
}

resolve_br_cli() {
  if [[ -x "$BR_BIN" ]]; then
    printf '%s\n' "$BR_BIN"
  elif command -v br >/dev/null 2>&1; then
    command -v br
  else
    return 1
  fi
}

examples() {
  printf '%s\n' \
    "idle-state-probe.sh --json" \
    "idle-state-probe.sh --doctor --json --session flywheel" \
    "FLYWHEEL_IDLE_STATE_ACTIVITY_FIXTURE=/tmp/activity.json idle-state-probe.sh --json"
}

# Canonical no-dash subcommand intercept BEFORE arg parser.
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
    --json) JSON_OUT=1; shift ;;
    --doctor) DOCTOR=1; JSON_OUT=1; shift ;;
    --include-non-waiting) INCLUDE_NON_WAITING=1; shift ;;
    --session) SESSION="${2:?}"; shift 2 ;;
    --repo) REPO="${2:?}"; shift 2 ;;
    --activity-fixture) ACTIVITY_FIXTURE="${2:?}"; shift 2 ;;
    --ready-fixture) READY_FIXTURE="${2:?}"; shift 2 ;;
    --mission-fixture) MISSION_FIXTURE="${2:?}"; shift 2 ;;
    --config) CONFIG_PATH="${2:?}"; shift 2 ;;
    --now-epoch) NOW_EPOCH="${2:?}"; shift 2 ;;
    --pane-last-fired) PANE_LAST_FIRED="${2:?}"; shift 2 ;;
    --bead-fired) BEAD_FIRED="${2:?}"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    --info) info; exit 0 ;;
    --schema) emit_schema; exit 0 ;;
    --examples)
      shift
      if [[ "${1:-}" == "--json" ]]; then emit_examples_json; else examples; fi
      exit 0
      ;;
    --version) printf '%s\n' "$VERSION"; exit 0 ;;
    *) printf 'ERR: unknown argument: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done

default_config() {
  local classes
  if [[ "$SESSION" == "mobile-eats" || "$SESSION" == "skillos" || "$SESSION" == "{capability-control-plane}" ]]; then
    classes='["dispatching","light_queue"]'
  else
    classes='["dispatching","cooldown","light_queue","saturated"]'
  fi
  jq -nc --argjson classes "$classes" '{
    schema_version:"idle-state-config/v1",
    enabled:true,
    classes_active:$classes,
    thresholds:{
      dispatching_fail_seconds:300,
      pane_cooldown_seconds:180,
      bead_dedupe_seconds:600,
      light_queue_ready_count:10
    },
    peer_orch_escalation:"xpane_to_flywheel_1"
  }'
}

config_json="$(default_config)"
config_loaded=false
if [[ -n "$CONFIG_PATH" && -f "$CONFIG_PATH" ]]; then
  if jq -e . "$CONFIG_PATH" >/dev/null 2>&1; then
    config_json="$(jq -c --argjson defaults "$config_json" '
      $defaults
      * .
      | .thresholds = (($defaults.thresholds // {}) * (.thresholds // {}))
    ' "$CONFIG_PATH")"
    config_loaded=true
  fi
elif [[ -f "$REPO/.flywheel/idle-state-config.json" ]]; then
  CONFIG_PATH="$REPO/.flywheel/idle-state-config.json"
  if jq -e . "$CONFIG_PATH" >/dev/null 2>&1; then
    config_json="$(jq -c --argjson defaults "$config_json" '
      $defaults
      * .
      | .thresholds = (($defaults.thresholds // {}) * (.thresholds // {}))
    ' "$CONFIG_PATH")"
    config_loaded=true
  fi
fi

enabled="$(jq -r 'if has("enabled") then .enabled else true end' <<<"$config_json")"
dispatching_fail_seconds="$(jq -r '.thresholds.dispatching_fail_seconds // 300' <<<"$config_json")"
pane_cooldown_seconds="$(jq -r '.thresholds.pane_cooldown_seconds // 180' <<<"$config_json")"
bead_dedupe_seconds="$(jq -r '.thresholds.bead_dedupe_seconds // 600' <<<"$config_json")"
light_queue_ready_count="$(jq -r '.thresholds.light_queue_ready_count // 10' <<<"$config_json")"

if [[ "$enabled" != "true" ]]; then
  jq -nc --arg session "$SESSION" --arg repo "$REPO" --arg config_path "$CONFIG_PATH" --argjson config_loaded "$config_loaded" '{
    schema_version:"idle-state-probe/v1",
    status:"pass",
    session:$session,
    repo:$repo,
    br_ready_count:0,
    br_ready_p0_p1_count:0,
    br_ready_source:"disabled",
    br_ready_error:null,
    idle_state_class:[],
    idle_state_summary:{dispatching:0,cooldown:0,light_queue:0,saturated:0,disabled_class:0,not_waiting:0},
    idle_dispatching_over_threshold_count:0,
    idle_state_config_path:(if $config_path == "" then null else $config_path end),
    idle_state_config_loaded:$config_loaded,
    disabled:true
  }'
  exit 0
fi

activity_json='{"agents":[]}'
if [[ -n "$ACTIVITY_FIXTURE" ]]; then
  activity_json="$(jq -c . "$ACTIVITY_FIXTURE")"
else
  activity_json="$(/Users/josh/.local/bin/ntm --robot-activity="$SESSION" --activity-type=codex 2>/dev/null || printf '{"agents":[]}')"
fi

ready_json='[]'
br_ready_source="none"
br_ready_error=""
if [[ -n "$READY_FIXTURE" ]]; then
  ready_json="$(jq -c . "$READY_FIXTURE" | normalize_ready_json)"
  br_ready_source="fixture"
else
  if [[ -d "$REPO" ]]; then
    br_cli=""
    if br_cli="$(resolve_br_cli)"; then
      ready_err="$(mktemp "${TMPDIR:-/tmp}/idle-state-br-ready.XXXXXX")"
      ready_raw=""
      ready_rc=0
      ready_raw="$(cd "$REPO" && "$br_cli" ready --json 2>"$ready_err")" || ready_rc=$?
      if [[ "$ready_rc" -eq 0 ]] && jq -e . >/dev/null 2>&1 <<<"$ready_raw"; then
        ready_json="$(normalize_ready_json <<<"$ready_raw")"
        br_ready_source="$br_cli"
      else
        ready_json='[]'
        br_ready_source="$br_cli"
        br_ready_error="$(tr '\n' ' ' <"$ready_err" | sed 's/[[:space:]]*$//')"
        [[ -n "$br_ready_error" ]] || br_ready_error="br_ready_failed_rc_$ready_rc"
      fi
      rm -f "$ready_err"
    else
      ready_json='[]'
      br_ready_source="missing"
      br_ready_error="br_cli_not_found"
    fi
  fi
fi
br_ready_count="$(jq -r 'length' <<<"$ready_json")"
br_ready_p0_p1_count="$(jq -r '[.[] | select((.priority // 99) <= 1)] | length' <<<"$ready_json")"

mission_pending_count=0
if [[ -n "$MISSION_FIXTURE" ]]; then
  mission_pending_count="$(jq -r 'if type == "number" then . else (.mission_pending_count // 0) end' "$MISSION_FIXTURE")"
fi

fired_beads_json='[]'
if [[ -f "$BEAD_FIRED" ]]; then
  cutoff=$((NOW_EPOCH - bead_dedupe_seconds))
  fired_beads_json="$(awk -F: -v cutoff="$cutoff" '$2 >= cutoff {print $1}' "$BEAD_FIRED" 2>/dev/null | sort -u | jq -Rsc 'split("\n") | map(select(length>0))')"
fi

pane_last_json='{}'
if [[ -f "$PANE_LAST_FIRED" ]]; then
  pane_last_json="$(awk -F: 'NF >= 2 {print "{\"pane\":\""$1"\",\"last\":"$2"}"}' "$PANE_LAST_FIRED" 2>/dev/null | jq -sc 'map(select(.pane != "")) | reduce .[] as $r ({}; .[$r.pane] = $r.last)' 2>/dev/null || printf '{}')"
fi

entries="$(jq -nc \
  --argjson activity "$activity_json" \
  --argjson ready "$ready_json" \
  --argjson fired "$fired_beads_json" \
  --argjson pane_last "$pane_last_json" \
  --argjson config "$config_json" \
  --arg session "$SESSION" \
  --argjson now "$NOW_EPOCH" \
  --argjson mission_pending_count "$mission_pending_count" \
  --argjson pane_cooldown_seconds "$pane_cooldown_seconds" \
  --argjson light_queue_ready_count "$light_queue_ready_count" \
  --argjson include_non_waiting "$([[ "$INCLUDE_NON_WAITING" -eq 1 ]] && printf true || printf false)" '
  def ready_items:
    if ($ready | type) == "array" then $ready
    elif ($ready | type) == "object" then (($ready.issues // $ready.items // $ready.ready // $ready.beads // []) | if type == "array" then . else [] end)
    else [] end;
  def epic: ((.title // .description // "") | test("(^|[^[:alnum:]_])(epic|meta[- ]?epic)([^[:alnum:]_]|$)"; "i"));
  def open_ready:
    ready_items
    | map(select((.priority // 99) <= 1))
    | map(select(epic | not));
  def candidates:
    open_ready
    | map(select((.id // "") as $id | ($fired | index($id)) | not))
    | sort_by((.priority // 99), (.created_at // ""));
  def oldest($p):
    candidates
    | map(select((.priority // 99) == $p))
    | sort_by(.created_at // "")
    | .[0].id // null;
  def is_active($class): (($config.classes_active // []) | index($class)) != null;
  def pane_age($a):
    if ($a.state_since_epoch? | type == "number") then ($now - $a.state_since_epoch)
    elif ($a.waiting_since_epoch? | type == "number") then ($now - $a.waiting_since_epoch)
    else 0 end;
  [($activity.agents // [])
    | map(select((.pane_idx // .pane // 0) >= 2 and (.pane_idx // .pane // 0) <= 4))
    | .[]
    | (.pane_idx // .pane) as $pane
    | (.state // "UNKNOWN") as $state
    | (.capture_provenance // "") as $prov
    | if (($state != "WAITING" or $prov != "live") and ($include_non_waiting | not)) then empty
      else
        (candidates) as $candidates
        | (oldest(0)) as $oldest_p0
        | (oldest(1)) as $oldest_p1
        | ($pane_last[($pane|tostring)] // 0) as $last
        | (if ($state != "WAITING" or $prov != "live") then "not_waiting"
           elif (($last|tonumber) > 0 and ($now - ($last|tonumber)) < $pane_cooldown_seconds) then "cooldown"
           elif (($candidates | length) > 0) then "dispatching"
           elif ((open_ready | length) >= $light_queue_ready_count) then "saturated"
           else "light_queue" end) as $raw_class
        | (if ($raw_class == "not_waiting" or is_active($raw_class)) then $raw_class else "disabled_class" end) as $class
        | {
            pane:$pane,
            state:$state,
            capture_provenance:$prov,
            idle_state_class:$class,
            disabled_original_class:(if $class == "disabled_class" then $raw_class else null end),
            oldest_p0:$oldest_p0,
            oldest_p1:$oldest_p1,
            mission_pending_count:$mission_pending_count,
            dispatch_candidate:($candidates[0].id // null),
            dispatch_priority:($candidates[0].priority // null),
            ready_p0_p1_count:(open_ready | length),
            cooldown_remaining_seconds:(if $class == "cooldown" then (($pane_cooldown_seconds - ($now - ($last|tonumber))) | if . < 0 then 0 else . end) else 0 end),
            age_seconds:(pane_age(.))
          }
      end]'
)"

summary="$(jq -nc --argjson entries "$entries" '
  {
    dispatching:($entries | map(select(.idle_state_class == "dispatching")) | length),
    cooldown:($entries | map(select(.idle_state_class == "cooldown")) | length),
    light_queue:($entries | map(select(.idle_state_class == "light_queue")) | length),
    saturated:($entries | map(select(.idle_state_class == "saturated")) | length),
    disabled_class:($entries | map(select(.idle_state_class == "disabled_class")) | length),
    not_waiting:($entries | map(select(.idle_state_class == "not_waiting")) | length)
  }')"
over_threshold="$(jq -r --argjson threshold "$dispatching_fail_seconds" '[.[] | select(.idle_state_class == "dispatching" and (.age_seconds // 0) > $threshold)] | length' <<<"$entries")"
status="pass"
if [[ "${over_threshold:-0}" -gt 0 ]]; then
  status="fail"
fi

jq -nc \
  --arg schema_version "idle-state-probe/v1" \
  --arg status "$status" \
  --arg session "$SESSION" \
  --arg repo "$REPO" \
  --arg config_path "$CONFIG_PATH" \
  --argjson config_loaded "$config_loaded" \
  --argjson entries "$entries" \
  --argjson summary "$summary" \
  --argjson over_threshold "$over_threshold" \
  --argjson threshold "$dispatching_fail_seconds" \
  --argjson br_ready_count "$br_ready_count" \
  --argjson br_ready_p0_p1_count "$br_ready_p0_p1_count" \
  --arg br_ready_source "$br_ready_source" \
  --arg br_ready_error "$br_ready_error" \
  '{
    schema_version:$schema_version,
    status:$status,
    session:$session,
    repo:$repo,
    br_ready_count:$br_ready_count,
    br_ready_p0_p1_count:$br_ready_p0_p1_count,
    br_ready_source:$br_ready_source,
    br_ready_error:(if $br_ready_error == "" then null else $br_ready_error end),
    idle_state_class:$entries,
    idle_state_summary:$summary,
    idle_dispatching_over_threshold_count:$over_threshold,
    idle_dispatching_threshold_seconds:$threshold,
    idle_state_config_path:(if $config_path == "" then null else $config_path end),
    idle_state_config_loaded:$config_loaded
  }'
