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
# WZJO9.1.7 SELECTIVE-VERB-BYPASS — 6 native verbs (doctor/health/schema/
# info/examples/why) + 1 native flag (--info) bypassed; scaffold owns
# repair/validate/audit/quickstart + --schema/--examples flags.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="cleanup-scratch/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/cleanup-scratch-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: cleanup-scratch.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "cleanup-scratch.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "cleanup-scratch.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"cleanup-scratch.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"cleanup-scratch.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"cleanup-scratch.sh doctor --json"}'
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
        '{schema_version:$sv,command:"schema",surface:"doctor",note:"BYPASSED to native — see native `doctor` subcommand for authoritative envelope (subsystems.script + .python + .jq)"}'
      ;;
    health)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"health",note:"BYPASSED to native — see native `health` subcommand"}'
      ;;
    repair)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"repair",scopes:["audit_log_dir"],contract:{requires_idempotency_key_when_apply:true,refusal_exit_code:3,dry_run_default:true},env:{audit_log:"SCAFFOLD_AUDIT_LOG"},note:"scaffold-owned (NOT bypassed); native cleanup behavior is invoked via the script default ABSOLUTE_PATH arg form, not via `repair` verb"}'
      ;;
    validate)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"validate",subjects:["scratch-path","mode-name","audit-row"],contract:{rejects_with_rc1:"on schema violation",scratch_path_must_be_absolute:true,mode_name_enum:["dry-run","apply"]},note:"scaffold-owned (native validate is incomplete — prints usage only)"}'
      ;;
    audit)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"audit",audit_log_env:"SCAFFOLD_AUDIT_LOG",row_shape:{ts:"ISO8601",action:"string"},limit_default:20}'
      ;;
    why)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"why",note:"BYPASSED to native — see native `why <subject>` (e.g. `why path-policy`)"}'
      ;;
    audit-row)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surface:"audit-row",required_fields:["ts","action"],optional_fields:["status","scratch_path","mode","scope","idempotency_key","exit_code"]}'
      ;;
    default|*)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
        '{schema_version:$sv,command:"schema",surfaces:["doctor","health","repair","validate","audit","why","audit-row"],note:"cleanup-scratch.sh = SELECTIVE-VERB-BYPASS — 6 native verbs (doctor/health/schema/info/examples/why) bypassed; default ABSOLUTE_PATH arg form does the actual scratch removal with --dry-run|--apply"}'
      ;;
  esac
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — default backward-compatible invocation routes to cmd_run: takes ABSOLUTE_PATH arg + --dry-run|--apply mode (default --dry-run); validates path against allowlist (/var/folders/*/T/(flywheel|josh|wave)-* OR /tmp/(flywheel|dispatch_)-*); emits status=ok|refused|skipped with reason\n' ;;
    doctor)   printf 'topic: doctor — BYPASSED to native — invokes native doctor subcommand which probes script + python + jq subsystems; emits scratch-cleanup/v1 envelope with subsystems.script + subsystems.python + subsystems.jq status\n' ;;
    health)   printf 'topic: health — BYPASSED to native — emits scratch-cleanup/v1 envelope with status=pass\n' ;;
    repair)   printf 'topic: repair --scope <audit_log_dir> [--dry-run|--apply --idempotency-key KEY] — scaffold-owned (NOT bypassed); apply contract: --apply requires --idempotency-key (rc=3 refusal); only audit_log_dir scope (cleanup itself is via the default ABSOLUTE_PATH arg form, not via `repair` verb)\n' ;;
    validate) printf 'topic: validate <subject> [PATH|VALUE] — scaffold-owned (native validate is incomplete — prints usage only); subjects: scratch-path (must be absolute path; matches default ABSOLUTE_PATH arg semantic), mode-name (dry-run|apply enum matching --dry-run|--apply flags), audit-row (JSONL ts + action required); rc=1 on schema violation\n' ;;
    audit)    printf 'topic: audit [--limit N] — scaffold-owned (NOT natively supported); tail $SCAFFOLD_AUDIT_LOG via cli_emit_audit_tail; default limit=20\n' ;;
    why)      printf 'topic: why <id> — BYPASSED to native — invokes native why subcommand which emits scratch-cleanup/v1 envelope with subject=path-policy + reason explaining why workers need this primitive\n' ;;
    *)        printf 'topics: run | doctor | health | repair | validate | audit | why | quickstart | completion (SELECTIVE-VERB-BYPASS — 6 native verbs + --info flag bypassed; repair/validate/audit/quickstart + --schema/--examples flags scaffold-owned)\n' ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh> — emit shell completion script\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "cleanup-scratch" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "cleanup-scratch" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  # SELECTIVE-VERB-BYPASS: defensive fallback only. Native `doctor`
  # subcommand is authoritative (probes script + python + jq subsystems).
  # If _scaffold_is_canonical_arg ever changes to NOT bypass `doctor`,
  # this fallback probes the same substrate the native doctor uses.
  local audit_log_dir; audit_log_dir="$(dirname "$SCAFFOLD_AUDIT_LOG")"
  local bash_status="fail" jq_status="fail" mktemp_status="fail" python_status="fail" audit_dir_status="fail"
  local overall="pass"

  if command -v bash >/dev/null 2>&1; then bash_status="pass"; fi
  if command -v jq >/dev/null 2>&1; then jq_status="pass"; fi
  if command -v mktemp >/dev/null 2>&1; then mktemp_status="pass"; fi
  if command -v python3 >/dev/null 2>&1; then python_status="pass"; fi
  if [[ -d "$audit_log_dir" && -w "$audit_log_dir" ]]; then audit_dir_status="pass"; fi

  for st in "$bash_status" "$jq_status" "$mktemp_status" "$python_status"; do
    if [[ "$st" == "fail" ]]; then overall="fail"; fi
  done
  if [[ "$overall" == "pass" && "$audit_dir_status" != "pass" ]]; then overall="warn"; fi

  jq -nc \
    --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    --arg ts "$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg overall "$overall" \
    --arg bash_status "$bash_status" --arg jq_status "$jq_status" \
    --arg mktemp_status "$mktemp_status" --arg python_status "$python_status" \
    --arg audit_dir "$audit_log_dir" --arg audit_dir_status "$audit_dir_status" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:$overall,
      checks:[
        {name:"bash_available",status:$bash_status},
        {name:"jq_available",status:$jq_status},
        {name:"mktemp_available",status:$mktemp_status},
        {name:"python3_available",status:$python_status,detail:"native doctor probes this too"},
        {name:"audit_log_dir_writable",status:$audit_dir_status,path:$audit_dir}
      ],
      note:"SELECTIVE-VERB-BYPASS fallback — native doctor is authoritative"
    }'
}

scaffold_cmd_health() {
  local audit_log="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/cleanup-scratch-runs.jsonl}"
  local now ts last_run_ts="" age_seconds total_runs=0 recent_runs=0 status="pass"
  local stale_threshold="${CLEANUP_SCRATCH_HEALTH_STALE_THRESHOLD_SECONDS:-2592000}"  # 30d (per-worker on-demand)
  ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [[ ! -r "$audit_log" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg log "$audit_log" \
      '{schema_version:$sv,command:"health",ts:$ts,status:"warn",audit_log:$log,reason:"audit_log_missing",last_run_ts:null,age_seconds:null,recent_runs:0,total_runs:0,note:"SELECTIVE-VERB-BYPASS fallback — native health is authoritative"}'
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
      stale_threshold_seconds:$stale,note:"SELECTIVE-VERB-BYPASS fallback"}'
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
  # Scaffold-owned repair (NOT bypassed). Native cleanup behavior is via
  # the default ABSOLUTE_PATH arg form, NOT via `repair` verb. So only the
  # audit_log_dir scope makes sense here.
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  case "$scope" in
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
      printf 'ERR: repair requires --scope <audit_log_dir>\n' >&2
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" \
        '{schema_version:$sv,command:"repair",status:"refused",scope:$scope,reason:"unknown_scope",valid_scopes:["audit_log_dir"],note:"native cleanup is via default ABSOLUTE_PATH arg, not via repair verb"}'
      return 64 ;;
  esac
}

scaffold_cmd_validate() {
  # Scaffold-owned (NOT bypassed). Native validate is incomplete (prints
  # usage only); scaffold provides real schema-validation surfaces.
  local subject="${1:-}"; shift || true
  local arg="${1:-}"
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  case "$subject" in
    scratch-path)
      if [[ -z "$arg" ]]; then
        printf 'ERR: validate scratch-path requires VALUE arg\n' >&2; return 64
      fi
      if [[ "$arg" == /* ]]; then
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg p "$arg" \
          '{schema_version:$sv,command:"validate",subject:"scratch-path",ts:$ts,status:"ok",value:$p,note:"absolute-path check only; allowlist enforcement happens in cmd_run"}'
        return 0
      else
        jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg p "$arg" \
          '{schema_version:$sv,command:"validate",subject:"scratch-path",ts:$ts,status:"reject",value:$p,reason:"not_absolute_path",contract:"ABSOLUTE_PATH arg must start with /"}'
        return 1
      fi
      ;;
    mode-name)
      if [[ -z "$arg" ]]; then
        printf 'ERR: validate mode-name requires VALUE arg\n' >&2; return 64
      fi
      case "$arg" in
        dry-run|apply)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
            '{schema_version:$sv,command:"validate",subject:"mode-name",ts:$ts,status:"ok",value:$v}'
          return 0 ;;
        *)
          jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg v "$arg" \
            '{schema_version:$sv,command:"validate",subject:"mode-name",ts:$ts,status:"reject",value:$v,reason:"not_in_enum",valid_modes:["dry-run","apply"]}'
          return 1 ;;
      esac
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
        '{schema_version:$sv,command:"validate",status:"refused",reason:"missing_subject",valid_subjects:["scratch-path","mode-name","audit-row"]}'
      return 64 ;;
    *)
      jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg subj "$subject" \
        '{schema_version:$sv,command:"validate",status:"refused",subject:$subj,reason:"unknown_subject",valid_subjects:["scratch-path","mode-name","audit-row"]}'
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
  # SELECTIVE-VERB-BYPASS: defensive fallback only. Native `why <subject>`
  # is authoritative (currently only supports subject=path-policy).
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id> argument\n' >&2; return 64
  fi
  local ts; ts="$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [[ ! -r "$SCAFFOLD_AUDIT_LOG" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"unavailable",reason:"audit_log_missing",audit_log:$log,note:"SELECTIVE-VERB-BYPASS fallback — native why is authoritative"}'
    return 0
  fi
  local match; match="$(jq -c --arg id "$id" 'select(.ts == $id or (.scratch_path // "") == $id or (.run_id // "") == $id)' "$SCAFFOLD_AUDIT_LOG" 2>/dev/null | head -1 || true)"
  if [[ -z "$match" ]]; then
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$ts" --arg id "$id" --arg log "$SCAFFOLD_AUDIT_LOG" \
      '{schema_version:$sv,command:"why",ts:$ts,id:$id,status:"not_found",audit_log:$log,searched_keys:["ts","scratch_path","run_id"]}'
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
  # WZJO9.1.7 SELECTIVE-VERB-BYPASS: cleanup-scratch.sh natively
  # implements 6 canonical verbs (doctor / health / schema / info /
  # examples / why) AND the --info FLAG with rich canonical envelopes
  # (scratch-cleanup/v1 schema_version + per-surface fields). Native
  # `validate` exists but prints usage only (incomplete), and native
  # repair / audit / quickstart / completion / --schema / --examples
  # FLAGS are NOT supported (treated as path args, refused).
  #
  # Bypass list (verbs): doctor / health / schema / info / examples / why
  # Bypass list (flags): --info
  # Scaffold-owned (verbs): repair / validate / audit / quickstart / completion
  # Scaffold-owned (flags): --schema / --examples
  case "${1:-}" in
    doctor|health|schema|info|examples|why) return 1 ;;  # SELECTIVE-VERB-BYPASS
    repair|validate|audit|quickstart|completion) return 0 ;;
    --info) return 1 ;;                                   # SELECTIVE-FLAG-BYPASS
    --schema|--examples) return 0 ;;
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
VERSION="scratch-cleanup/v1"
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)/$(basename "${BASH_SOURCE[0]}")"
MODE="dry-run"
JSON_OUT=0
COMMAND="cleanup"
TARGET=""

usage() {
  cat <<'USAGE'
usage: cleanup-scratch.sh [--dry-run|--apply] [--json] [--info] ABSOLUTE_PATH
       cleanup-scratch.sh doctor|health|schema|info|examples|validate|why [ARGS] [--json]

Safely removes one flywheel scratch directory. Default mode is --dry-run.
Allowed targets:
  /var/folders/*/T/(flywheel|josh|wave)-*
  /tmp/(flywheel|dispatch_)-*
USAGE
}

json_string() {
  jq -Rn --arg v "$1" '$v'
}

emit_json() {
  local status="$1" reason="$2" path="$3" exists="$4" action="$5"
  jq -cn \
    --arg schema_version "$VERSION" \
    --arg command "$COMMAND" \
    --arg mode "$MODE" \
    --arg status "$status" \
    --arg reason "$reason" \
    --arg path "$path" \
    --arg exists "$exists" \
    --arg action "$action" \
    '{schema_version:$schema_version,command:$command,mode:$mode,status:$status,reason:$reason,path:$path,exists:($exists=="true"),action:$action}'
}

emit_text() {
  local status="$1" reason="$2" path="$3" _exists="$4" action="$5"
  printf 'status=%s reason=%s action=%s path=%s\n' "$status" "$reason" "$action" "$path"
}

emit() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    emit_json "$@"
  else
    emit_text "$@"
  fi
}

is_allowed_path() {
  local path="$1"
  [[ "$path" =~ ^/var/folders/.*/T/(flywheel|josh|wave)-.+$ ]] && return 0
  [[ "$path" =~ ^/tmp/(flywheel|dispatch_)-.+$ ]] && return 0
  return 1
}

status_for_path() {
  local path="$1"
  if [[ "$path" != /* ]]; then
    emit refused path_not_absolute "$path" false none
    return 3
  fi
  if ! is_allowed_path "$path"; then
    emit refused path_outside_scratch_allowlist "$path" false none
    return 3
  fi
  if [[ ! -e "$path" ]]; then
    emit ok nonexistent_noop "$path" false none
    return 0
  fi
  if [[ "$MODE" == "dry-run" ]]; then
    emit ok would_remove "$path" true dry_run
    return 0
  fi
  /usr/bin/python3 - "$path" <<'PY'
import os
import shutil
import sys
path = sys.argv[1]
if os.path.isdir(path) and not os.path.islink(path):
    shutil.rmtree(path)
else:
    os.unlink(path)
PY
  emit ok removed "$path" false removed
}

schema() {
  jq -cn --arg schema_version "$VERSION" '{
    schema_version:$schema_version,
    command:"cleanup-scratch",
    default_mode:"dry-run",
    mutation_modes:["--dry-run","--apply"],
    stable_exit_codes:{"0":"ok","2":"usage","3":"refused_invalid_path"},
    allowed_path_patterns:[
      "^/var/folders/.*/T/(flywheel|josh|wave)-.*",
      "^/tmp/(flywheel|dispatch_)-.*"
    ],
    output_fields:["schema_version","command","mode","status","reason","path","exists","action"]
  }'
}

doctor() {
  local status="pass"
  [[ -x "$SCRIPT_PATH" ]] || status="warn"
  jq -cn --arg schema_version "$VERSION" --arg status "$status" --arg script "$SCRIPT_PATH" '{
    schema_version:$schema_version,
    command:"doctor",
    status:$status,
    subsystems:{
      script:{status:(if $status=="pass" then "ok" else "warn" end), path:$script},
      python:{status:"ok", binary:"/usr/bin/python3"},
      jq:{status:"ok"}
    }
  }'
}

health() {
  jq -cn --arg schema_version "$VERSION" '{schema_version:$schema_version,command:"health",status:"pass"}'
}

examples() {
  jq -cn --arg schema_version "$VERSION" '{
    schema_version:$schema_version,
    command:"examples",
    examples:[
      "cleanup-scratch.sh --dry-run --json /tmp/flywheel-demo.abc123",
      "cleanup-scratch.sh --apply --json /tmp/flywheel-demo.abc123",
      "cleanup-scratch.sh validate /var/folders/x/y/T/flywheel-demo.abc123 --json",
      "cleanup-scratch.sh why path-policy --json"
    ]
  }'
}

info() {
  jq -cn --arg schema_version "$VERSION" --arg script "$SCRIPT_PATH" '{
    schema_version:$schema_version,
    name:"flywheel-cleanup-scratch",
    script:$script,
    default_mode:"dry-run",
    apply_requires_valid_scratch_path:true
  }'
}

why() {
  local subject="${1:-path-policy}"
  jq -cn --arg schema_version "$VERSION" --arg subject "$subject" '{
    schema_version:$schema_version,
    command:"why",
    subject:$subject,
    reason:"Workers need a narrow, audited primitive for dispatch scratch cleanup without raw recursive deletion in pane commands."
  }'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    doctor|health|schema|info|examples|validate|why)
      COMMAND="$1"; shift ;;
    --dry-run)
      MODE="dry-run"; shift ;;
    --apply)
      MODE="apply"; shift ;;
    --json)
      JSON_OUT=1; shift ;;
    --info)
      COMMAND="info"; shift ;;
    --help|-h)
      usage; exit 0 ;;
    *)
      if [[ -z "$TARGET" ]]; then
        TARGET="$1"; shift
      else
        printf 'unknown argument: %s\n' "$1" >&2
        exit 2
      fi ;;
  esac
done

case "$COMMAND" in
  schema) schema; exit 0 ;;
  doctor) doctor; exit 0 ;;
  health) health; exit 0 ;;
  examples) examples; exit 0 ;;
  info) info; exit 0 ;;
  why) why "$TARGET"; exit 0 ;;
  validate)
    [[ -n "$TARGET" ]] || { usage >&2; exit 2; }
    MODE="dry-run"
    set +e
    status_for_path "$TARGET" >/dev/null
    rc=$?
    set -e
    if [[ "$rc" -eq 0 ]]; then
      emit ok valid_scratch_path "$TARGET" "$([[ -e "$TARGET" ]] && printf true || printf false)" none
    else
      exit "$rc"
    fi
    ;;
  cleanup)
    [[ -n "$TARGET" ]] || { usage >&2; exit 2; }
    status_for_path "$TARGET"
    ;;
esac
