#!/usr/bin/env bash
# Meta-pattern Adoption stance:
# Embodies MP-23-replayable-mutation-contract.md and MP-24-boundary-validation-fail-closed.md.
# Source: /Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/
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

SCAFFOLD_SCHEMA_VERSION="append-safe-write/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/append-safe-write-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: append-safe-write.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "append-safe-write.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "append-safe-write.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"append-safe-write.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"append-safe-write.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"append-safe-write.sh doctor --json"}'
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
        '{schema_version:$sv,command:"schema",surface:"repair",scopes:["scratch_dir","audit_log_dir"],contract:{requires_idempotency_key_when_apply:true,refusal_exit_code:3,dry_run_default:true},env:{scratch_dir:"TMPDIR (default /tmp; mktemp prefix append-safe-write.stdin.XXXXXX)",audit_log:"SCAFFOLD_AUDIT_LOG"}}'
      ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"validate",subjects:["target-path","lease-ms","audit-row"],contract:{rejects_with_rc1:"on schema violation",target_path_must_be_absolute:true,lease_ms_min_inclusive:1,lease_ms_max_inclusive:60000}}'
      ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"audit",audit_log_env:"SCAFFOLD_AUDIT_LOG",row_shape:{ts:"ISO8601",action:"string"},limit_default:20}'
      ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"why",input:"id (ts OR target OR idempotency_key OR run_id)",states:["found","not_found","unavailable"],source:"$SCAFFOLD_AUDIT_LOG"}'
      ;;
    audit-row)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"audit-row",required_fields:["ts","action"],optional_fields:["status","target","scope","mode","idempotency_key","attempts","divergences","bytes_appended"]}'
      ;;
    default|*)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surfaces:["doctor","health","repair","validate","audit","why","audit-row"],note:"append-safe-write.sh = stdin-payload append primitive with EOF-lease + tail-divergence retry; statuses: ok|lease_failed|tail_divergence_exhausted|readback_failed|invalid_args|idempotent_skip"}'
      ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — default backward-compatible invocation routes to cmd_run (python3 heredoc): reads stdin payload, captures it via $APPEND_SAFE_PAYLOAD_FILE, then appends to --target with EOF-lease (--lease-ms default 300) + tail-divergence retry (--max-retries default 5); --idempotency-key skips if already-present; emits one of ok|lease_failed|tail_divergence_exhausted|readback_failed|invalid_args|idempotent_skip\n' ;;
    doctor)   printf 'topic: doctor — substrate probes: bash, jq, mktemp (load-bearing for stdin payload capture), python3 (load-bearing for heredoc + lock_paths/lease primitives), scratch_dir_writable ($TMPDIR for .stdin.XXXXXX prefix), audit_log_dir_writable\n' ;;
    health)   printf 'topic: health — tails $SCAFFOLD_AUDIT_LOG (default ~/.local/state/flywheel/append-safe-write-runs.jsonl); reports last_run_ts, age_seconds, recent_runs, total_runs; status=warn at >7d stale (on-demand primitive, weekly grace)\n' ;;
    repair)   printf 'topic: repair --scope <scratch_dir|audit_log_dir> [--dry-run|--apply --idempotency-key KEY] — apply contract: --apply requires --idempotency-key (rc=3 refusal); scopes: scratch_dir (mkdir -p $TMPDIR for stdin-payload mktemp), audit_log_dir (mkdir -p $SCAFFOLD_AUDIT_LOG dirname)\n' ;;
    validate) printf 'topic: validate <subject> [PATH|VALUE] — subjects: target-path (must be absolute path; rejects relative or empty), lease-ms (integer in [1,60000]; matches --lease-ms range; default 300), audit-row (JSONL ts + action required); rc=1 on schema violation\n' ;;
    audit)    printf 'topic: audit [--limit N] — tail $SCAFFOLD_AUDIT_LOG via cli_emit_audit_tail (path-then-schema positional); default limit=20\n' ;;
    why)      printf 'topic: why <id> — provenance lookup against $SCAFFOLD_AUDIT_LOG; matches against ts/target/idempotency_key/run_id; states: found / not_found / unavailable\n' ;;
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
            && cli_emit_completion_bash "append-safe-write" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "append-safe-write" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  local scratch_dir="${TMPDIR:-/tmp}"
  local audit_log_dir; audit_log_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"
  local bash_status="fail" jq_status="fail" mktemp_status="fail" python_status="fail"
  local scratch_dir_status="fail" audit_dir_status="fail"
  local overall="pass"

  if command -v bash >/dev/null 2>&1; then bash_status="pass"; fi
  if command -v jq >/dev/null 2>&1; then jq_status="pass"; fi
  if command -v mktemp >/dev/null 2>&1; then mktemp_status="pass"; fi
  if command -v python3 >/dev/null 2>&1; then python_status="pass"; fi
  if [[ -d "$scratch_dir" && -w "$scratch_dir" ]]; then scratch_dir_status="pass"; fi
  if [[ -d "$audit_log_dir" && -w "$audit_log_dir" ]]; then audit_dir_status="pass"; fi

  for st in "$bash_status" "$jq_status" "$mktemp_status" "$python_status" "$scratch_dir_status"; do
    if [[ "$st" == "fail" ]]; then overall="fail"; fi
  done
  if [[ "$overall" == "pass" && "$audit_dir_status" != "pass" ]]; then overall="warn"; fi

  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg ts "$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg overall "$overall" \
    --arg bash_status "$bash_status" --arg jq_status "$jq_status" \
    --arg mktemp_status "$mktemp_status" --arg python_status "$python_status" \
    --arg scratch_dir "$scratch_dir" --arg scratch_dir_status "$scratch_dir_status" \
    --arg audit_dir "$audit_log_dir" --arg audit_dir_status "$audit_dir_status" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$overall,
      checks:[
        {name:"bash_available",status:$bash_status},
        {name:"jq_available",status:$jq_status},
        {name:"mktemp_available",status:$mktemp_status,detail:"required for stdin-payload capture"},
        {name:"python3_available",status:$python_status,detail:"load-bearing for lock/lease/append heredoc"},
        {name:"scratch_dir_writable",status:$scratch_dir_status,path:$scratch_dir},
        {name:"audit_log_dir_writable",status:$audit_dir_status,path:$audit_dir}
      ]
    }'
}

scaffold_cmd_health() {
  local audit_log="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/append-safe-write-runs.jsonl}"
  local now ts last_run_ts="" age_seconds total_runs=0 recent_runs=0 status="pass"
  local stale_threshold="${APPEND_SAFE_WRITE_HEALTH_STALE_THRESHOLD_SECONDS:-604800}"
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
    -h|--help)
      scaffold_emit_topic_help validate
      return 0
      ;;
    target-path)
      if [[ -z "$arg" ]]; then
        printf 'ERR: validate target-path requires VALUE arg\n' >&2; return 64
      fi
      if [[ "$arg" == /* ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg p "$arg" \
          '{schema_version:$sv,command:"validate",subject:"target-path",ts:$ts,status:"ok",value:$p}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg p "$arg" \
          '{schema_version:$sv,command:"validate",subject:"target-path",ts:$ts,status:"reject",value:$p,reason:"not_absolute_path",contract:"target-path must be an absolute path (start with /)"}'
        return 1
      fi
      ;;
    lease-ms)
      if [[ -z "$arg" ]]; then
        printf 'ERR: validate lease-ms requires VALUE arg\n' >&2; return 64
      fi
      if [[ "$arg" =~ ^[0-9]+$ ]] && (( arg >= 1 && arg <= 60000 )); then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --argjson v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"lease-ms",ts:$ts,status:"ok",value:$v}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"lease-ms",ts:$ts,status:"reject",value:$v,reason:"out_of_range_or_not_integer",valid_range:"[1, 60000]"}'
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
        '{schema_version:$sv,command:"validate",status:"refused",reason:"missing_subject",valid_subjects:["target-path","lease-ms","audit-row"]}'
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg subj "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",subject:$subj,reason:"unknown_subject",valid_subjects:["target-path","lease-ms","audit-row"]}'
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
  local match; match="$(jq -c --arg id "$id" 'select(.ts == $id or (.target // "") == $id or (.idempotency_key // "") == $id or (.run_id // "") == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | head -1 || true)"
  if [[ -z "$match" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"not_found",audit_log:$log,searched_keys:["ts","target","idempotency_key","run_id"]}'
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
payload_file=""
if [[ " $* " != *" --info "* ]]; then
  payload_file="$(mktemp "${TMPDIR:-/tmp}/append-safe-write.stdin.XXXXXX")"
  trap 'rm -f "$payload_file"' EXIT
  cat >"$payload_file"
  export APPEND_SAFE_PAYLOAD_FILE="$payload_file"
fi
python3 - "$@" <<'PY'
from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import subprocess
import time
from pathlib import Path

VERSION = "append-safe-write/v1"
TAIL_BYTES = 4096

def emit(payload: dict, json_mode: bool) -> None:
    if json_mode:
        print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
    else:
        print(payload.get("message") or payload.get("status", "ok"))


def info(json_mode: bool) -> int:
    payload = {
        "schema_version": VERSION,
        "status": "ok",
        "exit_codes": {
            "0": "success",
            "1": "lease-failed",
            "2": "tail-divergence-exhausted",
            "3": "invalid-args",
        },
    }
    emit(payload, json_mode)
    return 0


def read_tail(path: Path) -> bytes:
    if not path.exists():
        return b""
    size = path.stat().st_size
    with path.open("rb") as handle:
        handle.seek(max(0, size - TAIL_BYTES))
        return handle.read()


def lock_paths(target: Path) -> tuple[Path, Path]:
    lock_dir = target.with_name(target.name + ".append-safe.lock")
    return lock_dir, lock_dir / "owner.json"


def stale(lock_dir: Path, owner: Path, lease_ms: int) -> bool:
    threshold = max(lease_ms * 2, 1) / 1000.0
    now = time.time()
    try:
        raw = json.loads(owner.read_text(encoding="utf-8"))
        created = float(raw.get("created_at_epoch", 0))
    except Exception:
        try:
            created = lock_dir.stat().st_mtime
        except FileNotFoundError:
            return False
    return now - created > threshold


def acquire(lock_dir: Path, owner: Path, lease_ms: int) -> bool:
    deadline = time.monotonic() + max(lease_ms, 1) / 1000.0
    while True:
        try:
            lock_dir.mkdir(mode=0o700)
            owner.write_text(json.dumps({
                "pid": os.getpid(),
                "created_at_epoch": time.time(),
                "host": os.uname().nodename,
            }), encoding="utf-8")
            return True
        except FileExistsError:
            if stale(lock_dir, owner, lease_ms):
                shutil.rmtree(lock_dir, ignore_errors=True)
                continue
            if time.monotonic() >= deadline:
                return False
            time.sleep(0.01)


def release(lock_dir: Path) -> None:
    shutil.rmtree(lock_dir, ignore_errors=True)


def sleep_env_ms(name: str) -> None:
    try:
        ms = int(os.environ.get(name, "0"))
    except ValueError:
        ms = 0
    if ms > 0:
        time.sleep(ms / 1000.0)


def maybe_force_diverge(target: Path, attempt: int) -> None:
    once = os.environ.get("APPEND_SAFE_TEST_DIVERGE_ONCE")
    each = os.environ.get("APPEND_SAFE_TEST_DIVERGE_EACH_ATTEMPT")
    if each or (once and attempt == 1):
        target.parent.mkdir(parents=True, exist_ok=True)
        with target.open("ab") as handle:
            handle.write(f"test-diverge-{attempt}\n".encode())
            handle.flush()
            os.fsync(handle.fileno())


def contains_key(target: Path, key: str) -> bool:
    if not target.exists():
        return False
    with target.open("rb") as handle:
        return key.encode() in handle.read()


def append_payload(target: Path, payload: bytes) -> None:
    target.parent.mkdir(parents=True, exist_ok=True)
    data = payload if payload.endswith(b"\n") else payload + b"\n"
    with target.open("ab") as handle:
        handle.write(data)
        handle.flush()
        os.fsync(handle.fileno())


def truthy_env(name: str, default: str = "1") -> bool:
    return os.environ.get(name, default).strip().lower() not in {"0", "false", "no", "off"}


def listify(value) -> list[str]:
    if value is None or value == "":
        return []
    if isinstance(value, list):
        return [str(item) for item in value if str(item)]
    return [part for part in (str(value).replace(",", " ").split()) if part]


def nested(row: dict, *keys):
    cur = row
    for key in keys:
        if not isinstance(cur, dict):
            return None
        cur = cur.get(key)
    return cur


def compact_join(values: list[str], fallback: str = "none") -> str:
    return ",".join(values) if values else fallback


def append_jsonl(path: Path, row: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(row, sort_keys=True, separators=(",", ":")) + "\n")


def ledger_contains(path: Path, key: str) -> bool:
    if not path.exists():
        return False
    try:
        with path.open("r", encoding="utf-8") as handle:
            for line in handle:
                if f'"callback_key":"{key}"' in line:
                    return True
    except OSError:
        return False
    return False


def maybe_emit_pane1_sprint_complete(target: Path, payload: bytes) -> dict | None:
    if not truthy_env("FLYWHEEL_PANE1_SPRINT_CALLBACK_ENABLED", "1"):
        return None
    if target.name != "dispatch-log.jsonl":
        return None
    try:
        row = json.loads(payload.decode("utf-8").strip())
    except (UnicodeDecodeError, json.JSONDecodeError):
        return None
    if not isinstance(row, dict):
        return None
    if row.get("schema_version") != "callback-envelope/v1":
        return None
    if row.get("mode") != "goal":
        return None
    status = str(row.get("status") or row.get("callback_status") or "").upper()
    if status not in {"DONE", "PASS", "PASSED"}:
        return None

    callback_key = hashlib.sha256(payload.strip()).hexdigest()
    ledger = Path(os.environ.get(
        "FLYWHEEL_PANE1_SPRINT_CALLBACK_LEDGER",
        str(Path.home() / ".local/state/flywheel/pane1-sprint-complete-bridge.jsonl"),
    )).expanduser().resolve(strict=False)
    if ledger_contains(ledger, callback_key):
        return {
            "name": "pane1_sprint_complete_bridge",
            "status": "skipped",
            "reason": "duplicate_callback_key",
            "callback_key": callback_key,
            "ledger": str(ledger),
        }

    task_id = str(row.get("task_id") or row.get("bead") or "unknown")
    beads_closed = listify(row.get("beads_closed") or row.get("bead_ids_closed") or nested(row, "details", "beads_closed"))
    if not beads_closed:
        bead = str(row.get("bead") or "")
        if bead:
            beads_closed = [bead]
        elif task_id.startswith("flywheel-"):
            beads_closed = [task_id]
    followups = listify(
        row.get("followup_beads")
        or row.get("follow_up_beads")
        or row.get("followups")
        or nested(row, "details", "followup_beads")
        or nested(row, "details", "follow_up_beads")
    )
    evidence = listify(row.get("evidence") or row.get("evidence_paths") or nested(row, "details", "evidence") or nested(row, "details", "evidence_paths"))
    picks_value = row.get("picks_completed") or nested(row, "details", "picks_completed")
    if picks_value in (None, ""):
        picks_value = len(beads_closed) if beads_closed else 1
    total_work_time = (
        row.get("total_work_time")
        or row.get("total_work_time_seconds")
        or row.get("work_time")
        or nested(row, "details", "total_work_time")
        or "unknown"
    )
    tests = str(row.get("tests") or nested(row, "details", "tests") or "unknown")
    commit = str(row.get("commit") or "unknown")
    sprint_id = str(row.get("sprint_id") or row.get("goal_id") or task_id)
    session = os.environ.get("FLYWHEEL_PANE1_SPRINT_CALLBACK_SESSION") or str(row.get("session") or "flywheel")
    pane = os.environ.get("FLYWHEEL_PANE1_SPRINT_CALLBACK_PANE", "1")
    ntm = os.environ.get("FLYWHEEL_PANE1_SPRINT_CALLBACK_NTM") or os.environ.get("NTM") or "/Users/josh/.local/bin/ntm"
    timeout_seconds = int(os.environ.get("FLYWHEEL_PANE1_SPRINT_CALLBACK_TIMEOUT_SECONDS", "60"))
    message = (
        f"SPRINT DONE: sprint={sprint_id} task={task_id} picks_completed={picks_value} "
        f"beads_closed={compact_join(beads_closed)} followups={compact_join(followups)} "
        f"total_work_time={total_work_time} commit={commit} tests={tests} "
        f"evidence={compact_join(evidence)}"
    )

    started = time.monotonic()
    ledger_row = {
        "schema_version": "pane1-sprint-complete-bridge/v1",
        "ts": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "event": "pane1_sprint_complete_bridge",
        "callback_key": callback_key,
        "session": session,
        "pane": pane,
        "task_id": task_id,
        "sprint_id": sprint_id,
        "message": message,
        "status": "pending",
    }
    try:
        proc = subprocess.run(
            [ntm, "send", session, f"--pane={pane}", "--no-cass-check", message],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=timeout_seconds,
            check=False,
        )
        elapsed = round(time.monotonic() - started, 3)
        status_text = "sent" if proc.returncode == 0 else "failed"
        ledger_row.update({
            "status": status_text,
            "ntm_rc": proc.returncode,
            "elapsed_seconds": elapsed,
            "stdout": proc.stdout.strip(),
            "stderr": proc.stderr.strip(),
        })
        append_jsonl(ledger, ledger_row)
        return {
            "name": "pane1_sprint_complete_bridge",
            "status": status_text,
            "session": session,
            "pane": pane,
            "task_id": task_id,
            "sprint_id": sprint_id,
            "callback_key": callback_key,
            "elapsed_seconds": elapsed,
            "ledger": str(ledger),
        }
    except Exception as exc:
        elapsed = round(time.monotonic() - started, 3)
        ledger_row.update({"status": "failed", "elapsed_seconds": elapsed, "error": str(exc)})
        append_jsonl(ledger, ledger_row)
        return {
            "name": "pane1_sprint_complete_bridge",
            "status": "failed",
            "task_id": task_id,
            "sprint_id": sprint_id,
            "callback_key": callback_key,
            "elapsed_seconds": elapsed,
            "ledger": str(ledger),
            "error": str(exc),
        }


def run(args: argparse.Namespace, payload: bytes) -> int:
    if not args.target or args.lease_ms <= 0 or args.max_retries < 0:
        emit({"schema_version": VERSION, "status": "invalid_args"}, args.json)
        return 3
    if not payload:
        emit({"schema_version": VERSION, "status": "invalid_args", "reason": "empty stdin"}, args.json)
        return 3

    target = Path(args.target).expanduser().resolve(strict=False)
    target.parent.mkdir(parents=True, exist_ok=True)
    lock_dir, owner = lock_paths(target)
    divergences = 0

    for attempt in range(1, args.max_retries + 2):
        before = read_tail(target)
        sleep_env_ms("APPEND_SAFE_TEST_SLEEP_AFTER_TAIL_MS")
        maybe_force_diverge(target, attempt)
        if not acquire(lock_dir, owner, args.lease_ms):
            emit({"schema_version": VERSION, "status": "lease_failed", "attempt": attempt}, args.json)
            return 1
        try:
            if read_tail(target) != before:
                divergences += 1
                if divergences > args.max_retries:
                    emit({
                        "schema_version": VERSION,
                        "status": "tail_divergence_exhausted",
                        "attempts": attempt,
                        "divergences": divergences,
                    }, args.json)
                    return 2
                continue
            if args.idempotency_key and contains_key(target, args.idempotency_key):
                emit({"schema_version": VERSION, "status": "ok", "idempotent_skip": True}, args.json)
                return 0
            append_payload(target, payload)
            tail = read_tail(target)
            data = payload if payload.endswith(b"\n") else payload + b"\n"
            ok = data in tail
            post_hook = maybe_emit_pane1_sprint_complete(target, payload) if ok else None
            emit({
                "schema_version": VERSION,
                "status": "ok" if ok else "readback_failed",
                "target": str(target),
                "attempts": attempt,
                "divergences": divergences,
                "bytes_appended": len(data),
                "idempotent_skip": False,
                "post_append_hooks": [post_hook] if post_hook else [],
            }, args.json)
            return 0 if ok else 1
        finally:
            release(lock_dir)
    return 2


parser = argparse.ArgumentParser(description="Append one stdin payload using a short EOF lease.")
parser.add_argument("--target")
parser.add_argument("--lease-ms", type=int, default=300)
parser.add_argument("--max-retries", type=int, default=5)
parser.add_argument("--idempotency-key")
parser.add_argument("--json", action="store_true")
parser.add_argument("--info", action="store_true")
ns = parser.parse_args()
if ns.info:
    raise SystemExit(info(ns.json))
payload_path = os.environ.get("APPEND_SAFE_PAYLOAD_FILE")
payload = Path(payload_path).read_bytes() if payload_path else b""
raise SystemExit(run(ns, payload))
PY

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
