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
# WZJO9.1.7 PARTIAL-BYPASS — --info|--schema|--examples flags route to
# native python; verb subcommands route to scaffold.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="state-md-miner/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/state-md-miner-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: state-md-miner.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "state-md-miner.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "state-md-miner.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"state-md-miner.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"state-md-miner.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"state-md-miner.sh doctor --json"}'
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
        '{schema_version:$sv,command:"schema",surface:"repair",scopes:["state_dir","audit_log_dir"],contract:{requires_idempotency_key_when_apply:true,refusal_exit_code:3,dry_run_default:true},env:{state_dir:"~/.local/state/flywheel/state-md-miner (or --state-dir)",roster:"~/.local/state/flywheel/fleet-roster.json (or --roster)"}}'
      ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"validate",subjects:["repo-path","stale-days","audit-row"],contract:{rejects_with_rc1:"on schema violation",repo_path_must_be_absolute:true,stale_days_min_inclusive:1,stale_days_max_inclusive:365}}'
      ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"audit",audit_log_env:"SCAFFOLD_AUDIT_LOG",row_shape:{ts:"ISO8601",action:"string"},limit_default:20}'
      ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"why",input:"id (ts OR repo OR finding_id OR run_id)",states:["found","not_found","unavailable"],source:"$SCAFFOLD_AUDIT_LOG"}'
      ;;
    audit-row)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"audit-row",required_fields:["ts","action"],optional_fields:["status","repo","finding_id","scope","mode","idempotency_key","findings_count"]}'
      ;;
    default|*)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surfaces:["doctor","health","repair","validate","audit","why","audit-row"],note:"state-md-miner.sh = mine fleet STATE.md files for /flywheel:learn opportunities; native --info/--schema/--examples PASSTHRU emits state-md-miner/v1 schema with findings + decisions arrays"}'
      ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — default backward-compatible invocation routes to cmd_run (python heredoc): mines STATE.md files across the fleet roster (~/.local/state/flywheel/fleet-roster.json) OR a single --repo, identifies stale STATE entries (>--stale-days, default 14), proposes --max-beads-per-repo (default 5) auto-bead candidates; --apply turns proposals into action; emits state-md-miner/v1 with findings + decisions arrays\n' ;;
    doctor)   printf 'topic: doctor — substrate probes: bash, jq, mktemp, python3 (load-bearing for state-md-miner heredoc), roster_readable (~/.local/state/flywheel/fleet-roster.json), state_dir_writable (~/.local/state/flywheel/state-md-miner), audit_log_dir_writable\n' ;;
    health)   printf 'topic: health — tails $SCAFFOLD_AUDIT_LOG (default ~/.local/state/flywheel/state-md-miner-runs.jsonl); reports last_run_ts, age_seconds, recent_runs, total_runs; status=warn at >36h stale (1.5x daily mining cadence)\n' ;;
    repair)   printf 'topic: repair --scope <state_dir|audit_log_dir> [--dry-run|--apply --idempotency-key KEY] — apply contract: --apply requires --idempotency-key (rc=3 refusal); scopes: state_dir (mkdir -p $DEFAULT_STATE_DIR), audit_log_dir (mkdir -p $SCAFFOLD_AUDIT_LOG dirname)\n' ;;
    validate) printf 'topic: validate <subject> [PATH|VALUE] — subjects: repo-path (absolute path; matches --repo arg semantic), stale-days (integer in [1,365] matching --stale-days arg semantic; default 14), audit-row (JSONL ts + action required); rc=1 on schema violation\n' ;;
    audit)    printf 'topic: audit [--limit N] — tail $SCAFFOLD_AUDIT_LOG via cli_emit_audit_tail (path-then-schema positional); default limit=20\n' ;;
    why)      printf 'topic: why <id> — provenance lookup against $SCAFFOLD_AUDIT_LOG; matches against ts/repo/finding_id/run_id; states: found / not_found / unavailable\n' ;;
    *)        printf 'topics: run | doctor | health | repair | validate | audit | why | quickstart | completion (PARTIAL-BYPASS: --info/--schema/--examples flags route to native)\n' ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh> — emit shell completion script\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "state-md-miner" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "state-md-miner" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  local roster="$HOME/.local/state/flywheel/fleet-roster.json"
  local state_dir="$HOME/.local/state/flywheel/state-md-miner"
  local audit_log_dir; audit_log_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"
  local bash_status="fail" jq_status="fail" mktemp_status="fail" python_status="fail"
  local roster_status="warn" state_dir_status="warn" audit_dir_status="fail"
  local overall="pass"

  if command -v bash >/dev/null 2>&1; then bash_status="pass"; fi
  if command -v jq >/dev/null 2>&1; then jq_status="pass"; fi
  if command -v mktemp >/dev/null 2>&1; then mktemp_status="pass"; fi
  if command -v python3 >/dev/null 2>&1; then python_status="pass"; fi
  if [[ -r "$roster" ]]; then roster_status="pass"; fi
  if [[ -d "$state_dir" && -w "$state_dir" ]]; then state_dir_status="pass"; fi
  if [[ -d "$audit_log_dir" && -w "$audit_log_dir" ]]; then audit_dir_status="pass"; fi

  for st in "$bash_status" "$jq_status" "$mktemp_status" "$python_status"; do
    if [[ "$st" == "fail" ]]; then overall="fail"; fi
  done
  if [[ "$overall" == "pass" ]]; then
    for st in "$roster_status" "$state_dir_status" "$audit_dir_status"; do
      if [[ "$st" == "warn" || "$st" == "fail" ]]; then overall="warn"; fi
    done
  fi

  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg ts "$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg overall "$overall" \
    --arg bash_status "$bash_status" --arg jq_status "$jq_status" \
    --arg mktemp_status "$mktemp_status" --arg python_status "$python_status" \
    --arg roster "$roster" --arg roster_status "$roster_status" \
    --arg state_dir "$state_dir" --arg state_dir_status "$state_dir_status" \
    --arg audit_dir "$audit_log_dir" --arg audit_dir_status "$audit_dir_status" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$overall,
      checks:[
        {name:"bash_available",status:$bash_status},
        {name:"jq_available",status:$jq_status},
        {name:"mktemp_available",status:$mktemp_status},
        {name:"python3_available",status:$python_status,detail:"load-bearing for state-md-miner heredoc"},
        {name:"roster_readable",status:$roster_status,path:$roster,detail:"fleet roster source for multi-repo mining; warn if missing (single-repo mode still works via --repo)"},
        {name:"state_dir_writable",status:$state_dir_status,path:$state_dir,detail:"per-mining state output target"},
        {name:"audit_log_dir_writable",status:$audit_dir_status,path:$audit_dir}
      ]
    }'
}

scaffold_cmd_health() {
  local audit_log="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/state-md-miner-runs.jsonl}"
  local now ts last_run_ts="" age_seconds total_runs=0 recent_runs=0 status="pass"
  local stale_threshold="${STATE_MD_MINER_HEALTH_STALE_THRESHOLD_SECONDS:-129600}"
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
      local target="$HOME/.local/state/flywheel/state-md-miner"
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
    repo-path)
      if [[ -z "$arg" ]]; then
        printf 'ERR: validate repo-path requires VALUE arg\n' >&2; return 64
      fi
      if [[ "$arg" == /* ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg p "$arg" \
          '{schema_version:$sv,command:"validate",subject:"repo-path",ts:$ts,status:"ok",value:$p}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg p "$arg" \
          '{schema_version:$sv,command:"validate",subject:"repo-path",ts:$ts,status:"reject",value:$p,reason:"not_absolute_path",contract:"--repo arg must be an absolute path"}'
        return 1
      fi
      ;;
    stale-days)
      if [[ -z "$arg" ]]; then
        printf 'ERR: validate stale-days requires VALUE arg\n' >&2; return 64
      fi
      if [[ "$arg" =~ ^[0-9]+$ ]] && (( arg >= 1 && arg <= 365 )); then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --argjson v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"stale-days",ts:$ts,status:"ok",value:$v}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"stale-days",ts:$ts,status:"reject",value:$v,reason:"out_of_range_or_not_integer",valid_range:"[1, 365]",default:14}'
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
        '{schema_version:$sv,command:"validate",status:"refused",reason:"missing_subject",valid_subjects:["repo-path","stale-days","audit-row"]}'
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg subj "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",subject:$subj,reason:"unknown_subject",valid_subjects:["repo-path","stale-days","audit-row"]}'
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
  local match; match="$(jq -c --arg id "$id" 'select(.ts == $id or (.repo // "") == $id or (.finding_id // "") == $id or (.run_id // "") == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | head -1 || true)"
  if [[ -z "$match" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"not_found",audit_log:$log,searched_keys:["ts","repo","finding_id","run_id"]}'
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
  # WZJO9.1.7 PARTIAL-BYPASS: state-md-miner.sh natively implements
  # --info / --schema / --examples in its python heredoc with rich
  # canonical envelopes (state-md-miner/v1 schema_version + full
  # JSON-Schema for the result envelope). Verb subcommands (doctor /
  # health / repair / validate / audit / why) are NOT natively supported
  # — scaffold owns those. (Sister to 5ke66.6 / 5ke66.11.)
  case "${1:-}" in
    doctor|health|repair|validate|audit|why|quickstart|completion) return 0 ;;
    --info|--schema|--examples) return 1 ;;  # PARTIAL-BYPASS to native
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
python3 - "$@" <<'PY'
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from collections import Counter, defaultdict
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any

SCHEMA_VERSION = "state-md-miner/v1"
DEFAULT_ROSTER = Path.home() / ".local/state/flywheel/fleet-roster.json"
DEFAULT_STATE_DIR = Path.home() / ".local/state/flywheel/state-md-miner"


def parse_ts(value: Any) -> datetime | None:
    if value is None:
        return None
    text = str(value).strip()
    if not text:
        return None
    if re.fullmatch(r"\d{4}-\d{2}-\d{2}", text):
        text = f"{text}T00:00:00Z"
    for candidate in (text, text.replace("Z", "+00:00")):
        try:
            parsed = datetime.fromisoformat(candidate)
            if parsed.tzinfo is None:
                parsed = parsed.replace(tzinfo=timezone.utc)
            return parsed.astimezone(timezone.utc)
        except ValueError:
            continue
    return None


def now_utc(raw: str | None = None) -> datetime:
    return parse_ts(raw) or datetime.now(timezone.utc)


def iso(dt: datetime) -> str:
    return dt.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def read_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text())
    except Exception:
        return None


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    rows: list[dict[str, Any]] = []
    try:
        lines = path.read_text(errors="replace").splitlines()
    except Exception:
        return rows
    for line in lines:
        if not line.strip():
            continue
        try:
            row = json.loads(line)
        except Exception:
            continue
        if isinstance(row, dict):
            rows.append(row)
    return rows


def write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(payload, sort_keys=True, indent=2) + "\n")
    tmp.replace(path)


def append_jsonl(path: Path, rows: list[dict[str, Any]]) -> None:
    if not rows:
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle:
        for row in rows:
            handle.write(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n")


def load_roster(roster: Path, root: Path, explicit_repo: str | None) -> list[dict[str, str]]:
    if explicit_repo:
        repo = Path(explicit_repo).expanduser().resolve()
        return [{"name": repo.name, "repo": str(repo), "source": "explicit"}]

    rows: list[dict[str, str]] = []
    data = read_json(roster)
    if isinstance(data, dict):
        for item in data.get("members") or []:
            if not isinstance(item, dict):
                continue
            repo = item.get("repo") or item.get("path")
            if repo:
                rows.append({"name": str(item.get("name") or Path(str(repo)).name), "repo": str(repo), "source": str(roster)})
    elif isinstance(data, list):
        for item in data:
            if isinstance(item, dict) and (item.get("repo") or item.get("path")):
                repo = item.get("repo") or item.get("path")
                rows.append({"name": str(item.get("name") or Path(str(repo)).name), "repo": str(repo), "source": str(roster)})

    if not rows and roster.suffix == ".jsonl":
        for item in read_jsonl(roster):
            repo = item.get("repo") or item.get("path")
            if repo:
                rows.append({"name": str(item.get("name") or Path(str(repo)).name), "repo": str(repo), "source": str(roster)})

    if not rows:
        for state in sorted(root.glob("*/.flywheel/STATE.md")):
            rows.append({"name": state.parent.parent.name, "repo": str(state.parent.parent), "source": "root-scan"})
    return rows


def state_paths(repo: Path) -> list[Path]:
    paths = [repo / ".flywheel/STATE.md", repo / "STATE.md"]
    seen: set[str] = set()
    result: list[Path] = []
    for path in paths:
        key = str(path)
        if key not in seen:
            seen.add(key)
            result.append(path)
    return result


def section_kind(heading: str) -> str | None:
    text = heading.lower()
    if "next action" in text or "next safe action" in text:
        return "unresolved"
    if "known gap" in text or "gap" in text or "blocker" in text:
        return "orphaned"
    if "deferred" in text or "parking" in text:
        return "stale"
    if "resume" in text or "handoff" in text:
        return "recurring"
    return None


def normalize_text(text: str) -> str:
    text = re.sub(r"`([^`]+)`", r"\1", text.lower())
    text = re.sub(r"\b[A-Za-z]+-[A-Za-z0-9.]+\b", " BEAD ", text)
    text = re.sub(r"[^a-z0-9]+", " ", text)
    return re.sub(r"\s+", " ", text).strip()[:100]


def bead_refs(text: str) -> list[str]:
    return sorted(set(re.findall(r"\b[A-Za-z]+-[A-Za-z0-9.]+\b", text)))


def classify_line(kind: str | None, line: str, stale_cutoff: datetime) -> str | None:
    lowered = line.lower()
    if re.search(r"\b(done|closed|complete|completed|resolved)\b", lowered):
        return None
    if kind == "stale":
        dates = [parse_ts(match.group(0)) for match in re.finditer(r"\b20\d{2}-\d{2}-\d{2}\b", line)]
        dates = [dt for dt in dates if dt is not None]
        if dates and min(dates) <= stale_cutoff:
            return "stale"
        if re.search(r"\b(deferred|parked|stale)\b", lowered):
            return "stale"
    if kind == "unresolved":
        return "unresolved"
    if kind == "orphaned":
        return "orphaned" if not bead_refs(line) else "unresolved"
    if kind == "recurring" and re.search(r"\b(again|recurr|reopened|drift|keeps?|still)\b", lowered):
        return "recurring"
    if re.search(r"\b(next action|known gap|deferred|blocked|todo|fix|repair|follow[- ]?up)\b", lowered):
        return kind or "unresolved"
    return None


def extract_items(repo_row: dict[str, str], now: datetime, stale_days: int) -> list[dict[str, Any]]:
    repo = Path(repo_row["repo"]).expanduser()
    stale_cutoff = now - timedelta(days=stale_days)
    findings: list[dict[str, Any]] = []
    for path in state_paths(repo):
        if not path.exists():
            continue
        try:
            lines = path.read_text(errors="replace").splitlines()
        except Exception:
            continue
        current_kind: str | None = None
        current_heading = ""
        for lineno, raw in enumerate(lines, 1):
            stripped = raw.strip()
            if stripped.startswith("#"):
                current_heading = stripped.lstrip("#").strip()
                current_kind = section_kind(current_heading)
                continue
            if not stripped:
                continue
            bullet = re.match(r"^(?:[-*]|\d+[.)])\s+(.*)$", stripped)
            if bullet:
                item_text = bullet.group(1).strip()
            elif current_kind and re.search(r"\b(next action|known gap|deferred|blocked|todo|fix|repair|follow[- ]?up)\b", stripped, re.I):
                item_text = stripped
            else:
                continue
            item_class = classify_line(current_kind, item_text, stale_cutoff)
            if not item_class:
                continue
            refs = bead_refs(item_text)
            findings.append({
                "class": item_class,
                "repo": str(repo.resolve()) if repo.exists() else str(repo),
                "repo_name": repo_row["name"],
                "state_path": str(path),
                "line": lineno,
                "heading": current_heading,
                "text": item_text,
                "normalized": normalize_text(item_text),
                "bead_refs": refs,
                "has_bead_ref": bool(refs),
            })
    return findings


def add_pattern_findings(findings: list[dict[str, Any]]) -> None:
    repos_by_norm: dict[str, set[str]] = defaultdict(set)
    by_norm: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for finding in findings:
        key = str(finding.get("normalized") or "")
        if not key:
            continue
        repos_by_norm[key].add(str(finding.get("repo")))
        by_norm[key].append(finding)
    for key, repos in repos_by_norm.items():
        if len(repos) < 3:
            continue
        for finding in by_norm[key]:
            finding["class"] = "pattern"
            finding["pattern_repo_count"] = len(repos)


def br_issues(repo: Path) -> list[dict[str, Any]]:
    try:
        proc = subprocess.run(
            ["br", "list", "--all", "--json", "--limit", "0"],
            cwd=str(repo),
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            timeout=20,
            check=False,
        )
    except Exception:
        return []
    try:
        data = json.loads(proc.stdout)
    except Exception:
        return []
    if isinstance(data, dict) and isinstance(data.get("issues"), list):
        return [row for row in data["issues"] if isinstance(row, dict)]
    if isinstance(data, list):
        return [row for row in data if isinstance(row, dict)]
    return []


def existing_bead(repo: Path, finding: dict[str, Any]) -> str | None:
    needle = f"[state-md-miner] {finding['class']} {finding['normalized'][:80]}"
    for issue in br_issues(repo):
        if str(issue.get("title") or "") == needle:
            return str(issue.get("id") or "")
    return None


def create_bead(repo: Path, finding: dict[str, Any]) -> str | None:
    title = f"[state-md-miner] {finding['class']} {finding['normalized'][:80]}"
    body = "\n".join([
        "## Source",
        "",
        f"- repo: `{repo}`",
        f"- state_path: `{finding['state_path']}`",
        f"- line: {finding['line']}",
        f"- class: `{finding['class']}`",
        "",
        "## Finding",
        "",
        finding["text"],
        "",
        "## Acceptance Criteria",
        "",
        "1. Decide whether the STATE.md item is still valid.",
        "2. Either implement the item or close this bead with an explicit stale/no-longer-needed reason.",
        "3. Update the source STATE.md line or add a bead reference so the next mine does not rediscover it as orphaned.",
        "",
        "## Three-Q",
        "",
        "VALIDATED: source STATE.md line no longer mines as unresolved/orphaned/stale.",
        "DOCUMENTED: source state or close reason records the decision.",
        "SURFACED: bead/no-bead decision is visible to `/flywheel:learn --mine-state`.",
    ])
    existing = existing_bead(repo, finding)
    if existing:
        return existing
    try:
        proc = subprocess.run(
            ["br", "create", title, "--type", "task", "--priority", "2", "--description", body, "--json"],
            cwd=str(repo),
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=30,
            check=False,
        )
    except Exception:
        return None
    if proc.returncode != 0:
        return None
    try:
        data = json.loads(proc.stdout)
    except Exception:
        return None
    return str(data.get("id") or data.get("issue", {}).get("id") or "") or None


def decide(args: argparse.Namespace, findings: list[dict[str, Any]], now: datetime) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    decisions: list[dict[str, Any]] = []
    ledger_rows: list[dict[str, Any]] = []
    per_repo_filed: Counter[str] = Counter()
    for finding in findings:
        repo = Path(finding["repo"])
        row = {
            "ts": iso(now),
            "schema_version": SCHEMA_VERSION,
            "repo": finding["repo"],
            "class": finding["class"],
            "state_path": finding["state_path"],
            "line": finding["line"],
            "text": finding["text"],
            "bead_id": None,
            "decision": "planned",
            "no_bead_reason": None,
        }
        if finding.get("has_bead_ref"):
            row["decision"] = "existing_bead_reference"
            row["bead_id"] = ",".join(finding.get("bead_refs") or [])
            row["no_bead_reason"] = "source_state_line_already_references_bead"
        elif args.dry_run or not args.apply:
            row["decision"] = "would_file_bead"
        elif per_repo_filed[finding["repo"]] >= args.max_beads_per_repo:
            row["decision"] = "no_bead_reason"
            row["no_bead_reason"] = "daily_auto_bead_cap_exceeded"
        elif not (repo / ".beads").exists():
            row["decision"] = "no_bead_reason"
            row["no_bead_reason"] = "repo_has_no_beads_db"
        else:
            bead_id = create_bead(repo, finding)
            if bead_id:
                row["decision"] = "bead_filed_or_existing"
                row["bead_id"] = bead_id
                per_repo_filed[finding["repo"]] += 1
            else:
                row["decision"] = "no_bead_reason"
                row["no_bead_reason"] = "br_create_failed"
        decisions.append(row)
        if args.apply and not args.dry_run:
            ledger_rows.append(row)
    return decisions, ledger_rows


def schema() -> dict[str, Any]:
    return {
        "$schema": "https://json-schema.org/draft/2020-12/schema",
        "title": "state-md-miner result",
        "type": "object",
        "required": ["schema_version", "status", "findings_count", "findings", "decisions"],
        "properties": {
            "schema_version": {"const": SCHEMA_VERSION},
            "status": {"enum": ["pass", "warn", "fail"]},
            "findings_count": {"type": "integer"},
            "findings": {"type": "array"},
            "decisions": {"type": "array"},
        },
    }


def run(args: argparse.Namespace) -> dict[str, Any]:
    now = now_utc(args.now)
    roster = Path(args.roster).expanduser()
    root = Path(args.root).expanduser()
    repos = load_roster(roster, root, args.repo)
    findings: list[dict[str, Any]] = []
    missing_state: list[str] = []
    for repo_row in repos:
        repo = Path(repo_row["repo"]).expanduser()
        before = len(findings)
        findings.extend(extract_items(repo_row, now, args.stale_days))
        if len(findings) == before and not any(path.exists() for path in state_paths(repo)):
            missing_state.append(str(repo))
    add_pattern_findings(findings)
    findings.sort(key=lambda row: (row["repo_name"], row["class"], row["state_path"], row["line"]))
    decisions, ledger_rows = decide(args, findings, now)
    counts = Counter(str(row["class"]) for row in findings)
    state_dir = Path(args.state_dir).expanduser()
    payload = {
        "schema_version": SCHEMA_VERSION,
        "status": "warn" if findings else "pass",
        "mode": "apply" if args.apply and not args.dry_run else ("doctor" if args.doctor else "dry-run"),
        "generated_at": iso(now),
        "roster": str(roster),
        "repos_checked": len(repos),
        "state_files_missing_count": len(missing_state),
        "missing_state_repos": missing_state[:10],
        "findings_count": len(findings),
        "class_counts": dict(sorted(counts.items())),
        "findings": findings,
        "decisions": decisions,
        "audit_log": str(state_dir / "decisions.jsonl"),
        "latest_json": str(state_dir / "latest.json"),
    }
    if args.apply and not args.dry_run:
        append_jsonl(state_dir / "decisions.jsonl", ledger_rows)
        write_json(state_dir / "latest.json", payload)
    return payload


def finding_decision_key(row: dict[str, Any]) -> tuple[str, str, str, str, str]:
    return (
        str(row.get("repo") or ""),
        str(row.get("state_path") or ""),
        str(row.get("line") or ""),
        str(row.get("class") or ""),
        str(row.get("text") or ""),
    )


def decision_is_mined(row: dict[str, Any]) -> bool:
    decision = str(row.get("decision") or "")
    if decision == "existing_bead_reference":
        return bool(row.get("bead_id") or row.get("no_bead_reason"))
    if decision == "bead_filed_or_existing":
        return bool(row.get("bead_id"))
    if decision == "no_bead_reason":
        return str(row.get("no_bead_reason") or "") not in {"", "br_create_failed"}
    return False


def mined_decision_keys(latest: dict[str, Any] | None) -> set[tuple[str, str, str, str, str]]:
    if not isinstance(latest, dict):
        return set()
    decisions = latest.get("decisions")
    if not isinstance(decisions, list):
        return set()
    return {
        finding_decision_key(row)
        for row in decisions
        if isinstance(row, dict) and decision_is_mined(row)
    }


def doctor(args: argparse.Namespace) -> dict[str, Any]:
    args.dry_run = True
    args.apply = False
    payload = run(args)
    latest_path = Path(args.state_dir).expanduser() / "latest.json"
    latest = read_json(latest_path)
    last_run_age_hours = None
    if isinstance(latest, dict):
        ts = parse_ts(latest.get("generated_at"))
        if ts:
            last_run_age_hours = round((now_utc(args.now) - ts).total_seconds() / 3600, 2)
    warnings = []
    if last_run_age_hours is None:
        warnings.append({"code": "state_md_miner_never_applied", "message": "no applied STATE.md mine receipt found"})
    elif last_run_age_hours > 24:
        warnings.append({"code": "state_md_miner_stale", "message": f"last applied STATE.md mine age {last_run_age_hours}h exceeds 24h"})
    mined_keys = mined_decision_keys(latest if isinstance(latest, dict) else None)
    unmined_findings = [
        finding for finding in payload["findings"]
        if finding_decision_key(finding) not in mined_keys
    ]
    return {
        "schema_version": SCHEMA_VERSION,
        "status": "warn" if unmined_findings or warnings else "pass",
        "state_md_unmined_count": len(unmined_findings),
        "state_md_findings_count": payload["findings_count"],
        "state_md_mined_count": payload["findings_count"] - len(unmined_findings),
        "state_md_last_run_age_hours": last_run_age_hours,
        "state_md_class_counts": payload["class_counts"],
        "state_md_top_findings": unmined_findings[:5],
        "repos_checked": payload["repos_checked"],
        "warnings": warnings,
        "errors": [],
    }


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="Mine fleet STATE.md files for /flywheel:learn opportunities.")
    parser.add_argument("--repo", help="Mine a single repo instead of the fleet roster.")
    parser.add_argument("--root", default="/Users/josh/Developer")
    parser.add_argument("--roster", default=str(DEFAULT_ROSTER))
    parser.add_argument("--since", default="24h", help="Reserved for compatibility; STATE mining is current-state based.")
    parser.add_argument("--stale-days", type=int, default=14)
    parser.add_argument("--max-beads-per-repo", type=int, default=5)
    parser.add_argument("--state-dir", default=str(DEFAULT_STATE_DIR))
    parser.add_argument("--now", default=os.environ.get("FLYWHEEL_STATE_MD_MINER_NOW"))
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--dry-run", action="store_true", default=True)
    parser.add_argument("--apply", action="store_true")
    parser.add_argument("--doctor", action="store_true")
    parser.add_argument("--schema", action="store_true")
    parser.add_argument("--info", action="store_true")
    parser.add_argument("--examples", action="store_true")
    args = parser.parse_args(argv)
    if args.apply:
        args.dry_run = False
    if args.schema:
        print(json.dumps(schema(), sort_keys=True, separators=(",", ":")))
        return 0
    if args.info:
        print(json.dumps({"schema_version": SCHEMA_VERSION, "script": __file__, "default_roster": str(DEFAULT_ROSTER), "default_state_dir": str(DEFAULT_STATE_DIR)}, sort_keys=True, separators=(",", ":")))
        return 0
    if args.examples:
        print(".flywheel/scripts/state-md-miner.sh --json")
        print(".flywheel/scripts/state-md-miner.sh --repo /Users/josh/Developer/flywheel --dry-run --json")
        print(".flywheel/scripts/state-md-miner.sh --apply --max-beads-per-repo 5 --json")
        return 0
    if args.doctor:
        result = doctor(args)
    else:
        result = run(args)
    if args.json or args.doctor:
        print(json.dumps(result, sort_keys=True, separators=(",", ":")))
    else:
        print(f"findings={result['findings_count']} status={result['status']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
PY

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
