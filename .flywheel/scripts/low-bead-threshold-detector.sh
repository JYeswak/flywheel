#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (partial -> passing per bead flywheel-k8gcv.2)
# L5 lint requires `set -euo pipefail`. The script's emit pipeline uses
# explicit `|| return 1` on jq/append so strict mode is safe here.
set -euo pipefail

VERSION="low-bead-threshold-detector.v1.1.1"
SCHEMA_VERSION="low-bead-threshold/v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DEFAULT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
REPO="${LOW_BEAD_THRESHOLD_REPO:-$REPO_DEFAULT}"
LEDGER="${LOW_BEAD_THRESHOLD_LEDGER:-$HOME/.local/state/flywheel/low-bead-threshold-detector-ledger.jsonl}"
ISSUES_JSONL="${LOW_BEAD_THRESHOLD_ISSUES_JSONL:-$REPO/.beads/issues.jsonl}"
THRESHOLD="${LOW_BEAD_THRESHOLD_THRESHOLD:-10}"
COMMAND=""
AUTO_BEAD=0
JSON_OUT=0
APPLY_MODE=""
IDEMPOTENCY_KEY=""
REPAIR_SCOPE=""
SUBCOMMAND_ARGS=()

usage() {
  cat <<'EOF'
usage:
  low-bead-threshold-detector.sh check [--repo PATH] [--threshold 10] [--auto-bead] [--json]
  low-bead-threshold-detector.sh --info --json
  low-bead-threshold-detector.sh --schema --json
  low-bead-threshold-detector.sh --examples [--json]
  low-bead-threshold-detector.sh doctor --json
  low-bead-threshold-detector.sh health --json
  low-bead-threshold-detector.sh repair --scope <ledger-prime|issues-jsonl-prime> [--dry-run|--apply --idempotency-key KEY] [--json]
  low-bead-threshold-detector.sh validate --json
  low-bead-threshold-detector.sh audit --json [--limit N]
  low-bead-threshold-detector.sh why [topic] [--json]
  low-bead-threshold-detector.sh quickstart [--json]
  low-bead-threshold-detector.sh --help|-h

Counts ready beads from .beads/issues.jsonl and signals when the queue is light.
EOF
}

examples_text() {
  cat <<'EOF'
examples:
  .flywheel/scripts/low-bead-threshold-detector.sh check --json
  .flywheel/scripts/low-bead-threshold-detector.sh check --threshold 20 --json
  LOW_BEAD_THRESHOLD_LEDGER=/tmp/low.jsonl .flywheel/scripts/low-bead-threshold-detector.sh check --auto-bead --json
EOF
}

examples_json() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"examples",
    examples:[
      {name:"check-default",invocation:"low-bead-threshold-detector.sh check --json",purpose:"probe ready bead count vs default threshold (10)"},
      {name:"check-threshold-20",invocation:"low-bead-threshold-detector.sh check --threshold 20 --json",purpose:"probe with custom threshold; emits GREEN/YELLOW/RED signal"},
      {name:"check-auto-bead-on-red",invocation:"low-bead-threshold-detector.sh check --auto-bead --json",purpose:"file work-hunt bead automatically when ready count is RED"},
      {name:"doctor",invocation:"low-bead-threshold-detector.sh doctor --json",purpose:"verify jq, ledger writable, issues.jsonl present"},
      {name:"health",invocation:"low-bead-threshold-detector.sh health --json",purpose:"report ledger row count + last signal"},
      {name:"repair-ledger-prime",invocation:"low-bead-threshold-detector.sh repair --scope ledger-prime --dry-run --json",purpose:"dry-run: ensure ledger parent dir + empty file exist"},
      {name:"repair-apply-with-idem",invocation:"low-bead-threshold-detector.sh repair --scope ledger-prime --apply --idempotency-key low-2026-05-11 --json",purpose:"apply ledger prime with idempotency key"}
    ]
  }'
}

emit_info() {
  jq -nc \
    --arg sv "$SCHEMA_VERSION" \
    --arg name "low-bead-threshold-detector.sh" \
    --arg version "$VERSION" \
    --arg repo "$REPO" \
    --arg ledger "$LEDGER" \
    --arg issues "$ISSUES_JSONL" \
    --argjson threshold "$THRESHOLD" \
    '{
      schema_version:$sv,
      command:"info",
      name:$name,
      version:$version,
      repo:$repo,
      ledger:$ledger,
      issues_jsonl:$issues,
      default_threshold:$threshold,
      purpose:"probe ready-bead count and signal GREEN/YELLOW/RED when queue is light; optionally file a work-hunt bead on RED",
      subcommands:["check","doctor","health","repair","validate","audit","why","quickstart","schema"],
      canonical_flags:["--info","--schema","--examples","--json","--apply","--dry-run","--idempotency-key","--repo","--threshold","--auto-bead"],
      capabilities:["count-ready-beads","signal-gyr","auto-file-hunt-bead","ledger-append","idempotent-hunt-bead-via-dedupe"],
      apply_supported:true,
      dry_run_supported:true,
      idempotency_key_required_for_apply:true,
      mutates_state:true,
      env_vars:["LOW_BEAD_THRESHOLD_REPO","LOW_BEAD_THRESHOLD_LEDGER","LOW_BEAD_THRESHOLD_ISSUES_JSONL","LOW_BEAD_THRESHOLD_THRESHOLD"],
      exits:{"0":"probe completed","2":"usage, missing JSONL, or probe error","3":"refused apply without --idempotency-key"}
    }'
}

emit_schema() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"schema",
    input_schema:{
      type:"object",
      properties:{
        repo:{type:"string",description:"repo root (--repo)"},
        threshold:{type:"integer",minimum:1,description:"ready-bead threshold below which RED signals (--threshold)"},
        auto_bead:{type:"boolean",description:"file hunt-work bead on RED (--auto-bead)"}
      }
    },
    output_schema:{
      type:"object",
      required:["schema_version","audit_ts","status","signal","ready_count","in_progress_count","threshold","yellow_floor"],
      properties:{
        schema_version:{const:$sv},
        audit_ts:{type:"string",format:"date-time"},
        status:{enum:["pass","warn","fail","gray"]},
        signal:{enum:["GREEN","YELLOW","RED","GRAY"]},
        ready_count:{type:"integer",minimum:0},
        in_progress_count:{type:"integer",minimum:0},
        issues_count:{type:"integer",minimum:0},
        threshold:{type:"integer"},
        yellow_floor:{type:"integer"},
        auto_bead_filed:{type:"boolean"},
        hunt_bead_id:{type:["string","null"]},
        auto_bead_action:{enum:["skipped","reused","jsonl_fallback","suppressed_existing_id","append_failed"]}
      }
    },
    exit_codes:{"0":"probe completed","2":"usage / missing JSONL / probe error","3":"refused apply without --idempotency-key"}
  }'
}

emit_quickstart() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"quickstart",
    status:"ok",
    steps:[
      {step:1,action:"check-doctor",command:"low-bead-threshold-detector.sh doctor --json"},
      {step:2,action:"probe-readiness",command:"low-bead-threshold-detector.sh check --json"},
      {step:3,action:"auto-file-hunt-on-red",command:"low-bead-threshold-detector.sh check --auto-bead --json"},
      {step:4,action:"tail-recent-signals",command:"low-bead-threshold-detector.sh audit --json"}
    ],
    next_actions:["dispatch-hunt-work-mission-env-skills","tail-ledger"]
  }'
}

emit_why() {
  local topic="${1:-}"
  local body=""
  case "$topic" in
    ""|signal-thresholds)
      body='GREEN: ready_count >= threshold (default 10). YELLOW: ready_count >= ceil(threshold/2). RED: below yellow_floor — fleet is starving and should hunt work via MISSION/GOAL/env/skills before idling.'
      ;;
    auto-bead)
      body='When --auto-bead is set and signal=RED, the detector files a hunt-work-MISSION-env-skills bead at p0 via direct JSONL append (no br dep so the detector survives br outages). The fixed id is single-use: once it exists, future RED checks reuse or suppress instead of appending a duplicate id.'
      ;;
    gray-status)
      body='GRAY/exit-2: issues.jsonl is missing or parses fail. Detector emits a gray_payload so the orchestrator can surface substrate damage rather than silently report ready=0.'
      ;;
    *)
      body="unknown topic: $topic. known: signal-thresholds, auto-bead, gray-status"
      ;;
  esac
  jq -nc --arg sv "$SCHEMA_VERSION" --arg topic "${topic:-signal-thresholds}" --arg body "$body" \
    '{schema_version:$sv,command:"why",topic:$topic,body:$body}'
}

doctor_checks() {
  local ts; ts="$(now_iso)"
  local jq_status="pass"; command -v jq >/dev/null 2>&1 || jq_status="fail"
  local ledger_dir; ledger_dir="$(dirname "$LEDGER")"
  local ledger_status="pass"
  if [[ -e "$LEDGER" ]]; then
    [[ -w "$LEDGER" ]] || ledger_status="fail"
  else
    [[ -d "$ledger_dir" ]] || ledger_status="warn"
  fi
  local issues_status="pass"
  [[ -f "$ISSUES_JSONL" ]] || issues_status="warn"
  local repo_status="pass"
  [[ -d "$REPO_DEFAULT" ]] || repo_status="fail"
  local overall="pass"
  for s in "$jq_status" "$ledger_status" "$issues_status" "$repo_status"; do
    case "$s" in
      fail) overall="fail" ;;
      warn) [[ "$overall" == "pass" ]] && overall="warn" ;;
    esac
  done
  jq -nc --arg sv "$SCHEMA_VERSION.doctor" --arg ts "$ts" --arg overall "$overall" \
    --arg jq_s "$jq_status" \
    --arg ledger_s "$ledger_status" --arg ledger "$LEDGER" \
    --arg issues_s "$issues_status" --arg issues "$ISSUES_JSONL" \
    --arg repo_s "$repo_status" --arg repo "$REPO_DEFAULT" \
    '{
      schema_version:$sv,
      command:"doctor",
      ts:$ts,
      status:$overall,
      checks:[
        {name:"jq",status:$jq_s,detail:"jq required for envelope emission"},
        {name:"ledger_writable",status:$ledger_s,path:$ledger,detail:"append-only signal ledger"},
        {name:"issues_jsonl",status:$issues_s,path:$issues,detail:"source of ready-bead count (warn if missing — emits GRAY)"},
        {name:"repo_dir",status:$repo_s,path:$repo,detail:"flywheel repo root for jsonl-fallback path"}
      ]
    }'
}

health_summary() {
  local ts; ts="$(now_iso)"
  local row_count=0
  local last_signal=""
  local last_ts=""
  if [[ -r "$LEDGER" ]]; then
    row_count="$(wc -l <"$LEDGER" 2>/dev/null | tr -d ' ')"
    [[ -z "$row_count" ]] && row_count=0
    if [[ "$row_count" -gt 0 ]]; then
      last_signal="$(tail -n 1 "$LEDGER" 2>/dev/null | jq -r '.signal // empty' 2>/dev/null || true)"
      last_ts="$(tail -n 1 "$LEDGER" 2>/dev/null | jq -r '.audit_ts // empty' 2>/dev/null || true)"
    fi
  fi
  local status="pass"
  case "$last_signal" in
    RED) status="fail" ;;
    YELLOW) status="warn" ;;
    GRAY) status="warn" ;;
  esac
  jq -nc --arg sv "$SCHEMA_VERSION.health" --arg ts "$ts" --arg status "$status" \
    --arg ledger "$LEDGER" --argjson row_count "${row_count:-0}" \
    --arg last_signal "${last_signal:-}" --arg last_ts "${last_ts:-}" \
    '{
      schema_version:$sv,
      command:"health",
      ts:$ts,
      status:$status,
      ledger:$ledger,
      ledger_row_count:$row_count,
      last_signal:$last_signal,
      last_audit_ts:$last_ts
    }'
}

validate_self() {
  local ts; ts="$(now_iso)"
  local rows=0 invalid=0
  if [[ -r "$LEDGER" ]]; then
    rows="$(wc -l <"$LEDGER" 2>/dev/null | tr -d ' ')"
    [[ -z "$rows" ]] && rows=0
    if [[ "$rows" -gt 0 ]]; then
      invalid="$(jq -c 'select((.schema_version // "") != "low-bead-threshold/v1" or (.signal // "") == "")' "$LEDGER" 2>/dev/null | wc -l | tr -d ' ')"
      [[ -z "$invalid" ]] && invalid=0
    fi
  fi
  local status="pass"
  [[ "$invalid" -gt 0 ]] && status="violations"
  jq -nc --arg sv "$SCHEMA_VERSION.validate" --arg ts "$ts" --arg status "$status" \
    --argjson rows "${rows:-0}" --argjson invalid "${invalid:-0}" --arg ledger "$LEDGER" \
    '{
      schema_version:$sv,
      command:"validate",
      ts:$ts,
      status:$status,
      ledger:$ledger,
      ledger_row_count:$rows,
      invalid_row_count:$invalid,
      check:"every row has schema_version=low-bead-threshold/v1 and non-empty signal"
    }'
}

audit_tail() {
  local limit="${1:-20}"
  local ts; ts="$(now_iso)"
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

repair_run() {
  local scope="$REPAIR_SCOPE"
  local mode="${APPLY_MODE:-dry_run}"
  local idem_key="$IDEMPOTENCY_KEY"
  local ts; ts="$(now_iso)"
  if [[ -z "$scope" ]]; then
    printf '{"schema_version":"%s.repair","status":"refused","reason":"--scope required (ledger-prime|issues-jsonl-prime)","exit_code":2}\n' "$SCHEMA_VERSION"
    exit 2
  fi
  if [[ "$mode" == "apply" && -z "$idem_key" ]]; then
    printf '{"schema_version":"%s.repair","status":"refused","mode":"apply","scope":"%s","reason":"--apply requires --idempotency-key","exit_code":3}\n' "$SCHEMA_VERSION" "$scope"
    exit 3
  fi
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
    issues-jsonl-prime)
      local issues_before
      issues_before="$([[ -f "$ISSUES_JSONL" ]] && printf true || printf false)"
      jq -nc --arg sv "$SCHEMA_VERSION.repair" --arg ts "$ts" --arg scope "$scope" --arg mode "$mode" \
        --arg path "$ISSUES_JSONL" --arg key "$idem_key" --argjson present "$issues_before" \
        '{schema_version:$sv,command:"repair",ts:$ts,status:"pass",scope:$scope,mode:$mode,idempotency_key:$key,issues_jsonl:$path,issues_jsonl_present:$present,note:"read-only probe — issues.jsonl is owned by br; creating it here would mask substrate damage"}'
      ;;
    *)
      printf '{"schema_version":"%s.repair","status":"refused","scope":"%s","reason":"unknown scope; known: ledger-prime, issues-jsonl-prime","exit_code":2}\n' "$SCHEMA_VERSION" "$scope"
      exit 2
      ;;
  esac
}

now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }

append_ledger() {
  local row="$1"
  mkdir -p "$(dirname "$LEDGER")" 2>/dev/null || return 1
  jq -c . <<<"$row" >>"$LEDGER" 2>/dev/null || true
}

emit() {
  local payload="$1" text="$2" rc="${3:-0}"
  append_ledger "$payload" || payload="$(jq -c '. + {ledger_append_error:true}' <<<"$payload")"
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '%s\n' "$payload"
  else
    printf '%s\n' "$text"
  fi
  return "$rc"
}

# shellcheck disable=SC2016
latest_jq='
  def latest:
    reduce .[] as $r ({}; if (($r.id // "") | length) > 0 then .[$r.id] = $r else . end) | [.[]];
  def nonempty($x):
    ($x // null) as $v
    | if $v == null then false
      elif ($v | type) == "array" then ($v | length) > 0
      elif ($v | type) == "object" then ($v | length) > 0
      else (($v | tostring | length) > 0) end;
  def claimed:
    (.assignee // .owner // .claimed_by // "") as $a
    | if ($a | type) == "string"
      then (($a | length) > 0 and (($a | ascii_downcase) != "unassigned") and (($a | ascii_downcase) != "none"))
      else $a != null end;
  def blocked:
    (.blocked == true) or nonempty(.blocker) or nonempty(.blockers) or nonempty(.blocked_by) or ((.dependency_status // "") == "blocked");
'

issues_stats() {
  jq -s -c --argjson threshold "$THRESHOLD" "$latest_jq"'
    latest as $issues
    | [$issues[] | select((.status // "" | ascii_downcase) == "open") | select(blocked | not) | select(claimed | not)] as $ready
    | [$issues[] | select((.status // "" | ascii_downcase) == "in_progress") | select(claimed)] as $progress
    | ($threshold / 2 | ceil) as $yellow_floor
    | {
        issues_count:($issues | length),
        ready_count:($ready | length),
        in_progress_count:($progress | length),
        threshold:$threshold,
        yellow_floor:$yellow_floor,
        signal:(if ($ready | length) >= $threshold then "GREEN" elif ($ready | length) >= $yellow_floor then "YELLOW" else "RED" end),
        status:(if ($ready | length) >= $threshold then "pass" elif ($ready | length) >= $yellow_floor then "warn" else "fail" end)
      }' "$ISSUES_JSONL"
}

existing_hunt_bead() {
  jq -s -r "$latest_jq"'
    latest as $issues
    | (
        [$issues[] | select((.id // "") == "flywheel-hunt-work-mission-env-skills")]
        +
        [$issues[]
          | select((.id // "") != "flywheel-hunt-work-mission-env-skills")
          | select((.status // "" | ascii_downcase) == "open")
          | select((.title // "") | startswith("hunt-work-"))
          | select((.title // "") == "hunt-work-MISSION-env-skills"
              or (.created_by // "") == "low-bead-threshold-detector"
              or ((.labels // []) | index("low-bead-threshold-work-hunt")))]
      )
    | .[0]?
    | select(.)
    | [(.id // ""), (.status // "unknown" | ascii_downcase)]
    | @tsv' "$ISSUES_JSONL" 2>/dev/null | head -1
}

file_hunt_bead() {
  local audit_ts="$1"
  local existing existing_id existing_status action id desc row
  existing="$(existing_hunt_bead || true)"
  if [[ -n "$existing" ]]; then
    IFS=$'\t' read -r existing_id existing_status <<<"$existing"
    action="suppressed_existing_id"
    [[ "$existing_status" == "open" ]] && action="reused"
    jq -nc --arg id "$existing_id" --arg action "$action" '{auto_bead_filed:false,hunt_bead_id:$id,auto_bead_action:$action}'
    return 0
  fi
  id="flywheel-hunt-work-mission-env-skills"
  desc="Auto-filed by low-bead-threshold-detector. Ready bead count is below the threshold, so flywheel:1 must hunt work through .flywheel/MISSION.md, .flywheel/GOAL.md, .flywheel/STATE.md, repo environment signals, ~/.claude/skills/, and ~/.codex/skills/; notify Joshua only for a true blocker."
  row="$(jq -nc --arg id "$id" --arg title "hunt-work-MISSION-env-skills" --arg desc "$desc" --arg now "$audit_ts" --arg repo "$REPO" \
    '{id:$id,title:$title,description:$desc,status:"open",priority:0,issue_type:"task",created_at:$now,created_by:"low-bead-threshold-detector",updated_at:$now,source_repo:$repo,labels:["low-bead-threshold-work-hunt","donella-self-organization","jsonl-fallback"],compaction_level:0,original_size:0}')"
  mkdir -p "$(dirname "$ISSUES_JSONL")"
  if printf '%s\n' "$row" >>"$ISSUES_JSONL"; then
    jq -nc --arg id "$id" '{auto_bead_filed:true,hunt_bead_id:$id,auto_bead_action:"jsonl_fallback"}'
  else
    jq -nc --arg id "$id" '{auto_bead_filed:false,hunt_bead_id:$id,auto_bead_action:"append_failed"}'
  fi
}

gray_payload() {
  local audit_ts="$1" warning="$2"
  jq -nc --arg schema "$SCHEMA_VERSION" --arg ts "$audit_ts" --arg repo "$REPO" --arg issues "$ISSUES_JSONL" --arg ledger "$LEDGER" --arg warning "$warning" --argjson threshold "$THRESHOLD" \
    '{schema_version:$schema,audit_ts:$ts,repo:$repo,issues_path:$issues,status:"gray",signal:"GRAY",ready_count:0,in_progress_count:0,threshold:$threshold,yellow_floor:((($threshold / 2)|ceil)),auto_bead_requested:false,auto_bead_filed:false,hunt_bead_id:null,auto_bead_action:"skipped",ledger_appended:$ledger,warnings:[$warning],errors:[],exit_code:2}'
}

run_check() {
  local audit_ts stats action payload signal rc
  audit_ts="$(now_iso)"
  if [[ ! -f "$ISSUES_JSONL" ]]; then
    payload="$(gray_payload "$audit_ts" "issues_jsonl_missing")"
    set +e
    emit "$payload" "GRAY issues_jsonl_missing=$ISSUES_JSONL" 2
    rc=$?
    set -e
    return "$rc"
  fi
  set +e
  stats="$(issues_stats 2>/dev/null)"
  rc=$?
  set -e
  if [[ "$rc" -ne 0 ]] || [[ -z "$stats" ]]; then
    payload="$(gray_payload "$audit_ts" "issues_jsonl_parse_error")"
    set +e
    emit "$payload" "GRAY issues_jsonl_parse_error=$ISSUES_JSONL" 2
    rc=$?
    set -e
    return "$rc"
  fi
  signal="$(jq -r '.signal' <<<"$stats")"
  action="$(jq -nc '{auto_bead_filed:false,hunt_bead_id:null,auto_bead_action:"skipped"}')"
  if [[ "$AUTO_BEAD" -eq 1 && "$signal" == "RED" ]]; then
    action="$(file_hunt_bead "$audit_ts")"
  fi
  payload="$(jq -nc --arg schema "$SCHEMA_VERSION" --arg ts "$audit_ts" --arg repo "$REPO" --arg issues "$ISSUES_JSONL" --arg ledger "$LEDGER" \
    --argjson stats "$stats" --argjson action "$action" --argjson requested "$([[ "$AUTO_BEAD" -eq 1 ]] && printf true || printf false)" \
    '$stats + $action + {schema_version:$schema,audit_ts:$ts,repo:$repo,issues_path:$issues,auto_bead_requested:$requested,ledger_appended:$ledger,warnings:[],errors:[],exit_code:0,
      hunt_bead_suggestion:(if $stats.signal == "RED" then {title:"hunt-work-MISSION-env-skills",priority:0,reason:"ready_count_below_yellow_floor"} else null end)}')"
  set +e
  emit "$payload" "signal=$(jq -r '.signal' <<<"$payload") ready=$(jq -r '.ready_count' <<<"$payload") in_progress=$(jq -r '.in_progress_count' <<<"$payload") threshold=$(jq -r '.threshold' <<<"$payload")" 0
  rc=$?
  set -e
  return "$rc"
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    check) COMMAND="check"; shift ;;
    --repo) REPO="${2:?}"; ISSUES_JSONL="$REPO/.beads/issues.jsonl"; shift 2 ;;
    --threshold) THRESHOLD="${2:?}"; shift 2 ;;
    --auto-bead) AUTO_BEAD=1; shift ;;
    --json) JSON_OUT=1; shift ;;
    --info) emit_info; exit 0 ;;
    --schema) emit_schema; exit 0 ;;
    --examples)
      shift
      if [[ "${1:-}" == "--json" ]]; then examples_json; else examples_text; fi
      exit 0
      ;;
    doctor|health|validate|quickstart)
      COMMAND="$1"
      shift
      ;;
    repair|why|audit)
      COMMAND="$1"
      shift
      SUBCOMMAND_ARGS=("$@")
      break
      ;;
    --apply) APPLY_MODE="apply"; shift ;;
    --dry-run) APPLY_MODE="dry_run"; shift ;;
    --idempotency-key) IDEMPOTENCY_KEY="${2:-}"; shift 2 ;;
    --idempotency-key=*) IDEMPOTENCY_KEY="${1#--idempotency-key=}"; shift ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$COMMAND" in
  doctor) doctor_checks; exit 0 ;;
  health) health_summary; exit 0 ;;
  validate) validate_self; exit 0 ;;
  quickstart) emit_quickstart; exit 0 ;;
  audit)
    LIMIT=20
    set -- "${SUBCOMMAND_ARGS[@]:-}"
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --limit) LIMIT="${2:-20}"; shift 2 ;;
        --json) shift ;;
        --help|-h) usage; exit 0 ;;
        "") shift ;;
        *) shift ;;
      esac
    done
    audit_tail "$LIMIT"
    exit 0
    ;;
  why)
    TOPIC=""
    set -- "${SUBCOMMAND_ARGS[@]:-}"
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --json) shift ;;
        --help|-h) usage; exit 0 ;;
        "") shift ;;
        *) [[ -z "$TOPIC" ]] && TOPIC="$1"; shift ;;
      esac
    done
    emit_why "$TOPIC"
    exit 0
    ;;
  repair)
    set -- "${SUBCOMMAND_ARGS[@]:-}"
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --scope) REPAIR_SCOPE="${2:-}"; shift 2 ;;
        --apply) APPLY_MODE="apply"; shift ;;
        --dry-run) APPLY_MODE="dry_run"; shift ;;
        --idempotency-key) IDEMPOTENCY_KEY="${2:-}"; shift 2 ;;
        --idempotency-key=*) IDEMPOTENCY_KEY="${1#--idempotency-key=}"; shift ;;
        --json) shift ;;
        --help|-h) usage; exit 0 ;;
        "") shift ;;
        *) printf 'unknown repair arg: %s\n' "$1" >&2; exit 2 ;;
      esac
    done
    repair_run
    exit 0
    ;;
esac

if ! [[ "$THRESHOLD" =~ ^[1-9][0-9]*$ ]]; then
  printf 'threshold must be a positive integer\n' >&2
  exit 2
fi

if [[ "$COMMAND" != "check" ]]; then
  usage >&2
  exit 2
fi

run_check

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-100-contention-shaped-state-owner.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-53-idempotent-delivery-replay.md`
