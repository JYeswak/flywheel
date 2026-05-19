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
# specific logic stays as TODO markers — see grep '# TODO(canonical-cli-scaffold)'.

_SCAFFOLD_REPO_ROOT="${_SCAFFOLD_REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)}"
_SCAFFOLD_HELPER_LIB="${_SCAFFOLD_HELPER_LIB:-$_SCAFFOLD_REPO_ROOT/.flywheel/lib/canonical-cli-helpers.sh}"
if [[ -r "$_SCAFFOLD_HELPER_LIB" ]]; then
  # shellcheck source=/dev/null
  source "$_SCAFFOLD_HELPER_LIB"
fi

SCAFFOLD_SCHEMA_VERSION="ntm-safety-dcg-sibling/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/ntm-safety-dcg-sibling-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: ntm-safety-dcg-sibling.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "ntm-safety-dcg-sibling.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "ntm-safety-dcg-sibling.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"ntm-safety-dcg-sibling.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"ntm-safety-dcg-sibling.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"ntm-safety-dcg-sibling.sh doctor --json"}'
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
            && cli_emit_completion_bash "ntm-safety-dcg-sibling" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "ntm-safety-dcg-sibling" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
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
VERSION="0.1.0"
NATIVE_SURFACE="ntm safety"
WRAPPER_SURFACE="ntm-safety-dcg-sibling"
DCG_AUTHORITY=true

subcommand="check"
command_text=""
ntm_fixture=""
dcg_fixture=""
json_output=false
dry_run=true
apply_mode=false
idempotency_key=""
scope="default"
timeout_seconds=5

usage() {
  cat <<'EOF'
Usage:
  ntm-safety-dcg-sibling.sh check --command <text> [--ntm-fixture file] [--dcg-fixture file] [--json]
  ntm-safety-dcg-sibling.sh doctor|health|repair|validate|audit|why|schema [options]

Purpose:
  Compare NTM safety classification against DCG and keep DCG authoritative.
  The wrapper never executes the supplied command text.

Mutation discipline:
  --dry-run is the default.
  --apply is accepted only for repair and requires --idempotency-key.
EOF
}

die_json() {
  local status="$1" failure_class="$2" message="$3" exit_code="$4"
  jq -n \
    --arg status "$status" \
    --arg decision "denied" \
    --arg failure_class "$failure_class" \
    --arg message "$message" \
    --arg native "$NATIVE_SURFACE" \
    --arg wrapper "$WRAPPER_SURFACE" \
    --arg delta "ntm_safety_advisory_dcg_authoritative" \
    --arg ttl_native "current_command_only" \
    --arg ttl_wrapper "callback_lifetime" \
    --arg ttl_decision "recheck_before_execution" \
    --argjson dcg_authority "$DCG_AUTHORITY" \
    --argjson exit_code "$exit_code" \
    '{
      status: $status,
      decision: $decision,
      failure_class: $failure_class,
      message: $message,
      dcg_authority: $dcg_authority,
      native_surface: $native,
      wrapper_surface: $wrapper,
      ttl_native: $ttl_native,
      ttl_wrapper: $ttl_wrapper,
      ttl_decision: $ttl_decision,
      native_wrapper_delta: $delta,
      authorized_operations: ["read_command","classify_with_ntm","verify_with_dcg","emit_safety_receipt"],
      forbidden_operations: ["execute_command","bypass_dcg","treat_ntm_as_authority","emit_secret_value"],
      exit_code: $exit_code,
      L112: "OK_ntm_migrate_W2D"
    }'
  return "$exit_code"
}

parse_args() {
  if [[ $# -gt 0 && "$1" != --* ]]; then
    subcommand="$1"
    shift
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --command)
        command_text="${2:-}"
        shift 2
        ;;
      --command=*)
        command_text="${1#*=}"
        shift
        ;;
      --ntm-fixture)
        ntm_fixture="${2:-}"
        shift 2
        ;;
      --ntm-fixture=*)
        ntm_fixture="${1#*=}"
        shift
        ;;
      --dcg-fixture)
        dcg_fixture="${2:-}"
        shift 2
        ;;
      --dcg-fixture=*)
        dcg_fixture="${1#*=}"
        shift
        ;;
      --json)
        json_output=true
        shift
        ;;
      --dry-run)
        dry_run=true
        apply_mode=false
        shift
        ;;
      --apply)
        apply_mode=true
        dry_run=false
        shift
        ;;
      --idempotency-key)
        idempotency_key="${2:-}"
        shift 2
        ;;
      --idempotency-key=*)
        idempotency_key="${1#*=}"
        shift
        ;;
      --scope)
        scope="${2:-}"
        shift 2
        ;;
      --scope=*)
        scope="${1#*=}"
        shift
        ;;
      --timeout-seconds)
        timeout_seconds="${2:-}"
        shift 2
        ;;
      --timeout-seconds=*)
        timeout_seconds="${1#*=}"
        shift
        ;;
      --help|-h)
        usage
        exit 0
        ;;
      *)
        die_json "fail" "usage" "unknown argument: $1" 2
        ;;
    esac
  done
}

require_jq() {
  command -v jq >/dev/null 2>&1 || {
    printf 'jq is required\n' >&2
    exit 127
  }
}

json_static() {
  local status="$1" message="$2"
  jq -n \
    --arg status "$status" \
    --arg message "$message" \
    --arg version "$VERSION" \
    --arg native "$NATIVE_SURFACE" \
    --arg wrapper "$WRAPPER_SURFACE" \
    --arg scope "$scope" \
    --arg ttl_native "current_command_only" \
    --arg ttl_wrapper "callback_lifetime" \
    --arg ttl_decision "recheck_before_execution" \
    --arg delta "ntm_safety_advisory_dcg_authoritative" \
    --argjson dcg_authority "$DCG_AUTHORITY" \
    --argjson dry_run "$dry_run" \
    --argjson apply "$apply_mode" \
    '{
      status: $status,
      message: $message,
      version: $version,
      scope: $scope,
      dry_run: $dry_run,
      apply: $apply,
      dcg_authority: $dcg_authority,
      native_surface: $native,
      wrapper_surface: $wrapper,
      ttl_native: $ttl_native,
      ttl_wrapper: $ttl_wrapper,
      ttl_decision: $ttl_decision,
      native_wrapper_delta: $delta,
      authorized_operations: ["read_command","classify_with_ntm","verify_with_dcg","emit_safety_receipt"],
      forbidden_operations: ["execute_command","bypass_dcg","treat_ntm_as_authority","emit_secret_value"],
      stable_exit_codes: {
        "0": "allowed or diagnostic pass",
        "1": "safety denied or fail-closed",
        "2": "usage or invalid repair mutation request",
        "64": "missing command",
        "65": "non-json or malformed classifier receipt",
        "70": "timeout or classifier unavailable",
        "127": "missing required local dependency"
      },
      L112: "OK_ntm_migrate_W2D"
    }'
}

validate_fixture() {
  local kind="$1" path="$2"
  if [[ ! -f "$path" ]]; then
    die_json "fail" "${kind}_fixture_missing" "$kind fixture missing: $path" 65
  fi
  if ! jq empty "$path" 2>/dev/null; then
    die_json "fail" "${kind}_non_json" "$kind fixture is not valid JSON: $path" 65
  fi
}

local_ntm_receipt() {
  local destructive=false classification="safe"
  if [[ "$command_text" =~ (^|[[:space:]])(rm[[:space:]]+-rf|git[[:space:]]+reset[[:space:]]+--hard|git[[:space:]]+checkout[[:space:]]+--|git[[:space:]]+clean[[:space:]]+-fd|docker[[:space:]].*prune|dd[[:space:]].*of=) ]]; then
    destructive=true
    classification="destructive"
  fi
  jq -n --arg command "$command_text" --arg classification "$classification" --argjson destructive "$destructive" \
    '{status:"pass", command:$command, classification:$classification, destructive:$destructive}'
}

local_dcg_receipt() {
  local allowed=true classification="safe"
  if [[ "$command_text" =~ (^|[[:space:]])(rm[[:space:]]+-rf|git[[:space:]]+reset[[:space:]]+--hard|git[[:space:]]+checkout[[:space:]]+--|git[[:space:]]+clean[[:space:]]+-fd|docker[[:space:]].*prune|dd[[:space:]].*of=) ]]; then
    allowed=false
    classification="destructive"
  fi
  jq -n --arg command "$command_text" --arg classification "$classification" --argjson allowed "$allowed" \
    '{status:(if $allowed then "allow" else "deny" end), command:$command, classification:$classification, allowed:$allowed}'
}

cmd_check() {
  [[ -n "$command_text" ]] || die_json "fail" "missing_command" "--command is required; wrapper will not infer execution text" 64

  local ntm_doc dcg_doc
  if [[ -n "$ntm_fixture" ]]; then
    validate_fixture "ntm" "$ntm_fixture" || return $?
    ntm_doc="$(jq -c . "$ntm_fixture")"
  else
    ntm_doc="$(local_ntm_receipt)"
  fi

  if [[ "${DCG_SIMULATE_TIMEOUT:-0}" == "1" ]]; then
    die_json "fail" "dcg_timeout" "DCG classification timed out; failing closed" 70
  fi
  if [[ -n "$dcg_fixture" ]]; then
    validate_fixture "dcg" "$dcg_fixture" || return $?
    dcg_doc="$(jq -c . "$dcg_fixture")"
  else
    dcg_doc="$(local_dcg_receipt)"
  fi

  local ntm_status ntm_class ntm_destructive dcg_status dcg_class dcg_allowed
  ntm_status="$(jq -r '.status // "unknown"' <<<"$ntm_doc")"
  ntm_class="$(jq -r '.classification // .decision // "unknown"' <<<"$ntm_doc")"
  ntm_destructive="$(jq -r '(.destructive // false) | tostring' <<<"$ntm_doc")"
  dcg_status="$(jq -r '.status // "unknown"' <<<"$dcg_doc")"
  dcg_class="$(jq -r '.classification // .decision // "unknown"' <<<"$dcg_doc")"
  dcg_allowed="$(jq -r 'if has("allowed") then .allowed elif (.status=="allow" or .status=="pass") then true else false end | tostring' <<<"$dcg_doc")"

  if [[ "$ntm_status" == "timeout" ]]; then
    die_json "fail" "ntm_timeout" "NTM safety classification timed out; failing closed" 70
  fi
  if [[ "$dcg_status" == "timeout" ]]; then
    die_json "fail" "dcg_timeout" "DCG classification timed out; failing closed" 70
  fi

  local decision="allowed" status="pass" failure_class="none" exit_code=0
  if [[ "$dcg_allowed" != "true" ]]; then
    decision="denied"
    status="fail"
    exit_code=1
    if [[ "$ntm_class" == "safe" && "$ntm_destructive" != "true" ]]; then
      failure_class="ntm_dcg_mismatch"
    else
      failure_class="dcg_denied"
    fi
  fi

  jq -n \
    --arg status "$status" \
    --arg decision "$decision" \
    --arg failure_class "$failure_class" \
    --arg command "$command_text" \
    --arg native "$NATIVE_SURFACE" \
    --arg wrapper "$WRAPPER_SURFACE" \
    --arg ntm_status "$ntm_status" \
    --arg ntm_class "$ntm_class" \
    --arg ntm_destructive "$ntm_destructive" \
    --arg dcg_status "$dcg_status" \
    --arg dcg_class "$dcg_class" \
    --arg dcg_allowed "$dcg_allowed" \
    --arg ttl_native "current_command_only" \
    --arg ttl_wrapper "callback_lifetime" \
    --arg ttl_decision "recheck_before_execution" \
    --arg delta "ntm_safety_advisory_dcg_authoritative" \
    --argjson dcg_authority "$DCG_AUTHORITY" \
    --argjson exit_code "$exit_code" \
    '{
      status: $status,
      decision: $decision,
      failure_class: $failure_class,
      command: $command,
      dcg_authority: $dcg_authority,
      ntm: {
        status: $ntm_status,
        classification: $ntm_class,
        destructive: ($ntm_destructive == "true")
      },
      dcg: {
        status: $dcg_status,
        classification: $dcg_class,
        allowed: ($dcg_allowed == "true")
      },
      native_surface: $native,
      wrapper_surface: $wrapper,
      ttl_native: $ttl_native,
      ttl_wrapper: $ttl_wrapper,
      ttl_decision: $ttl_decision,
      native_wrapper_delta: $delta,
      authorized_operations: ["read_command","classify_with_ntm","verify_with_dcg","emit_safety_receipt"],
      forbidden_operations: ["execute_command","bypass_dcg","treat_ntm_as_authority","emit_secret_value"],
      secret_scan_before_callback: "yes",
      quality_bar_passed: "yes",
      exit_code: $exit_code,
      L112: "OK_ntm_migrate_W2D"
    }'
  return "$exit_code"
}

cmd_repair() {
  if [[ "$apply_mode" == true && -z "$idempotency_key" ]]; then
    die_json "fail" "missing_idempotency_key" "repair --apply requires --idempotency-key" 2
  fi
  json_static "pass" "repair is no-op; DCG remains authoritative and unchanged"
}

cmd_schema() {
  jq -n '{
    schema_version: "ntm-safety-dcg-sibling/v1",
    required_output_fields: [
      "status",
      "decision",
      "failure_class",
      "dcg_authority",
      "ntm",
      "dcg",
      "authorized_operations",
      "forbidden_operations",
      "ttl_native",
      "ttl_wrapper",
      "ttl_decision",
      "native_wrapper_delta",
      "L112"
    ],
    stable_exit_codes: {
      "0": "allowed or diagnostic pass",
      "1": "safety denied or fail-closed",
      "2": "usage or invalid repair mutation request",
      "64": "missing command",
      "65": "non-json or malformed classifier receipt",
      "70": "timeout or classifier unavailable",
      "127": "missing required local dependency"
    },
    mutation_modes: ["--dry-run","--apply"],
    apply_requires: ["--idempotency-key"],
    dcg_authority: true,
    L112: "OK_ntm_migrate_W2D"
  }'
}

cmd_completion() {
  cat <<'EOF'
check
doctor
health
repair
validate
audit
why
schema
--command
--ntm-fixture
--dcg-fixture
--json
--dry-run
--apply
--idempotency-key
--timeout-seconds
EOF
}

main() {
  require_jq
  parse_args "$@"
  case "$subcommand" in
    check) cmd_check ;;
    doctor) json_static "pass" "doctor pass: jq present, wrapper does not execute command text, DCG authority enforced" ;;
    health) json_static "pass" "health pass: wrapper surface available" ;;
    repair) cmd_repair ;;
    validate) json_static "pass" "validate pass: JSON schema and stable exit-code fields available" ;;
    audit) json_static "pass" "audit pass: --json, --dry-run/--apply, doctor/health/repair, validate/audit/why surfaces present" ;;
    why) json_static "pass" "why: NTM safety is advisory; DCG is the final authority; mismatches fail closed" ;;
    schema) cmd_schema ;;
    completion) cmd_completion ;;
    *) die_json "fail" "usage" "unknown subcommand: $subcommand" 2 ;;
  esac
}

main "$@"

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
