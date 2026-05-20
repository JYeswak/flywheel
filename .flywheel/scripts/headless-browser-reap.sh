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
# specific logic was filled in by bead flywheel-1hshd.35 (NO-BYPASS variant).

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="headless-browser-reap/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/headless-browser-reap-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: headless-browser-reap.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "headless-browser-reap.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "headless-browser-reap.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"headless-browser-reap.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"headless-browser-reap.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"headless-browser-reap.sh doctor --json"}'
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
    doctor)   jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"doctor",emits:{schema_version:"string",command:"\"doctor\"",ts:"iso8601",status:"string",checks:"array<{name,status,note?}>"},notes:"probes bash/jq/ps/pkill, process_pattern (agent-browser-chrome), age_threshold_minutes (30), count_threshold (5), audit_log_dir"}' ;;
    health)   jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"health",emits:{schema_version:"string",command:"\"health\"",ts:"iso8601",status:"string",last_run_ts:"iso8601|null",audit_log:"path"},binds_audit_log:true}' ;;
    repair)   jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"repair",valid_scopes:["audit_log_dir","fixture_dir"],apply_contract:"--apply requires --idempotency-key (rc=3 refusal)",unknown_scope:"rc=64",emits:{schema_version:"string",command:"\"repair\"",ts:"iso8601",mode:"\"dry_run\"|\"apply\"",scope:"string",status:"\"ok\"|\"refused\""}}' ;;
    validate) jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"validate",valid_subjects:["process-pattern","age-minutes","reap-mode"],reap_mode_enum:["dry_run","apply"],age_minutes_default:30,age_minutes_range:"[1, 1440]",cross_source:"native --apply/--dry-run flag contract",emits:{schema_version:"string",command:"\"validate\"",subject:"string",ts:"iso8601",status:"\"ok\"|\"reject\"|\"refused\"",value:"any",reason:"string?"}}' ;;
    audit)    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"audit",emits:{schema_version:"string",command:"\"audit\"",ts:"iso8601",audit_log:"path",rows:"array<jsonl>",limit:"int"}}' ;;
    why)      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surface:"why",states:["found","not_found","unavailable"],searched_keys:["ts","run_id","pid","pattern"],emits:{schema_version:"string",command:"\"why\"",id:"string",ts:"iso8601",status:"string",row:"object?"}}' ;;
    *)        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"schema",surfaces:["doctor","health","repair","validate","audit","why"],variant:"NO-BYPASS",note:"native --dry-run/--apply/--json/--fixture/--now-epoch fall through to cmd_run"}' ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — native owns; reaps agent-browser-chrome processes older than 30m or all when count > 5. Flags: --dry-run (default), --apply, --json, --fixture PATH, --now-epoch EPOCH.\n' ;;
    doctor)   printf 'topic: doctor — probes bash/jq/ps/pkill, process_pattern (agent-browser-chrome), age + count thresholds, audit_log_dir.\n' ;;
    health)   printf 'topic: health — emits last_run_ts from audit log.\n' ;;
    repair)   printf 'topic: repair --scope <audit_log_dir|fixture_dir> [--dry-run|--apply --idempotency-key KEY] — apply needs key (rc=3). Unknown = rc=64.\n' ;;
    validate) printf 'topic: validate <process-pattern|age-minutes|reap-mode> VALUE — process-pattern non-empty string; age-minutes integer in [1, 1440] (default 30); reap-mode enum {dry_run, apply} cross-sourced with native --apply/--dry-run. Bare validate refuses rc=64.\n' ;;
    audit)    printf 'topic: audit [--limit N] — tails $SCAFFOLD_AUDIT_LOG (default 20 rows).\n' ;;
    why)      printf 'topic: why <id> — explains row by id; matches against ts / run_id / pid / pattern.\n' ;;
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
            && cli_emit_completion_bash "headless-browser-reap" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "headless-browser-reap" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  local checks=()
  if command -v bash >/dev/null 2>&1; then checks+=('{"name":"bash_available","status":"pass"}')
  else checks+=('{"name":"bash_available","status":"fail"}'); fi
  if command -v jq >/dev/null 2>&1; then checks+=('{"name":"jq_available","status":"pass"}')
  else checks+=('{"name":"jq_available","status":"fail"}'); fi
  if command -v ps >/dev/null 2>&1; then checks+=('{"name":"ps_available","status":"pass"}')
  else checks+=('{"name":"ps_available","status":"fail","note":"load-bearing — script enumerates processes via ps"}'); fi
  if command -v pkill >/dev/null 2>&1; then checks+=('{"name":"pkill_available","status":"pass"}')
  else checks+=('{"name":"pkill_available","status":"fail","note":"load-bearing — script kills via pkill on --apply"}'); fi
  checks+=('{"name":"process_pattern","status":"pass","pattern":"agent-browser-chrome","note":"canonical pattern target"}')
  checks+=('{"name":"thresholds","status":"pass","age_minutes":30,"count":5,"note":"defaults from native --help"}')
  local audit_dir; audit_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"
  if [[ -w "$audit_dir" || ( ! -e "$audit_dir" && -w "$(dirname "$audit_dir")" ) ]]; then
    checks+=('{"name":"audit_log_dir_writable","status":"pass","path":"'"$audit_dir"'"}')
  else
    checks+=('{"name":"audit_log_dir_writable","status":"fail","path":"'"$audit_dir"'"}')
  fi
  local arr; arr="[$(IFS=,; echo "${checks[*]}")]"
  local status="ok"
  if echo "$arr" | jq -e 'any(.status == "fail")' >/dev/null 2>&1; then status="degraded"; fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg st "$status" --argjson checks "$arr" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$st,checks:$checks}'
}

scaffold_cmd_health() {
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  local last_run_ts="null"
  if [[ -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    local raw; raw="$(tail -n 1 "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | jq -r '.ts // empty' 2>/dev/null || true)"
    if [[ -n "$raw" ]]; then last_run_ts="\"$raw\""; fi
  fi
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$SCAFFOLD_AUDIT_LOG" --argjson last "$last_run_ts" \
    '{schema_version:$sv,command:"health",ts:$ts,status:"ok",last_run_ts:$last,audit_log:$log,binds_audit_log:true}'
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
    audit_log_dir)
      local target; target="$(dirname "$SCAFFOLD_AUDIT_LOG")"
      local existed="true"; if [[ ! -d "$target" ]]; then existed="false"; fi
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$target"
        cli_audit_append --action repair --status apply --scope audit_log_dir \
          --idempotency-key "$idem_key" --target "$target" >/dev/null 2>&1 || true
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" --arg existed "$existed" \
        '{schema_version:$sv,command:"repair",status:"ok",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed_before:($existed == "true")}'
      ;;
    fixture_dir)
      local target="$HOME/.local/state/flywheel/headless-browser-reap-fixtures"
      local existed="true"; if [[ ! -d "$target" ]]; then existed="false"; fi
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$target"
        cli_audit_append --action repair --status apply --scope fixture_dir \
          --idempotency-key "$idem_key" --target "$target" >/dev/null 2>&1 || true
      fi
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg mode "$mode" \
        --arg scope "$scope" --arg idem "$idem_key" --arg target "$target" --arg existed "$existed" \
        '{schema_version:$sv,command:"repair",status:"ok",ts:$ts,mode:$mode,scope:$scope,idempotency_key:$idem,target:$target,existed_before:($existed == "true")}'
      ;;
    "")
      printf 'ERR: repair requires --scope <audit_log_dir|fixture_dir>\n' >&2
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",scope:$scope,reason:"unknown_scope",valid_scopes:["audit_log_dir","fixture_dir"]}'
      return 64 ;;
  esac
}

scaffold_cmd_validate() {
  local subject="${1:-}"; shift || true
  local arg="${1:-}"
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  case "$subject" in
    process-pattern)
      if [[ -z "$arg" ]]; then printf 'ERR: validate process-pattern requires VALUE\n' >&2; return 64; fi
      if [[ "$arg" =~ ^[A-Za-z][A-Za-z0-9_.-]*$ ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"process-pattern",ts:$ts,status:"ok",value:$v}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"process-pattern",ts:$ts,status:"reject",value:$v,reason:"pattern_mismatch",pattern:"^[A-Za-z][A-Za-z0-9_.-]*$"}'
        return 1
      fi
      ;;
    age-minutes)
      if [[ -z "$arg" ]]; then printf 'ERR: validate age-minutes requires VALUE\n' >&2; return 64; fi
      if [[ "$arg" =~ ^[0-9]+$ ]] && (( arg >= 1 && arg <= 1440 )); then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --argjson v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"age-minutes",ts:$ts,status:"ok",value:$v,default:30,note:"matches native 30m default"}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
          '{schema_version:$sv,command:"validate",subject:"age-minutes",ts:$ts,status:"reject",value:$v,reason:"out_of_range_or_not_integer",valid_range:"[1, 1440]"}'
        return 1
      fi
      ;;
    reap-mode)
      if [[ -z "$arg" ]]; then printf 'ERR: validate reap-mode requires VALUE\n' >&2; return 64; fi
      case "$arg" in
        dry_run|apply)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
            '{schema_version:$sv,command:"validate",subject:"reap-mode",ts:$ts,status:"ok",value:$v,source:"native --apply/--dry-run flag contract"}'
          return 0 ;;
        *)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
            '{schema_version:$sv,command:"validate",subject:"reap-mode",ts:$ts,status:"reject",value:$v,reason:"not_in_enum",valid_modes:["dry_run","apply"]}'
          return 1 ;;
      esac
      ;;
    "")
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"validate",status:"refused",reason:"missing_subject",valid_subjects:["process-pattern","age-minutes","reap-mode"]}'
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg subj "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",subject:$subj,reason:"unknown_subject",valid_subjects:["process-pattern","age-minutes","reap-mode"]}'
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
  local match; match="$(jq -c --arg id "$id" 'select(.ts == $id or (.run_id // "") == $id or (.pid // "") == $id or (.pattern // "") == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | head -1 || true)"
  if [[ -z "$match" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"not_found",audit_log:$log,searched_keys:["ts","run_id","pid","pattern"]}'
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
  # NO-BYPASS variant (verb-first): scaffold owns all canonical surfaces.
  # Native flags --dry-run/--apply/--json/--fixture/--now-epoch fall through.
  case "${1:-}" in
    doctor|health|repair|validate|audit|why|quickstart|completion) return 0 ;;
    --info|--schema|--examples) return 0 ;;
    -h|--help) return 0 ;;
    help)
      case "${2:-}" in run|doctor|health|repair|validate|audit|why|-h|--help) return 0 ;; esac
      return 1 ;;
  esac
  return 1
}

if [[ $# -gt 0 ]] && _scaffold_is_canonical_arg "$@"; then
  scaffold_main "$@"
  exit $?
fi
# ====== END canonical-cli scaffold ======
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
PROBE="${FLYWHEEL_HEADLESS_BROWSER_PROBE:-$ROOT/.flywheel/scripts/headless-browser-probe.sh}"
HISTORY="${FLYWHEEL_HEADLESS_BROWSER_REAP_HISTORY:-$HOME/.local/state/flywheel/headless-browser-reaps.jsonl}"
JSONL_APPEND_LIB="${FLYWHEEL_JSONL_APPEND_LIB:-$HOME/.local/share/flywheel-watchers/lib/jsonl-append.sh}"
JSONL_APPEND_AVAILABLE=0
MIN_AGE_MINUTES="${FLYWHEEL_HEADLESS_BROWSER_REAP_MIN_AGE_MINUTES:-30}"
COUNT_THRESHOLD="${FLYWHEEL_HEADLESS_BROWSER_REAP_COUNT_THRESHOLD:-5}"
APPLY=0
FIXTURE=""
NOW_EPOCH=""
NOTIFY=0
NOTIFY_BIN="${NOTIFY_BIN:-$HOME/.local/bin/notify}"

if [[ -f "$JSONL_APPEND_LIB" ]]; then
  # shellcheck disable=SC1090,SC1091
  if source "$JSONL_APPEND_LIB" && declare -F fw_jsonl_append_validated >/dev/null; then
    JSONL_APPEND_AVAILABLE=1
  fi
fi

usage() {
  printf '%s\n' \
    "Usage:" \
    "  headless-browser-reap.sh [--dry-run|--apply] [--json]" \
    "  headless-browser-reap.sh --fixture PATH [--dry-run] [--now-epoch EPOCH] [--json]" \
    "  headless-browser-reap.sh --help" \
    "" \
    "Candidates are agent-browser-chrome processes older than 30m, or all such processes when count > 5."
}

now_iso() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

append_jsonl_best_effort() {
  local path="$1" row="$2" label="$3" rc
  if [[ "$JSONL_APPEND_AVAILABLE" -ne 1 ]] || ! declare -F fw_jsonl_append_validated >/dev/null; then
    printf 'WARN: %s append skipped; JSONL primitive unavailable: %s\n' "$label" "$JSONL_APPEND_LIB" >&2
    return 0
  fi
  if fw_jsonl_append_validated "$path" "$row"; then
    return 0
  else
    rc=$?
    printf 'WARN: %s append failed rc=%s path=%s\n' "$label" "$rc" "$path" >&2
    return 0
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json|--dry-run)
      shift ;;
    --apply)
      APPLY=1; shift ;;
    --fixture)
      FIXTURE="${2:?missing fixture path}"; shift 2 ;;
    --now-epoch)
      NOW_EPOCH="${2:?missing epoch}"; shift 2 ;;
    --min-age-minutes)
      MIN_AGE_MINUTES="${2:?missing minutes}"; shift 2 ;;
    --count-threshold)
      COUNT_THRESHOLD="${2:?missing count}"; shift 2 ;;
    --history)
      HISTORY="${2:?missing history path}"; shift 2 ;;
    --notify)
      NOTIFY=1; shift ;;
    --help|-h)
      usage; exit 0 ;;
    *)
      printf 'unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 2 ;;
  esac
done

probe_args=(--json)
if [[ -n "$FIXTURE" ]]; then
  probe_args+=(--fixture "$FIXTURE")
fi
if [[ -n "$NOW_EPOCH" ]]; then
  probe_args+=(--now-epoch "$NOW_EPOCH")
fi

probe_json="$("$PROBE" "${probe_args[@]}")"
if ! jq -e . >/dev/null 2>&1 <<<"$probe_json"; then
  jq -nc '{version:"headless-browser-reap.v1",status:"error",reason:"probe_invalid_json"}'
  exit 1
fi

candidates_json="$(jq -c --argjson min_age "$MIN_AGE_MINUTES" --argjson threshold "$COUNT_THRESHOLD" '
  . as $root
  | [(.agent_browser_processes // [])[]
      | select((.age_minutes // 0) > $min_age or (($root.headless_agent_browser_count // 0) > $threshold))]
' <<<"$probe_json")"
candidate_count="$(jq 'length' <<<"$candidates_json")"
killed_pids_json="[]"
kill_errors_json="[]"

if [[ "$APPLY" -eq 1 && "$candidate_count" -gt 0 && -z "$FIXTURE" ]]; then
  mapfile -t pids < <(jq -r '.[].pid' <<<"$candidates_json")
  killed=()
  errors=()
  for pid in "${pids[@]}"; do
    if kill -TERM "$pid" 2>/dev/null; then
      killed+=("$pid")
    else
      errors+=("term_failed:$pid")
    fi
  done
  sleep 1
  for pid in "${pids[@]}"; do
    if kill -0 "$pid" 2>/dev/null; then
      if kill -KILL "$pid" 2>/dev/null; then
        :
      else
        errors+=("kill_failed:$pid")
      fi
    fi
  done
  killed_pids_json="$(printf '%s\n' "${killed[@]}" | jq -R 'select(length > 0) | tonumber' | jq -s .)"
  kill_errors_json="$(printf '%s\n' "${errors[@]}" | jq -R 'select(length > 0)' | jq -s .)"
elif [[ "$APPLY" -eq 1 && -n "$FIXTURE" ]]; then
  kill_errors_json='["fixture_mode_no_kill"]'
fi

if [[ "$NOTIFY" -eq 1 && "$candidate_count" -gt 0 && -x "$NOTIFY_BIN" ]]; then
  "$NOTIFY_BIN" "HEADLESS BROWSER LEAK" "agent-browser-chrome candidates=$candidate_count" >/dev/null 2>&1 || true
fi

ts="$(now_iso)"
payload="$(jq -nc \
  --arg version "headless-browser-reap.v1" \
  --arg ts "$ts" \
  --argjson apply "$([[ "$APPLY" -eq 1 ]] && printf true || printf false)" \
  --argjson before "$probe_json" \
  --argjson candidates "$candidates_json" \
  --argjson killed "$killed_pids_json" \
  --argjson errors "$kill_errors_json" \
  --argjson min_age "$MIN_AGE_MINUTES" \
  --argjson threshold "$COUNT_THRESHOLD" \
  '{
    version:$version,
    ts:$ts,
    status:(if (($errors | length) > 0 and ($errors[0] != "fixture_mode_no_kill")) then "error" else "ok" end),
    apply:$apply,
    dry_run:($apply | not),
    before_count:($before.headless_agent_browser_count // 0),
    candidate_count:($candidates | length),
    candidates:$candidates,
    killed_pids:$killed,
    kill_errors:$errors,
    thresholds:{min_age_minutes:$min_age,count_threshold:$threshold},
    primary_chrome_profile:($before.primary_chrome_profile // null),
    history_path:null
  }')"

history_row="$(jq -c --arg path "$HISTORY" '.history_path=$path' <<<"$payload")"
if [[ "$APPLY" -eq 1 ]]; then
  append_jsonl_best_effort "$HISTORY" "$history_row" "headless-browser reap history"
fi
printf '%s\n' "$history_row"

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
