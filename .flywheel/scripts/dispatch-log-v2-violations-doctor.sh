#!/usr/bin/env bash
# dispatch-log-v2-violations-doctor.sh
# Bounded read-only wrapper around dispatch-log-schema-validator.sh that emits
# a doctor packet exposing dispatch_log_v2_violations_count for the last N
# rows of .flywheel/dispatch-log.jsonl. Wires into flywheel-loop doctor and
# tick Step 4z.1. Bead: flywheel-yu8g.
set -euo pipefail


# ====== BEGIN canonical-cli scaffold (bead flywheel-ws02m) ======
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (TODO markers in stubs need fill-in)
# doctor-mode-tier: scaffolded (bead flywheel-ws02m)
#
# This block is APPENDED by scaffold-canonical-cli.sh. The original
# top-level dispatch is preserved as `cmd_run` (the new main routes
# default invocation through cmd_run for backward compat). Surface-
# specific logic stays as TODO markers — see grep '# TODO(canonical-cli-scaffold)'.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="dispatch-log-v2-violations-doctor/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/dispatch-log-v2-violations-doctor-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: dispatch-log-v2-violations-doctor.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "dispatch-log-v2-violations-doctor.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "dispatch-log-v2-violations-doctor.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"dispatch-log-v2-violations-doctor.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"dispatch-log-v2-violations-doctor.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"dispatch-log-v2-violations-doctor.sh doctor --json"}'
)"
  if command -v cli_emit_quickstart >/dev/null; then
    cli_emit_quickstart "$SCAFFOLD_SCHEMA_VERSION" "$steps" "doctor,health,repair"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"quickstart",helper_lib_missing:true}'
  fi
}

scaffold_emit_schema() {
  local surface="${1:-default}"
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg surface "$surface" \
    '{schema_version:$sv,command:"schema",surface:$surface,note:"TODO(canonical-cli-scaffold): per-surface schema fill-in"}'
}

scaffold_emit_topic_help() {
  local topic="${1:-}"
  case "$topic" in
    run)      printf 'topic: run — default backward-compatible invocation routes to cmd_run.\n' ;;
    doctor)   printf 'topic: doctor — TODO(canonical-cli-scaffold): document doctor checks specific to this surface.\n' ;;
    health)   printf 'topic: health — TODO(canonical-cli-scaffold): document health probes specific to this surface.\n' ;;
    repair)   printf 'topic: repair — TODO(canonical-cli-scaffold): document repair scopes + idempotency contract.\n' ;;
    validate) printf 'topic: validate — TODO(canonical-cli-scaffold): document validation subjects + contracts.\n' ;;
    *)        printf 'topics: run | doctor | health | repair | validate\n' ;;
  esac
}

scaffold_emit_completion() {
  local shell="${1:-bash}"
  case "$shell" in
    -h|--help) scaffold_emit_topic_help completion 2>/dev/null \
                 || printf 'topic: completion <bash|zsh> — emit shell completion script\n'
               return 0 ;;
    bash) command -v cli_emit_completion_bash >/dev/null \
            && cli_emit_completion_bash "dispatch-log-v2-violations-doctor" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "dispatch-log-v2-violations-doctor" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    *) printf 'ERR: unknown shell %s (use bash|zsh)\n' "$shell" >&2; return 64 ;;
  esac
}

# ---------- canonical-cli stubs (TODO markers preserved) ----------

scaffold_cmd_doctor() {
  # TODO(canonical-cli-scaffold): probe substrate this script depends on
  # (env vars, paths, external tools) and emit per-check status.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{schema_version:$sv,command:"doctor",ts:$ts,status:"todo",checks:[],note:"TODO(canonical-cli-scaffold): fill in doctor checks"}'
}

scaffold_cmd_health() {
  # TODO(canonical-cli-scaffold): summarize last-run state from audit log.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg ts "$(iso_now 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ)" \
    '{schema_version:$sv,command:"health",ts:$ts,status:"todo",note:"TODO(canonical-cli-scaffold): fill in health probe from audit log"}'
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
  # TODO(canonical-cli-scaffold): per-scope repair actions go here.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg scope "$scope" --arg mode "$mode" --arg idem "$idem_key" \
    '{schema_version:$sv,command:"repair",status:"todo",mode:$mode,scope:$scope,idempotency_key:$idem,note:"TODO(canonical-cli-scaffold): fill in repair scope actions"}'
}

scaffold_cmd_validate() {
  # TODO(canonical-cli-scaffold): document validation subjects + contracts.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" \
    '{schema_version:$sv,command:"validate",status:"todo",note:"TODO(canonical-cli-scaffold): fill in per-subject validation"}'
}

scaffold_cmd_audit() {
  # TODO(canonical-cli-scaffold): tail audit log; emit recent rows.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg log "$SCAFFOLD_AUDIT_LOG" \
    '{schema_version:$sv,command:"audit",audit_log:$log,status:"todo",note:"TODO(canonical-cli-scaffold): fill in audit tail"}'
}

scaffold_cmd_why() {
  local id="${1:-}"
  if [[ -z "$id" ]]; then
    printf 'ERR: why requires <id> argument\n' >&2; return 64
  fi
  # TODO(canonical-cli-scaffold): explain why <id> is/isn't in scope.
  jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg id "$id" \
    '{schema_version:$sv,command:"why",id:$id,status:"todo",note:"TODO(canonical-cli-scaffold): fill in why-id semantics"}'
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
VERSION="dispatch-log-v2-violations-doctor/v1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
REPO="$ROOT"
TAIL_N="${FLYWHEEL_DISPATCH_LOG_V2_TAIL:-100}"
JSON_OUT=0
COMMAND="doctor"

usage() {
  cat <<'EOF'
usage:
  dispatch-log-v2-violations-doctor.sh [doctor|health|validate|info|schema|why|help]
                                       [--repo PATH] [--tail N] [--json]

flags:
  --tail N    rows to validate from the end of dispatch-log.jsonl
              (default: 100, env FLYWHEEL_DISPATCH_LOG_V2_TAIL overrides)

exit codes: 0=report emitted (PASS/INFO), 1=violations found, 2=usage error
EOF
}

info() {
  jq -nc \
    --arg version "$VERSION" \
    --arg repo "$REPO" \
    --arg tail "$TAIL_N" \
    '{name:"dispatch-log-v2-violations-doctor.sh",version:$version,repo:$repo,default_tail:($tail|tonumber),mutates:"none",delegates_to:".flywheel/scripts/dispatch-log-schema-validator.sh",commands:["doctor","health","validate","info","schema","why","help"],flags:["--repo PATH","--tail N","--json"]}'
}

die_usage() { printf 'ERR: %s\n' "$1" >&2; exit 2; }

subcmd="${1:-}"
case "$subcmd" in
  doctor|health|validate)
    COMMAND="$subcmd"; shift ;;
  why)
    cat <<'EOF'
why: surfaces the count of dispatch-log v2 schema violations from the most
recent N rows so flywheel-loop doctor and tick Step 4z.1 can fail closed
when worker-emitted v2 rows drop required fields.
EOF
    exit 0 ;;
  info)
    info; exit 0 ;;
  schema)
    cat "$REPO/.flywheel/validation-schema/v1/dispatch-log-entry-v2.schema.json"; exit 0 ;;
  help|-h|--help)
    usage; exit 0 ;;
esac

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) [[ $# -ge 2 ]] || die_usage "--repo requires PATH"; REPO="$(cd "$2" && pwd -P)"; shift 2 ;;
    --repo=*) REPO="$(cd "${1#*=}" && pwd -P)"; shift ;;
    --tail) [[ $# -ge 2 ]] || die_usage "--tail requires N"; TAIL_N="$2"; shift 2 ;;
    --tail=*) TAIL_N="${1#*=}"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --help|-h) usage; exit 0 ;;
    --*) die_usage "unknown argument: $1" ;;
    *) die_usage "unexpected argument: $1" ;;
  esac
done

[[ "$TAIL_N" =~ ^[0-9]+$ ]] || die_usage "--tail must be a non-negative integer: $TAIL_N"

# The wrapper script and the validator ship together; use $ROOT (this script's
# own repo) to find the validator binary, while $REPO is the target whose
# dispatch-log.jsonl + schema are read.
VALIDATOR="${FLYWHEEL_DISPATCH_LOG_VALIDATOR:-$ROOT/.flywheel/scripts/dispatch-log-schema-validator.sh}"
LOG_PATH="$REPO/.flywheel/dispatch-log.jsonl"

if [[ ! -x "$VALIDATOR" ]]; then
  jq -nc --arg version "$VERSION" --arg log "$LOG_PATH" \
    '{schema_version:$version,status:"warn",dispatch_log_v2_violations_count:0,tail_size:0,log_present:false,errors:[{code:"validator_missing",message:"dispatch-log-schema-validator.sh is not executable"}],warnings:[]}'
  exit 0
fi

if [[ ! -f "$LOG_PATH" ]]; then
  jq -nc --arg version "$VERSION" --arg log "$LOG_PATH" \
    '{schema_version:$version,status:"pass",dispatch_log_v2_violations_count:0,tail_size:0,log_present:false,errors:[],warnings:[{code:"log_missing",message:"dispatch-log.jsonl not present"}]}'
  exit 0
fi

VAL_TMP="$(mktemp "${TMPDIR:-/tmp}/dispatch-log-v2-violations-doctor.XXXXXX")"
trap 'rm -f "$VAL_TMP"' EXIT

# Validator exits 1 when invalid > 0 under validate; we always want to read its
# JSON and decide here, so swallow the exit and inspect the summary.
if ! bash "$VALIDATOR" validate --repo "$REPO" --tail "$TAIL_N" --json >"$VAL_TMP" 2>/dev/null; then
  :
fi

if ! jq -e . >/dev/null 2>&1 <"$VAL_TMP"; then
  jq -nc --arg version "$VERSION" --arg log "$LOG_PATH" \
    '{schema_version:$version,status:"warn",dispatch_log_v2_violations_count:0,tail_size:0,log_present:true,errors:[{code:"validator_invalid_json",message:"validator emitted non-JSON output"}],warnings:[]}'
  exit 0
fi

PACKET="$(jq -c \
  --arg version "$VERSION" \
  --argjson tail_n "$TAIL_N" \
  '{
    schema_version: $version,
    status: (if (.invalid // 0) > 0 then "fail" else "pass" end),
    dispatch_log_v2_violations_count: (.invalid // 0),
    dispatch_log_v2_total_rows_checked: (.total // 0),
    dispatch_log_v2_malformed_count: (.malformed_count // 0),
    dispatch_log_v2_missing_fitness_class_count: (.missing_fitness_class // 0),
    dispatch_log_v2_missing_fitness_claim_count: (.missing_fitness_claim // 0),
    tail_size: $tail_n,
    log_present: (.log_present // true),
    expected_mission_anchor: (.expected_mission_anchor // ""),
    schema_id: (.schema_id // null),
    errors: [],
    warnings: (if (.invalid // 0) > 0 then [{code:"v2_violations_present",message:("invalid=" + ((.invalid // 0)|tostring) + " of " + ((.total // 0)|tostring) + " rows checked")}] else [] end)
  }' "$VAL_TMP")"

if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$PACKET"
else
  jq -r '"dispatch_log_v2_violations_count=\(.dispatch_log_v2_violations_count) tail_size=\(.tail_size) total=\(.dispatch_log_v2_total_rows_checked) status=\(.status)"' <<<"$PACKET"
fi

if [[ "$COMMAND" == "doctor" || "$COMMAND" == "validate" ]]; then
  count="$(jq -r '.dispatch_log_v2_violations_count' <<<"$PACKET")"
  [[ "$count" == "0" ]] || exit 1
fi
exit 0
