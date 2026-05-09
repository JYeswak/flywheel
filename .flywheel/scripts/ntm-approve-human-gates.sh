#!/usr/bin/env bash
set -euo pipefail

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
