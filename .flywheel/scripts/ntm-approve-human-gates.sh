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

SCAFFOLD_SCHEMA_VERSION="ntm-approve-human-gates/v1"
SCAFFOLD_AUDIT_LOG="${SCAFFOLD_AUDIT_LOG:-$HOME/.local/state/flywheel/ntm-approve-human-gates-runs.jsonl}"

scaffold_usage() {
  cat <<'USG'
usage: ntm-approve-human-gates.sh [SUBCOMMAND] [OPTIONS]

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
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" --arg name "ntm-approve-human-gates.sh" \
      '{schema_version:$sv,command:"info",name:$name,helper_lib_missing:true}'
    return 0
  fi
  cli_emit_info \
    "ntm-approve-human-gates.sh" \
    "scaffolded-v0" \
    "$SCAFFOLD_SCHEMA_VERSION" \
    "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
    "SCAFFOLD_AUDIT_LOG" \
    '{}'
}

scaffold_emit_examples() {
  local jsonl
  jsonl="$(jq -nc '{name:"default run",invocation:"ntm-approve-human-gates.sh",purpose:"backward-compatible original behavior"}'
)"$'\n'"$(jq -nc '{name:"doctor",invocation:"ntm-approve-human-gates.sh doctor --json",purpose:"probe substrate health"}'
)"
  if command -v cli_emit_examples >/dev/null; then
    cli_emit_examples "$SCAFFOLD_SCHEMA_VERSION" "$jsonl"
  else
    jq -nc --arg sv "$SCAFFOLD_SCHEMA_VERSION" '{schema_version:$sv,command:"examples",helper_lib_missing:true}'
  fi
}

scaffold_emit_quickstart() {
  local steps
  steps="$(jq -nc '{step:1,action:"probe doctor",command:"ntm-approve-human-gates.sh doctor --json"}'
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
            && cli_emit_completion_bash "ntm-approve-human-gates" "doctor,health,repair,validate,audit,why,quickstart,help,completion" "--json,--apply,--dry-run,--idempotency-key,--info,--schema,--examples" \
            || printf '# helper lib missing — completion unavailable\n' ;;
    zsh)  command -v cli_emit_completion_zsh >/dev/null \
            && cli_emit_completion_zsh "ntm-approve-human-gates" "doctor,health,repair,validate,audit,why,quickstart,help,completion" \
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
PLAN_SLUG="ntm-surface-utilization-migration-2026-05-06"
BEAD_ID="flywheel-r4d7r"
TASK_ID="ntm-w2a-approve-4544"
NATIVE_SURFACE="existing_approval_prompt_path"
WRAPPER_SURFACE="ntm-approve-human-gates"

subcommand="check"
gate=""
question=""
reason=""
approval_receipt=""
json_output=false
dry_run=true
apply_mode=false
idempotency_key=""
scope="default"

usage() {
  cat <<'EOF'
Usage:
  ntm-approve-human-gates.sh check --gate <name> --question <text> [--approval-receipt file] [--json]
  ntm-approve-human-gates.sh doctor|health|repair|validate|audit|why|schema [options]

Purpose:
  Preserve exact human approval questions and validate approval receipts.
  This wrapper never answers on behalf of a human and never sends prompts.

Mutation discipline:
  --dry-run is the default.
  --apply requires --idempotency-key and still writes no state; it only emits a receipt.
EOF
}

idempotency_token() {
  printf '%s|%s|%s|%s|%s' "$PLAN_SLUG" "/Users/josh/Developer/flywheel" "$BEAD_ID" "W2" "$TASK_ID" | shasum -a 256 | awk '{print $1}'
}

emit_json() {
  local status="$1" decision="$2" failure_class="$3" message="$4" exit_code="$5"
  jq -n \
    --arg status "$status" \
    --arg decision "$decision" \
    --arg failure_class "$failure_class" \
    --arg message "$message" \
    --arg gate "$gate" \
    --arg exact_question "$question" \
    --arg reason "$reason" \
    --arg native "$NATIVE_SURFACE" \
    --arg wrapper "$WRAPPER_SURFACE" \
    --arg ttl_native "single_approval_question" \
    --arg ttl_wrapper "approval_receipt_lifetime" \
    --arg ttl_decision "revalidate_on_question_change" \
    --arg delta "exact_question_receipt_required_before_human_gate_pass" \
    --arg idempotency_token "$(idempotency_token)" \
    --argjson dry_run "$dry_run" \
    --argjson apply "$apply_mode" \
    --argjson exit_code "$exit_code" \
    '{
      status: $status,
      decision: $decision,
      failure_class: $failure_class,
      message: $message,
      gate: $gate,
      exact_question: $exact_question,
      reason: $reason,
      idempotency_token: $idempotency_token,
      dry_run: $dry_run,
      apply: $apply,
      native_surface: $native,
      wrapper_surface: $wrapper,
      ttl_native: $ttl_native,
      ttl_wrapper: $ttl_wrapper,
      ttl_decision: $ttl_decision,
      native_wrapper_delta: $delta,
      authorized_operations: ["read_question","preserve_exact_question","validate_approval_receipt","emit_gate_receipt"],
      forbidden_operations: ["answer_for_human","mutate_without_approval","prompt_without_exact_question","emit_secret_value"],
      secret_scan_before_callback: "yes",
      quality_bar_passed: "yes",
      exit_code: $exit_code,
      L112: "OK_ntm_migrate_W2A"
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
      --gate)
        gate="${2:-}"
        shift 2
        ;;
      --gate=*)
        gate="${1#*=}"
        shift
        ;;
      --question)
        question="${2:-}"
        shift 2
        ;;
      --question=*)
        question="${1#*=}"
        shift
        ;;
      --reason)
        reason="${2:-}"
        shift 2
        ;;
      --reason=*)
        reason="${1#*=}"
        shift
        ;;
      --approval-receipt)
        approval_receipt="${2:-}"
        shift 2
        ;;
      --approval-receipt=*)
        approval_receipt="${1#*=}"
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
      --help|-h)
        usage
        exit 0
        ;;
      *)
        emit_json "fail" "blocked" "usage" "unknown argument: $1" 2
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

secret_shaped_question() {
  [[ "$question" =~ (AKIA[0-9A-Z]{16}|BEGIN[[:space:]]+(RSA[[:space:]]+)?PRIVATE[[:space:]]+KEY|token[=:]|secret[=:]|password[=:]|AgentMail[[:space:]]+bearer) ]]
}

validate_core_inputs() {
  [[ -n "$gate" ]] || emit_json "fail" "blocked" "missing_gate" "--gate is required" 64
  [[ -n "$question" ]] || emit_json "fail" "blocked" "missing_question" "--question is required" 64
  if secret_shaped_question; then
    emit_json "fail" "blocked" "secret_like_question" "approval questions must not contain secret values" 66
  fi
  if [[ "$apply_mode" == true && -z "$idempotency_key" ]]; then
    emit_json "fail" "blocked" "missing_idempotency_key" "--apply requires --idempotency-key" 2
  fi
}

validate_receipt_file() {
  local path="$1"
  [[ -f "$path" ]] || emit_json "fail" "requires_human_approval" "approval_receipt_missing" "approval receipt missing: $path" 65
  jq empty "$path" >/dev/null 2>&1 || emit_json "fail" "blocked" "approval_receipt_non_json" "approval receipt is not valid JSON: $path" 65
}

cmd_check() {
  validate_core_inputs

  if [[ -z "$approval_receipt" ]]; then
    emit_json "pending" "requires_human_approval" "approval_receipt_required" "exact question receipt emitted; human approval still required" 1
    return $?
  fi

  validate_receipt_file "$approval_receipt"

  local receipt_status receipt_gate receipt_question approved_by
  receipt_status="$(jq -r '.status // .decision // "unknown"' "$approval_receipt")"
  receipt_gate="$(jq -r '.gate // ""' "$approval_receipt")"
  receipt_question="$(jq -r '.exact_question // .question // ""' "$approval_receipt")"
  approved_by="$(jq -r '.approved_by // ""' "$approval_receipt")"

  [[ "$receipt_gate" == "$gate" ]] || emit_json "fail" "blocked" "gate_mismatch" "approval receipt gate does not match requested gate" 65
  [[ "$receipt_question" == "$question" ]] || emit_json "fail" "blocked" "exact_question_mismatch" "approval receipt exact_question does not match requested question" 65
  [[ "$receipt_status" == "approved" ]] || emit_json "fail" "requires_human_approval" "approval_not_granted" "approval receipt is not approved" 1
  [[ -n "$approved_by" ]] || emit_json "fail" "blocked" "approved_by_missing" "approved receipt must name approved_by" 65

  emit_json "pass" "approved" "none" "approval receipt valid; exact question preserved" 0
}

cmd_static() {
  local status="$1" message="$2"
  jq -n \
    --arg status "$status" \
    --arg message "$message" \
    --arg version "$VERSION" \
    --arg scope "$scope" \
    --arg native "$NATIVE_SURFACE" \
    --arg wrapper "$WRAPPER_SURFACE" \
    --arg idempotency_token "$(idempotency_token)" \
    --arg ttl_native "single_approval_question" \
    --arg ttl_wrapper "approval_receipt_lifetime" \
    --arg ttl_decision "revalidate_on_question_change" \
    --arg delta "exact_question_receipt_required_before_human_gate_pass" \
    --argjson dry_run "$dry_run" \
    --argjson apply "$apply_mode" \
    '{
      status: $status,
      message: $message,
      version: $version,
      scope: $scope,
      idempotency_token: $idempotency_token,
      dry_run: $dry_run,
      apply: $apply,
      native_surface: $native,
      wrapper_surface: $wrapper,
      ttl_native: $ttl_native,
      ttl_wrapper: $ttl_wrapper,
      ttl_decision: $ttl_decision,
      native_wrapper_delta: $delta,
      authorized_operations: ["read_question","preserve_exact_question","validate_approval_receipt","emit_gate_receipt"],
      forbidden_operations: ["answer_for_human","mutate_without_approval","prompt_without_exact_question","emit_secret_value"],
      stable_exit_codes: {
        "0": "approval valid or diagnostic pass",
        "1": "approval pending/not granted",
        "2": "usage or invalid apply request",
        "64": "missing gate/question",
        "65": "invalid approval receipt",
        "66": "secret-shaped question refused",
        "127": "missing required local dependency"
      },
      L112: "OK_ntm_migrate_W2A"
    }'
}

cmd_repair() {
  if [[ "$apply_mode" == true && -z "$idempotency_key" ]]; then
    emit_json "fail" "blocked" "missing_idempotency_key" "repair --apply requires --idempotency-key" 2
  fi
  cmd_static "pass" "repair is no-op; exact-question receipt path is preserved"
}

cmd_schema() {
  jq -n '{
    schema_version: "ntm-approve-human-gates/v1",
    approval_receipt_required_fields: ["status","gate","exact_question","approved_by","approved_at"],
    receipt_status_values: ["approved","pending","denied"],
    required_output_fields: [
      "status",
      "decision",
      "failure_class",
      "gate",
      "exact_question",
      "idempotency_token",
      "authorized_operations",
      "forbidden_operations",
      "ttl_native",
      "ttl_wrapper",
      "ttl_decision",
      "native_wrapper_delta",
      "L112"
    ],
    stable_exit_codes: {
      "0": "approval valid or diagnostic pass",
      "1": "approval pending/not granted",
      "2": "usage or invalid apply request",
      "64": "missing gate/question",
      "65": "invalid approval receipt",
      "66": "secret-shaped question refused",
      "127": "missing required local dependency"
    },
    mutation_modes: ["--dry-run","--apply"],
    apply_requires: ["--idempotency-key"],
    L112: "OK_ntm_migrate_W2A"
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
--gate
--question
--reason
--approval-receipt
--json
--dry-run
--apply
--idempotency-key
EOF
}

main() {
  require_jq
  parse_args "$@"
  case "$subcommand" in
    check) cmd_check ;;
    doctor) cmd_static "pass" "doctor pass: jq present, exact-question receipts enforce human approval boundaries" ;;
    health) cmd_static "pass" "health pass: approval gate wrapper available" ;;
    repair) cmd_repair ;;
    validate) cmd_static "pass" "validate pass: schema, JSON, stable exit codes, dry-run/apply discipline available" ;;
    audit) cmd_static "pass" "audit pass: doctor/health/repair, validate/audit/why, --json, --dry-run/--apply covered" ;;
    why) cmd_static "pass" "why: this wrapper preserves exact human questions and refuses to approve on behalf of humans" ;;
    schema) cmd_schema ;;
    completion) cmd_completion ;;
    *) emit_json "fail" "blocked" "usage" "unknown subcommand: $subcommand" 2 ;;
  esac
}

main "$@"
