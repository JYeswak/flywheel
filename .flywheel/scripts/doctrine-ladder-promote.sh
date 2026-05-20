#!/usr/bin/env bash
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (TODO markers in stubs need fill-in)
# doctor-mode-tier: scaffolded (bead flywheel-ws02m)
#
# This block is APPENDED by scaffold-canonical-cli.sh. The original
# top-level dispatch is preserved as `cmd_run` (the new main routes
# default invocation through cmd_run for backward compat). Surface-
# specific logic was filled in by flywheel-vc29u (P3 sub-bead from flywheel-frm53).

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="doctrine-ladder-promote/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/doctrine-ladder-promote-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: doctrine-ladder-promote.sh [SUBCOMMAND] [OPTIONS]

Backward-compatible run mode: default invocation routes to the original
top-level logic (now exposed as `cmd_run`).

Canonical CLI surfaces:
  doctor [--json]          probe substrate health
  health [--json]          last-run status
  repair --scope <s>       repair misconfigured state
                            Default: --dry-run; mutate with --apply --idempotency-key KEY
  validate <subject> [...] validate per-subject contract (TODO: define subjects)
  audit [--json]           recent run history
  why <id>                 explain provenance for a given id (TODO: id semantics)
  quickstart [--json]      operator orientation
  help <topic>             topic help (run | doctor | health | repair | validate)
  completion <shell>       emit bash or zsh completion

Introspection:
  --info --json            version, paths, env vars, dependencies, sha256
  --schema [<surface>]     JSON Schema for output envelopes
  --examples --json        curated workflow examples
  --help / -h              this help
USG
}

scaffold_emit_info() {
  if ! command -v cli_emit_info >/dev/null; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "doctrine-ladder-promote.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "doctrine-ladder-promote.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"doctrine-ladder-promote.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"doctrine-ladder-promote.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"doctrine-ladder-promote.sh doctor --json"}'
)"
  if command -v cli_emit_quickstart >/dev/null; then
    cli_emit_quickstart "$SCAFFOLD_SCHEMA_VERSION" "$steps" "doctor,health,repair"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"quickstart",helper_lib_missing:true}'
  fi
}

scaffold_emit_schema() {
  local surface="${1:-doctrine-ladder-promote}"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" '{
    schema_version:$sv,
    command:"schema",
    surface:$surface,
    description:"analyze fuckup-log.jsonl for promotion candidates over a lookback window; create beads for recurrent classes that lack INCIDENTS coverage",
    inputs:{
      repo:{type:"path",default:"/Users/josh/Developer/flywheel"},
      period_days:{type:"integer",default:7,env:"DOCTRINE_LADDER_PERIOD_DAYS"},
      fuckup_log:{type:"path",env:"FUCKUP_LOG",default:"$HOME/.local/state/flywheel/fuckup-log.jsonl"},
      br_bin:{type:"binary",env:"BR_BIN",default:"br"}
    },
    outputs:{
      runs_log:{path:"$HOME/.local/state/flywheel/doctrine-ladder-promote-runs.jsonl"},
      candidate_beads:{description:"beads created via br for fuckup classes that recurred and lack INCIDENTS coverage"},
      stdout_per_class_action:["skip","already_open","created","covered_by_incidents"]
    },
    side_effects:["reads fuckup-log.jsonl","reads INCIDENTS.md files for coverage check","may create beads via br"]
  }'
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — analyze fuckup-log.jsonl over the lookback window (DOCTRINE_LADDER_PERIOD_DAYS, default 7), identify recurrent classes lacking INCIDENTS coverage, and create promotion-candidate beads via br. Default invocation: doctrine-ladder-promote.sh [REPO_PATH].\n' ;;
    doctor)   printf 'topic: doctor — probes 6 substrate dimensions: fuckup-log readable, BR_BIN on PATH, jq present, INCIDENTS files exist+readable, PERIOD_DAYS sane (>=1), runs ledger writable.\n' ;;
    health)   printf 'topic: health — tails the runs ledger; reports recent_run_count, last_run_ts, age_seconds_since_last, candidates_created_total. Status warn when stale >14 days or no runs in lookback.\n' ;;
    repair)   printf 'topic: repair — scopes: ladder-rerun (re-run promotion analysis with --apply on br create), runs-log-rotate (rotate runs ledger when >5MB). --apply requires --idempotency-key.\n' ;;
    validate) printf 'topic: validate — subjects: fuckup-row (--row-json against required fields ts/class/severity), incidents-coverage (--class CLASS; checks INCIDENTS.md heading match), config (validates PERIOD_DAYS + REPO + FUCKUP_LOG paths).\n' ;;
    audit)    printf 'topic: audit — tail recent rows from the runs ledger. --tail=N (default 10).\n' ;;
    why)      printf 'topic: why <class> — explain whether a fuckup-class has a promotion candidate bead, INCIDENTS coverage, and recent occurrence count over the lookback window.\n' ;;
    *)        printf 'topics: run | doctor | health | repair | validate | audit | why\n' ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh> — emit shell completion script\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "doctrine-ladder-promote" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "doctrine-ladder-promote" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  # 6 substrate checks. Pure if/then/else/fi (no L4 short-circuits).
  local ts fuckup_log br_bin period_days runs_log script_self repo_default
  ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  fuckup_log="${FUCKUP_LOG:-$HOME/.local/state/flywheel/fuckup-log.jsonl}"
  br_bin="${BR_BIN:-br}"
  period_days="${DOCTRINE_LADDER_PERIOD_DAYS:-7}"
  runs_log="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/doctrine-ladder-promote-runs.jsonl}"
  script_self="${BASH_SOURCE[0]}"
  repo_default="/Users/josh/Developer/flywheel"

  local fuckup_status="fail" fuckup_reason=""
  if [[ -f "$fuckup_log" && -r "$fuckup_log" ]]; then fuckup_status="pass"
  elif [[ -f "$fuckup_log" ]]; then fuckup_reason="exists but not readable: $fuckup_log"
  else fuckup_reason="fuckup-log absent: $fuckup_log"; fi

  local br_status="fail" br_reason=""
  if command -v "$br_bin" >/dev/null 2>&1; then br_status="pass"
  else br_reason="br not on PATH: $br_bin"; fi

  local jq_status="fail" jq_reason=""
  if command -v jq >/dev/null 2>&1; then jq_status="pass"
  else jq_reason="jq not on PATH (script will exit 1)"; fi

  local incidents_status="fail" incidents_reason="" incidents_count=0
  if [[ -d "$repo_default" ]]; then
    while IFS= read -r f; do
      [[ -r "$f" ]] && incidents_count=$((incidents_count + 1))
    done < <(find "$repo_default" -maxdepth 4 -name 'INCIDENTS.md' 2>/dev/null)
    if [[ "$incidents_count" -gt 0 ]]; then incidents_status="pass"
    else incidents_reason="no INCIDENTS.md files found under $repo_default"; fi
  else
    incidents_reason="repo absent: $repo_default"
  fi

  local period_status="fail" period_reason=""
  if [[ "$period_days" =~ ^[0-9]+$ ]] && [[ "$period_days" -ge 1 ]]; then period_status="pass"
  else period_reason="period_days invalid: '$period_days' (must be int >= 1)"; fi

  local runs_status="fail" runs_reason=""
  if [[ -f "$runs_log" && -w "$runs_log" ]]; then runs_status="pass"
  elif [[ -f "$runs_log" ]]; then runs_reason="exists but not writable: $runs_log"
  elif [[ -w "$(dirname "$runs_log")" ]]; then runs_status="pass"; runs_reason="absent but parent writable"
  else runs_reason="parent not writable: $(dirname "$runs_log")"; fi

  local overall="pass"
  for s in "$fuckup_status" "$br_status" "$jq_status" "$incidents_status" "$period_status" "$runs_status"; do
    if [[ "$s" == "fail" ]]; then overall="fail"; fi
  done

  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg overall "$overall" \
    --arg fuckup_log "$fuckup_log" --arg fuckup_status "$fuckup_status" --arg fuckup_reason "$fuckup_reason" \
    --arg br_bin "$br_bin" --arg br_status "$br_status" --arg br_reason "$br_reason" \
    --arg jq_status "$jq_status" --arg jq_reason "$jq_reason" \
    --arg incidents_status "$incidents_status" --arg incidents_reason "$incidents_reason" --argjson incidents_count "$incidents_count" \
    --argjson period_days "$period_days" --arg period_status "$period_status" --arg period_reason "$period_reason" \
    --arg runs_log "$runs_log" --arg runs_status "$runs_status" --arg runs_reason "$runs_reason" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$overall,checks:[
      {name:"fuckup_log_readable",status:$fuckup_status,path:$fuckup_log,reason:$fuckup_reason},
      {name:"br_on_path",status:$br_status,bin:$br_bin,reason:$br_reason},
      {name:"jq_on_path",status:$jq_status,reason:$jq_reason},
      {name:"incidents_files_present",status:$incidents_status,count:$incidents_count,reason:$incidents_reason},
      {name:"period_days_sane",status:$period_status,value:$period_days,reason:$period_reason},
      {name:"runs_log_writable",status:$runs_status,path:$runs_log,reason:$runs_reason}
    ]}'
}

scaffold_cmd_health() {
  # Tail the runs ledger and summarize recent ladder-promote activity.
  local ts runs_log tail_count=20 tail_lines total last_ts age_seconds candidates_created
  ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  runs_log="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/doctrine-ladder-promote-runs.jsonl}"

  if [[ ! -f "$runs_log" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$runs_log" \
      '{schema_version:$sv,command:"health",ts:$ts,status:"warn",reason:"runs ledger absent (no analyses recorded yet)",runs_log:$log,recent_count:0}'
    return 0
  fi

  tail_lines="$(tail -n "$tail_count" "$runs_log" 2>/dev/null)"
  total="$(printf '%s\n' "$tail_lines" | grep -c . || echo 0)"
  last_ts="$(printf '%s\n' "$tail_lines" | tail -1 | jq -r '.ts // ""' 2>/dev/null)"
  candidates_created="$(printf '%s\n' "$tail_lines" | jq -r 'select(.action == "created") | .class' 2>/dev/null | wc -l | tr -d ' ')"

  if [[ -n "$last_ts" ]]; then
    local now_epoch last_epoch
    now_epoch="$(date -u +%s)"
    last_epoch="$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_ts" +%s 2>/dev/null || echo "$now_epoch")"
    age_seconds=$((now_epoch - last_epoch))
  else
    age_seconds=null
  fi

  local status="pass" reason=""
  if [[ "$total" -eq 0 ]]; then
    status="warn"; reason="runs ledger present but empty"
  elif [[ "$age_seconds" != "null" ]] && [[ "$age_seconds" -gt 1209600 ]]; then
    status="warn"; reason="last analysis > 14 days ago (age=${age_seconds}s) — cron may be stalled"
  fi

  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg status "$status" --arg reason "$reason" \
    --arg runs_log "$runs_log" \
    --argjson total "$total" --argjson candidates "$candidates_created" \
    --arg last_ts "$last_ts" --argjson age "${age_seconds:-null}" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,reason:(if $reason == "" then null else $reason end),
      runs_log:$runs_log,recent_count:$total,candidates_created_in_window:$candidates,
      last_run_ts:(if $last_ts == "" then null else $last_ts end),
      age_seconds_since_last:$age}'
}

scaffold_cmd_repair() {
  local scope="" mode="dry_run" idem_key=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) scaffold_emit_topic_help repair; return 0 ;;
      --scope) scope="${2:-}"; shift 2 ;;
      --dry-run) mode="dry_run"; shift ;;
      --apply) mode="apply"; shift ;;
      --idempotency-key) idem_key="${2:-}"; shift 2 ;;
      --idempotency-key=*) idem_key="${1#--idempotency-key=}"; shift ;;
      --json) shift ;;
      *) printf 'ERR: unknown repair arg %s\n' "$1" >&2; return 64 ;;
    esac
  done
  if [[ "$mode" == "apply" && -z "$idem_key" ]]; then
    if command -v cli_refuse_apply_without_idem_key >/dev/null; then
      cli_refuse_apply_without_idem_key "$SCAFFOLD_SCHEMA_VERSION" "repair" "$scope"
    else
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",mode:"apply",scope:$scope,reason:"--apply requires --idempotency-key"}'
      exit 3
    fi
  fi
  # Per-scope repair actions:
  #   ladder-rerun     — re-run the promotion analysis (canonical run path)
  #   runs-log-rotate  — rotate runs ledger when >5MB
  local runs_log fuckup_log repo
  runs_log="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/doctrine-ladder-promote-runs.jsonl}"
  fuckup_log="${FUCKUP_LOG:-$HOME/.local/state/flywheel/fuckup-log.jsonl}"
  repo="/Users/josh/Developer/flywheel"

  case "$scope" in
    ladder-rerun)
      local recent_count=0
      if [[ -f "$fuckup_log" ]]; then
        recent_count="$(wc -l <"$fuckup_log" | tr -d ' ')"
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" --arg idem "$idem_key" \
        --arg fuckup "$fuckup_log" --argjson count "$recent_count" --arg repo "$repo" \
        '{schema_version:$sv,command:"repair",status:"plan",mode:$mode,scope:$scope,idempotency_key:$idem,fuckup_log:$fuckup,fuckup_log_lines:$count,repo:$repo,note:"plan-only emitted; the canonical apply path is `doctrine-ladder-promote.sh REPO_PATH` which exercises full INCIDENTS coverage check + br create"}'
      ;;
    runs-log-rotate)
      local size=0 rotate_threshold=5242880  # 5 MB
      if [[ -f "$runs_log" ]]; then
        size="$(wc -c <"$runs_log" | tr -d ' ')"
      fi
      local needs_rotate=false
      if [[ "$size" -gt "$rotate_threshold" ]]; then needs_rotate=true; fi
      if [[ "$mode" == "apply" && "$needs_rotate" == "true" ]]; then
        local rotated="${runs_log}.$(date -u +%Y%m%dT%H%M%SZ)"
        mv "$runs_log" "$rotated" 2>/dev/null
        : > "$runs_log"
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg idem "$idem_key" \
          --arg runs_log "$runs_log" --arg rotated "$rotated" --argjson size "$size" \
          '{schema_version:$sv,command:"repair",status:"ok",mode:"apply",scope:$scope,idempotency_key:$idem,runs_log:$runs_log,rotated_to:$rotated,old_size_bytes:$size}'
      elif [[ "$mode" == "apply" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg idem "$idem_key" \
          --arg runs_log "$runs_log" --argjson size "$size" --argjson threshold "$rotate_threshold" \
          '{schema_version:$sv,command:"repair",status:"noop",mode:"apply",scope:$scope,idempotency_key:$idem,runs_log:$runs_log,size_bytes:$size,threshold_bytes:$threshold,reason:"under threshold; no rotation needed"}'
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
          --arg runs_log "$runs_log" --argjson size "$size" --argjson threshold "$rotate_threshold" --argjson needs "$needs_rotate" \
          '{schema_version:$sv,command:"repair",status:"plan",mode:"dry_run",scope:$scope,runs_log:$runs_log,size_bytes:$size,threshold_bytes:$threshold,needs_rotate:$needs}'
      fi
      ;;
    ""|none)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg mode "$mode" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"info",mode:$mode,scope:$scope,reason:"no scope specified",valid_scopes:["ladder-rerun","runs-log-rotate"]}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg mode "$mode" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",mode:$mode,scope:$scope,reason:"unknown scope",valid_scopes:["ladder-rerun","runs-log-rotate"]}'
      return 64
      ;;
  esac
}

scaffold_cmd_validate() {
  # Per-subject validation:
  #   --row-json=<JSON>      validate a fuckup-log row against required fields
  #   --class=<CLASS>        check INCIDENTS coverage for a fuckup class
  #   --config               validate REPO + PERIOD_DAYS + FUCKUP_LOG
  local subject="" row_json="" class_arg=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --row-json=*) row_json="${1#--row-json=}"; subject="row"; shift ;;
      --class=*) class_arg="${1#--class=}"; subject="class"; shift ;;
      --config) subject="config"; shift ;;
      --json) shift ;;
      -h|--help) scaffold_emit_topic_help validate; return 0 ;;
      *) printf 'ERR: unknown validate arg: %s\n' "$1" >&2; return 64 ;;
    esac
  done

  case "$subject" in
    row)
      [[ -z "$row_json" ]] && { jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",status:"refused",reason:"--row-json=JSON required"}'; return 64; }
      local required='["ts","class","severity"]'
      local missing valid
      missing="$(echo "$row_json" | jq -c --argjson req "$required" --argjson r "$row_json" '[$req[] | select(. as $f | ($r | has($f) | not))] // []' 2>/dev/null || echo "[]")"
      if echo "$row_json" | jq -e 'type == "object"' >/dev/null 2>&1; then valid=true; else valid=false; fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --argjson valid "$valid" --argjson missing "$missing" --argjson r "$row_json" \
        '{schema_version:$sv,command:"validate",subject:"row",status:(if $valid and ($missing | length == 0) then "pass" else "fail" end),valid:$valid,missing_fields:$missing,row:$r}'
      ;;
    class)
      [[ -z "$class_arg" ]] && { jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",status:"refused",reason:"--class=CLASS required"}'; return 64; }
      local repo_root="/Users/josh/Developer/flywheel"
      local covered=false matched_files=()
      while IFS= read -r f; do
        if grep -qiE "(^|[^a-z_])${class_arg}([^a-z_]|$)" "$f" 2>/dev/null; then
          covered=true
          matched_files+=("$f")
        fi
      done < <(find "$repo_root/.flywheel" -name 'INCIDENTS.md' 2>/dev/null)
      local matched_json="[]"
      if [[ ${#matched_files[@]} -gt 0 ]]; then
        matched_json="$(printf '%s\n' "${matched_files[@]}" | jq -R . | jq -sc '.')"
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg class "$class_arg" --argjson covered "$covered" --argjson matched "$matched_json" \
        '{schema_version:$sv,command:"validate",subject:"class",class:$class,status:(if $covered then "pass" else "fail" end),covered_in_incidents:$covered,matched_files:$matched}'
      ;;
    config)
      local fuckup_log period_days repo
      fuckup_log="${FUCKUP_LOG:-$HOME/.local/state/flywheel/fuckup-log.jsonl}"
      period_days="${DOCTRINE_LADDER_PERIOD_DAYS:-7}"
      repo="/Users/josh/Developer/flywheel"
      local fuckup_valid=false repo_valid=false period_valid=false
      [[ -f "$fuckup_log" || -d "$(dirname "$fuckup_log")" ]] && fuckup_valid=true
      [[ -d "$repo/.flywheel" ]] && repo_valid=true
      [[ "$period_days" =~ ^[0-9]+$ ]] && [[ "$period_days" -ge 1 ]] && period_valid=true
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        --arg fuckup_log "$fuckup_log" --argjson fuckup_valid "$fuckup_valid" \
        --arg repo "$repo" --argjson repo_valid "$repo_valid" \
        --argjson period "$period_days" --argjson period_valid "$period_valid" \
        '{schema_version:$sv,command:"validate",subject:"config",
          status:(if $fuckup_valid and $repo_valid and $period_valid then "pass" else "fail" end),
          fuckup_log:{value:$fuckup_log,valid:$fuckup_valid},
          repo:{value:$repo,valid:$repo_valid},
          period_days:{value:$period,valid:$period_valid}}'
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"info",reason:"no subject specified",valid_subjects:["row","class","config"]}'
      ;;
  esac
}

scaffold_cmd_audit() {
  # Tail the runs ledger. --tail=N (default 10).
  local runs_log="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/doctrine-ladder-promote-runs.jsonl}"
  local tail_n=10
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --tail=*) tail_n="${1#--tail=}"; shift ;;
      --tail) tail_n="${2:-10}"; shift 2 ;;
      --json) shift ;;
      -h|--help) scaffold_emit_topic_help audit; return 0 ;;
      *) printf 'ERR: unknown audit arg: %s\n' "$1" >&2; return 64 ;;
    esac
  done
  if [[ ! -f "$runs_log" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$runs_log" \
      --argjson tail_n "$tail_n" \
      '{schema_version:$sv,command:"audit",audit_log:$log,tail_n:$tail_n,count:0,status:"warn",reason:"runs ledger absent",rows:[]}'
    return 0
  fi
  local rows count
  rows="$(tail -n "$tail_n" "$runs_log" | jq -sc '.' 2>/dev/null || echo '[]')"
  count="$(echo "$rows" | jq 'length')"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$runs_log" \
    --argjson tail_n "$tail_n" --argjson count "$count" --argjson rows "$rows" \
    '{schema_version:$sv,command:"audit",audit_log:$log,tail_n:$tail_n,count:$count,rows:$rows}'
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <class> argument\n' >&2; return 64
  fi
  # 3-tier provenance for a fuckup class:
  # 1. Recent occurrence count in fuckup-log (within PERIOD_DAYS)
  # 2. Existing promotion-candidate bead?
  # 3. INCIDENTS coverage status
  local fuckup_log period_days br_bin repo
  fuckup_log="${FUCKUP_LOG:-$HOME/.local/state/flywheel/fuckup-log.jsonl}"
  period_days="${DOCTRINE_LADDER_PERIOD_DAYS:-7}"
  br_bin="${BR_BIN:-br}"
  repo="/Users/josh/Developer/flywheel"

  # Wrap diagnostics in `set +e` because pipefail trips on jq/grep
  # not-found rc that we want to treat as 0/empty.
  local recent_count=0 last_ts="" cutoff_epoch
  set +e
  if [[ -f "$fuckup_log" ]]; then
    cutoff_epoch="$(( $(date -u +%s) - period_days * 86400 ))"
    recent_count="$(jq -r --arg class "$id" --argjson cutoff "$cutoff_epoch" \
      'select(.class == $class) | select((.ts // "" | sub("Z$"; "+00:00") | fromdateiso8601? // 0) >= $cutoff) | .ts' \
      "$fuckup_log" 2>/dev/null | wc -l | tr -d ' ')"
    last_ts="$(jq -r --arg class "$id" 'select(.class == $class) | .ts' "$fuckup_log" 2>/dev/null | tail -1)"
  fi
  [[ -z "$recent_count" ]] && recent_count=0

  local has_open_bead=false
  if command -v "$br_bin" >/dev/null 2>&1; then
    "$br_bin" list 2>/dev/null | grep -qi "$id" && has_open_bead=true
  fi

  local incidents_covered=false matched_files=()
  # Search both repo root and .flywheel/ subtree for INCIDENTS.md
  while IFS= read -r f; do
    if grep -qiE "(^|[^a-z_])${id}([^a-z_]|$)" "$f" 2>/dev/null; then
      incidents_covered=true
      matched_files+=("$f")
    fi
  done < <(find "$repo" -maxdepth 4 -name 'INCIDENTS.md' 2>/dev/null)
  local matched_json="[]"
  if [[ ${#matched_files[@]} -gt 0 ]]; then
    matched_json="$(printf '%s\n' "${matched_files[@]}" | jq -R . | jq -sc '.')"
  fi
  set -e

  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg class "$id" \
    --argjson recent "$recent_count" --argjson period "$period_days" \
    --arg last_ts "$last_ts" \
    --argjson has_bead "$has_open_bead" \
    --argjson covered "$incidents_covered" --argjson matched "$matched_json" \
    '{schema_version:$sv,command:"why",class:$class,
      recent_occurrences_in_window:$recent,
      lookback_period_days:$period,
      last_occurrence_ts:(if $last_ts == "" then null else $last_ts end),
      has_open_promotion_bead:$has_bead,
      incidents_coverage:{covered:$covered,matched_files:$matched},
      promotion_recommended:(if $recent >= 3 and ($covered | not) and ($has_bead | not) then true else false end)}'
}

# ---------- scaffolded main dispatcher ----------

# When the scaffolder appends this block, it expects the target's original
# top-level main is renamed to `cmd_run` (or the original final
# `main "$@"` line is replaced with this dispatcher). Default invocation
# falls through to the original logic for backward compat.
scaffold_main() {
  if [[ $# -eq 0 ]]; then
    scaffold_usage; exit 0
  fi
  case "$1" in
    -h|--help)    scaffold_usage; exit 0 ;;
    --info)       shift; scaffold_emit_info "$@"; exit 0 ;;
    --schema)     shift; scaffold_emit_schema "${1:-default}"; exit 0 ;;
    --examples)   shift; scaffold_emit_examples "$@"; exit 0 ;;
    doctor)       shift; scaffold_cmd_doctor "$@"; exit $? ;;
    health)       shift; scaffold_cmd_health "$@"; exit $? ;;
    repair)       shift; scaffold_cmd_repair "$@"; exit $? ;;
    validate)     shift; scaffold_cmd_validate "$@"; exit $? ;;
    audit)        shift; scaffold_cmd_audit "$@"; exit $? ;;
    why)          shift; scaffold_cmd_why "$@"; exit $? ;;
    quickstart)   shift; scaffold_emit_quickstart "$@"; exit 0 ;;
    help)         shift; scaffold_emit_topic_help "${1:-}"; exit 0 ;;
    completion)   shift; scaffold_emit_completion "${1:-bash}"; exit $? ;;
    *)
      printf 'ERR: unknown canonical subcommand: %s\n' "$1" >&2
      scaffold_usage >&2
      exit 64 ;;
  esac
}

# Early-dispatch intercept: if argv[0] looks like a canonical subcommand
# or introspection flag, run the canonical surface and exit BEFORE the
# target's original arg parser sees the args. Works for both `main "$@"`
# style and inline `while [[ $# -gt 0 ]]` style targets.
_scaffold_is_canonical_arg() {
  case "${1:-}" in
    doctor|health|repair|validate|audit|why|quickstart|completion) return 0 ;;
    --info|--schema|--examples) return 0 ;;
    -h|--help) return 0 ;;
    help)
      # Intercept `help <topic>` and `help --help`; bare `help` could be
      # a legacy subcommand of the target so it falls through.
      case "${2:-}" in run|doctor|health|repair|validate|audit|why|-h|--help) return 0 ;; esac
      return 1 ;;
    *) return 1 ;;
  esac
}

if [[ $# -gt 0 ]] && _scaffold_is_canonical_arg "$@"; then
  scaffold_main "$@"
  exit $?
fi
# ====== END canonical-cli scaffold ======
REPO="${1:-/Users/josh/Developer/flywheel}"
FUCKUP_LOG="${FUCKUP_LOG:-$HOME/.local/state/flywheel/fuckup-log.jsonl}"
BR_BIN="${BR_BIN:-br}"
PERIOD_DAYS="${DOCTRINE_LADDER_PERIOD_DAYS:-7}"

if ! command -v jq >/dev/null 2>&1; then
  printf '{"action":"error","reason":"jq_missing"}\n'
  exit 1
fi

if ! command -v "$BR_BIN" >/dev/null 2>&1; then
  if [ -x "$HOME/.cargo/bin/br" ]; then
    BR_BIN="$HOME/.cargo/bin/br"
  else
    printf '{"action":"error","reason":"br_missing"}\n'
    exit 1
  fi
fi

if [ ! -f "$FUCKUP_LOG" ]; then
  jq -nc '{action:"noop",reason:"no_fuckup_log"}'
  exit 0
fi

cutoff_iso() {
  python3 - "$PERIOD_DAYS" <<'PY' 2>/dev/null || date -u -v-"${PERIOD_DAYS}"d +%Y-%m-%dT%H:%M:%SZ
import datetime
import sys

days = int(sys.argv[1])
cutoff = datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=days)
print(cutoff.strftime("%Y-%m-%dT%H:%M:%SZ"))
PY
}

default_incident_paths() {
  printf '%s\n' "$HOME/.claude/skills/.flywheel/INCIDENTS.md"
  printf '%s\n' "$HOME"/.claude/skills/*/references/INCIDENTS.md
  printf '%s\n' "$REPO/INCIDENTS.md"
  printf '%s\n' "$REPO/AGENTS.md"
  # flywheel-iyaym: also scan canonical flywheel INCIDENTS at its absolute
  # path so worktree-relative $REPO/INCIDENTS.md never masks coverage. When
  # orch tick runs from /Users/josh/Developer/flywheel-*-worktree (stale
  # branch), $REPO/INCIDENTS.md may be days out of date; the canonical
  # flywheel checkout is the source of truth.
  printf '%s\n' "/Users/josh/Developer/flywheel/INCIDENTS.md"
  # flywheel-vl0c9: extend coverage scan to .flywheel/rules/*.md so
  # trauma classes already covered at the canonical L-rule layer don't
  # re-fire as promotion-candidate beads. Surfaced by 6+ duplicate
  # filings in one session for daily_report_missing_dispatch_gate,
  # mobile-eats-dispatch-health-gate-fail, sister-orch-2-tick-blocker,
  # three_q_surface_gap, and orch-punt-to-next-tick — all already
  # covered by L91/L92/L70/L152/two-blocker-ticks-escalate L-rules.
  printf '%s\n' "$REPO"/.flywheel/rules/*.md
  printf '%s\n' "$HOME"/.claude/skills/.flywheel/rules/*.md
  printf '%s\n' /Users/josh/Developer/flywheel/.flywheel/rules/*.md
}

incident_paths() {
  if [ -n "${INCIDENTS_SEARCH_PATHS:-}" ]; then
    printf '%s\n' $INCIDENTS_SEARCH_PATHS
  else
    default_incident_paths
  fi
}

incidents_cover_class() {
  local class="$1"
  while IFS= read -r path; do
    [ -f "$path" ] || continue
    if grep -Fqi -- "$class" "$path"; then
      return 0
    fi
  done < <(incident_paths)
  return 1
}

issues_json() {
  (cd "$REPO" && "$BR_BIN" list --json --limit 0)
}

open_promotion_candidate_exists() {
  local class="$1"
  issues_json | jq -e --arg class "$class" '
    .issues[]?
    | select((.status // "") != "closed")
    | select(((.title // "") | ascii_downcase | contains("promotion-candidate"))
      and ((.title // "") | contains($class)))
  ' >/dev/null
}

create_candidate_bead() {
  local class="$1" count="$2"
  local description bead
  description="Auto-created by doctrine-ladder-promote.sh per L56 ladder. Trauma class '$class' hit $count times in last ${PERIOD_DAYS}d with no INCIDENTS coverage. Run /flywheel:learn --promote $class to draft doctrine entry."
  bead="$(cd "$REPO" && "$BR_BIN" create "[promotion-candidate] $class ($count events in ${PERIOD_DAYS}d)" \
    --type task \
    --priority 2 \
    --description "$description" \
    --silent)"
  printf '%s\n' "$bead"
}

cutoff="$(cutoff_iso)"
classes="$(
  jq -Rr 'fromjson? | select(type == "object")' "$FUCKUP_LOG" 2>/dev/null \
    | jq -r --arg cutoff "$cutoff" '
      select(((.ts // .timestamp // "") | tostring) >= $cutoff)
      | (.trauma_class // "") | tostring
      | select(length > 0)
    ' \
    | sort \
    | uniq -c \
    | awk -v threshold=3 '$1 >= threshold { count=$1; $1=""; sub(/^ +/, ""); print $0 "\t" count }'
)"

created_file="$(mktemp)"
skipped_file="$(mktemp)"
trap 'rm -f "$created_file" "$skipped_file"' EXIT

if [ -n "$classes" ]; then
  while IFS=$'\t' read -r class count; do
    [ -n "${class:-}" ] || continue
    if incidents_cover_class "$class"; then
      printf '%s:incidents_covered\n' "$class" >>"$skipped_file"
      continue
    fi
    if open_promotion_candidate_exists "$class"; then
      printf '%s:bead_exists\n' "$class" >>"$skipped_file"
      continue
    fi
    bead="$(create_candidate_bead "$class" "$count")"
    printf '%s:%s\n' "$class" "$bead" >>"$created_file"
  done <<<"$classes"
fi

created_json="$(jq -R 'select(length > 0)' "$created_file" | jq -s .)"
skipped_json="$(jq -R 'select(length > 0)' "$skipped_file" | jq -s .)"

jq -nc \
  --argjson period_days "$PERIOD_DAYS" \
  --arg cutoff "$cutoff" \
  --argjson created "$created_json" \
  --argjson skipped "$skipped_json" \
  '{
    action:"completed",
    period_days:$period_days,
    cutoff:$cutoff,
    created:$created,
    skipped:$skipped
  }'

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
