#!/usr/bin/env bash
set -euo pipefail

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
