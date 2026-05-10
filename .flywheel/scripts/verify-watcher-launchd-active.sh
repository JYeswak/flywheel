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

SCAFFOLD_SCHEMA_VERSION="verify-watcher-launchd-active/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/verify-watcher-launchd-active-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: verify-watcher-launchd-active.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "verify-watcher-launchd-active.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "verify-watcher-launchd-active.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"verify-watcher-launchd-active.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"verify-watcher-launchd-active.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"verify-watcher-launchd-active.sh doctor --json"}'
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
        '{schema_version:$sv,command:"schema",surface:"repair",scopes:["state_dir","audit_log_dir"],contract:{requires_idempotency_key_when_apply:true,refusal_exit_code:3,dry_run_default:true}}'
      ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"validate",subjects:["launchd-label","session-name","audit-row"],contract:{rejects_with_rc1:"on schema violation",launchd_label_pattern:"^ai\\.zeststream\\.[a-z0-9-]+$",session_name_pattern:"^[a-z0-9-]+$"}}'
      ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"audit",audit_log_env:"SCAFFOLD_AUDIT_LOG",row_shape:{ts:"ISO8601",action:"string"},limit_default:20}'
      ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"why",input:"id (ts OR launchd_label OR session OR run_id)",states:["found","not_found","unavailable"],source:"$SCAFFOLD_AUDIT_LOG"}'
      ;;
    audit-row)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"audit-row",required_fields:["ts","action"],optional_fields:["status","launchd_label","session","scope","mode","idempotency_key"]}'
      ;;
    default|*)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surfaces:["doctor","health","repair","validate","audit","why","audit-row"],note:"verify-watcher-launchd-active.sh = verify per-session launchd watcher daemons (codex-stuck-detector + coordinator + per-session detectors) are loaded + active"}'
      ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — default backward-compatible invocation: verify per-session launchd watcher daemons are loaded + active under DOMAIN gui/$(id -u); checks ledger freshness within MAX_AGE_SECONDS\n' ;;
    doctor)   printf 'topic: doctor — substrate probes: bash, jq, mktemp, launchctl available (load-bearing for launchd verification), detector script executable, pattern test executable, audit_log_dir writable\n' ;;
    health)   printf 'topic: health — tails $SCAFFOLD_AUDIT_LOG (default ~/.local/state/flywheel/verify-watcher-launchd-active-runs.jsonl); reports last_run_ts, age_seconds, recent_runs, total_runs; status=warn at >24h stale\n' ;;
    repair)   printf 'topic: repair --scope <state_dir|audit_log_dir> [--dry-run|--apply --idempotency-key KEY] — apply contract: --apply requires --idempotency-key (rc=3 refusal); scopes: state_dir (mkdir -p ~/.local/state/flywheel), audit_log_dir (mkdir -p $SCAFFOLD_AUDIT_LOG dirname)\n' ;;
    validate) printf 'topic: validate <subject> [PATH|VALUE] — subjects: launchd-label (matches ^ai\\.zeststream\\.[a-z0-9-]+$), session-name (matches ^[a-z0-9-]+$), audit-row (JSONL ts + action required); rc=1 on schema violation\n' ;;
    audit)    printf 'topic: audit [--limit N] — tail $SCAFFOLD_AUDIT_LOG via cli_emit_audit_tail (path-then-schema positional); default limit=20\n' ;;
    why)      printf 'topic: why <id> — provenance lookup against $SCAFFOLD_AUDIT_LOG; matches against ts/launchd_label/session/run_id; states: found / not_found / unavailable\n' ;;
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
            && cli_emit_completion_bash "verify-watcher-launchd-active" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "verify-watcher-launchd-active" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  local repo_root; repo_root="$(git rev-parse --show-toplevel 2>/dev/null || echo "")"
  local detector="$repo_root/.flywheel/scripts/codex-template-stuck-detector.sh"
  local pattern_test="$repo_root/.flywheel/tests/test-detector-pattern-bank-replay.sh"
  local audit_log_dir; audit_log_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"
  local bash_status="fail" jq_status="fail" mktemp_status="fail"
  local launchctl_status="fail" detector_status="warn" pattern_test_status="warn" audit_dir_status="fail"
  local overall="pass"

  if command -v bash >/dev/null 2>&1; then bash_status="pass"; fi
  if command -v jq >/dev/null 2>&1; then jq_status="pass"; fi
  if command -v mktemp >/dev/null 2>&1; then mktemp_status="pass"; fi
  if command -v launchctl >/dev/null 2>&1; then launchctl_status="pass"; fi
  if [[ -x "$detector" ]]; then detector_status="pass"; fi
  if [[ -x "$pattern_test" ]]; then pattern_test_status="pass"; fi
  if [[ -d "$audit_log_dir" && -w "$audit_log_dir" ]]; then audit_dir_status="pass"; fi

  for st in "$bash_status" "$jq_status" "$mktemp_status" "$launchctl_status"; do
    if [[ "$st" == "fail" ]]; then overall="fail"; fi
  done
  if [[ "$overall" == "pass" ]]; then
    for st in "$detector_status" "$pattern_test_status" "$audit_dir_status"; do
      if [[ "$st" == "warn" || "$st" == "fail" ]]; then overall="warn"; fi
    done
  fi

  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg ts "$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg overall "$overall" \
    --arg bash_status "$bash_status" \
    --arg jq_status "$jq_status" \
    --arg mktemp_status "$mktemp_status" \
    --arg launchctl_status "$launchctl_status" \
    --arg detector "$detector" --arg detector_status "$detector_status" \
    --arg pattern_test "$pattern_test" --arg pattern_test_status "$pattern_test_status" \
    --arg audit_dir "$audit_log_dir" --arg audit_dir_status "$audit_dir_status" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$overall,
      checks:[
        {name:"bash_available",status:$bash_status},
        {name:"jq_available",status:$jq_status},
        {name:"mktemp_available",status:$mktemp_status},
        {name:"launchctl_available",status:$launchctl_status},
        {name:"detector_executable",status:$detector_status,path:$detector},
        {name:"pattern_test_executable",status:$pattern_test_status,path:$pattern_test},
        {name:"audit_log_dir_writable",status:$audit_dir_status,path:$audit_dir}
      ]
    }'
}

scaffold_cmd_health() {
  local audit_log="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/verify-watcher-launchd-active-runs.jsonl}"
  local now ts last_run_ts="" age_seconds total_runs=0 recent_runs=0 status="pass"
  local stale_threshold="${VERIFY_WATCHER_HEALTH_STALE_THRESHOLD_SECONDS:-86400}"
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
      local target="$HOME/.local/state/flywheel"
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
    launchd-label)
      if [[ -z "$arg" ]]; then
        printf 'ERR: validate launchd-label requires VALUE arg\n' >&2; return 64
      fi
      if [[ "$arg" =~ ^ai\.zeststream\.[a-z0-9-]+$ ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg label "$arg" \
          '{schema_version:$sv,command:"validate",subject:"launchd-label",ts:$ts,status:"ok",value:$label}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg label "$arg" \
          '{schema_version:$sv,command:"validate",subject:"launchd-label",ts:$ts,status:"reject",value:$label,reason:"pattern_mismatch",pattern:"^ai\\.zeststream\\.[a-z0-9-]+$"}'
        return 1
      fi
      ;;
    session-name)
      if [[ -z "$arg" ]]; then
        printf 'ERR: validate session-name requires VALUE arg\n' >&2; return 64
      fi
      if [[ "$arg" =~ ^[a-z0-9-]+$ ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg s "$arg" \
          '{schema_version:$sv,command:"validate",subject:"session-name",ts:$ts,status:"ok",value:$s}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg s "$arg" \
          '{schema_version:$sv,command:"validate",subject:"session-name",ts:$ts,status:"reject",value:$s,reason:"pattern_mismatch",pattern:"^[a-z0-9-]+$"}'
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
        '{schema_version:$sv,command:"validate",status:"refused",reason:"missing_subject",valid_subjects:["launchd-label","session-name","audit-row"]}'
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg subj "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",subject:$subj,reason:"unknown_subject",valid_subjects:["launchd-label","session-name","audit-row"]}'
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
  local match; match="$(jq -c --arg id "$id" 'select(.ts == $id or .launchd_label == $id or .session == $id or (.run_id // "") == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | head -1 || true)"
  if [[ -z "$match" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"not_found",audit_log:$log,searched_keys:["ts","launchd_label","session","run_id"]}'
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
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
LAUNCHCTL="${WATCHER_LAUNCHD_LAUNCHCTL:-launchctl}"
LEDGER="${WATCHER_DETECTOR_LEDGER:-$HOME/.local/state/flywheel/codex-stuck-detector.jsonl}"
TOPOLOGY="${WATCHER_SESSION_TOPOLOGY:-$HOME/.local/state/flywheel/session-topology.jsonl}"
MAX_AGE_SECONDS="${WATCHER_MAX_AGE_SECONDS:-90}"
DOMAIN="${WATCHER_LAUNCHD_DOMAIN:-gui/$(id -u)}"
PRIMARY_LOG="${WATCHER_PRIMARY_LOG:-$HOME/.local/logs/codex-template-stuck-detector-watchdog.out.log}"
SESSION_LOG_DIR="${WATCHER_SESSION_LOG_DIR:-$HOME/.local/state/flywheel}"
SUBCLASS="post_callback_reminder_template_with_stale_spinner"
PATTERN_TEST="$ROOT/.flywheel/tests/test-detector-pattern-bank-replay.sh"
DETECTOR="$ROOT/.flywheel/scripts/codex-template-stuck-detector.sh"

DEFAULT_SPECS=(
  "ai.zeststream.codex-stuck-detector-watchdog:flywheel:primary"
  "ai.zeststream.flywheel-coordinator-daemon:flywheel:coordinator"
  "ai.zeststream.mobile-eats-codex-stuck-detector:mobile-eats:session"
  "ai.zeststream.skillos-codex-stuck-detector:skillos:session"
  "ai.zeststream.alps-codex-stuck-detector:alpsinsurance:session"
  "ai.zeststream.vrtx-codex-stuck-detector:vrtx:session"
)

fail() {
  printf 'FAIL: %s\n' "$1"
  exit 1
}

log_for_session() {
  if [[ "$1" == "flywheel" ]]; then
    printf '%s\n' "$PRIMARY_LOG"
  else
    printf '%s\n' "$SESSION_LOG_DIR/codex-stuck-detector.$1.log"
  fi
}

latest_for_session() {
  python3 -c 'import json, sys
from datetime import datetime, timezone
from pathlib import Path

ledger, log_path, session, max_age_raw = sys.argv[1:5]
max_age = int(float(max_age_raw))
latest = None
latest_source = None

def row_matches_session(row):
    if row.get("session") == session:
        return True
    panes = row.get("panes")
    if isinstance(panes, list):
        return any(isinstance(pane, dict) and pane.get("session") == session for pane in panes)
    return False

def parse_ts(raw):
    if not isinstance(raw, str):
        return None
    try:
        dt = datetime.fromisoformat(raw.replace("Z", "+00:00"))
    except ValueError:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)

for source, path_raw in (("ledger", ledger), ("launchd-log", log_path)):
    path = Path(path_raw)
    if not path.exists() or path.stat().st_size == 0:
        continue
    with path.open(encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            try:
                row = json.loads(line)
            except json.JSONDecodeError:
                continue
            if not row_matches_session(row):
                continue
            dt = parse_ts(row.get("ts"))
            if dt is None:
                continue
            if latest is None or dt > latest:
                latest = dt
                latest_source = source

if latest is None:
    raise SystemExit(f"no detector timestamp for session={session} sources={ledger},{log_path}")
age = (datetime.now(timezone.utc) - latest).total_seconds()
if age < 0:
    age = 0
latest_s = latest.isoformat().replace("+00:00", "Z")
if age > max_age:
    raise SystemExit(f"last-run-ts stale: session={session} ts={latest_s} age_seconds={int(age)} max_age_seconds={max_age}")
print(f"{latest_s} {latest_source} {int(age)}")' "$LEDGER" "$(log_for_session "$1")" "$1" "$MAX_AGE_SECONDS"
}

topology_has_session() {
  python3 -c 'import json, sys
path, wanted = sys.argv[1:3]
latest = {}
with open(path, encoding="utf-8") as handle:
    for line in handle:
        line = line.strip()
        if not line:
            continue
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        session = row.get("session")
        if not session:
            continue
        prev = latest.get(session)
        if prev is None or str(row.get("effective_at") or "") >= str(prev.get("effective_at") or ""):
            latest[session] = row
row = latest.get(wanted)
if not row:
    raise SystemExit(f"missing latest topology row for session={wanted}")
if row.get("session_status") and "not_live" in str(row.get("session_status")):
    raise SystemExit(f"latest topology row is not live for session={wanted}")
' "$TOPOLOGY" "$1"
}

specs=("${DEFAULT_SPECS[@]}")
if [[ -n "${WATCHER_LAUNCHD_LABEL:-}" ]]; then
  specs=("${WATCHER_LAUNCHD_LABEL}:${WATCHER_LAUNCHD_SESSION:-flywheel}:primary")
fi

test -x "$DETECTOR" || fail "detector not executable: $DETECTOR"
test -f "$PATTERN_TEST" || fail "fixture-pinned subclass test missing: $PATTERN_TEST"
grep -q "$SUBCLASS" "$PATTERN_TEST" || fail "fixture-pinned subclass not referenced by pattern replay test"
test -s "$LEDGER" || fail "detector ledger missing or empty: $LEDGER"
test -s "$TOPOLOGY" || fail "session topology missing or empty: $TOPOLOGY"

max_observed_age=0
checked=0
for spec in "${specs[@]}"; do
  IFS=: read -r label session kind <<<"$spec"
  plist="${WATCHER_LAUNCHD_PLIST_DIR:-$HOME/Library/LaunchAgents}/${label}.plist"

  test -f "$plist" || fail "plist missing: $plist"
  grep -q "<string>${label}</string>" "$plist" || fail "installed plist label mismatch: $label"
  if [[ "$kind" == "coordinator" ]]; then
    grep -q "ntm-coordinator-pinned" "$plist" || fail "coordinator command missing from plist: $label"
    grep -q -- "--session=${session}" "$plist" || fail "coordinator session missing from plist: $label"
  else
    grep -q "codex-template-stuck-detector.sh" "$plist" || fail "scheduled detector path missing from plist: $label"
    grep -q -- "--worker-panes-from-topology" "$plist" || fail "scheduled topology path missing from plist: $label"
    grep -q -- "--apply" "$plist" || fail "scheduled apply path missing from plist: $label"
  fi
  if [[ "$kind" == "session" ]]; then
    grep -q -- "--auto-recover" "$plist" || fail "scheduled auto-recover missing from plist: $label"
    grep -q "select(.session==\"${session}\")" "$plist" || fail "session topology filter missing from plist: $label"
  fi
  "$LAUNCHCTL" print "$DOMAIN/$label" >/dev/null 2>&1 || fail "launchctl print failed: $DOMAIN/$label"
  topology_has_session "$session" || fail "topology latest-wins missing session=$session"
  if [[ "$kind" == "coordinator" ]]; then
    ps -axo command= | grep -F "ntm-coordinator-pinned" | grep -F -- "--session=${session}" >/dev/null || fail "coordinator process missing from ps: $label"
  fi

  if [[ "$kind" == "session" ]]; then
    latest="$(latest_for_session "$session")" || fail "$latest"
    age_seconds="${latest##* }"
    if [[ "$age_seconds" -gt "$max_observed_age" ]]; then
      max_observed_age="$age_seconds"
    fi
  fi
  checked=$((checked + 1))
done

printf 'OK_watcher_launchd_active labels_checked=%s gui_domain=%s last_run_max_age_seconds=%s\n' "$checked" "$DOMAIN" "$max_observed_age"
