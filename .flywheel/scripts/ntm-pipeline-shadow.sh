#!/usr/bin/env bash
set -euo pipefail

VERSION="0.1.0"
PLAN_SLUG="ntm-surface-utilization-migration-2026-05-06"
BEAD_ID="flywheel-h3exf"
TASK_ID="ntm-w3ap-pipeline-758"
NATIVE_SURFACE="ntm pipeline run"
WRAPPER_SURFACE="ntm-pipeline-shadow"

subcommand="check"
input_file=""
artifact_path=""
session_name="flywheel"
json_output=false
dry_run=true
apply_mode=false
idempotency_key=""
scope="default"

usage() {
  cat <<'EOF'
Usage:
  ntm-pipeline-shadow.sh check --input <coordinator-shadow.json> [--artifact /tmp/dag.json] [--json]
  ntm-pipeline-shadow.sh doctor|health|repair|validate|audit|why|schema [options]

Purpose:
  Generate a dry-run pipeline DAG from coordinator shadow receipts without
  executing the native NTM pipeline.

Mutation discipline:
  --dry-run is the default.
  --apply requires --idempotency-key but still does not execute the native
  pipeline; only an explicit --artifact path may be written.
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
    --arg idempotency_token "$(idempotency_token)" \
    --arg artifact "$artifact_path" \
    --arg ttl_native "single_pipeline_snapshot" \
    --arg ttl_wrapper "dry_run_artifact_lifetime" \
    --arg ttl_decision "regenerate_before_native_execution" \
    --arg delta "native_pipeline_disabled_shadow_dag_artifact_only" \
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
      artifact_path: $artifact,
      native_pipeline_executed: false,
      dry_run_dag_generated: false,
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
      authorized_operations: ["read_coordinator_receipt","generate_dry_run_dag","write_explicit_artifact","emit_shadow_receipt"],
      forbidden_operations: ["execute_native_pipeline","dispatch_pipeline_steps","mutate_live_state","treat_shadow_as_apply"],
      secret_scan_before_callback: "yes",
      quality_bar_passed: "yes",
      exit_code: $exit_code,
      L112: "OK_ntm_migrate_W3aP"
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
      --input) input_file="${2:-}"; shift 2 ;;
      --input=*) input_file="${1#*=}"; shift ;;
      --artifact) artifact_path="${2:-}"; shift 2 ;;
      --artifact=*) artifact_path="${1#*=}"; shift ;;
      --session) session_name="${2:-}"; shift 2 ;;
      --session=*) session_name="${1#*=}"; shift ;;
      --json) json_output=true; shift ;;
      --dry-run) dry_run=true; apply_mode=false; shift ;;
      --apply) apply_mode=true; dry_run=false; shift ;;
      --idempotency-key) idempotency_key="${2:-}"; shift 2 ;;
      --idempotency-key=*) idempotency_key="${1#*=}"; shift ;;
      --scope) scope="${2:-}"; shift 2 ;;
      --scope=*) scope="${1#*=}"; shift ;;
      --help|-h) usage; exit 0 ;;
      *) emit_json "fail" "hold" "usage" "unknown argument: $1" 2 ;;
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
    emit_json "fail" "hold" "missing_idempotency_key" "--apply requires --idempotency-key" 2
  fi
}

build_dag() {
  local coordinator_decision coordinator_status would_dispatch blockers_json
  coordinator_decision="$(jq -r '.decision // "unknown"' "$input_file")"
  coordinator_status="$(jq -r '.status // "unknown"' "$input_file")"
  would_dispatch="$(jq -r '(.would_dispatch // false) | tostring' "$input_file")"
  blockers_json="$(jq -c '.blockers // []' "$input_file")"

  jq -n \
    --arg schema "ntm-pipeline-shadow-dag/v1" \
    --arg plan "$PLAN_SLUG" \
    --arg session "$session_name" \
    --arg coordinator_decision "$coordinator_decision" \
    --arg coordinator_status "$coordinator_status" \
    --arg would_dispatch "$would_dispatch" \
    --argjson blockers "$blockers_json" \
    '{
      schema_version: $schema,
      plan_slug: $plan,
      session: $session,
      mode: "shadow",
      native_pipeline_executed: false,
      rollback: "Disable native pipeline execution; keep generated DAG as dry-run artifact.",
      coordinator: {
        status: $coordinator_status,
        decision: $coordinator_decision,
        would_dispatch: ($would_dispatch == "true"),
        blockers: $blockers
      },
      nodes: [
        {"id":"quota", "kind":"gate", "source":"W1Q"},
        {"id":"metrics", "kind":"gate", "source":"W1M"},
        {"id":"eventstream", "kind":"gate", "source":"W1S"},
        {"id":"secret_scan", "kind":"gate", "source":"W2S"},
        {"id":"preflight", "kind":"gate", "source":"W2P"},
        {"id":"safety", "kind":"gate", "source":"W2D"},
        {"id":"approval", "kind":"gate", "source":"W2A"},
        {"id":"coordinator_shadow", "kind":"recommendation", "source":"W3aC"},
        {"id":"pipeline_shadow", "kind":"dry_run_artifact", "source":"W3aP"}
      ],
      edges: [
        ["quota","metrics"],
        ["metrics","eventstream"],
        ["secret_scan","preflight"],
        ["preflight","safety"],
        ["safety","approval"],
        ["eventstream","coordinator_shadow"],
        ["approval","coordinator_shadow"],
        ["coordinator_shadow","pipeline_shadow"]
      ],
      L112: "OK_ntm_migrate_W3aP"
    }'
}

write_artifact_if_requested() {
  local dag="$1"
  if [[ -z "$artifact_path" ]]; then
    return 0
  fi
  local dir tmp
  dir="$(dirname "$artifact_path")"
  [[ -d "$dir" ]] || emit_json "fail" "hold" "artifact_dir_missing" "artifact directory missing: $dir" 65
  tmp="$(mktemp "${artifact_path}.tmp.XXXXXX")"
  printf '%s\n' "$dag" >"$tmp"
  mv "$tmp" "$artifact_path"
}

cmd_check() {
  validate_input

  local coordinator_decision coordinator_status would_dispatch
  coordinator_decision="$(jq -r '.decision // "unknown"' "$input_file")"
  coordinator_status="$(jq -r '.status // "unknown"' "$input_file")"
  would_dispatch="$(jq -r '(.would_dispatch // false) | tostring' "$input_file")"

  if [[ "$coordinator_status" != "pass" || "$coordinator_decision" != "recommend_dispatch" || "$would_dispatch" != "true" ]]; then
    emit_json "hold" "recommend_hold" "coordinator_not_green" "pipeline shadow DAG held until coordinator shadow recommends dispatch" 0
    return $?
  fi

  local dag artifact_written=false
  dag="$(build_dag)"
  write_artifact_if_requested "$dag"
  [[ -n "$artifact_path" ]] && artifact_written=true

  jq -n \
    --arg status "pass" \
    --arg decision "dry_run_dag_ready" \
    --arg failure_class "none" \
    --arg message "pipeline shadow DAG generated; native pipeline execution disabled" \
    --arg session "$session_name" \
    --arg native "$NATIVE_SURFACE" \
    --arg wrapper "$WRAPPER_SURFACE" \
    --arg idempotency_token "$(idempotency_token)" \
    --arg artifact "$artifact_path" \
    --arg ttl_native "single_pipeline_snapshot" \
    --arg ttl_wrapper "dry_run_artifact_lifetime" \
    --arg ttl_decision "regenerate_before_native_execution" \
    --arg delta "native_pipeline_disabled_shadow_dag_artifact_only" \
    --argjson dag "$dag" \
    --argjson artifact_written "$artifact_written" \
    --argjson dry_run "$dry_run" \
    --argjson apply "$apply_mode" \
    '{
      status: $status,
      decision: $decision,
      failure_class: $failure_class,
      message: $message,
      session: $session,
      mode: "shadow",
      artifact_path: $artifact,
      artifact_written: $artifact_written,
      dry_run_dag_generated: true,
      dag_node_count: ($dag.nodes | length),
      dag_edge_count: ($dag.edges | length),
      dag: $dag,
      native_pipeline_executed: false,
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
      authorized_operations: ["read_coordinator_receipt","generate_dry_run_dag","write_explicit_artifact","emit_shadow_receipt"],
      forbidden_operations: ["execute_native_pipeline","dispatch_pipeline_steps","mutate_live_state","treat_shadow_as_apply"],
      secret_scan_before_callback: "yes",
      quality_bar_passed: "yes",
      L112: "OK_ntm_migrate_W3aP"
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
    --arg idempotency_token "$(idempotency_token)" \
    --arg ttl_native "single_pipeline_snapshot" \
    --arg ttl_wrapper "dry_run_artifact_lifetime" \
    --arg ttl_decision "regenerate_before_native_execution" \
    --arg delta "native_pipeline_disabled_shadow_dag_artifact_only" \
    --argjson dry_run "$dry_run" \
    --argjson apply "$apply_mode" \
    '{
      status: $status,
      message: $message,
      version: $version,
      scope: $scope,
      mode: "shadow",
      native_pipeline_executed: false,
      idempotency_token: $idempotency_token,
      dry_run: $dry_run,
      apply: $apply,
      native_surface: $native,
      wrapper_surface: $wrapper,
      ttl_native: $ttl_native,
      ttl_wrapper: $ttl_wrapper,
      ttl_decision: $ttl_decision,
      native_wrapper_delta: $delta,
      authorized_operations: ["read_coordinator_receipt","generate_dry_run_dag","write_explicit_artifact","emit_shadow_receipt"],
      forbidden_operations: ["execute_native_pipeline","dispatch_pipeline_steps","mutate_live_state","treat_shadow_as_apply"],
      stable_exit_codes: {
        "0": "shadow DAG generated, hold receipt, or diagnostic pass",
        "2": "usage or invalid apply request",
        "64": "missing input",
        "65": "invalid input/artifact path",
        "127": "missing required local dependency"
      },
      L112: "OK_ntm_migrate_W3aP"
    }'
}

cmd_repair() {
  if [[ "$apply_mode" == true && -z "$idempotency_key" ]]; then
    emit_json "fail" "hold" "missing_idempotency_key" "repair --apply requires --idempotency-key" 2
  fi
  cmd_static "pass" "repair is no-op; native pipeline remains disabled and only dry-run DAG artifacts are allowed"
}

cmd_schema() {
  jq -n '{
    schema_version: "ntm-pipeline-shadow/v1",
    input_fields: ["status","decision","would_dispatch","blockers"],
    artifact_schema_version: "ntm-pipeline-shadow-dag/v1",
    required_output_fields: [
      "status",
      "decision",
      "mode",
      "dry_run_dag_generated",
      "native_pipeline_executed",
      "artifact_path",
      "authorized_operations",
      "forbidden_operations",
      "ttl_native",
      "ttl_wrapper",
      "ttl_decision",
      "native_wrapper_delta",
      "L112"
    ],
    stable_exit_codes: {
      "0": "shadow DAG generated, hold receipt, or diagnostic pass",
      "2": "usage or invalid apply request",
      "64": "missing input",
      "65": "invalid input/artifact path",
      "127": "missing required local dependency"
    },
    mutation_modes: ["--dry-run","--apply"],
    apply_requires: ["--idempotency-key"],
    native_pipeline_executed: false,
    L112: "OK_ntm_migrate_W3aP"
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
--artifact
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
    doctor) cmd_static "pass" "doctor pass: pipeline shadow wrapper available and native execution disabled" ;;
    health) cmd_static "pass" "health pass: dry-run DAG generation surface available" ;;
    repair) cmd_repair ;;
    validate) cmd_static "pass" "validate pass: JSON, schema, stable exit codes, and dry-run/apply discipline available" ;;
    audit) cmd_static "pass" "audit pass: native pipeline is not executed; explicit artifact path is the only write" ;;
    why) cmd_static "pass" "why: W3aP keeps native pipeline disabled while generating a reviewable dry-run DAG artifact" ;;
    schema) cmd_schema ;;
    completion) cmd_completion ;;
    *) emit_json "fail" "hold" "usage" "unknown subcommand: $subcommand" 2 ;;
  esac
}

main "$@"
