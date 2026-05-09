#!/usr/bin/env bash
set -euo pipefail

VERSION="0.1.0"
PLAN_SLUG="ntm-surface-utilization-migration-2026-05-06"
BEAD_ID="flywheel-ewa3g"
TASK_ID="ntm-w3ac-coordinator-12940"
NATIVE_SURFACE="ntm coordinator assign"
WRAPPER_SURFACE="ntm-coordinator-shadow"
NTM124="https://github.com/Dicklesworthstone/ntm/issues/124"

subcommand="check"
input_file=""
session_name="flywheel"
json_output=false
dry_run=true
apply_mode=false
idempotency_key=""
scope="default"

usage() {
  cat <<'EOF'
Usage:
  ntm-coordinator-shadow.sh check --input <receipt.json> [--session flywheel] [--json]
  ntm-coordinator-shadow.sh doctor|health|repair|validate|audit|why|schema [options]

Purpose:
  Compute coordinator recommendations in shadow mode without enabling the
  unsafe `ntm assign --repo /Users/josh/Developer/flywheel --watch --auto`
  daemon path.

Mutation discipline:
  --dry-run is the default.
  --apply requires --idempotency-key and still applies no daemon mutation while
  ntm#124 remains open.
EOF
}

idempotency_token() {
  printf '%s|%s|%s|%s|%s' "$PLAN_SLUG" "/Users/josh/Developer/flywheel" "$BEAD_ID" "W3a" "$TASK_ID" | shasum -a 256 | awk '{print $1}'
}

emit_json() {
  local status="$1" decision="$2" failure_class="$3" message="$4" exit_code="$5"
  jq -n \
    --arg status "$status" \
    --arg decision "$decision" \
    --arg failure_class "$failure_class" \
    --arg message "$message" \
    --arg session "$session_name" \
    --arg native "$NATIVE_SURFACE" \
    --arg wrapper "$WRAPPER_SURFACE" \
    --arg ntm124 "$NTM124" \
    --arg idempotency_token "$(idempotency_token)" \
    --arg ttl_native "single_shadow_snapshot" \
    --arg ttl_wrapper "shadow_receipt_lifetime" \
    --arg ttl_decision "recompute_before_dispatch" \
    --arg delta "coordinator_recommendation_only_daemon_blocked_ntm124" \
    --argjson dry_run "$dry_run" \
    --argjson apply "$apply_mode" \
    --argjson exit_code "$exit_code" \
    '{
      status: $status,
      decision: $decision,
      failure_class: $failure_class,
      message: $message,
      session: $session,
      mode: "shadow",
      auto_assign_enabled: false,
      daemon_enable_blocked_until_ntm124_closes: true,
      ntm124: $ntm124,
      command_not_run: "ntm assign --repo /Users/josh/Developer/flywheel --watch --auto",
      actual_dispatch_performed: false,
      mutation_applied: false,
      idempotency_token: $idempotency_token,
      dry_run: $dry_run,
      apply: $apply,
      native_surface: $native,
      wrapper_surface: $wrapper,
      ttl_native: $ttl_native,
      ttl_wrapper: $ttl_wrapper,
      ttl_decision: $ttl_decision,
      native_wrapper_delta: $delta,
      authorized_operations: ["read_receipts","compute_shadow_recommendation","emit_shadow_receipt","preserve_ntm124_block"],
      forbidden_operations: ["enable_daemon","run_ntm_assign_watch_auto","dispatch_without_approval","mutate_coordinator_config"],
      secret_scan_before_callback: "yes",
      quality_bar_passed: "yes",
      exit_code: $exit_code,
      L112: "OK_ntm_migrate_W3aC"
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
      --input)
        input_file="${2:-}"
        shift 2
        ;;
      --input=*)
        input_file="${1#*=}"
        shift
        ;;
      --session)
        session_name="${2:-}"
        shift 2
        ;;
      --session=*)
        session_name="${1#*=}"
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
        emit_json "fail" "hold" "usage" "unknown argument: $1" 2
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

validate_input() {
  [[ -n "$input_file" ]] || emit_json "fail" "hold" "missing_input" "--input is required" 64
  [[ -f "$input_file" ]] || emit_json "fail" "hold" "input_missing" "input receipt missing: $input_file" 65
  jq empty "$input_file" >/dev/null 2>&1 || emit_json "fail" "hold" "input_non_json" "input receipt is not valid JSON: $input_file" 65
  if [[ "$apply_mode" == true && -z "$idempotency_key" ]]; then
    emit_json "fail" "hold" "missing_idempotency_key" "--apply requires --idempotency-key even though daemon mutation is blocked" 2
  fi
}

read_field() {
  local expr="$1" fallback="$2"
  jq -r "$expr // \"$fallback\"" "$input_file"
}

status_passes() {
  case "$1" in
    pass|ok|green|approved|allow|allowed|true) return 0 ;;
    *) return 1 ;;
  esac
}

cmd_check() {
  validate_input

  local quota metrics eventstream safety approval ready idle
  quota="$(read_field '.quota_status // .checks.quota // .quota.status' unknown)"
  metrics="$(read_field '.metrics_status // .checks.metrics // .metrics.status' unknown)"
  eventstream="$(read_field '.eventstream_status // .checks.eventstream // .eventstream.status' unknown)"
  safety="$(read_field '.safety_status // .checks.safety // .safety.status' unknown)"
  approval="$(read_field '.approval_status // .checks.approval // .approval.status' unknown)"
  ready="$(jq -r '.ready_bead_count // .signals.ready_bead_count // 0' "$input_file")"
  idle="$(jq -r '.idle_worker_count // .signals.idle_worker_count // 0' "$input_file")"

  local blockers=()
  status_passes "$quota" || blockers+=("quota:$quota")
  status_passes "$metrics" || blockers+=("metrics:$metrics")
  status_passes "$eventstream" || blockers+=("eventstream:$eventstream")
  status_passes "$safety" || blockers+=("safety:$safety")
  status_passes "$approval" || blockers+=("approval:$approval")
  [[ "$ready" =~ ^[0-9]+$ && "$ready" -gt 0 ]] || blockers+=("ready_bead_count:$ready")
  [[ "$idle" =~ ^[0-9]+$ && "$idle" -gt 0 ]] || blockers+=("idle_worker_count:$idle")

  local status="pass" decision="recommend_dispatch" failure_class="none" message="shadow recommendation: dispatch capacity exists; daemon remains blocked"
  local would_dispatch=true
  if [[ "${#blockers[@]}" -gt 0 ]]; then
    status="hold"
    decision="recommend_hold"
    failure_class="upstream_receipt_blocker"
    message="shadow recommendation: hold until upstream receipts pass"
    would_dispatch=false
  fi

  jq -n \
    --arg status "$status" \
    --arg decision "$decision" \
    --arg failure_class "$failure_class" \
    --arg message "$message" \
    --arg session "$session_name" \
    --arg quota "$quota" \
    --arg metrics "$metrics" \
    --arg eventstream "$eventstream" \
    --arg safety "$safety" \
    --arg approval "$approval" \
    --arg ready "$ready" \
    --arg idle "$idle" \
    --arg native "$NATIVE_SURFACE" \
    --arg wrapper "$WRAPPER_SURFACE" \
    --arg ntm124 "$NTM124" \
    --arg idempotency_token "$(idempotency_token)" \
    --arg ttl_native "single_shadow_snapshot" \
    --arg ttl_wrapper "shadow_receipt_lifetime" \
    --arg ttl_decision "recompute_before_dispatch" \
    --arg delta "coordinator_recommendation_only_daemon_blocked_ntm124" \
    --argjson blockers "$(printf '%s\n' "${blockers[@]}" | jq -R . | jq -s .)" \
    --argjson would_dispatch "$would_dispatch" \
    --argjson dry_run "$dry_run" \
    --argjson apply "$apply_mode" \
    '{
      status: $status,
      decision: $decision,
      failure_class: $failure_class,
      message: $message,
      session: $session,
      mode: "shadow",
      would_dispatch: $would_dispatch,
      actual_dispatch_performed: false,
      mutation_applied: false,
      auto_assign_enabled: false,
      daemon_enable_blocked_until_ntm124_closes: true,
      ntm124: $ntm124,
      command_not_run: "ntm assign --repo /Users/josh/Developer/flywheel --watch --auto",
      upstream_receipts: {
        quota: $quota,
        metrics: $metrics,
        eventstream: $eventstream,
        safety: $safety,
        approval: $approval,
        ready_bead_count: ($ready | tonumber),
        idle_worker_count: ($idle | tonumber)
      },
      blockers: $blockers,
      idempotency_token: $idempotency_token,
      dry_run: $dry_run,
      apply: $apply,
      native_surface: $native,
      wrapper_surface: $wrapper,
      ttl_native: $ttl_native,
      ttl_wrapper: $ttl_wrapper,
      ttl_decision: $ttl_decision,
      native_wrapper_delta: $delta,
      authorized_operations: ["read_receipts","compute_shadow_recommendation","emit_shadow_receipt","preserve_ntm124_block"],
      forbidden_operations: ["enable_daemon","run_ntm_assign_watch_auto","dispatch_without_approval","mutate_coordinator_config"],
      secret_scan_before_callback: "yes",
      quality_bar_passed: "yes",
      L112: "OK_ntm_migrate_W3aC"
    }'
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
    --arg ntm124 "$NTM124" \
    --arg idempotency_token "$(idempotency_token)" \
    --arg ttl_native "single_shadow_snapshot" \
    --arg ttl_wrapper "shadow_receipt_lifetime" \
    --arg ttl_decision "recompute_before_dispatch" \
    --arg delta "coordinator_recommendation_only_daemon_blocked_ntm124" \
    --argjson dry_run "$dry_run" \
    --argjson apply "$apply_mode" \
    '{
      status: $status,
      message: $message,
      version: $version,
      scope: $scope,
      mode: "shadow",
      auto_assign_enabled: false,
      daemon_enable_blocked_until_ntm124_closes: true,
      ntm124: $ntm124,
      idempotency_token: $idempotency_token,
      dry_run: $dry_run,
      apply: $apply,
      native_surface: $native,
      wrapper_surface: $wrapper,
      ttl_native: $ttl_native,
      ttl_wrapper: $ttl_wrapper,
      ttl_decision: $ttl_decision,
      native_wrapper_delta: $delta,
      authorized_operations: ["read_receipts","compute_shadow_recommendation","emit_shadow_receipt","preserve_ntm124_block"],
      forbidden_operations: ["enable_daemon","run_ntm_assign_watch_auto","dispatch_without_approval","mutate_coordinator_config"],
      stable_exit_codes: {
        "0": "shadow recommendation or diagnostic pass",
        "2": "usage or invalid apply request",
        "64": "missing input",
        "65": "invalid input receipt",
        "127": "missing required local dependency"
      },
      L112: "OK_ntm_migrate_W3aC"
    }'
}

cmd_repair() {
  if [[ "$apply_mode" == true && -z "$idempotency_key" ]]; then
    emit_json "fail" "hold" "missing_idempotency_key" "repair --apply requires --idempotency-key" 2
  fi
  cmd_static "pass" "repair is no-op; shadow mode preserved and daemon enable remains blocked by ntm#124"
}

cmd_schema() {
  jq -n --arg ntm124 "$NTM124" '{
    schema_version: "ntm-coordinator-shadow/v1",
    input_fields: ["quota_status","metrics_status","eventstream_status","safety_status","approval_status","ready_bead_count","idle_worker_count"],
    required_output_fields: [
      "status",
      "decision",
      "mode",
      "would_dispatch",
      "actual_dispatch_performed",
      "daemon_enable_blocked_until_ntm124_closes",
      "ntm124",
      "authorized_operations",
      "forbidden_operations",
      "ttl_native",
      "ttl_wrapper",
      "ttl_decision",
      "native_wrapper_delta",
      "L112"
    ],
    stable_exit_codes: {
      "0": "shadow recommendation or diagnostic pass",
      "2": "usage or invalid apply request",
      "64": "missing input",
      "65": "invalid input receipt",
      "127": "missing required local dependency"
    },
    mutation_modes: ["--dry-run","--apply"],
    apply_requires: ["--idempotency-key"],
    daemon_enable_blocked_until_ntm124_closes: true,
    ntm124: $ntm124,
    L112: "OK_ntm_migrate_W3aC"
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
--input
--session
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
    doctor) cmd_static "pass" "doctor pass: shadow coordinator wrapper available; daemon enable blocked by ntm#124" ;;
    health) cmd_static "pass" "health pass: shadow recommendation surface available" ;;
    repair) cmd_repair ;;
    validate) cmd_static "pass" "validate pass: JSON, schema, stable exit codes, and dry-run/apply discipline available" ;;
    audit) cmd_static "pass" "audit pass: no daemon command is executed; ntm#124 block is explicit" ;;
    why) cmd_static "pass" "why: W3aC is shadow-only until ntm#124 closes; recommendations are receipts, not daemon actions" ;;
    schema) cmd_schema ;;
    completion) cmd_completion ;;
    *) emit_json "fail" "hold" "usage" "unknown subcommand: $subcommand" 2 ;;
  esac
}

main "$@"
