#!/usr/bin/env bash
set -euo pipefail

SCHEMA_VERSION="ntm-quota-proactive-probe.v1"
MISSION_ANCHOR="continuous-orchestrator-uptime-self-sustaining-fleet"
NATIVE_SURFACE="ntm quota"
TTL_NATIVE="native_quota_snapshot_current"
TTL_WRAPPER="probe_receipt_15m"
TTL_DECISION="native_snapshot_for_capacity_truth_wrapper_receipt_feeds_w1_metrics"
NATIVE_WRAPPER_DELTA="native_ntm_quota_owns_usage_collection;wrapper_owns_threshold_classification_unknown_provider_policy_and_metrics_ready_receipt"
AUTHORIZED_OPERATIONS="ntm_quota_read,capacity_threshold_classification,metrics_source_receipt"
FORBIDDEN_OPERATIONS="dispatch_mutation,quota_reset,credential_read,credential_rotation,pane_mutation"

session="flywheel"
provider="auto"
warning_threshold=25
critical_threshold=10
unknown_provider_policy="warn"
fixture=""
ntm_bin="${NTM_BIN:-ntm}"
json=false
command="probe"

usage() {
  cat <<'EOF'
usage: ntm-quota-proactive-probe.sh [doctor|health|validate|schema|quickstart] [options]

Read native ntm quota JSON and emit a flywheel W1Q capacity receipt.

Options:
  --session NAME                 NTM session to query (default: flywheel)
  --provider NAME                Expected provider/tool name (default: auto)
  --warning-threshold N          Remaining-units warning threshold (default: 25)
  --critical-threshold N         Remaining-units critical threshold (default: 10)
  --unknown-provider-policy P    warn|fail (default: warn)
  --fixture PATH                 Read native quota JSON from fixture instead of ntm
  --ntm-bin PATH                 Native ntm binary (default: ntm)
  --json                         Emit JSON
  --dry-run                      Accepted; this probe is read-only
  --apply                        Refused; quota probe never mutates
  --info | --examples | --schema Self-documenting surfaces
EOF
}

now_utc() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

emit_json() {
  jq -cn \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg mission_anchor "$MISSION_ANCHOR" \
    --arg native_surface "$NATIVE_SURFACE" \
    --arg ttl_native "$TTL_NATIVE" \
    --arg ttl_wrapper "$TTL_WRAPPER" \
    --arg ttl_decision "$TTL_DECISION" \
    --arg native_wrapper_delta "$NATIVE_WRAPPER_DELTA" \
    --arg authorized_operations "$AUTHORIZED_OPERATIONS" \
    --arg forbidden_operations "$FORBIDDEN_OPERATIONS" \
    "$1"
}

info_json() {
  emit_json '{
    schema_version:$schema_version,
    name:"ntm-quota-proactive-probe",
    mission_anchor:$mission_anchor,
    native_surface:$native_surface,
    canonical_cli:{doctor:true,health:true,validate:true,schema:true,examples:true,json:true,dry_run:true,apply_refused:true},
    authorized_operations:($authorized_operations | split(",")),
    forbidden_operations:($forbidden_operations | split(",")),
    ttl_native:$ttl_native,
    ttl_wrapper:$ttl_wrapper,
    ttl_decision:$ttl_decision,
    native_wrapper_delta:$native_wrapper_delta
  }'
}

examples_json() {
  emit_json '{
    schema_version:$schema_version,
    examples:[
      ".flywheel/scripts/ntm-quota-proactive-probe.sh --session flywheel --json",
      ".flywheel/scripts/ntm-quota-proactive-probe.sh --fixture /tmp/quota.json --json",
      ".flywheel/scripts/ntm-quota-proactive-probe.sh validate --fixture /tmp/quota.json --json",
      ".flywheel/scripts/ntm-quota-proactive-probe.sh doctor --json"
    ]
  }'
}

schema_json() {
  emit_json '{
    schema_version:$schema_version,
    required:["schema_version","status","scope","checked_at","findings","capacity_class","remaining_units","window_reset_at","source","native_surface","native_wrapper_delta"],
    status_values:["ok","warn","fail"],
    capacity_class_values:["ok","warning","critical","unknown"],
    mutation_requires:"not_supported",
    default_mode:"read_only"
  }'
}

fail_json() {
  local status="$1" rc="$2" reason="$3"
  jq -cn \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg status "$status" \
    --arg checked_at "$(now_utc)" \
    --arg reason "$reason" \
    --arg session "$session" \
    '{schema_version:$schema_version,status:$status,checked_at:$checked_at,scope:{session:$session},findings:[{severity:"error",reason:$reason}]}'
  exit "$rc"
}

read_native_quota() {
  if [[ -n "$fixture" ]]; then
    cat "$fixture"
    return
  fi
  "$ntm_bin" quota "$session" --json
}

normalize_quota() {
  jq -c \
    --arg session "$session" \
    --arg provider "$provider" \
    --argjson warning "$warning_threshold" \
    --argjson critical "$critical_threshold" \
    --arg unknown_policy "$unknown_provider_policy" \
    --arg checked_at "$(now_utc)" \
    --arg native_surface "$NATIVE_SURFACE" \
    --arg ttl_native "$TTL_NATIVE" \
    --arg ttl_wrapper "$TTL_WRAPPER" \
    --arg ttl_decision "$TTL_DECISION" \
    --arg native_wrapper_delta "$NATIVE_WRAPPER_DELTA" \
    --arg authorized_operations "$AUTHORIZED_OPERATIONS" \
    --arg forbidden_operations "$FORBIDDEN_OPERATIONS" \
    --arg mission_anchor "$MISSION_ANCHOR" \
    --arg schema_version "$SCHEMA_VERSION" '
      def num_or_null: if type == "number" then . elif type == "string" and test("^[0-9]+([.][0-9]+)?$") then tonumber else null end;
      . as $raw
      | ($raw.provider // $raw.tool // $raw.agent // $raw.model_provider // "unknown") as $raw_provider
      | (if $provider == "auto" then $raw_provider else $provider end) as $effective_provider
      | ($raw.remaining_units // $raw.remaining // $raw.remaining_percent // $raw.quota.remaining_units // $raw.quota.remaining // null | num_or_null) as $remaining
      | ($raw.capacity_class // $raw.class // $raw.quota.capacity_class // null) as $native_class
      | (if $remaining == null then "unknown"
         elif $remaining <= $critical then "critical"
         elif $remaining <= $warning then "warning"
         else "ok" end) as $derived_class
      | ($native_class // $derived_class) as $capacity_class
      | ($raw.window_reset_at // $raw.reset_at // $raw.quota.window_reset_at // $raw.quota.reset_at // null) as $reset
      | ($raw.source // "ntm quota") as $source
      | ($effective_provider == "unknown") as $unknown_provider
      | (if $capacity_class == "critical" then "fail"
         elif $unknown_provider and $unknown_policy == "fail" then "fail"
         elif $capacity_class == "warning" or $capacity_class == "unknown" or $unknown_provider then "warn"
         else "ok" end) as $status
      | {
          schema_version:$schema_version,
          status:$status,
          mission_anchor:$mission_anchor,
          scope:{session:$session,provider:$effective_provider},
          checked_at:$checked_at,
          native_surface:$native_surface,
          native_invocation:"ntm quota \($session) --json",
          wrapper_retained_reason:"flywheel threshold classification, unknown-provider policy, metrics-ready receipt",
          capacity_class:$capacity_class,
          remaining_units:$remaining,
          window_reset_at:$reset,
          source:$source,
          findings:([
            (if $capacity_class == "critical" then {severity:"error",reason:"quota_critical",remaining_units:$remaining} else empty end),
            (if $capacity_class == "warning" then {severity:"warn",reason:"quota_warning",remaining_units:$remaining} else empty end),
            (if $capacity_class == "unknown" then {severity:"warn",reason:"quota_unknown"} else empty end),
            (if $unknown_provider then {severity:(if $unknown_policy == "fail" then "error" else "warn" end),reason:"unknown_provider",policy:$unknown_policy} else empty end)
          ]),
          metrics_source_ready:($status != "fail"),
          dispatch_mutation_performed:false,
          rollback:"disable_quota_gate_and_leave_metrics_source_unset",
          authorized_operations:($authorized_operations | split(",")),
          forbidden_operations:($forbidden_operations | split(",")),
          ttl_native:$ttl_native,
          ttl_wrapper:$ttl_wrapper,
          ttl_decision:$ttl_decision,
          native_wrapper_delta:$native_wrapper_delta,
          secret_values_observed:0
        }'
}

run_probe() {
  local raw
  if ! raw="$(read_native_quota)"; then
    fail_json "fail" 2 "ntm_quota_failed"
  fi
  if ! jq empty >/dev/null 2>&1 <<<"$raw"; then
    fail_json "fail" 2 "ntm_quota_non_json"
  fi
  normalize_quota <<<"$raw"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    doctor|health|validate|schema|quickstart) command="$1"; shift ;;
    --session) session="$2"; shift 2 ;;
    --provider) provider="$2"; shift 2 ;;
    --warning-threshold) warning_threshold="$2"; shift 2 ;;
    --critical-threshold) critical_threshold="$2"; shift 2 ;;
    --unknown-provider-policy) unknown_provider_policy="$2"; shift 2 ;;
    --fixture) fixture="$2"; shift 2 ;;
    --ntm-bin) ntm_bin="$2"; shift 2 ;;
    --json) json=true; shift ;;
    --dry-run) shift ;;
    --apply) fail_json "fail" 3 "apply_not_supported_read_only_probe" ;;
    --info) info_json; exit 0 ;;
    --examples|examples) examples_json; exit 0 ;;
    --schema) schema_json; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) fail_json "fail" 3 "unknown_argument:$1" ;;
  esac
done

case "$unknown_provider_policy" in
  warn|fail) ;;
  *) fail_json "fail" 3 "invalid_unknown_provider_policy" ;;
esac

case "$command" in
  schema) schema_json ;;
  quickstart) jq -cn --arg schema_version "$SCHEMA_VERSION" '{schema_version:$schema_version,status:"ok",steps:["run --info --json","run --schema --json","run --session flywheel --json","feed receipt to W1 metrics"]}' ;;
  doctor) jq -cn --arg schema_version "$SCHEMA_VERSION" --arg checked_at "$(now_utc)" '{schema_version:$schema_version,status:"ok",checked_at:$checked_at,doctor_fields:["ntm_quota_status","ntm_quota_capacity_class","ntm_quota_remaining_units","ntm_quota_metrics_source_ready"]}' ;;
  health) run_probe ;;
  validate|probe) run_probe ;;
esac
