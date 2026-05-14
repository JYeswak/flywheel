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
# WZJO9.1.7 PARTIAL-BYPASS applies — see _scaffold_is_canonical_arg.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="daily-report/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/daily-report-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: daily-report.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "daily-report.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "daily-report.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"daily-report.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"daily-report.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"daily-report.sh doctor --json"}'
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
        '{schema_version:$sv,command:"schema",surface:"repair",scopes:["scratch_dir","audit_log_dir"],contract:{requires_idempotency_key_when_apply:true,refusal_exit_code:3,dry_run_default:true}}'
      ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"validate",subjects:["session-name","report-path","audit-row"],contract:{rejects_with_rc1:"on schema violation",session_name_pattern:"^[a-z][a-z0-9_-]*$",report_path_extensions:[".md",".json"]}}'
      ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"audit",audit_log_env:"SCAFFOLD_AUDIT_LOG",row_shape:{ts:"ISO8601",action:"string"},limit_default:20}'
      ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"why",input:"id (ts OR session OR report_path OR run_id)",states:["found","not_found","unavailable"],source:"$SCAFFOLD_AUDIT_LOG"}'
      ;;
    audit-row)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"audit-row",required_fields:["ts","action"],optional_fields:["status","session","report_path","scope","mode","idempotency_key"]}'
      ;;
    default|*)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surfaces:["doctor","health","repair","validate","audit","why","audit-row"],note:"daily-report.sh = bash wrapper around daily-report.py with NTM rollup append; --info/--schema/--examples PASSTHRU to native python (richer JSON-Schema)"}'
      ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — default backward-compatible invocation routes to cmd_run: probes ntm analytics/summary/bugs/scan via "$NTM" CLI, builds rollup with per-agent + UBS-counts, calls daily-report.py to generate report, appends NTM rollup section to the report file\n' ;;
    doctor)   printf 'topic: doctor — substrate probes: bash, jq, mktemp, python3 (load-bearing for daily-report.py heredoc), ntm_available (load-bearing for analytics/summary/bugs/scan probes), daily_report_py_executable, audit_log_dir_writable\n' ;;
    health)   printf 'topic: health — tails $SCAFFOLD_AUDIT_LOG (default ~/.local/state/flywheel/daily-report-runs.jsonl); reports last_run_ts, age_seconds, recent_runs, total_runs; status=warn at >36h stale (1.5x daily cadence)\n' ;;
    repair)   printf 'topic: repair --scope <scratch_dir|audit_log_dir> [--dry-run|--apply --idempotency-key KEY] — apply contract: --apply requires --idempotency-key (rc=3 refusal); scopes: scratch_dir (mkdir -p $TMPDIR for daily-report-ntm.XXXXXX), audit_log_dir (mkdir -p $SCAFFOLD_AUDIT_LOG dirname)\n' ;;
    validate) printf 'topic: validate <subject> [PATH|VALUE] — subjects: session-name (matches ^[a-z][a-z0-9_-]*$ — defaults to basename of --repo), report-path (must end .md or .json — daily-report.py emits .md by default with .json via --json), audit-row (JSONL ts + action required); rc=1 on schema violation\n' ;;
    audit)    printf 'topic: audit [--limit N] — tail $SCAFFOLD_AUDIT_LOG via cli_emit_audit_tail (path-then-schema positional); default limit=20\n' ;;
    why)      printf 'topic: why <id> — provenance lookup against $SCAFFOLD_AUDIT_LOG; matches against ts/session/report_path/run_id; states: found / not_found / unavailable\n' ;;
    *)        printf 'topics: run | doctor | health | repair | validate | audit | why | quickstart | completion (PARTIAL-BYPASS: --info/--schema/--examples flags route to native python heredoc)\n' ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh> — emit shell completion script\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "daily-report" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "daily-report" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  local repo_root; repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
  local daily_report_py="$repo_root/.flywheel/scripts/daily-report.py"
  local ntm_bin="${NTM:-$HOME/.local/bin/ntm}"
  local audit_log_dir; audit_log_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"
  local bash_status="fail" jq_status="fail" mktemp_status="fail" python_status="fail"
  local ntm_status="warn" daily_py_status="fail" audit_dir_status="fail"
  local overall="pass"

  if command -v bash >/dev/null 2>&1; then bash_status="pass"; fi
  if command -v jq >/dev/null 2>&1; then jq_status="pass"; fi
  if command -v mktemp >/dev/null 2>&1; then mktemp_status="pass"; fi
  if command -v python3 >/dev/null 2>&1; then python_status="pass"; fi
  if [[ -x "$ntm_bin" ]]; then ntm_status="pass"; fi
  if [[ -x "$daily_report_py" ]]; then daily_py_status="pass"; fi
  if [[ -d "$audit_log_dir" && -w "$audit_log_dir" ]]; then audit_dir_status="pass"; fi

  for st in "$bash_status" "$jq_status" "$mktemp_status" "$python_status" "$daily_py_status"; do
    if [[ "$st" == "fail" ]]; then overall="fail"; fi
  done
  if [[ "$overall" == "pass" ]]; then
    for st in "$ntm_status" "$audit_dir_status"; do
      if [[ "$st" == "warn" || "$st" == "fail" ]]; then overall="warn"; fi
    done
  fi

  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg ts "$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg overall "$overall" \
    --arg bash_status "$bash_status" --arg jq_status "$jq_status" \
    --arg mktemp_status "$mktemp_status" --arg python_status "$python_status" \
    --arg ntm "$ntm_bin" --arg ntm_status "$ntm_status" \
    --arg daily_py "$daily_report_py" --arg daily_py_status "$daily_py_status" \
    --arg audit_dir "$audit_log_dir" --arg audit_dir_status "$audit_dir_status" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$overall,
      checks:[
        {name:"bash_available",status:$bash_status},
        {name:"jq_available",status:$jq_status},
        {name:"mktemp_available",status:$mktemp_status,detail:"required for daily-report-ntm.XXXXXX scratch"},
        {name:"python3_available",status:$python_status,detail:"load-bearing for daily-report.py"},
        {name:"ntm_available",status:$ntm_status,path:$ntm,detail:"load-bearing for analytics/summary/bugs/scan probes"},
        {name:"daily_report_py_executable",status:$daily_py_status,path:$daily_py,detail:"load-bearing for report generation"},
        {name:"audit_log_dir_writable",status:$audit_dir_status,path:$audit_dir}
      ]
    }'
}

scaffold_cmd_health() {
  local audit_log="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/daily-report-runs.jsonl}"
  local now ts last_run_ts="" age_seconds total_runs=0 recent_runs=0 status="pass"
  local stale_threshold="${DAILY_REPORT_HEALTH_STALE_THRESHOLD_SECONDS:-129600}"
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
    scratch_dir)
      local target="${TMPDIR:-/tmp}"
      local existed="true"
      if [[ ! -d "$target" ]]; then existed="false"; fi
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$target"
        cli_audit_append --action repair --status apply --scope scratch_dir \
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
      printf 'ERR: repair requires --scope <scratch_dir|audit_log_dir>\n' >&2
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",scope:$scope,reason:"unknown_scope",valid_scopes:["scratch_dir","audit_log_dir"]}'
      return 64 ;;
  esac
}

scaffold_cmd_validate() {
  local subject="${1:-}"; shift || true
  local arg="${1:-}"
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  case "$subject" in
    session-name)
      if [[ -z "$arg" ]]; then
        printf 'ERR: validate session-name requires VALUE arg\n' >&2; return 64
      fi
      if [[ "$arg" =~ ^[a-z][a-z0-9_-]*$ ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg s "$arg" \
          '{schema_version:$sv,command:"validate",subject:"session-name",ts:$ts,status:"ok",value:$s}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg s "$arg" \
          '{schema_version:$sv,command:"validate",subject:"session-name",ts:$ts,status:"reject",value:$s,reason:"pattern_mismatch",pattern:"^[a-z][a-z0-9_-]*$"}'
        return 1
      fi
      ;;
    report-path)
      if [[ -z "$arg" ]]; then
        printf 'ERR: validate report-path requires VALUE arg\n' >&2; return 64
      fi
      if [[ "$arg" == *.md || "$arg" == *.json ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg p "$arg" \
          '{schema_version:$sv,command:"validate",subject:"report-path",ts:$ts,status:"ok",value:$p}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg p "$arg" \
          '{schema_version:$sv,command:"validate",subject:"report-path",ts:$ts,status:"reject",value:$p,reason:"unsupported_extension",valid_extensions:[".md",".json"]}'
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
        '{schema_version:$sv,command:"validate",status:"refused",reason:"missing_subject",valid_subjects:["session-name","report-path","audit-row"]}'
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg subj "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",subject:$subj,reason:"unknown_subject",valid_subjects:["session-name","report-path","audit-row"]}'
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
  local match; match="$(jq -c --arg id "$id" 'select(.ts == $id or (.session // "") == $id or (.report_path // "") == $id or (.run_id // "") == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | head -1 || true)"
  if [[ -z "$match" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"not_found",audit_log:$log,searched_keys:["ts","session","report_path","run_id"]}'
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
  # WZJO9.1.7 PARTIAL-BYPASS: daily-report.sh natively forwards
  # --info / --schema / --examples to daily-report.py via its PASSTHRU
  # mode (see line ~16 of cmd_run). The python heredoc emits richer
  # domain-specific schemas (full JSON-Schema for the daily-report
  # result envelope). The scaffold subcommands (doctor/health/repair/
  # validate/audit/why) are NOT natively supported and the scaffold
  # owns those. This is a PARTIAL bypass — flag form goes native, verb
  # form goes scaffold.
  case "${1:-}" in
    doctor|health|repair|validate|audit|why|quickstart|completion) return 0 ;;
    --info|--schema|--examples) return 1 ;;  # PARTIAL-BYPASS to native PASSTHRU
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
PYTHON_REPORT="$SCRIPT_DIR/daily-report.py"
NTM="${NTM:-/Users/josh/.local/bin/ntm}"
REPO="$PWD"; SESSION="${FLYWHEEL_DAILY_REPORT_SESSION:-}"; WANT_JSON=0; PASSTHRU=0
PY_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="$2"; PY_ARGS+=("$1" "$2"); shift 2 ;;
    --repo=*) REPO="${1#--repo=}"; PY_ARGS+=("$1"); shift ;;
    --session) SESSION="$2"; shift 2 ;;
    --session=*) SESSION="${1#--session=}"; shift ;;
    --json) WANT_JSON=1; PY_ARGS+=("$1"); shift ;;
    --schema|--info|--examples) PASSTHRU=1; PY_ARGS+=("$1"); shift ;;
    *) PY_ARGS+=("$1"); shift ;;
  esac
done
[[ "$PASSTHRU" -eq 0 ]] || exec python3 "$PYTHON_REPORT" "${PY_ARGS[@]}"

REPO="$(cd "$REPO" && pwd -P)"
SESSION="${SESSION:-$(basename "$REPO")}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/daily-report-ntm.XXXXXX")"; trap 'rm -rf "$TMP"' EXIT

json_probe() {
  local env_name="$1" file_env_name="$2" raw; shift 2
  if [[ -n "${!env_name:-}" ]]; then raw="${!env_name}"
  elif [[ -n "${!file_env_name:-}" ]]; then raw="$(cat "${!file_env_name}" 2>/dev/null || true)"
  else raw="$("$@" 2>/dev/null || true)"
  fi
  jq -e . >/dev/null 2>&1 <<<"$raw" && printf '%s\n' "$raw" || printf '{}\n'
}

ANALYTICS="$(json_probe NTM_ANALYTICS_JSON NTM_ANALYTICS_JSON_FILE "$NTM" analytics --days 1 --format json)"
SUMMARY="$(json_probe NTM_SUMMARY_JSON NTM_SUMMARY_JSON_FILE "$NTM" summary "$SESSION" --since 24h --json)"
BUGS="$(json_probe NTM_BUGS_JSON NTM_BUGS_JSON_FILE "$NTM" bugs summary "$REPO" --json)"
SCAN="$(json_probe NTM_SCAN_JSON NTM_SCAN_JSON_FILE "$NTM" scan "$REPO" --json --dry-run --timeout "${NTM_SCAN_TIMEOUT:-30}")"
ROLLUP="$(jq -nc --arg session "$SESSION" --argjson analytics "$ANALYTICS" --argjson summary "$SUMMARY" --argjson bugs "$BUGS" --argjson scan "$SCAN" '
def n($x): (($x // 0) | tonumber? // 0);
def t($x): {critical:n($x.critical//$x.totals.critical//$x.summary.critical//$x.scan.totals.critical),warning:n($x.warning//$x.totals.warning//$x.summary.warning//$x.scan.totals.warning),info:n($x.info//$x.totals.info//$x.summary.info//$x.scan.totals.info)};
{session:$session,analytics_totals:($analytics.summary//$analytics.totals//$analytics),per_agent_rollup:(($summary.agents//$summary.agent_summaries//$summary.per_agent//[])|if type=="array" then . else [] end),ubs_counts:{bugs:t($bugs),scan:t($scan),combined:{critical:(t($bugs).critical+t($scan).critical),warning:(t($bugs).warning+t($scan).warning),info:(t($bugs).info+t($scan).info)}}}')"

PY_OUT="$TMP/python.out"
python3 "$PYTHON_REPORT" "${PY_ARGS[@]}" >"$PY_OUT"
REPORT_PATH="$(jq -r '.report_path // empty' "$PY_OUT" 2>/dev/null || head -n 1 "$PY_OUT")"
if [[ -f "$REPORT_PATH" ]]; then
  {
    printf '\n## Native NTM rollup\n'
    jq -r '"- session: \(.session)\n- per_agent_rollup_count: \(.per_agent_rollup|length)\n- ubs_bugs: critical=\(.ubs_counts.bugs.critical) warning=\(.ubs_counts.bugs.warning) info=\(.ubs_counts.bugs.info)\n- ubs_scan: critical=\(.ubs_counts.scan.critical) warning=\(.ubs_counts.scan.warning) info=\(.ubs_counts.scan.info)"' <<<"$ROLLUP"
  } >>"$REPORT_PATH"
fi

# ── bszgl.3: git hygiene block ───────────────────────────────────────────────
GIT_UNCOMMITTED=0; GIT_UNTRACKED=0; GIT_AHEAD="?"; GIT_STASHES=0; GIT_ALARM=""
if git -C "$REPO" rev-parse --git-dir &>/dev/null; then
  GIT_UNCOMMITTED="$(git -C "$REPO" status --short 2>/dev/null | grep -cE '^.M|^ M|^[MADRC]' || true)"
  GIT_UNTRACKED="$(git -C "$REPO" status --short 2>/dev/null | grep -c '^??' || true)"
  GIT_AHEAD="$(git -C "$REPO" rev-list --count @{u}..HEAD 2>/dev/null || echo '?')"
  GIT_STASHES="$(git -C "$REPO" stash list 2>/dev/null | wc -l | tr -d ' ')"
  [[ "$GIT_UNTRACKED" -gt 0 ]] && GIT_ALARM=" ← ALARM: classify or gitignore"
fi

GOAL_GATE_STATUS="unknown"
LOOP_GOAL_GATE="${LOOP_GOAL_GATE:-$(dirname "$0")/loop-goal-gate.sh}"
if [[ -x "$LOOP_GOAL_GATE" ]]; then
  GATE_EXIT=0; GATE_OUT="$("$LOOP_GOAL_GATE" --repo "$REPO" --json 2>/dev/null)" || GATE_EXIT=$?
  GATE_STATUS="$(printf '%s\n' "$GATE_OUT" | jq -r '.status // "unknown"' 2>/dev/null || echo unknown)"
  case "$GATE_STATUS" in
    gated)  GOAL_GATE_STATUS="GATED — all blockers external, loop must halt" ;;
    pass)   GOAL_GATE_STATUS="COMPLETE — goal satisfied" ;;
    clear)  GOAL_GATE_STATUS="CLEAR — agent-actionable blockers exist" ;;
    *)      GOAL_GATE_STATUS="unknown (${GATE_STATUS})" ;;
  esac
fi

GIT_BLOCK="$(printf 'Git hygiene (%s):\n  uncommitted:    %s\n  unclassified:   %s%s\n  commits_ahead:  %s\n  stash_count:    %s\n  goal_gate:      %s' \
  "$(basename "$REPO")" "$GIT_UNCOMMITTED" "$GIT_UNTRACKED" "$GIT_ALARM" "$GIT_AHEAD" "$GIT_STASHES" "$GOAL_GATE_STATUS")"

if [[ -f "$REPORT_PATH" ]]; then
  { printf '\n## Git hygiene\n'; printf '%s\n' "$GIT_BLOCK"; } >>"$REPORT_PATH"
fi

if [[ "$WANT_JSON" -eq 1 ]]; then
  GIT_JSON="$(jq -nc \
    --argjson u "${GIT_UNCOMMITTED:-0}" --argjson n "${GIT_UNTRACKED:-0}" \
    --arg a "${GIT_AHEAD:-?}" --argjson s "${GIT_STASHES:-0}" --arg g "$GOAL_GATE_STATUS" \
    '{uncommitted:$u,untracked:$n,commits_ahead:$a,stash_count:$s,goal_gate:$g}')"
  jq -c --argjson ntm_rollup "$ROLLUP" --argjson git_hygiene "$GIT_JSON" \
    '. + {ntm_rollup:$ntm_rollup,git_hygiene:$git_hygiene}' "$PY_OUT"
else
  cat "$PY_OUT"
  printf '\n%s\n' "$GIT_BLOCK"
fi
