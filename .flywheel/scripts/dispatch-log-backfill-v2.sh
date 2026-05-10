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
# specific logic was filled in by flywheel-x882q (P3 sub-bead from flywheel-wgitr).

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="dispatch-log-backfill-v2/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/dispatch-log-backfill-v2-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: dispatch-log-backfill-v2.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "dispatch-log-backfill-v2.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "dispatch-log-backfill-v2.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"dispatch-log-backfill-v2.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"dispatch-log-backfill-v2.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"dispatch-log-backfill-v2.sh doctor --json"}'
)"
  if command -v cli_emit_quickstart >/dev/null; then
    cli_emit_quickstart "$SCAFFOLD_SCHEMA_VERSION" "$steps" "doctor,health,repair"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"quickstart",helper_lib_missing:true}'
  fi
}

scaffold_emit_schema() {
  local surface="${1:-dispatch-log-backfill-v2}"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" '{
    schema_version:$sv,
    command:"schema",
    surface:$surface,
    description:"backfill v2 metadata fields onto existing rows in dispatch-log.jsonl. Reads each row, computes/normalizes derived fields, writes a new file then atomically swaps. Default --dry-run.",
    inputs:{
      log_path:{type:"path",default:"$REPO/.flywheel/dispatch-log.jsonl"},
      mission_anchor:{type:"string",env:"FLYWHEEL_MISSION_ANCHOR",default:"continuous-orchestrator-uptime-self-sustaining-fleet"},
      mode:{type:"enum",values:["dry-run","apply"],default:"dry-run"}
    },
    outputs:{
      runs_log:{path:"$HOME/.local/state/flywheel/dispatch-log-backfill-v2-runs.jsonl"},
      stdout:{type:"json",fields:["before_lines","after_lines","backfilled_count","mode"]}
    },
    side_effects:["dry_run: read-only enumeration","apply: writes new dispatch-log.jsonl atomically (mv after write)","appends row to runs ledger"]
  }'
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — backfill v2 metadata onto existing dispatch-log.jsonl rows. Default --dry-run; --apply atomically swaps in new file. Idempotent: re-applying produces byte-identical result.\n' ;;
    doctor)   printf 'topic: doctor — probes 5 substrate dimensions: REPO is flywheel, dispatch-log.jsonl readable, dispatch-log.jsonl writable (parent), jq present, runs ledger writable.\n' ;;
    health)   printf 'topic: health — tail runs ledger; reports recent_run_count, last_apply_ts, age_seconds_since_last, total_rows_backfilled. Status warn when stale >7 days.\n' ;;
    repair)   printf 'topic: repair — scopes: dispatch-log-backfill-rerun (re-run; plan-only points at canonical run path) + runs-log-rotate (rotate runs ledger when >5MB).\n' ;;
    validate) printf 'topic: validate — subjects: row (--row-json against v2 required fields), tail (--tail=N validate last N rows of dispatch-log.jsonl for v2 schema), config (env values).\n' ;;
    audit)    printf 'topic: audit — tail recent rows from runs ledger. --tail=N (default 10).\n' ;;
    why)      printf 'topic: why <task_id> — explain whether a task_id is/isnt v2-conformant in dispatch-log.jsonl; emits row + missing v2 fields.\n' ;;
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
            && cli_emit_completion_bash "dispatch-log-backfill-v2" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "dispatch-log-backfill-v2" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  # 5 substrate checks. Pure if/then/else/fi.
  local ts script_dir repo_root log_path runs_log
  ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
  repo_root="$(cd "$script_dir/../.." 2>/dev/null && pwd -P)"
  log_path="$repo_root/.flywheel/dispatch-log.jsonl"
  runs_log="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/dispatch-log-backfill-v2-runs.jsonl}"

  local repo_status="fail" repo_reason=""
  if [[ -d "$repo_root/.flywheel" ]]; then repo_status="pass"
  else repo_reason="$repo_root is not a flywheel repo (no .flywheel/)"; fi

  local log_read_status="fail" log_read_reason=""
  if [[ -f "$log_path" && -r "$log_path" ]]; then log_read_status="pass"
  elif [[ -f "$log_path" ]]; then log_read_reason="exists but not readable: $log_path"
  else log_read_reason="dispatch-log absent: $log_path"; fi

  local log_write_status="fail" log_write_reason=""
  if [[ -w "$(dirname "$log_path")" ]]; then log_write_status="pass"
  else log_write_reason="parent dir not writable: $(dirname "$log_path")"; fi

  local jq_status="fail" jq_reason=""
  if command -v jq >/dev/null 2>&1; then jq_status="pass"
  else jq_reason="jq not on PATH"; fi

  local runs_status="fail" runs_reason=""
  if [[ -f "$runs_log" && -w "$runs_log" ]]; then runs_status="pass"
  elif [[ -w "$(dirname "$runs_log")" ]]; then runs_status="pass"; runs_reason="absent but parent writable"
  else runs_reason="parent not writable: $(dirname "$runs_log")"; fi

  local overall="pass"
  for s in "$repo_status" "$log_read_status" "$log_write_status" "$jq_status" "$runs_status"; do
    if [[ "$s" == "fail" ]]; then overall="fail"; fi
  done

  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg overall "$overall" \
    --arg repo "$repo_root" --arg repo_status "$repo_status" --arg repo_reason "$repo_reason" \
    --arg log "$log_path" --arg log_read_status "$log_read_status" --arg log_read_reason "$log_read_reason" \
    --arg log_write_status "$log_write_status" --arg log_write_reason "$log_write_reason" \
    --arg jq_status "$jq_status" --arg jq_reason "$jq_reason" \
    --arg runs "$runs_log" --arg runs_status "$runs_status" --arg runs_reason "$runs_reason" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$overall,checks:[
      {name:"flywheel_repo_resolvable",status:$repo_status,path:$repo,reason:$repo_reason},
      {name:"dispatch_log_readable",status:$log_read_status,path:$log,reason:$log_read_reason},
      {name:"dispatch_log_writable",status:$log_write_status,reason:$log_write_reason},
      {name:"jq_on_path",status:$jq_status,reason:$jq_reason},
      {name:"runs_ledger_writable",status:$runs_status,path:$runs,reason:$runs_reason}
    ]}'
}

scaffold_cmd_health() {
  # Tail runs ledger; report recent backfill activity.
  local ts runs_log tail_count=20 tail_lines total last_ts age_seconds total_backfilled
  ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  runs_log="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/dispatch-log-backfill-v2-runs.jsonl}"

  if [[ ! -f "$runs_log" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$runs_log" \
      '{schema_version:$sv,command:"health",ts:$ts,status:"warn",reason:"runs ledger absent",runs_log:$log,recent_count:0}'
    return 0
  fi

  set +e
  tail_lines="$(tail -n "$tail_count" "$runs_log" 2>/dev/null)"
  total="$(printf '%s\n' "$tail_lines" | grep -c . || echo 0)"
  last_ts="$(printf '%s\n' "$tail_lines" | tail -1 | jq -r '.ts // ""' 2>/dev/null)"
  total_backfilled="$(printf '%s\n' "$tail_lines" | jq -r '.backfilled_count // 0' 2>/dev/null | awk '{s+=$1} END{print s+0}')"
  set -e

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
  elif [[ "$age_seconds" != "null" ]] && [[ "$age_seconds" -gt 604800 ]]; then
    status="warn"; reason="last backfill > 7 days ago (age=${age_seconds}s)"
  fi

  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg status "$status" --arg reason "$reason" \
    --arg runs "$runs_log" \
    --argjson total "$total" --argjson backfilled "${total_backfilled:-0}" \
    --arg last_ts "$last_ts" --argjson age "${age_seconds:-null}" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,reason:(if $reason == "" then null else $reason end),
      runs_log:$runs,recent_count:$total,total_rows_backfilled_recent:$backfilled,
      last_apply_ts:(if $last_ts == "" then null else $last_ts end),
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
  # Per-scope repair:
  #   dispatch-log-backfill-rerun  — point at canonical run path
  #   runs-log-rotate              — rotate runs ledger when >5MB
  local runs_log script_dir repo_root log_path
  runs_log="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/dispatch-log-backfill-v2-runs.jsonl}"
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
  repo_root="$(cd "$script_dir/../.." 2>/dev/null && pwd -P)"
  log_path="$repo_root/.flywheel/dispatch-log.jsonl"

  case "$scope" in
    dispatch-log-backfill-rerun)
      set +e
      local total_rows=0
      [[ -f "$log_path" ]] && total_rows="$(wc -l <"$log_path" | tr -d ' ')"
      set -e
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" --arg idem "$idem_key" \
        --arg log "$log_path" --argjson rows "$total_rows" \
        '{schema_version:$sv,command:"repair",status:"plan",mode:$mode,scope:$scope,idempotency_key:$idem,
          dispatch_log:$log,total_rows:$rows,
          note:"plan-only; canonical apply path is `dispatch-log-backfill-v2.sh --apply --idempotency-key KEY`"}'
      ;;
    runs-log-rotate)
      local size=0 rotate_threshold=5242880
      [[ -f "$runs_log" ]] && size="$(wc -c <"$runs_log" | tr -d ' ')"
      local needs_rotate=false
      [[ "$size" -gt "$rotate_threshold" ]] && needs_rotate=true
      if [[ "$mode" == "apply" && "$needs_rotate" == "true" ]]; then
        local rotated="${runs_log}.$(date -u +%Y%m%dT%H%M%SZ)"
        mv "$runs_log" "$rotated" 2>/dev/null
        : > "$runs_log"
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg idem "$idem_key" \
          --arg runs "$runs_log" --arg rotated "$rotated" --argjson size "$size" \
          '{schema_version:$sv,command:"repair",status:"ok",mode:"apply",scope:$scope,idempotency_key:$idem,runs_log:$runs,rotated_to:$rotated,old_size_bytes:$size}'
      elif [[ "$mode" == "apply" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg idem "$idem_key" \
          --arg runs "$runs_log" --argjson size "$size" --argjson threshold "$rotate_threshold" \
          '{schema_version:$sv,command:"repair",status:"noop",mode:"apply",scope:$scope,idempotency_key:$idem,runs_log:$runs,size_bytes:$size,threshold_bytes:$threshold,reason:"under threshold"}'
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
          --arg runs "$runs_log" --argjson size "$size" --argjson threshold "$rotate_threshold" --argjson needs "$needs_rotate" \
          '{schema_version:$sv,command:"repair",status:"plan",mode:"dry_run",scope:$scope,runs_log:$runs,size_bytes:$size,threshold_bytes:$threshold,needs_rotate:$needs}'
      fi
      ;;
    ""|none)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg mode "$mode" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"info",mode:$mode,scope:$scope,reason:"no scope specified",valid_scopes:["dispatch-log-backfill-rerun","runs-log-rotate"]}'
      ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg mode "$mode" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",mode:$mode,scope:$scope,reason:"unknown scope",valid_scopes:["dispatch-log-backfill-rerun","runs-log-rotate"]}'
      return 64
      ;;
  esac
}

scaffold_cmd_validate() {
  # Per-subject validation:
  #   --row-json=<JSON>   validate one dispatch row's v2 schema fields
  #   --tail=<N>          validate last N rows of dispatch-log.jsonl
  #   --config            validate REPO + dispatch-log path + mission anchor
  local subject="" row_json="" tail_n="10"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --row-json=*) row_json="${1#--row-json=}"; subject="row"; shift ;;
      --tail=*) tail_n="${1#--tail=}"; subject="tail"; shift ;;
      --config) subject="config"; shift ;;
      --json) shift ;;
      -h|--help) scaffold_emit_topic_help validate; return 0 ;;
      *) printf 'ERR: unknown validate arg: %s\n' "$1" >&2; return 64 ;;
    esac
  done

  # v2 required fields per the canonical dispatch row schema
  local v2_required='["ts","session","task_id","pane","task_file","channel"]'

  validate_one_row() {
    local r="$1"
    local missing valid
    missing="$(echo "$r" | jq -c --argjson req "$v2_required" --argjson r "$r" '[$req[] | select(. as $f | ($r | has($f) | not))] // []' 2>/dev/null || echo "[]")"
    if echo "$r" | jq -e 'type == "object"' >/dev/null 2>&1; then valid=true; else valid=false; fi
    jq -nc --argjson valid "$valid" --argjson missing "$missing" --argjson r "$r" \
      '{valid:($valid and ($missing | length == 0)),missing_fields:$missing,row:$r}'
  }

  case "$subject" in
    row)
      [[ -z "$row_json" ]] && { jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"validate",status:"refused",reason:"--row-json=JSON required"}'; return 64; }
      local result
      result="$(validate_one_row "$row_json")"
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --argjson r "$result" \
        '{schema_version:$sv,command:"validate",subject:"row",status:(if $r.valid then "pass" else "fail" end),result:$r}'
      ;;
    tail)
      local script_dir repo_root log_path
      script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
      repo_root="$(cd "$script_dir/../.." 2>/dev/null && pwd -P)"
      log_path="$repo_root/.flywheel/dispatch-log.jsonl"
      [[ -f "$log_path" ]] || { jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$log_path" '{schema_version:$sv,command:"validate",subject:"tail",status:"warn",reason:"dispatch-log absent",log_path:$log}'; return 0; }
      local total=0 valid_count=0 results="[]"
      while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        total=$((total + 1))
        local result
        result="$(validate_one_row "$line")"
        if echo "$result" | jq -e '.valid' >/dev/null 2>&1; then
          valid_count=$((valid_count + 1))
        fi
        results="$(echo "$results" | jq -c --argjson r "$result" '. + [$r]')"
      done < <(tail -n "$tail_n" "$log_path")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --argjson tail_n "$tail_n" \
        --argjson total "$total" --argjson valid "$valid_count" --argjson results "$results" \
        '{schema_version:$sv,command:"validate",subject:"tail",tail_n:$tail_n,
          total_rows:$total,v2_valid_rows:$valid,
          status:(if $total == 0 then "warn" elif $valid == $total then "pass" else "fail" end),
          per_row:$results}'
      ;;
    config)
      local script_dir repo_root log_path mission_anchor
      script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
      repo_root="$(cd "$script_dir/../.." 2>/dev/null && pwd -P)"
      log_path="$repo_root/.flywheel/dispatch-log.jsonl"
      mission_anchor="${FLYWHEEL_MISSION_ANCHOR:-continuous-orchestrator-uptime-self-sustaining-fleet}"
      local repo_valid=false log_valid=false anchor_valid=false
      [[ -d "$repo_root/.flywheel" ]] && repo_valid=true
      [[ -f "$log_path" ]] && log_valid=true
      [[ -n "$mission_anchor" ]] && anchor_valid=true
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        --arg repo "$repo_root" --argjson repo_valid "$repo_valid" \
        --arg log "$log_path" --argjson log_valid "$log_valid" \
        --arg anchor "$mission_anchor" --argjson anchor_valid "$anchor_valid" \
        '{schema_version:$sv,command:"validate",subject:"config",
          status:(if $repo_valid and $log_valid and $anchor_valid then "pass" else "fail" end),
          repo:{value:$repo,valid:$repo_valid},
          dispatch_log:{value:$log,valid:$log_valid},
          mission_anchor:{value:$anchor,valid:$anchor_valid}}'
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"info",reason:"no subject specified",valid_subjects:["row","tail","config"]}'
      ;;
  esac
}

scaffold_cmd_audit() {
  # Tail the runs ledger.
  local runs_log="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/dispatch-log-backfill-v2-runs.jsonl}"
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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$runs_log" --argjson tail_n "$tail_n" \
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
    printf 'ERR: why requires <task_id> argument\n' >&2; return 64
  fi
  # Look up <task_id> in dispatch-log.jsonl; check v2 schema conformance.
  local script_dir repo_root log_path
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
  repo_root="$(cd "$script_dir/../.." 2>/dev/null && pwd -P)"
  log_path="$repo_root/.flywheel/dispatch-log.jsonl"

  if [[ ! -f "$log_path" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --arg log "$log_path" \
      '{schema_version:$sv,command:"why",id:$id,status:"warn",reason:"dispatch-log absent",log_path:$log}'
    return 0
  fi

  set +e
  local row
  row="$(grep -F "\"task_id\":\"$id\"" "$log_path" 2>/dev/null | tail -1)"
  set -e

  if [[ -z "$row" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" \
      '{schema_version:$sv,command:"why",id:$id,status:"not_in_dispatch_log",reason:"task_id not found in dispatch-log.jsonl"}'
    return 0
  fi

  # Check v2 conformance
  local v2_required='["ts","session","task_id","pane","task_file","channel"]'
  local missing
  missing="$(echo "$row" | jq -c --argjson req "$v2_required" --argjson r "$row" '[$req[] | select(. as $f | ($r | has($f) | not))] // []' 2>/dev/null || echo "[]")"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" --argjson row "$row" --argjson missing "$missing" \
    '{schema_version:$sv,command:"why",id:$id,status:"found",
      v2_conformant:($missing | length == 0),
      missing_v2_fields:$missing,
      row:$row}'
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
VERSION="dispatch-log-backfill-v2/v1"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
MODE="dry-run"
JSON_OUT=0
IDEMPOTENCY_KEY=""
RECEIPT_PATH=""
EXPECTED_ANCHOR="${FLYWHEEL_MISSION_ANCHOR:-continuous-orchestrator-uptime-self-sustaining-fleet}"

usage() {
  cat <<'EOF'
usage: dispatch-log-backfill-v2.sh [--repo PATH] [--dry-run|--apply] [--idempotency-key KEY] [--receipt PATH] [--json]

Annotates legacy .flywheel/dispatch-log.jsonl rows into schema_version=2 shape.
Dry-run prints planned row annotations and does not mutate the dispatch log.
Apply requires --idempotency-key and writes an audit receipt.
EOF
}

die() {
  if [ "$JSON_OUT" -eq 1 ]; then
    jq -nc --arg status "error" --arg reason "$1" --arg version "$VERSION" \
      '{schema_version:$version,status:$status,reason:$reason}'
  else
    printf 'ERR: %s\n' "$1" >&2
  fi
  exit "${2:-2}"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo) [ "$#" -ge 2 ] || die "--repo requires PATH"; REPO="$(cd "$2" && pwd -P)"; shift 2 ;;
    --repo=*) REPO="$(cd "${1#*=}" && pwd -P)"; shift ;;
    --dry-run) MODE="dry-run"; shift ;;
    --apply) MODE="apply"; shift ;;
    --idempotency-key) [ "$#" -ge 2 ] || die "--idempotency-key requires KEY"; IDEMPOTENCY_KEY="$2"; shift 2 ;;
    --idempotency-key=*) IDEMPOTENCY_KEY="${1#*=}"; shift ;;
    --receipt) [ "$#" -ge 2 ] || die "--receipt requires PATH"; RECEIPT_PATH="$2"; shift 2 ;;
    --receipt=*) RECEIPT_PATH="${1#*=}"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --help|-h) usage; exit 0 ;;
    --info)
      jq -nc --arg version "$VERSION" --arg repo "$REPO" \
        '{name:"dispatch-log-backfill-v2.sh",version:$version,repo:$repo,default_mode:"dry-run",mutates:"--apply rewrites .flywheel/dispatch-log.jsonl atomically and writes receipt",requires_apply:["--idempotency-key"]}'
      exit 0
      ;;
    *) die "unknown argument: $1" ;;
  esac
done

[ -d "$REPO/.flywheel" ] || die "repo_missing_flywheel"
LOG_PATH="$REPO/.flywheel/dispatch-log.jsonl"
[ -f "$LOG_PATH" ] || die "dispatch_log_missing" 1

if [ "$MODE" = "apply" ] && [ -z "$IDEMPOTENCY_KEY" ]; then
  die "idempotency_key_required"
fi

if [ -z "$RECEIPT_PATH" ]; then
  safe_key="${IDEMPOTENCY_KEY:-dry-run}"
  safe_key="$(printf '%s' "$safe_key" | tr -cs 'A-Za-z0-9._-' '-')"
  RECEIPT_PATH="$REPO/.flywheel/receipts/dispatch-log-backfill-${safe_key}.json"
fi

TMPDIR_BACKFILL="$(mktemp -d -t u1x3.XXXXXX)"
trap 'rm -rf "$TMPDIR_BACKFILL"' EXIT
SUMMARY="$TMPDIR_BACKFILL/summary.json"
NEW_LOG="$TMPDIR_BACKFILL/dispatch-log.jsonl"

python3 - "$LOG_PATH" "$NEW_LOG" "$VERSION" "$MODE" "$IDEMPOTENCY_KEY" "$EXPECTED_ANCHOR" >"$SUMMARY" <<'PY'
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

log_path = Path(sys.argv[1])
new_log_path = Path(sys.argv[2])
version = sys.argv[3]
mode = sys.argv[4]
key = sys.argv[5]
mission_anchor = sys.argv[6]

now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

def is_v2(row):
    return str(row.get("schema_version", "")) == "2"

def first_str(row, *names, default=""):
    for name in names:
        value = row.get(name)
        if value is not None and str(value).strip():
            return str(value).strip()
    return default

def infer_session(row):
    direct = first_str(row, "session", "target_session")
    if direct:
        return direct
    for name in ("dispatched_to", "to", "target"):
        value = first_str(row, name)
        if ":" in value:
            return value.split(":", 1)[0]
    return "legacy"

def infer_pane(row):
    for name in ("pane", "target_pane", "topology_resolved_pane", "callback_pane"):
        value = row.get(name)
        if isinstance(value, int) and not isinstance(value, bool):
            return value
        if isinstance(value, str) and value.isdigit():
            return int(value)
    for name in ("dispatched_to", "to", "target"):
        value = first_str(row, name)
        match = re.search(r":([0-9]+)\b", value)
        if match:
            return int(match.group(1))
    return 0

def short_summary(row, line):
    value = first_str(row, "task_summary", "summary", "task", "bead_id", "bead", default=f"legacy dispatch row {line}")
    return value[:100] or f"legacy dispatch row {line}"

def task_file(row, line):
    value = first_str(row, "task_file", "dispatch_file", "file")
    if value.startswith("/"):
        return value
    return f"/tmp/legacy-dispatch-log-line-{line}.md"

def agent_type(row):
    value = first_str(row, "agent_type").lower()
    if value in {"codex", "claude", "gemini", "other"}:
        return value
    joined = " ".join(str(row.get(name, "")) for name in ("to", "agent", "agent_type", "worker_substrate")).lower()
    if "codex" in joined:
        return "codex"
    if "claude" in joined:
        return "claude"
    if "gemini" in joined:
        return "gemini"
    return "other"

def pane_state_source(row):
    value = first_str(row, "pane_state_source")
    if value in {"ntm_health", "ntm_copy", "raw_capture", "none"}:
        return value
    return "none"

def iso_or_now(row):
    value = first_str(row, "ts", "timestamp", "created_at")
    return value or now

def backfill(row, line):
    session = infer_session(row)
    pane = infer_pane(row)
    task_id = first_str(row, "task_id", "dispatch_id", "id", default=f"legacy-line-{line}")
    updated = dict(row)
    updated.update({
        "schema_version": 2,
        "task_id": task_id,
        "ts": iso_or_now(row),
        "from": first_str(row, "from", default="legacy-dispatch-log"),
        "to": first_str(row, "to", default=f"{session}:{pane}"),
        "pane": pane,
        "session": session,
        "task_summary": short_summary(row, line),
        "task_file": task_file(row, line),
        "agent_type": agent_type(row),
        "pane_state_source": pane_state_source(row),
        "mission_anchor": first_str(row, "mission_anchor", default=mission_anchor),
        "mission_fitness_claim": first_str(row, "mission_fitness_claim", default="legacy backfill: row predates dispatch-log v2 contract"),
        "mission_fitness_class": first_str(row, "mission_fitness_class", default="unknown"),
        "idempotency_token": first_str(row, "idempotency_token", default=f"{key or 'dry-run'}:{task_id}:{line}"),
        "callback_received_at": row.get("callback_received_at", None),
        "dispatch_skill_version": first_str(row, "dispatch_skill_version", default="legacy"),
        "backfilled": True,
        "backfill_schema_version": version,
        "backfill_source_line": line,
    })
    if key:
        updated["backfill_idempotency_key"] = key
    return updated

planned = []
output_lines = []
malformed = 0
already_v2 = 0
already_keyed = 0

for line_no, raw in enumerate(log_path.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
    if not raw.strip():
        output_lines.append(raw)
        continue
    try:
        row = json.loads(raw)
    except json.JSONDecodeError:
        malformed += 1
        output_lines.append(raw)
        continue
    if not isinstance(row, dict):
        output_lines.append(raw)
        continue
    if is_v2(row):
        already_v2 += 1
        output_lines.append(json.dumps(row, sort_keys=True, separators=(",", ":")))
        continue
    if key and row.get("backfill_idempotency_key") == key:
        already_keyed += 1
        output_lines.append(json.dumps(row, sort_keys=True, separators=(",", ":")))
        continue
    new_row = backfill(row, line_no)
    planned.append({
        "line": line_no,
        "task_id": new_row["task_id"],
        "session": new_row["session"],
        "pane": new_row["pane"],
        "dispatch_skill_version": new_row["dispatch_skill_version"],
    })
    output_lines.append(json.dumps(new_row, sort_keys=True, separators=(",", ":")))

new_log_path.write_text("\n".join(output_lines) + ("\n" if output_lines else ""), encoding="utf-8")

summary = {
    "schema_version": version,
    "mode": mode,
    "status": "ok",
    "dispatch_log": str(log_path),
    "checked": len(output_lines),
    "planned_annotations": planned,
    "planned_annotations_count": len(planned),
    "already_v2_count": already_v2,
    "already_keyed_count": already_keyed,
    "malformed_skipped_count": malformed,
    "mutated": False,
}
if key:
    summary["idempotency_key"] = key
print(json.dumps(summary, sort_keys=True))
PY

if [ "$MODE" = "apply" ]; then
  tmp_log="$(mktemp "${LOG_PATH}.XXXXXX")"
  cp "$NEW_LOG" "$tmp_log"
  mv "$tmp_log" "$LOG_PATH"
  mkdir -p "$(dirname "$RECEIPT_PATH")"
  jq --arg ts "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" --arg receipt "$RECEIPT_PATH" \
    '. + {mutated:true, applied_at:$ts, audit_receipt_path:$receipt}' "$SUMMARY" >"$RECEIPT_PATH"
  cp "$RECEIPT_PATH" "$SUMMARY"
fi

if [ "$JSON_OUT" -eq 1 ]; then
  cat "$SUMMARY"
else
  jq -r '
    "mode=\(.mode) planned_annotations=\(.planned_annotations_count) already_v2=\(.already_v2_count) malformed_skipped=\(.malformed_skipped_count) mutated=\(.mutated)",
    (.planned_annotations[]? | "line=\(.line) task_id=\(.task_id) session=\(.session) pane=\(.pane) dispatch_skill_version=\(.dispatch_skill_version)")
  ' "$SUMMARY"
fi
