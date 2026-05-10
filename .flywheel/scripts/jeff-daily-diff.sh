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
# specific logic has been filled in (no scaffold-stub markers remain).

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="jeff-daily-diff/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/jeff-daily-diff-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: jeff-daily-diff.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "jeff-daily-diff.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "jeff-daily-diff.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"jeff-daily-diff.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"jeff-daily-diff.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"jeff-daily-diff.sh doctor --json"}'
)"
  if command -v cli_emit_quickstart >/dev/null; then
    cli_emit_quickstart "$SCAFFOLD_SCHEMA_VERSION" "$steps" "doctor,health,repair"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"quickstart",helper_lib_missing:true}'
  fi
}

scaffold_emit_schema() {
  local surface="${1:-default}"
  case "$surface" in
    doctor)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"doctor",fields:{ts:"ISO8601",status:"pass|warn|fail",checks:"array of {name,status,detail?}"}}'
      ;;
    health)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"health",fields:{ts:"ISO8601",status:"pass|warn|fail",audit_log:"path",last_run_ts:"ISO8601 or null",age_seconds:"int or null",recent_runs:"int (last 20)",total_runs:"int"}}'
      ;;
    repair)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"repair",scopes:["state_dir","audit_log_dir"],contract:{requires_idempotency_key_when_apply:true,refusal_exit_code:3,dry_run_default:true},env:{state_dir:"JEFF_INTEL_STATE_DIR (default ~/.local/state/jeff-intel)",audit_log:"SCAFFOLD_AUDIT_LOG"}}'
      ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"validate",subjects:["repo-name","state-path","audit-row"],contract:{rejects_with_rc1:"on schema violation",repo_name_pattern:"^[A-Za-z0-9_.-]+$",state_path_extensions:[".json",".jsonl"]}}'
      ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"audit",audit_log_env:"SCAFFOLD_AUDIT_LOG",row_shape:{ts:"ISO8601",action:"string"},limit_default:20}'
      ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"why",input:"id (ts OR repo OR run_id)",states:["found","not_found","unavailable"],source:"$SCAFFOLD_AUDIT_LOG"}'
      ;;
    audit-row)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"audit-row",required_fields:["ts","action"],optional_fields:["status","repo","scope","mode","idempotency_key","report_path"]}'
      ;;
    default|*)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surfaces:["doctor","health","repair","validate","audit","why","audit-row"],note:"jeff-daily-diff.sh = bash wrapper around python3 heredoc; produces daily git-diff reports across jeff-corpus repos"}'
      ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — default backward-compatible invocation routes to cmd_run (python3 heredoc): walks $JEFF_DAILY_DIFF_REPO_ROOT (default ~/Developer/jeff-corpus or legacy dicklesworthstone-stack), git diffs each repo since last snapshot, writes report under $JEFF_INTEL_STATE_DIR/reports/\n' ;;
    doctor)   printf 'topic: doctor — substrate probes: bash, jq, mktemp, python3 (load-bearing for heredoc), git available (load-bearing for diff), repo_root_exists (~/Developer/jeff-corpus), state_dir_writable, audit_log_dir_writable\n' ;;
    health)   printf 'topic: health — tails $SCAFFOLD_AUDIT_LOG (default ~/.local/state/flywheel/jeff-daily-diff-runs.jsonl); reports last_run_ts, age_seconds, recent_runs, total_runs; status=warn at >36h stale (daily script with 1.5x grace)\n' ;;
    repair)   printf 'topic: repair --scope <state_dir|audit_log_dir> [--dry-run|--apply --idempotency-key KEY] — apply contract: --apply requires --idempotency-key (rc=3 refusal); scopes: state_dir (mkdir -p $JEFF_INTEL_STATE_DIR), audit_log_dir (mkdir -p $SCAFFOLD_AUDIT_LOG dirname)\n' ;;
    validate) printf 'topic: validate <subject> [PATH|VALUE] — subjects: repo-name (matches ^[A-Za-z0-9_.-]+$ — names of dirs under jeff-corpus root e.g. mcp_agent_mail / beads_rust / frankensqlite), state-path (must end .json or .jsonl — last-diff-run.json / daily-runs.jsonl / reindex-queue.jsonl), audit-row (JSONL ts + action required); rc=1 on schema violation\n' ;;
    audit)    printf 'topic: audit [--limit N] — tail $SCAFFOLD_AUDIT_LOG via cli_emit_audit_tail (path-then-schema positional); default limit=20\n' ;;
    why)      printf 'topic: why <id> — provenance lookup against $SCAFFOLD_AUDIT_LOG; matches against ts/repo/run_id; states: found / not_found / unavailable\n' ;;
    *)        printf 'topics: run | doctor | health | repair | validate | audit | why | quickstart | completion\n' ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh> — emit shell completion script\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "jeff-daily-diff" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "jeff-daily-diff" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  local repo_root="${JEFF_DAILY_DIFF_REPO_ROOT:-$HOME/Developer/jeff-corpus}"
  local legacy_root="$HOME/Developer/dicklesworthstone-stack"
  local state_dir="${JEFF_INTEL_STATE_DIR:-$HOME/.local/state/jeff-intel}"
  local audit_log_dir; audit_log_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"
  local bash_status="fail" jq_status="fail" mktemp_status="fail" python_status="fail" git_status="fail"
  local repo_root_status="fail" state_dir_status="warn" audit_dir_status="fail"
  local effective_root="$repo_root"
  local overall="pass"

  if command -v bash >/dev/null 2>&1; then bash_status="pass"; fi
  if command -v jq >/dev/null 2>&1; then jq_status="pass"; fi
  if command -v mktemp >/dev/null 2>&1; then mktemp_status="pass"; fi
  if command -v python3 >/dev/null 2>&1; then python_status="pass"; fi
  if command -v git >/dev/null 2>&1; then git_status="pass"; fi
  if [[ -d "$repo_root" ]]; then
    repo_root_status="pass"
  elif [[ -d "$legacy_root" ]]; then
    repo_root_status="warn"; effective_root="$legacy_root"
  fi
  if [[ -d "$state_dir" && -w "$state_dir" ]]; then state_dir_status="pass"; fi
  if [[ -d "$audit_log_dir" && -w "$audit_log_dir" ]]; then audit_dir_status="pass"; fi

  for st in "$bash_status" "$jq_status" "$mktemp_status" "$python_status" "$git_status"; do
    if [[ "$st" == "fail" ]]; then overall="fail"; fi
  done
  if [[ "$overall" == "pass" ]]; then
    for st in "$repo_root_status" "$state_dir_status" "$audit_dir_status"; do
      if [[ "$st" == "warn" || "$st" == "fail" ]]; then overall="warn"; fi
    done
  fi

  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg ts "$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg overall "$overall" \
    --arg bash_status "$bash_status" --arg jq_status "$jq_status" \
    --arg mktemp_status "$mktemp_status" --arg python_status "$python_status" \
    --arg git_status "$git_status" \
    --arg repo_root "$effective_root" --arg repo_root_status "$repo_root_status" \
    --arg state_dir "$state_dir" --arg state_dir_status "$state_dir_status" \
    --arg audit_dir "$audit_log_dir" --arg audit_dir_status "$audit_dir_status" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$overall,
      checks:[
        {name:"bash_available",status:$bash_status},
        {name:"jq_available",status:$jq_status},
        {name:"mktemp_available",status:$mktemp_status},
        {name:"python3_available",status:$python_status},
        {name:"git_available",status:$git_status},
        {name:"repo_root_exists",status:$repo_root_status,path:$repo_root},
        {name:"state_dir_writable",status:$state_dir_status,path:$state_dir},
        {name:"audit_log_dir_writable",status:$audit_dir_status,path:$audit_dir}
      ]
    }'
}

scaffold_cmd_health() {
  local audit_log="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/jeff-daily-diff-runs.jsonl}"
  local now ts last_run_ts="" age_seconds total_runs=0 recent_runs=0 status="pass"
  local stale_threshold="${JEFF_DAILY_DIFF_HEALTH_STALE_THRESHOLD_SECONDS:-129600}"
  ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [[ ! -r "$audit_log" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$audit_log" \
      '{schema_version:$sv,command:"health",ts:$ts,status:"warn",audit_log:$log,reason:"audit_log_missing",last_run_ts:null,age_seconds:null,recent_runs:0,total_runs:0}'
    return 0
  fi
  total_runs="$(wc -l < "$audit_log" 2>/dev/null | tr -d ' ' || echo 0)"
  recent_runs="$(tail -20 "$audit_log" 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
  last_run_ts="$(tail -1 "$audit_log" 2>/dev/null | jq -r '.ts // empty' 2>/dev/null || true)"
  if [[ -n "$last_run_ts" ]]; then
    now="$(date -u +%s)"
    local last_epoch
    last_epoch="$(date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$last_run_ts" +%s 2>/dev/null \
                  || date -u -d "$last_run_ts" +%s 2>/dev/null \
                  || echo 0)"
    age_seconds=$((now - last_epoch))
    if [[ "$age_seconds" -gt "$stale_threshold" ]]; then status="warn"; fi
  else
    age_seconds=null
    status="warn"
  fi
  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg status "$status" \
    --arg log "$audit_log" --arg last_run_ts "$last_run_ts" \
    --argjson age "${age_seconds:-null}" \
    --argjson total "$total_runs" --argjson recent "$recent_runs" \
    --argjson stale "$stale_threshold" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,audit_log:$log,
      last_run_ts:(if $last_run_ts == "" then null else $last_run_ts end),
      age_seconds:$age, recent_runs:$recent, total_runs:$total,
      stale_threshold_seconds:$stale}'
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
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  case "$scope" in
    state_dir)
      local target="${JEFF_INTEL_STATE_DIR:-$HOME/.local/state/jeff-intel}"
      local existed="true"
      if [[ ! -d "$target" ]]; then existed="false"; fi
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$target"
        cli_audit_append --action repair --status apply --scope state_dir \
          --idempotency-key "$idem_key" --target "$target" >/dev/null 2>&1 || true
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" --arg existed "$existed" \
        '{schema_version:$sv,command:"repair",status:"ok",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed_before:($existed == "true")}'
      ;;
    audit_log_dir)
      local target; target="$(dirname "$SCAFFOLD_AUDIT_LOG")"
      local existed="true"
      if [[ ! -d "$target" ]]; then existed="false"; fi
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$target"
        cli_audit_append --action repair --status apply --scope audit_log_dir \
          --idempotency-key "$idem_key" --target "$target" >/dev/null 2>&1 || true
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" --arg existed "$existed" \
        '{schema_version:$sv,command:"repair",status:"ok",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed_before:($existed == "true")}'
      ;;
    "")
      printf 'ERR: repair requires --scope <state_dir|audit_log_dir>\n' >&2
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",scope:$scope,reason:"unknown_scope",valid_scopes:["state_dir","audit_log_dir"]}'
      return 64 ;;
  esac
}

scaffold_cmd_validate() {
  local subject="${1:-}"; shift || true
  local arg="${1:-}"
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  case "$subject" in
    repo-name)
      if [[ -z "$arg" ]]; then
        printf 'ERR: validate repo-name requires VALUE arg\n' >&2; return 64
      fi
      if [[ "$arg" =~ ^[A-Za-z0-9_.-]+$ ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg name "$arg" \
          '{schema_version:$sv,command:"validate",subject:"repo-name",ts:$ts,status:"ok",value:$name}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg name "$arg" \
          '{schema_version:$sv,command:"validate",subject:"repo-name",ts:$ts,status:"reject",value:$name,reason:"pattern_mismatch",pattern:"^[A-Za-z0-9_.-]+$"}'
        return 1
      fi
      ;;
    state-path)
      if [[ -z "$arg" ]]; then
        printf 'ERR: validate state-path requires VALUE arg\n' >&2; return 64
      fi
      if [[ "$arg" == *.json || "$arg" == *.jsonl ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg p "$arg" \
          '{schema_version:$sv,command:"validate",subject:"state-path",ts:$ts,status:"ok",value:$p}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg p "$arg" \
          '{schema_version:$sv,command:"validate",subject:"state-path",ts:$ts,status:"reject",value:$p,reason:"unsupported_extension",valid_extensions:[".json",".jsonl"]}'
        return 1
      fi
      ;;
    audit-row)
      if [[ -z "$arg" || ! -r "$arg" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg path "$arg" \
          '{schema_version:$sv,command:"validate",subject:"audit-row",ts:$ts,status:"reject",path:$path,reason:"file_not_readable"}'
        return 1
      fi
      local bad; bad="$(jq -c 'select((.ts // empty) == "" or (.action // empty) == "") | {missing: ([(if (.ts // empty) == "" then "ts" else empty end), (if (.action // empty) == "" then "action" else empty end)])}' "$arg" 2>/dev/null | head -5 || true)"
      if [[ -n "$bad" ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg path "$arg" --arg bad "$bad" \
          '{schema_version:$sv,command:"validate",subject:"audit-row",ts:$ts,status:"reject",path:$path,reason:"missing_required_fields",sample:$bad}'
        return 1
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg path "$arg" \
        '{schema_version:$sv,command:"validate",subject:"audit-row",ts:$ts,status:"ok",path:$path}'
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"refused",reason:"missing_subject",valid_subjects:["repo-name","state-path","audit-row"]}'
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg subj "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",subject:$subj,reason:"unknown_subject",valid_subjects:["repo-name","state-path","audit-row"]}'
      return 64 ;;
  esac
}

scaffold_cmd_audit() {
  local limit=20
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) scaffold_emit_topic_help audit; return 0 ;;
      --limit) limit="${2:-20}"; shift 2 ;;
      --limit=*) limit="${1#--limit=}"; shift ;;
      --json) shift ;;
      *) printf 'ERR: unknown audit arg %s\n' "$1" >&2; return 64 ;;
    esac
  done
  if command -v cli_emit_audit_tail >/dev/null; then
    cli_emit_audit_tail "$SCAFFOLD_AUDIT_LOG" "$SCAFFOLD_SCHEMA_VERSION" "$limit"
  else
    local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
    if [[ ! -r "$SCAFFOLD_AUDIT_LOG" ]]; then
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$SCAFFOLD_AUDIT_LOG" \
        '{schema_version:$sv,command:"audit",ts:$ts,status:"empty",audit_log:$log,reason:"audit_log_missing",rows:[]}'
      return 0
    fi
    local rows; rows="$(tail -n "$limit" "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | jq -s . 2>/dev/null || echo '[]')"
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$SCAFFOLD_AUDIT_LOG" \
      --argjson rows "$rows" --argjson limit "$limit" \
      '{schema_version:$sv,command:"audit",ts:$ts,status:"ok",audit_log:$log,limit:$limit,rows:$rows}'
  fi
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id> argument\n' >&2; return 64
  fi
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [[ ! -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"unavailable",reason:"audit_log_missing",audit_log:$log}'
    return 0
  fi
  local match; match="$(jq -c --arg id "$id" 'select(.ts == $id or .repo == $id or (.run_id // "") == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | head -1 || true)"
  if [[ -z "$match" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"not_found",audit_log:$log,searched_keys:["ts","repo","run_id"]}'
    return 0
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" --argjson row "$match" \
    '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"found",audit_log:$log,row:$row}'
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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
export JEFF_DAILY_DIFF_SCRIPT_DIR="$SCRIPT_DIR"

exec python3 - "$@" <<'PY'
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

VERSION = "jeff-daily-diff.v1"


def utc_now():
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())


def day_from_iso(ts):
    return ts[:10]


def default_repo_root():
    env = os.environ.get("JEFF_DAILY_DIFF_REPO_ROOT")
    if env:
        return Path(env).expanduser()
    canonical = Path.home() / "Developer/jeff-corpus"
    legacy = Path.home() / "Developer/dicklesworthstone-stack"
    return canonical if canonical.exists() else legacy


def run(cmd, cwd=None, timeout=300):
    try:
        proc = subprocess.run(
            cmd,
            cwd=str(cwd) if cwd else None,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=timeout,
            check=False,
        )
        return proc.returncode, proc.stdout, proc.stderr
    except subprocess.TimeoutExpired as exc:
        return 124, exc.stdout or "", exc.stderr or "timeout"


def git(repo, *args, timeout=300):
    return run(["git", "-C", str(repo), *args], timeout=timeout)


def load_json(path, default):
    if not path.exists():
        return default
    try:
        return json.loads(path.read_text())
    except Exception:
        return default


def atomic_write_json(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(prefix=path.name + ".", suffix=".tmp", dir=str(path.parent))
    with os.fdopen(fd, "w") as fh:
        json.dump(data, fh, indent=2, sort_keys=True)
        fh.write("\n")
        fh.flush()
        os.fsync(fh.fileno())
    Path(tmp).replace(path)


def append_jsonl(path, row):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a") as fh:
        fh.write(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n")


def discover_repos(root, max_repos=None):
    if not root.exists():
        return []
    repos = [
        p for p in sorted(root.iterdir(), key=lambda item: item.name.lower())
        if p.is_dir() and not p.name.startswith(".") and (p / ".git").exists()
    ]
    return repos[:max_repos] if max_repos else repos


def commit_lines(repo, previous, head):
    if not previous or previous == head:
        return []
    rc, out, _ = git(repo, "log", "--oneline", f"{previous}..{head}", "--")
    if rc != 0:
        rc, out, _ = git(repo, "log", "--oneline", "--max-count=20", "--")
    return [line for line in out.splitlines() if line.strip()]


def stat_text(repo, previous, head, since, out_dir):
    out_dir.mkdir(parents=True, exist_ok=True)
    path = out_dir / f"{repo.name}.txt"
    if previous and previous != head:
        rc, out, err = git(repo, "log", "--stat", f"{previous}..{head}", "--")
    else:
        rc, out, err = git(repo, "log", "--stat", f"--since={since}", "--")
    path.write_text(out if rc == 0 else err)
    return path


def sha256_text(text):
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def read_text_source(fixture, command, url, timeout=30):
    if fixture:
        path = Path(fixture).expanduser()
        return {"status": "pass", "text": path.read_text() if path.exists() else "", "source": str(path)}
    if command:
        rc, out, err = run(command, timeout=timeout)
        return {"status": "pass" if rc == 0 else "fail", "text": out, "source": " ".join(command), "error": err.strip()}
    if url:
        curl = shutil.which("curl")
        if not curl:
            return {"status": "skipped", "text": "", "source": url, "error": "curl_missing"}
        rc, out, err = run([curl, "-fsSL", "--max-time", str(timeout), url], timeout=timeout + 5)
        return {"status": "pass" if rc == 0 else "fail", "text": out, "source": url, "error": err.strip()}
    return {"status": "skipped", "text": "", "source": "none"}


def rss_titles(text):
    raw_titles = re.findall(r"<title>(.*?)</title>", text, flags=re.I | re.S)
    cleaned = []
    for raw in raw_titles:
        title = re.sub(r"^<!\[CDATA\[|\]\]>$", "", raw.strip())
        title = re.sub(r"\s+", " ", title).strip()
        if title:
            cleaned.append(title)
    return cleaned[:20]


def script_path(name, env_name):
    override = os.environ.get(env_name)
    if override:
        return Path(override).expanduser()
    script_dir = Path(os.environ.get("JEFF_DAILY_DIFF_SCRIPT_DIR", ".")).expanduser()
    return script_dir / name


def diff_shortstat(repo, previous, head):
    if previous and previous != head:
        rc, out, _ = git(repo, "diff", "--shortstat", f"{previous}..{head}", "--")
    else:
        rc, out, _ = git(repo, "show", "--shortstat", "--format=", head, "--")
    if rc != 0:
        return {"files_changed": 0, "insertions": 0, "deletions": 0}
    files = re.search(r"(\d+) files? changed", out)
    insertions = re.search(r"(\d+) insertions?\(\+\)", out)
    deletions = re.search(r"(\d+) deletions?\(-\)", out)
    return {
        "files_changed": int(files.group(1)) if files else 0,
        "insertions": int(insertions.group(1)) if insertions else 0,
        "deletions": int(deletions.group(1)) if deletions else 0,
    }


def verdict_for(repo_name, commits, diff_path):
    verdict_script = script_path("jeff-verdict-heuristic.sh", "JEFF_VERDICT_HEURISTIC_BIN")
    if not verdict_script.exists():
        return {
            "verdict": "NEED_RESEARCH",
            "reason": f"verdict script missing: {verdict_script}",
            "suggested_action": "monitor",
            "matched": [],
        }
    cmd = [str(verdict_script), "--repo", repo_name, "--diff", str(diff_path), "--json"]
    for commit in commits[:20]:
        cmd.extend(["--commit", commit])
    rc, out, err = run(cmd, timeout=30)
    if rc != 0:
        return {
            "verdict": "NEED_RESEARCH",
            "reason": f"verdict script failed: {err.strip()[:160]}",
            "suggested_action": "monitor",
            "matched": [],
        }
    try:
        payload = json.loads(out)
    except Exception:
        return {
            "verdict": "NEED_RESEARCH",
            "reason": "verdict script returned invalid JSON",
            "suggested_action": "monitor",
            "matched": [],
        }
    return {
        "verdict": payload.get("verdict", "NEED_RESEARCH"),
        "reason": payload.get("reason", "needs human review"),
        "suggested_action": payload.get("suggested_action", "monitor"),
        "matched": payload.get("matched", []),
    }


def verdict_for_text(source_name, text):
    verdict_script = script_path("jeff-verdict-heuristic.sh", "JEFF_VERDICT_HEURISTIC_BIN")
    if not verdict_script.exists():
        return {
            "verdict": "NEED_RESEARCH",
            "reason": f"verdict script missing: {verdict_script}",
            "suggested_action": "monitor",
            "matched": [],
        }
    rc, out, err = run([str(verdict_script), "--repo", source_name, "--text", text, "--json"], timeout=30)
    if rc != 0:
        return {
            "verdict": "NEED_RESEARCH",
            "reason": f"verdict script failed: {err.strip()[:160]}",
            "suggested_action": "monitor",
            "matched": [],
        }
    try:
        payload = json.loads(out)
    except Exception:
        return {
            "verdict": "NEED_RESEARCH",
            "reason": "verdict script returned invalid JSON",
            "suggested_action": "monitor",
            "matched": [],
        }
    return {
        "verdict": payload.get("verdict", "NEED_RESEARCH"),
        "reason": payload.get("reason", "needs human review"),
        "suggested_action": payload.get("suggested_action", "monitor"),
        "matched": payload.get("matched", []),
    }


def text_blocks(text):
    blocks = [part.strip() for part in re.split(r"(?m)^---\s*$", text) if part.strip()]
    if len(blocks) > 1:
        return blocks
    lines = [line.strip() for line in text.splitlines() if line.strip()]
    return ["\n".join(lines[idx:idx + 3]) for idx in range(0, len(lines), 3)]


def source_ref(source_name, index, text):
    match = re.search(r"https?://\S+", text)
    if match:
        return match.group(0).rstrip(").,")
    id_match = re.search(r"\bID:\s*`?([0-9]+)`?", text)
    if id_match:
        return f"{source_name}#{id_match.group(1)}"
    return f"{source_name}#{index}"


def signal_class(matched):
    text = " ".join(matched)
    labels = [
        ("agent-mail", r"agent|mail|mcp"),
        ("beads", r"beads?"),
        ("socraticode", r"socraticode"),
        ("dcg", r"dcg"),
        ("cass", r"cass"),
        ("ntm", r"ntm"),
        ("flywheel", r"flywheel"),
        ("skills", r"skills?"),
        ("structured-concurrency", r"structured|quiescence|asupersync"),
        ("callback-contract", r"callback"),
        ("doctor-surface", r"doctor"),
        ("cli-surface", r"\bcli\b"),
    ]
    lowered = text.lower()
    for label, pattern in labels:
        if re.search(pattern, lowered):
            return label
    return "review"


def actionable_signals(source_name, text, limit=12):
    rows = []
    for index, block in enumerate(text_blocks(text), start=1):
        verdict = verdict_for_text(source_name, block)
        if verdict["verdict"] not in {"YES_ADOPT", "YES_ADAPT", "NEED_RESEARCH"}:
            continue
        if verdict["verdict"] == "NEED_RESEARCH" and not verdict.get("matched"):
            continue
        rows.append({
            "source": source_name,
            "source_ref": source_ref(source_name, index, block),
            "signal_class": signal_class(verdict.get("matched", [])),
            "verdict": verdict["verdict"],
            "reason": verdict["reason"],
            "apply_to_flywheel": verdict["suggested_action"],
            "matched": verdict.get("matched", []),
            "evidence": re.sub(r"\s+", " ", block).strip()[:240],
        })
        if len(rows) >= limit:
            break
    return rows


def write_report(path, tmp_path, payload, dry_run):
    template_script = script_path("jeff-report-template.sh", "JEFF_REPORT_TEMPLATE_BIN")
    if not template_script.exists():
        raise RuntimeError(f"report template missing: {template_script}")
    payload_path = tmp_path.with_suffix(".input.json")
    payload_path.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n")
    rc, out, err = run([str(template_script), "--input", str(payload_path), "--output", str(tmp_path), "--json"], timeout=60)
    if rc != 0:
        raise RuntimeError(f"report template failed rc={rc}: {err.strip() or out.strip()}")
    if not dry_run:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(tmp_path.read_text())


def info(args):
    return {
        "schema_version": "jeff-daily-diff/info/v1",
        "version": VERSION,
        "status": "pass",
        "repo_root": str(args.repo_root),
        "state_file": str(args.state_file),
        "reports_dir": str(args.reports_dir),
        "runs_ledger": str(args.runs_ledger),
        "reindex_queue": str(args.reindex_queue),
        "dry_run_supported": True,
    }


def schema():
    return {
        "schema_version": "jeff-daily-diff/schema/v1",
        "status": "pass",
        "receipt_required": ["status", "changed_repo_count", "reindex_queued_count", "report_path", "state_file"],
        "state_file": "jeff-daily-diff-state/v1",
        "report_sections": [
            "Run metadata",
            "New Commits (by repo)",
            "New Releases",
            "New Tweets (doodlestein)",
            "New Blog Posts",
            "Re-indexed (socraticode)",
            "Aggregate \"What can we learn\" digest",
        ],
        "verdict_enum": ["YES_ADOPT", "YES_ADAPT", "NO_NOT_OUR_DOMAIN", "NEED_RESEARCH"],
    }


def run_daily(args):
    start = time.time()
    now = args.now or utc_now()
    state = load_json(args.state_file, {"schema_version": "jeff-daily-diff-state/v1", "repos": {}, "blog": {}, "x": {}})
    state.setdefault("repos", {})
    repos = discover_repos(args.repo_root, args.max_repos)
    tmp_diff = Path(tempfile.mkdtemp(prefix="jeff-diff-", dir=args.tmp_dir))
    changed, queued, errors, processed, releases = [], [], [], [], []

    for repo in repos:
        name = repo.name
        prev = state["repos"].get(name, {}).get("last_seen_sha")
        fetch_rc = 0
        if not args.dry_run and not args.skip_fetch:
            fetch_rc, _, fetch_err = git(repo, "fetch", "--all", "--tags", "--prune", timeout=args.fetch_timeout)
            if fetch_rc != 0:
                errors.append({"repo": name, "code": "git_fetch_failed", "detail": fetch_err.strip()[:300]})
        rc, head, err = git(repo, "rev-parse", "HEAD")
        if rc != 0:
            errors.append({"repo": name, "code": "git_head_failed", "detail": err.strip()[:300]})
            continue
        head = head.strip()
        rc, tag_out, _ = git(repo, "tag", "--list")
        tags = sorted([line for line in tag_out.splitlines() if line.strip()]) if rc == 0 else []
        prior_tags = set(state["repos"].get(name, {}).get("last_seen_tags", []))
        new_tags = [tag for tag in tags if tag not in prior_tags]
        commits = commit_lines(repo, prev, head)
        if commits:
            diff_path = stat_text(repo, prev, head, state.get("last_run_ts", "1970-01-01T00:00:00Z"), tmp_diff)
            stats = diff_shortstat(repo, prev, head)
            verdict = verdict_for(name, commits, diff_path)
            changed.append({
                "repo": name,
                "path": str(repo),
                "previous_sha": prev or "",
                "head_sha": head,
                "commit_count": len(commits),
                "commits": commits,
                "diff_path": str(diff_path),
                **stats,
                **verdict,
            })
            queued.append(name)
            if not args.dry_run:
                append_jsonl(args.reindex_queue, {"schema_version": "jeff-daily-reindex-queue/v1", "ts": now, "repo": name, "path": str(repo), "old_sha": prev, "new_sha": head, "reason": "new_commits"})
        for tag in new_tags:
            releases.append(f"{name}: {tag}")
        processed.append(name)
        if not args.dry_run and fetch_rc == 0:
            state["repos"][name] = {"path": str(repo), "last_seen_sha": head, "last_seen_tags": tags, "last_success_ts": now}

    x_result = read_text_source(args.x_fixture, args.x_command, None)
    if x_result["status"] == "fail":
        errors.append({"repo": "x:doodlestein", "code": "x_capture_failed"})
    rss_result = read_text_source(args.rss_fixture, None, args.rss_url)
    blog_hash = sha256_text(rss_result["text"])
    previous_blog_hash = state.get("blog", {}).get("last_hash")
    blog_titles = rss_titles(rss_result["text"]) if rss_result["status"] == "pass" and blog_hash != previous_blog_hash else []
    if rss_result["status"] == "fail":
        errors.append({"repo": "jeffreyemanuel.com", "code": "rss_capture_failed"})

    report_name = f"jeff-report-{day_from_iso(now)}.md"
    report_path = args.reports_dir / report_name
    tmp_report = Path(args.tmp_dir) / report_name
    duration_sec = max(0, round(time.time() - start, 3))
    tweet_lines = [line for line in x_result["text"].splitlines() if line.strip()]
    signals = actionable_signals("x:doodlestein", x_result["text"])
    if blog_titles:
        signals.extend(actionable_signals("jeffreyemanuel.com", "\n".join(blog_titles)))
    report_payload = {
        "schema_version": "jeff-daily-report/input/v1",
        "report_date": day_from_iso(now),
        "run_metadata": {
            "run_ts": now,
            "duration_sec": duration_sec,
            "repos_checked": len(repos),
            "repos_with_changes": len(changed),
            "new_commits_total": sum(item["commit_count"] for item in changed),
            "new_tweets": len(tweet_lines),
            "new_blog_posts": len(blog_titles),
            "re_indexed_repos": len(queued),
        },
        "repo_root": str(args.repo_root),
        "changed": changed,
        "releases": releases,
        "tweets": tweet_lines,
        "actionable_signals": signals,
        "blog_titles": blog_titles,
        "reindexed": [{"repo": repo, "new_chunks_indexed": "queued"} for repo in queued],
        "errors": errors,
        "dry_run": args.dry_run,
        "skip_fetch": args.skip_fetch,
    }
    write_report(report_path, tmp_report, report_payload, args.dry_run)

    if not args.dry_run:
        state["schema_version"] = "jeff-daily-diff-state/v1"
        state["last_run_ts"] = now
        state["blog"] = {"last_hash": blog_hash, "last_checked_ts": now}
        state["x"] = {"last_hash": sha256_text(x_result["text"]), "last_checked_ts": now}
        atomic_write_json(args.state_file, state)

    receipt = {
        "schema_version": "jeff-daily-diff-run/v1",
        "version": VERSION,
        "status": "pass" if repos else "fail",
        "ts": now,
        "dry_run": args.dry_run,
        "skip_fetch": args.skip_fetch,
        "repo_root": str(args.repo_root),
        "repo_count": len(repos),
        "processed_repo_count": len(processed),
        "changed_repo_count": len(changed),
        "actionable_signal_count": len(signals),
        "reindex_queued_count": len(queued),
        "new_release_count": len(releases),
        "sources_failed": len(errors),
        "report_path": str(report_path if not args.dry_run else tmp_report),
        "tmp_report_path": str(tmp_report),
        "state_file": str(args.state_file),
        "runs_ledger": str(args.runs_ledger),
        "reindex_queue": str(args.reindex_queue),
        "errors": errors,
    }
    if not args.dry_run:
        append_jsonl(args.runs_ledger, receipt)
    return receipt


def parse_args():
    parser = argparse.ArgumentParser(description="Build daily Jeff corpus diffs and report.")
    parser.add_argument("--repo-root", type=Path, default=default_repo_root())
    parser.add_argument("--state-dir", type=Path, default=Path(os.environ.get("JEFF_INTEL_STATE_DIR", str(Path.home() / ".local/state/jeff-intel"))).expanduser())
    parser.add_argument("--state-file", type=Path)
    parser.add_argument("--reports-dir", type=Path)
    parser.add_argument("--runs-ledger", type=Path)
    parser.add_argument("--reindex-queue", type=Path)
    parser.add_argument("--tmp-dir", type=Path, default=Path(os.environ.get("JEFF_DAILY_DIFF_TMP_DIR", "/tmp")))
    parser.add_argument("--x-fixture")
    parser.add_argument("--rss-fixture")
    parser.add_argument("--rss-url", default=os.environ.get("JEFF_DAILY_DIFF_RSS_URL", "https://jeffreyemanuel.com/rss.xml"))
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--skip-fetch", action="store_true", default=os.environ.get("JEFF_DAILY_DIFF_SKIP_FETCH", "") == "1")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--now", default=os.environ.get("JEFF_DAILY_DIFF_NOW", ""))
    parser.add_argument("--max-repos", type=int)
    parser.add_argument("--fetch-timeout", type=int, default=30)
    parser.add_argument("--info", action="store_true")
    parser.add_argument("--schema", action="store_true")
    parser.add_argument("--examples", action="store_true")
    parser.add_argument("--doctor", action="store_true")
    args = parser.parse_args()
    args.repo_root = args.repo_root.expanduser()
    args.state_file = args.state_file or args.state_dir / "last-diff-run.json"
    args.reports_dir = args.reports_dir or args.state_dir / "reports"
    args.runs_ledger = args.runs_ledger or args.state_dir / "daily-runs.jsonl"
    args.reindex_queue = args.reindex_queue or args.state_dir / "reindex-queue.jsonl"
    x_cmd = os.environ.get("JEFF_DAILY_DIFF_X_COMMAND")
    args.x_command = x_cmd.split() if x_cmd else (["x-cli", "-md", "user", "timeline", "doodlestein", "--max", "20"] if shutil.which("x-cli") else None)
    return args


args = parse_args()
if args.examples:
    print("jeff-daily-diff.sh --dry-run --json")
    print("JEFF_INTEL_STATE_DIR=/tmp/jeff-state jeff-daily-diff.sh --repo-root /Users/josh/Developer/jeff-corpus --json")
    sys.exit(0)
if args.info:
    payload = info(args)
elif args.schema:
    payload = schema()
elif args.doctor:
    payload = info(args) | {"mode": "doctor", "status": "pass" if args.repo_root.exists() else "fail", "repo_root_exists": args.repo_root.exists()}
else:
    payload = run_daily(args)

if args.json or args.info or args.schema or args.doctor:
    print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
else:
    print(f"{payload['status']} changed={payload.get('changed_repo_count', 0)} report={payload.get('report_path', 'none')}")
sys.exit(0 if payload.get("status") == "pass" else 1)
PY
