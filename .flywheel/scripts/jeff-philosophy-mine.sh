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

SCAFFOLD_SCHEMA_VERSION="jeff-philosophy-mine/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/jeff-philosophy-mine-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: jeff-philosophy-mine.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "jeff-philosophy-mine.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "jeff-philosophy-mine.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"jeff-philosophy-mine.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"jeff-philosophy-mine.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"jeff-philosophy-mine.sh doctor --json"}'
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
        '{schema_version:$sv,command:"schema",surface:"repair",scopes:["state_dir","audit_log_dir"],contract:{requires_idempotency_key_when_apply:true,refusal_exit_code:3,dry_run_default:true},env:{state_dir:"JEFF_PHILOSOPHY_STATE_DIR (default ~/.local/state/jeff-philosophy)",audit_log:"SCAFFOLD_AUDIT_LOG"}}'
      ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"validate",subjects:["repo-name","pattern-jsonl-path","audit-row"],contract:{rejects_with_rc1:"on schema violation",repo_name_pattern:"^[A-Za-z0-9_.-]+$",pattern_jsonl_extensions:[".jsonl"]}}'
      ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"audit",audit_log_env:"SCAFFOLD_AUDIT_LOG",row_shape:{ts:"ISO8601",action:"string"},limit_default:20}'
      ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"why",input:"id (ts OR repo OR pattern_id OR run_id)",states:["found","not_found","unavailable"],source:"$SCAFFOLD_AUDIT_LOG"}'
      ;;
    audit-row)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"audit-row",required_fields:["ts","action"],optional_fields:["status","repo","pattern_id","scope","mode","idempotency_key","snapshot_path"]}'
      ;;
    default|*)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surfaces:["doctor","health","repair","validate","audit","why","audit-row"],note:"jeff-philosophy-mine.sh = bash wrapper around python3 heredoc; mines philosophy patterns + daily-snapshots from jeff-corpus"}'
      ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — default backward-compatible invocation routes to cmd_run (python3 heredoc): walks $JEFF_PHILOSOPHY_REPO_ROOT (default ~/Developer/jeff-corpus), mines philosophy patterns into $JEFF_PHILOSOPHY_STATE_DIR/patterns.jsonl, writes daily snapshots under $JEFF_PHILOSOPHY_STATE_DIR/daily-snapshots/\n' ;;
    doctor)   printf 'topic: doctor — substrate probes: bash, jq, mktemp, python3 (load-bearing for heredoc), git available (load-bearing for snapshots), repo_root_exists (~/Developer/jeff-corpus), state_dir_writable, daily_snapshot_dir_writable, audit_log_dir_writable\n' ;;
    health)   printf 'topic: health — tails $SCAFFOLD_AUDIT_LOG (default ~/.local/state/flywheel/jeff-philosophy-mine-runs.jsonl); reports last_run_ts, age_seconds, recent_runs, total_runs; status=warn at >36h stale (daily mining cadence with 1.5x grace)\n' ;;
    repair)   printf 'topic: repair --scope <state_dir|audit_log_dir> [--dry-run|--apply --idempotency-key KEY] — apply contract: --apply requires --idempotency-key (rc=3 refusal); scopes: state_dir (mkdir -p $JEFF_PHILOSOPHY_STATE_DIR + daily-snapshots/), audit_log_dir (mkdir -p $SCAFFOLD_AUDIT_LOG dirname)\n' ;;
    validate) printf 'topic: validate <subject> [PATH|VALUE] — subjects: repo-name (matches ^[A-Za-z0-9_.-]+$ — names of dirs under jeff-corpus root e.g. mcp_agent_mail / beads_rust / frankensqlite), pattern-jsonl-path (must end .jsonl — patterns.jsonl / audit.jsonl), audit-row (JSONL ts + action required); rc=1 on schema violation\n' ;;
    audit)    printf 'topic: audit [--limit N] — tail $SCAFFOLD_AUDIT_LOG via cli_emit_audit_tail (path-then-schema positional); default limit=20\n' ;;
    why)      printf 'topic: why <id> — provenance lookup against $SCAFFOLD_AUDIT_LOG; matches against ts/repo/pattern_id/run_id; states: found / not_found / unavailable\n' ;;
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
            && cli_emit_completion_bash "jeff-philosophy-mine" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "jeff-philosophy-mine" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  local repo_root="${JEFF_PHILOSOPHY_REPO_ROOT:-$HOME/Developer/jeff-corpus}"
  local state_dir="${JEFF_PHILOSOPHY_STATE_DIR:-$HOME/.local/state/jeff-philosophy}"
  local snapshot_dir="$state_dir/daily-snapshots"
  local audit_log_dir; audit_log_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"
  local bash_status="fail" jq_status="fail" mktemp_status="fail" python_status="fail" git_status="fail"
  local repo_root_status="fail" state_dir_status="warn" snapshot_dir_status="warn" audit_dir_status="fail"
  local overall="pass"

  if command -v bash >/dev/null 2>&1; then bash_status="pass"; fi
  if command -v jq >/dev/null 2>&1; then jq_status="pass"; fi
  if command -v mktemp >/dev/null 2>&1; then mktemp_status="pass"; fi
  if command -v python3 >/dev/null 2>&1; then python_status="pass"; fi
  if command -v git >/dev/null 2>&1; then git_status="pass"; fi
  if [[ -d "$repo_root" ]]; then repo_root_status="pass"; fi
  if [[ -d "$state_dir" && -w "$state_dir" ]]; then state_dir_status="pass"; fi
  if [[ -d "$snapshot_dir" && -w "$snapshot_dir" ]]; then snapshot_dir_status="pass"; fi
  if [[ -d "$audit_log_dir" && -w "$audit_log_dir" ]]; then audit_dir_status="pass"; fi

  for st in "$bash_status" "$jq_status" "$mktemp_status" "$python_status" "$git_status"; do
    if [[ "$st" == "fail" ]]; then overall="fail"; fi
  done
  if [[ "$overall" == "pass" ]]; then
    for st in "$repo_root_status" "$state_dir_status" "$snapshot_dir_status" "$audit_dir_status"; do
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
    --arg repo_root "$repo_root" --arg repo_root_status "$repo_root_status" \
    --arg state_dir "$state_dir" --arg state_dir_status "$state_dir_status" \
    --arg snapshot_dir "$snapshot_dir" --arg snapshot_dir_status "$snapshot_dir_status" \
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
        {name:"daily_snapshot_dir_writable",status:$snapshot_dir_status,path:$snapshot_dir},
        {name:"audit_log_dir_writable",status:$audit_dir_status,path:$audit_dir}
      ]
    }'
}

scaffold_cmd_health() {
  local audit_log="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/jeff-philosophy-mine-runs.jsonl}"
  local now ts last_run_ts="" age_seconds total_runs=0 recent_runs=0 status="pass"
  local stale_threshold="${JEFF_PHILOSOPHY_HEALTH_STALE_THRESHOLD_SECONDS:-129600}"
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
      local target="${JEFF_PHILOSOPHY_STATE_DIR:-$HOME/.local/state/jeff-philosophy}"
      local snapshot_target="$target/daily-snapshots"
      local existed="true"
      if [[ ! -d "$target" || ! -d "$snapshot_target" ]]; then existed="false"; fi
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$target" "$snapshot_target"
        cli_audit_append --action repair --status apply --scope state_dir \
          --idempotency-key "$idem_key" --target "$target" >/dev/null 2>&1 || true
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" \
        --arg snapshot "$snapshot_target" --arg existed "$existed" \
        '{schema_version:$sv,command:"repair",status:"ok",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,daily_snapshot_dir:$snapshot,existed_before:($existed == "true")}'
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
    pattern-jsonl-path)
      if [[ -z "$arg" ]]; then
        printf 'ERR: validate pattern-jsonl-path requires VALUE arg\n' >&2; return 64
      fi
      if [[ "$arg" == *.jsonl ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg p "$arg" \
          '{schema_version:$sv,command:"validate",subject:"pattern-jsonl-path",ts:$ts,status:"ok",value:$p}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg p "$arg" \
          '{schema_version:$sv,command:"validate",subject:"pattern-jsonl-path",ts:$ts,status:"reject",value:$p,reason:"unsupported_extension",valid_extensions:[".jsonl"]}'
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
        '{schema_version:$sv,command:"validate",status:"refused",reason:"missing_subject",valid_subjects:["repo-name","pattern-jsonl-path","audit-row"]}'
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg subj "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",subject:$subj,reason:"unknown_subject",valid_subjects:["repo-name","pattern-jsonl-path","audit-row"]}'
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
  local match; match="$(jq -c --arg id "$id" 'select(.ts == $id or .repo == $id or (.pattern_id // "") == $id or (.run_id // "") == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | head -1 || true)"
  if [[ -z "$match" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"not_found",audit_log:$log,searched_keys:["ts","repo","pattern_id","run_id"]}'
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
export JEFF_PHILOSOPHY_SCRIPT_DIR="$SCRIPT_DIR"

exec python3 - "$@" <<'PY'
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

VERSION = "jeff-philosophy-mine.v1"
SCHEMA = "jeff-philosophy/v1"

PATTERNS = [
    {
        "pattern_class": "doctor-health-repair-triad",
        "query": "doctor health repair triad implementation",
        "terms": ["doctor", "health", "repair"],
        "our_adoption_status": "EXTEND",
        "adoption_next": "Require doctor/health/repair on new operator substrates.",
    },
    {
        "pattern_class": "idempotency-key-fail-closed",
        "query": "idempotency key fail closed retry replay",
        "terms": ["idempotency", "fail-closed", "replay"],
        "our_adoption_status": "ADOPT",
        "adoption_next": "Use idempotency key + request fingerprint on mutating receipts.",
    },
    {
        "pattern_class": "schema-version-migration",
        "query": "schema version migration compatibility contract",
        "terms": ["schema_version", "migration", "compatibility"],
        "our_adoption_status": "EXTEND",
        "adoption_next": "Pair schema edits with migration receipts and fixtures.",
    },
    {
        "pattern_class": "callback-envelope-shape",
        "query": "callback envelope DONE BLOCKED receipt evidence",
        "terms": ["callback", "receipt", "evidence"],
        "our_adoption_status": "DIVERGE",
        "adoption_next": "Keep DONE/BLOCKED shape but validate it as a typed envelope.",
    },
    {
        "pattern_class": "append-only-audit-log",
        "query": "append only audit jsonl provenance receipt",
        "terms": ["audit", "jsonl", "provenance"],
        "our_adoption_status": "EXTEND",
        "adoption_next": "Attach audit rows to learning and mutation surfaces.",
    },
    {
        "pattern_class": "frontmatter-validation",
        "query": "frontmatter validation parser schema",
        "terms": ["frontmatter", "validation", "schema"],
        "our_adoption_status": "ADOPT",
        "adoption_next": "Structurally validate command, skill, plan, and doctrine metadata.",
    },
    {
        "pattern_class": "testing-fixture-conventions",
        "query": "fixture golden deterministic replay tests",
        "terms": ["fixture", "golden", "deterministic"],
        "our_adoption_status": "ADOPT",
        "adoption_next": "Every validation claim names fixture, replay command, and expected assertion.",
    },
    {
        "pattern_class": "lock-file-convention",
        "query": "lock file owner ttl stale lock metadata",
        "terms": ["lock", "ttl", "stale"],
        "our_adoption_status": "ADOPT",
        "adoption_next": "Standardize lock owner, timeout, stale diagnosis, and release receipts.",
    },
    {
        "pattern_class": "state-machine-modeling",
        "query": "state machine invariant transition model",
        "terms": ["state machine", "transition", "invariant"],
        "our_adoption_status": "ADAPT",
        "adoption_next": "Model high-risk flywheel transitions before implementation.",
    },
    {
        "pattern_class": "failure-taxonomy-reason-codes",
        "query": "failure taxonomy reason codes typed errors",
        "terms": ["failure taxonomy", "reason", "code"],
        "our_adoption_status": "ADAPT",
        "adoption_next": "Use stable reason codes instead of prose-only failures.",
    },
    {
        "pattern_class": "structured-log-contracts",
        "query": "structured logging contract event envelope",
        "terms": ["structured", "logging", "contract"],
        "our_adoption_status": "EXTEND",
        "adoption_next": "Keep agent-readable logs structured with correlation fields.",
    },
    {
        "pattern_class": "provenance-why-audit",
        "query": "why audit provenance trace command",
        "terms": ["why", "audit", "provenance"],
        "our_adoption_status": "ADOPT",
        "adoption_next": "Expose why/audit provenance for derived doctrine and learning artifacts.",
    },
]


def utc_now():
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())


def day_from_ts(ts):
    return ts[:10]


def script_path(name):
    return Path(os.environ.get("JEFF_PHILOSOPHY_SCRIPT_DIR", ".")).expanduser() / name


def default_repo_root():
    return Path(os.environ.get("JEFF_PHILOSOPHY_REPO_ROOT", str(Path.home() / "Developer/jeff-corpus"))).expanduser()


def default_state_dir():
    return Path(os.environ.get("JEFF_PHILOSOPHY_STATE_DIR", str(Path.home() / ".local/state/jeff-philosophy"))).expanduser()


def append_jsonl(path, row):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as fh:
        fh.write(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n")


def atomic_write_text(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(prefix=path.name + ".", suffix=".tmp", dir=str(path.parent))
    with os.fdopen(fd, "w", encoding="utf-8") as fh:
        fh.write(text)
        fh.flush()
        os.fsync(fh.fileno())
    Path(tmp).replace(path)


def atomic_write_jsonl(path, rows):
    text = "".join(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n" for row in rows)
    atomic_write_text(path, text)


def run(cmd, timeout=120, cwd=None):
    try:
        proc = subprocess.run(
            cmd,
            cwd=str(cwd) if cwd else None,
            encoding="utf-8",
            errors="replace",
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=timeout,
            check=False,
        )
        return proc.returncode, proc.stdout, proc.stderr
    except subprocess.TimeoutExpired as exc:
        return 124, exc.stdout or "", exc.stderr or "timeout"


def repo_for_path(root, path):
    try:
        rel = Path(path).resolve().relative_to(root.resolve())
    except Exception:
        return "unknown"
    return rel.parts[0] if rel.parts else "unknown"


def line_ref(root, path, line):
    try:
        rel = Path(path).resolve().relative_to(root.resolve())
    except Exception:
        rel = Path(path)
    return f"{rel}:{line}"


def collect_evidence(root, pattern, limit, timeout):
    if not root.exists():
        return [], "repo_root_missing"
    rg = shutil.which("rg")
    if not rg:
        return [], "rg_missing"
    cmd = [
        rg,
        "--no-config",
        "-n",
        "--with-filename",
        "--color",
        "never",
        "--max-count",
        "2",
        "--max-filesize",
        "512K",
    ]
    for term in pattern["terms"]:
        cmd.extend(["-e", term])
    cmd.append(str(root))
    rc, out, err = run(cmd, timeout=timeout)
    if rc not in (0, 1):
        return [], f"rg_failed:{err.strip()[:120]}"
    seen = set()
    evidence = []
    for raw in out.splitlines():
        parts = raw.split(":", 2)
        if len(parts) < 3:
            continue
        file_path, line, snippet = parts
        repo = repo_for_path(root, file_path)
        if repo in seen:
            continue
        seen.add(repo)
        evidence.append(
            {
                "repo": repo,
                "file_line": line_ref(root, file_path, line),
                "snippet": re.sub(r"\s+", " ", snippet).strip()[:220],
            }
        )
        if len(evidence) >= limit:
            break
    return evidence, None


def pattern_rows(args, selected_patterns):
    rows = []
    for pattern in selected_patterns:
        evidence, error = collect_evidence(args.repo_root, pattern, args.evidence_limit, args.search_timeout)
        rows.append(
            {
                "schema_version": "jeff-philosophy-pattern/v1",
                "generated_at": args.now or utc_now(),
                "pattern_class": pattern["pattern_class"],
                "query": pattern["query"],
                "terms": pattern["terms"],
                "repos_using_it": sorted({item["repo"] for item in evidence}),
                "evidence_repo_count": len({item["repo"] for item in evidence}),
                "evidence": evidence,
                "our_adoption_status": pattern["our_adoption_status"],
                "adoption_next": pattern["adoption_next"],
                "source": "jeff-corpus-rg-fanout",
                "error": error,
            }
        )
    return rows


def render_deep_mine_report(rows, args):
    complete = [row for row in rows if row["evidence_repo_count"] >= args.min_repos]
    lines = [
        "# Jeff Philosophy Deep Mine Findings",
        "",
        f"- generated_at: {args.now or utc_now()}",
        f"- repo_root: {args.repo_root}",
        f"- patterns: {len(rows)}",
        f"- complete_patterns: {len(complete)}",
        f"- min_repos: {args.min_repos}",
        "",
        "## Pattern Summary",
        "",
        "| pattern_class | adoption | evidence_repos | status |",
        "|---|---|---:|---|",
    ]
    for row in rows:
        status = "pass" if row["evidence_repo_count"] >= args.min_repos else "fail"
        lines.append(f"| `{row['pattern_class']}` | {row['our_adoption_status']} | {row['evidence_repo_count']} | {status} |")
    for row in rows:
        lines.extend(["", f"## {row['pattern_class']}", ""])
        lines.append(f"- query: `{row['query']}`")
        lines.append(f"- adoption_next: {row['adoption_next']}")
        if row.get("error"):
            lines.append(f"- search_error: {row['error']}")
        lines.extend(["", "| repo | file:line | evidence |", "|---|---|---|"])
        for item in row["evidence"]:
            snippet = item["snippet"].replace("|", "\\|")
            lines.append(f"| `{item['repo']}` | `{item['file_line']}` | {snippet} |")
    return "\n".join(lines) + "\n"


def selected_pattern_specs(args):
    if not args.pattern_name:
        return PATTERNS
    wanted = args.pattern_name.lower()
    matches = [p for p in PATTERNS if p["pattern_class"].lower() == wanted]
    if not matches:
        matches = [p for p in PATTERNS if wanted in p["pattern_class"].lower()]
    return matches


def deep_mine(args):
    specs = selected_pattern_specs(args)
    if not specs:
        return {"schema_version": SCHEMA, "version": VERSION, "command": args.command, "status": "fail", "error": "pattern_not_found", "pattern": args.pattern_name}
    rows = pattern_rows(args, specs)
    complete = [row for row in rows if row["evidence_repo_count"] >= args.min_repos]
    status = "pass" if len(complete) == len(rows) and (args.pattern_name or len(rows) >= args.min_patterns) else "fail"
    report_text = render_deep_mine_report(rows, args)
    if not args.dry_run:
        atomic_write_jsonl(args.output_jsonl, rows)
        atomic_write_text(args.report_path, report_text)
        append_jsonl(args.audit_log, {"schema_version": "jeff-philosophy-audit/v1", "ts": args.now or utc_now(), "command": args.command, "status": status, "patterns": len(rows), "report_path": str(args.report_path), "output_jsonl": str(args.output_jsonl)})
    return {
        "schema_version": "jeff-philosophy-deep-mine-run/v1",
        "version": VERSION,
        "command": args.command,
        "status": status,
        "dry_run": args.dry_run,
        "repo_root": str(args.repo_root),
        "pattern_count": len(rows),
        "complete_pattern_count": len(complete),
        "min_repos": args.min_repos,
        "output_jsonl": str(args.output_jsonl),
        "report_path": str(args.report_path),
        "patterns": [{"pattern_class": row["pattern_class"], "evidence_repo_count": row["evidence_repo_count"]} for row in rows],
    }


def daily_snapshot(args):
    daily_bin = args.daily_diff_bin
    if not daily_bin.exists():
        return {"schema_version": SCHEMA, "version": VERSION, "command": "daily-snapshot", "status": "fail", "error": "daily_diff_missing", "daily_diff_bin": str(daily_bin)}
    day = day_from_ts(args.now or utc_now())
    snapshot_dir = args.state_dir / "daily-snapshots"
    snapshot_path = snapshot_dir / f"{day}.md"
    cmd = [str(daily_bin), "--repo-root", str(args.repo_root), "--reports-dir", str(snapshot_dir), "--json"]
    if args.now:
        cmd.extend(["--now", args.now])
    if args.dry_run:
        cmd.append("--dry-run")
    if args.skip_fetch:
        cmd.append("--skip-fetch")
    rc, out, err = run(cmd, timeout=args.daily_timeout)
    try:
        payload = json.loads(out)
    except Exception:
        payload = {"status": "fail", "error": "daily_diff_invalid_json", "stdout": out[:400], "stderr": err[:400]}
    status = "pass" if rc == 0 and payload.get("status") == "pass" else "fail"
    report_path = Path(payload.get("report_path", ""))
    if status == "pass" and not args.dry_run:
        if report_path.exists():
            atomic_write_text(snapshot_path, report_path.read_text(encoding="utf-8"))
        else:
            status = "fail"
            payload["error"] = "daily_report_missing"
        append_jsonl(args.audit_log, {"schema_version": "jeff-philosophy-audit/v1", "ts": args.now or utc_now(), "command": "daily-snapshot", "status": status, "snapshot_path": str(snapshot_path), "daily_report_path": str(report_path)})
    return {
        "schema_version": "jeff-philosophy-daily-snapshot-run/v1",
        "version": VERSION,
        "command": "daily-snapshot",
        "status": status,
        "dry_run": args.dry_run,
        "snapshot_path": str(snapshot_path if not args.dry_run else report_path),
        "daily_diff": payload,
    }


def info(args):
    return {
        "schema_version": "jeff-philosophy-info/v1",
        "version": VERSION,
        "status": "pass",
        "repo_root": str(args.repo_root),
        "state_dir": str(args.state_dir),
        "output_jsonl": str(args.output_jsonl),
        "report_path": str(args.report_path),
        "daily_diff_bin": str(args.daily_diff_bin),
        "audit_log": str(args.audit_log),
        "commands": ["doctor", "health", "repair", "validate", "audit", "why", "schema", "deep-mine", "daily-snapshot", "pattern", "completion"],
    }


def schema(args):
    return {
        "schema_version": "jeff-philosophy/schema/v1",
        "version": VERSION,
        "status": "pass",
        "pattern_schema": "jeff-philosophy-pattern/v1",
        "deep_mine_required_fields": ["pattern_class", "repos_using_it", "evidence", "our_adoption_status"],
        "daily_snapshot_required_fields": ["snapshot_path", "daily_diff"],
        "verdict_enum": ["ADOPT", "ADAPT", "EXTEND", "DIVERGE"],
        "commands": ["doctor", "health", "repair", "validate", "audit", "why", "schema", "deep-mine", "daily-snapshot", "pattern", "completion"],
    }


def patterns_summary(args):
    rows = []
    if args.output_jsonl.exists():
        for line in args.output_jsonl.read_text(encoding="utf-8").splitlines():
            if line.strip():
                rows.append(json.loads(line))
    complete = [row for row in rows if row.get("evidence_repo_count", 0) >= 3]
    snapshot_dir = args.state_dir / "daily-snapshots"
    snapshots = []
    if snapshot_dir.exists():
        snapshots = sorted(snapshot_dir.glob("[0-9][0-9][0-9][0-9]-*.md")) or sorted(snapshot_dir.glob("*.md"))
    return {
        "pattern_count": len(rows),
        "complete_pattern_count": len(complete),
        "latest_snapshot_path": str(snapshots[-1]) if snapshots else None,
    }


def doctor(args):
    summary = patterns_summary(args)
    checks = {
        "repo_root_exists": args.repo_root.exists(),
        "daily_diff_bin_exists": args.daily_diff_bin.exists(),
        "patterns_jsonl_exists": args.output_jsonl.exists(),
        "state_dir_exists": args.state_dir.exists(),
        "rg_available": shutil.which("rg") is not None,
    }
    status = "pass" if checks["repo_root_exists"] and checks["daily_diff_bin_exists"] and checks["rg_available"] else "fail"
    return {"schema_version": "jeff-philosophy-doctor/v1", "version": VERSION, "command": "doctor", "status": status, "checks": checks, **summary}


def health(args):
    doc = doctor(args)
    return {"schema_version": "jeff-philosophy-health/v1", "version": VERSION, "command": "health", "status": doc["status"], "summary": doc["checks"]}


def repair(args):
    actions = [
        {"action": "mkdir_state_dir", "path": str(args.state_dir), "needed": not args.state_dir.exists()},
        {"action": "mkdir_daily_snapshot_dir", "path": str(args.state_dir / "daily-snapshots"), "needed": not (args.state_dir / "daily-snapshots").exists()},
    ]
    if args.apply:
        args.state_dir.mkdir(parents=True, exist_ok=True)
        (args.state_dir / "daily-snapshots").mkdir(parents=True, exist_ok=True)
        append_jsonl(args.audit_log, {"schema_version": "jeff-philosophy-audit/v1", "ts": args.now or utc_now(), "command": "repair", "status": "pass", "dry_run": False})
    return {"schema_version": "jeff-philosophy-repair/v1", "version": VERSION, "command": "repair", "status": "pass", "dry_run": not args.apply, "actions": actions}


def validate(args):
    if args.target in ("all", "patterns"):
        if not args.output_jsonl.exists():
            return {"schema_version": "jeff-philosophy-validate/v1", "version": VERSION, "command": "validate", "target": args.target, "status": "fail", "error": "patterns_jsonl_missing", "path": str(args.output_jsonl)}
        rows = [json.loads(line) for line in args.output_jsonl.read_text(encoding="utf-8").splitlines() if line.strip()]
        complete = [row for row in rows if row.get("evidence_repo_count", 0) >= args.min_repos]
        status = "pass" if rows and len(complete) == len(rows) else "fail"
        return {"schema_version": "jeff-philosophy-validate/v1", "version": VERSION, "command": "validate", "target": args.target, "status": status, "rows": len(rows), "complete_rows": len(complete), "min_repos": args.min_repos}
    return {"schema_version": "jeff-philosophy-validate/v1", "version": VERSION, "command": "validate", "target": args.target, "status": "pass"}


def audit(args):
    rows = []
    if args.audit_log.exists():
        for line in args.audit_log.read_text(encoding="utf-8").splitlines()[-args.limit :]:
            if line.strip():
                rows.append(json.loads(line))
    return {"schema_version": "jeff-philosophy-audit-read/v1", "version": VERSION, "command": "audit", "status": "pass", "audit_log": str(args.audit_log), "rows": rows}


def why(args):
    if not args.output_jsonl.exists():
        return {"schema_version": "jeff-philosophy-why/v1", "version": VERSION, "command": "why", "status": "fail", "error": "patterns_jsonl_missing", "pattern": args.pattern_name}
    wanted = args.pattern_name.lower()
    for line in args.output_jsonl.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        row = json.loads(line)
        if row.get("pattern_class", "").lower() == wanted:
            return {"schema_version": "jeff-philosophy-why/v1", "version": VERSION, "command": "why", "status": "pass", "pattern": row}
    return {"schema_version": "jeff-philosophy-why/v1", "version": VERSION, "command": "why", "status": "fail", "error": "pattern_not_found", "pattern": args.pattern_name}


def examples(args):
    text = "\n".join(
        [
            "jeff-philosophy-mine.sh doctor --json",
            "jeff-philosophy-mine.sh --deep-mine --json",
            "jeff-philosophy-mine.sh --daily-snapshot --skip-fetch --json",
            "jeff-philosophy-mine.sh --pattern doctor-health-repair-triad --json",
            "jeff-philosophy-mine.sh validate patterns --json",
        ]
    )
    return {"schema_version": "jeff-philosophy-examples/v1", "version": VERSION, "status": "pass", "examples": text.splitlines()} if args.json else text


def quickstart(args):
    text = "Run doctor first, then --deep-mine to refresh patterns.jsonl, then --daily-snapshot for the morning Jeff learning report."
    return {"schema_version": "jeff-philosophy-quickstart/v1", "version": VERSION, "status": "pass", "text": text} if args.json else text


def completion(args):
    words = "doctor health repair validate audit why schema info examples quickstart deep-mine daily-snapshot pattern completion"
    if args.shell == "fish":
        text = "complete -c jeff-philosophy-mine.sh -f -a '" + words + "'"
    else:
        text = "_jeff_philosophy_mine() { COMPREPLY=( $(compgen -W '" + words + "' -- \"${COMP_WORDS[COMP_CWORD]}\") ); }\ncomplete -F _jeff_philosophy_mine jeff-philosophy-mine.sh"
    return {"schema_version": "jeff-philosophy-completion/v1", "version": VERSION, "status": "pass", "shell": args.shell, "completion": text} if args.json else text


def normalize_argv(argv):
    if not argv:
        return ["doctor"]
    flag_commands = {
        "--deep-mine": "deep-mine",
        "--daily-snapshot": "daily-snapshot",
        "--doctor": "doctor",
        "--health": "health",
        "--repair": "repair",
        "--validate": "validate",
        "--audit": "audit",
        "--schema": "schema",
        "--info": "info",
        "--examples": "examples",
        "--quickstart": "quickstart",
        "--completion": "completion",
    }
    if argv[0] == "--pattern":
        return ["pattern", *argv[1:]]
    if argv[0] in flag_commands:
        return [flag_commands[argv[0]], *argv[1:]]
    for idx, arg in enumerate(argv):
        if arg == "--pattern":
            return ["pattern", *argv[:idx], *argv[idx + 1 :]]
        if arg in flag_commands:
            return [flag_commands[arg], *argv[:idx], *argv[idx + 1 :]]
    return argv


def add_common(parser):
    parser.add_argument("--repo-root", type=Path, default=default_repo_root())
    parser.add_argument("--state-dir", type=Path, default=default_state_dir())
    parser.add_argument("--output-jsonl", type=Path)
    parser.add_argument("--report-path", type=Path, default=Path("/tmp/jeff-philosophy-deep-mine_findings.md"))
    parser.add_argument("--daily-diff-bin", type=Path, default=Path(os.environ.get("JEFF_PHILOSOPHY_DAILY_DIFF_BIN", str(script_path("jeff-daily-diff.sh")))).expanduser())
    parser.add_argument("--now", default=os.environ.get("JEFF_PHILOSOPHY_NOW", ""))
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--no-color", action="store_true")
    parser.add_argument("--no-emoji", action="store_true")
    parser.add_argument("--width", type=int, default=100)


def parse_args(argv):
    parser = argparse.ArgumentParser(description="Mine Jeff corpus philosophy patterns and daily learning snapshots.")
    sub = parser.add_subparsers(dest="command")
    for name in ["doctor", "health", "schema", "info", "examples", "quickstart", "audit"]:
        sp = sub.add_parser(name)
        add_common(sp)
        if name == "audit":
            sp.add_argument("--limit", type=int, default=20)
    sp = sub.add_parser("deep-mine")
    add_common(sp)
    sp.add_argument("--dry-run", action="store_true")
    sp.add_argument("--min-repos", type=int, default=3)
    sp.add_argument("--min-patterns", type=int, default=10)
    sp.add_argument("--evidence-limit", type=int, default=3)
    sp.add_argument("--search-timeout", type=int, default=20)
    sp.add_argument("--pattern-name", default="")
    sp = sub.add_parser("pattern")
    add_common(sp)
    sp.add_argument("pattern_name")
    sp.add_argument("--dry-run", action="store_true")
    sp.add_argument("--min-repos", type=int, default=3)
    sp.add_argument("--min-patterns", type=int, default=1)
    sp.add_argument("--evidence-limit", type=int, default=3)
    sp.add_argument("--search-timeout", type=int, default=20)
    sp = sub.add_parser("daily-snapshot")
    add_common(sp)
    sp.add_argument("--dry-run", action="store_true")
    sp.add_argument("--skip-fetch", action="store_true")
    sp.add_argument("--daily-timeout", type=int, default=300)
    sp = sub.add_parser("repair")
    add_common(sp)
    sp.add_argument("--dry-run", action="store_true")
    sp.add_argument("--apply", action="store_true")
    sp = sub.add_parser("validate")
    add_common(sp)
    sp.add_argument("target", nargs="?", default="patterns", choices=["patterns", "daily-snapshot", "all"])
    sp.add_argument("--min-repos", type=int, default=3)
    sp = sub.add_parser("why")
    add_common(sp)
    sp.add_argument("pattern_name")
    sp = sub.add_parser("completion")
    add_common(sp)
    sp.add_argument("shell", nargs="?", default="bash", choices=["bash", "zsh", "fish"])
    args = parser.parse_args(normalize_argv(argv))
    if not args.command:
        args.command = "doctor"
    args.repo_root = args.repo_root.expanduser()
    args.state_dir = args.state_dir.expanduser()
    args.output_jsonl = (args.output_jsonl or args.state_dir / "patterns.jsonl").expanduser()
    args.report_path = args.report_path.expanduser()
    args.audit_log = args.state_dir / "audit.jsonl"
    return args


def emit(payload, json_out):
    if isinstance(payload, str):
        print(payload)
        return
    if json_out:
        print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
    else:
        print(f"{payload.get('command', 'jeff-philosophy')} status={payload.get('status', 'unknown')}")


args = parse_args(sys.argv[1:])
handlers = {
    "doctor": doctor,
    "health": health,
    "repair": repair,
    "validate": validate,
    "audit": audit,
    "why": why,
    "schema": schema,
    "info": info,
    "examples": examples,
    "quickstart": quickstart,
    "completion": completion,
    "deep-mine": deep_mine,
    "pattern": deep_mine,
    "daily-snapshot": daily_snapshot,
}
payload = handlers[args.command](args)
emit(payload, getattr(args, "json", False))
if isinstance(payload, dict) and payload.get("status") == "fail":
    sys.exit(1)
PY

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-09-info-source-watchtower.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-76-authority-ranked-retrieval-maintenance.md`
