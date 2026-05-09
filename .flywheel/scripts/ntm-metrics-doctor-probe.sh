#!/usr/bin/env bash
set -euo pipefail

SCHEMA_VERSION="ntm-metrics-doctor-probe.v1"
MISSION_ANCHOR="continuous-orchestrator-uptime-self-sustaining-fleet"
NATIVE_SURFACE="ntm quota"
WRAPPER_SURFACE="flywheel metrics doctor"
L112="OK_ntm_migrate_W1M"
TTL_NATIVE="native_quota_snapshot_current"
TTL_WRAPPER="metrics_doctor_receipt_15m"
TTL_DECISION="quota_metrics_drive_doctor_gate_or_action"
NATIVE_WRAPPER_DELTA="native_ntm_quota_retains_usage_collection;metrics_doctor_adds_gate_action_mapping_for_orchestrator_doctor"
AUTHORIZED_OPERATIONS="ntm_quota_read,quota_receipt_validation,metrics_gate_mapping,doctor_receipt_emit"
FORBIDDEN_OPERATIONS="dispatch_mutation,quota_reset,credential_read,credential_rotation,pane_mutation,metrics_state_mutation"
ROLLBACK="remove_metrics_doctor_section_quota_still_emits_local_json"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
session="flywheel"
quota_probe="$ROOT/.flywheel/scripts/ntm-quota-proactive-probe.sh"
fixture=""
ntm_bin="${NTM_BIN:-ntm}"
warning_threshold=25
critical_threshold=10
unknown_provider_policy="warn"
reason="overview"
json=false
command="doctor"

usage() {
  cat <<'EOF'
usage: ntm-metrics-doctor-probe.sh [doctor|health|repair|validate|audit|why|schema|quickstart] [options]

Map W1Q quota metrics to an explicit flywheel doctor gate and action.

Options:
  --session NAME                 NTM session to query (default: flywheel)
  --quota-probe PATH             W1Q quota probe path
  --fixture PATH                 Read quota JSON through the quota probe fixture path
  --ntm-bin PATH                 Native ntm binary passed to quota probe (default: ntm)
  --warning-threshold N          Remaining-units warning threshold (default: 25)
  --critical-threshold N         Remaining-units critical threshold (default: 10)
  --unknown-provider-policy P    warn|fail (default: warn)
  --reason NAME                  Finding/action explanation for why
  --json                         Emit JSON
  --dry-run                      Accepted; this probe is read-only
  --apply                        Refused; metrics doctor never mutates
  --info | --examples | --schema Self-documenting surfaces
EOF
}

now_utc() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

emit_json() {
  jq -cn \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg mission_anchor "$MISSION_ANCHOR" \
    --arg native_surface "$NATIVE_SURFACE" \
    --arg wrapper_surface "$WRAPPER_SURFACE" \
    --arg l112 "$L112" \
    --arg ttl_native "$TTL_NATIVE" \
    --arg ttl_wrapper "$TTL_WRAPPER" \
    --arg ttl_decision "$TTL_DECISION" \
    --arg native_wrapper_delta "$NATIVE_WRAPPER_DELTA" \
    --arg authorized_operations "$AUTHORIZED_OPERATIONS" \
    --arg forbidden_operations "$FORBIDDEN_OPERATIONS" \
    --arg rollback "$ROLLBACK" \
    "$1"
}

info_json() {
  emit_json '{
    schema_version:$schema_version,
    name:"ntm-metrics-doctor-probe",
    mission_anchor:$mission_anchor,
    native_surface:$native_surface,
    wrapper_surface:$wrapper_surface,
    l112_observed:$l112,
    canonical_cli:{
      doctor:true, health:true, repair:true, validate:true, audit:true, why:true,
      schema:true, examples:true, json:true, dry_run:true, apply_refused:true
    },
    authorized_operations:($authorized_operations | split(",")),
    forbidden_operations:($forbidden_operations | split(",")),
    ttl_native:$ttl_native,
    ttl_wrapper:$ttl_wrapper,
    ttl_decision:$ttl_decision,
    native_wrapper_delta:$native_wrapper_delta,
    rollback:$rollback
  }'
}

examples_json() {
  emit_json '{
    schema_version:$schema_version,
    examples:[
      ".flywheel/scripts/ntm-metrics-doctor-probe.sh doctor --session flywheel --json",
      ".flywheel/scripts/ntm-metrics-doctor-probe.sh validate --fixture /tmp/quota.json --json",
      ".flywheel/scripts/ntm-metrics-doctor-probe.sh audit --json",
      ".flywheel/scripts/ntm-metrics-doctor-probe.sh why --reason quota_warning --json"
    ]
  }'
}

schema_json() {
  emit_json '{
    schema_version:$schema_version,
    required:[
      "schema_version","status","scope","checked_at","findings","metrics",
      "gate","action","gate_action_mapped","l112_observed","native_wrapper_delta"
    ],
    status_values:["ok","warn","fail"],
    gate_values:["none","quota_warning_advisory","metrics_source_advisory","dispatch_capacity_gate","metrics_contract_gate"],
    action_values:["continue_dispatch","throttle_new_dispatches_and_monitor_reset","configure_provider_or_keep_native_quota_receipt","pause_dispatch_until_reset_or_rotate_provider","fix_quota_metrics_source"],
    mutation_requires:"not_supported",
    default_mode:"read_only"
  }'
}

fail_json() {
  local rc="$1" reason_text="$2"
  jq -cn \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg checked_at "$(now_utc)" \
    --arg session "$session" \
    --arg reason "$reason_text" \
    --arg mission_anchor "$MISSION_ANCHOR" \
    --arg native_surface "$NATIVE_SURFACE" \
    --arg wrapper_surface "$WRAPPER_SURFACE" \
    --arg l112 "$L112" \
    --arg native_wrapper_delta "$NATIVE_WRAPPER_DELTA" \
    --arg rollback "$ROLLBACK" \
    '{schema_version:$schema_version,status:"fail",mission_anchor:$mission_anchor,scope:{session:$session},checked_at:$checked_at,native_surface:$native_surface,wrapper_surface:$wrapper_surface,findings:[{severity:"error",reason:$reason}],metrics:null,gate:"metrics_contract_gate",action:"fix_quota_metrics_source",gate_action_mapped:true,l112_observed:$l112,native_wrapper_delta:$native_wrapper_delta,rollback:$rollback,dispatch_mutation_performed:false,secret_values_observed:0}'
  exit "$rc"
}

read_quota_receipt() {
  if [[ -n "$fixture" ]]; then
    cat "$fixture"
    return
  fi

  if [[ ! -x "$quota_probe" ]]; then
    fail_json 2 "quota_probe_missing_or_not_executable"
  fi

  local args=(validate --session "$session" --warning-threshold "$warning_threshold" --critical-threshold "$critical_threshold" --unknown-provider-policy "$unknown_provider_policy" --json)
  args+=(--ntm-bin "$ntm_bin")

  "$quota_probe" "${args[@]}"
}

map_metrics() {
  jq -c \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg checked_at "$(now_utc)" \
    --arg session "$session" \
    --arg mission_anchor "$MISSION_ANCHOR" \
    --arg native_surface "$NATIVE_SURFACE" \
    --arg wrapper_surface "$WRAPPER_SURFACE" \
    --arg l112 "$L112" \
    --arg ttl_native "$TTL_NATIVE" \
    --arg ttl_wrapper "$TTL_WRAPPER" \
    --arg ttl_decision "$TTL_DECISION" \
    --arg native_wrapper_delta "$NATIVE_WRAPPER_DELTA" \
    --arg authorized_operations "$AUTHORIZED_OPERATIONS" \
    --arg forbidden_operations "$FORBIDDEN_OPERATIONS" \
    --arg rollback "$ROLLBACK" '
      . as $quota
      | ($quota.status // null) as $status_field
      | ($quota.capacity_class // $quota.class // $quota.quota.capacity_class // null) as $native_class
      | ($quota.remaining_units // $quota.remaining // $quota.remaining_percent // $quota.quota.remaining_units // $quota.quota.remaining // null) as $remaining
      | (if $remaining == null then "unknown"
         elif $remaining <= 10 then "critical"
         elif $remaining <= 25 then "warning"
         else "ok" end) as $derived_class
      | (if $status_field == null and $native_class == null then true else false end) as $raw_native_receipt
      | {
          status:(if $raw_native_receipt then (if $derived_class == "critical" then "fail" elif $derived_class == "warning" or $derived_class == "unknown" then "warn" else "ok" end) else $status_field end),
          capacity_class:($native_class // $derived_class),
          remaining_units:$remaining,
          window_reset_at:($quota.window_reset_at // $quota.reset_at // $quota.quota.window_reset_at // $quota.quota.reset_at // null),
          source:($quota.source // (if $raw_native_receipt then "ntm quota" else null end))
        } as $m
      | ([($m.status|type),($m.capacity_class|type),($m.source|type)]
          | all(. == "string")) as $string_fields_present
      | (if $m.status == null or $m.capacity_class == null or $m.source == null or ($string_fields_present | not) then false else true end) as $required_present
      | (if ($required_present | not) then "fail"
         elif $m.status == "fail" or $m.capacity_class == "critical" then "fail"
         elif $m.status == "warn" or $m.capacity_class == "warning" or $m.capacity_class == "unknown" then "warn"
         else "ok" end) as $status
      | (if ($required_present | not) then "metrics_contract_gate"
         elif $m.status == "fail" or $m.capacity_class == "critical" then "dispatch_capacity_gate"
         elif $m.capacity_class == "warning" then "quota_warning_advisory"
         elif $m.status == "warn" or $m.capacity_class == "unknown" then "metrics_source_advisory"
         else "none" end) as $gate
      | (if $gate == "metrics_contract_gate" then "fix_quota_metrics_source"
         elif $gate == "dispatch_capacity_gate" then "pause_dispatch_until_reset_or_rotate_provider"
         elif $gate == "quota_warning_advisory" then "throttle_new_dispatches_and_monitor_reset"
         elif $gate == "metrics_source_advisory" then "configure_provider_or_keep_native_quota_receipt"
         else "continue_dispatch" end) as $action
      | (($quota.findings // []) + [
          (if ($required_present | not) then {severity:"error",reason:"metrics_missing_required_fields",required:["status","capacity_class","remaining_units","window_reset_at","source"]} else empty end),
          {severity:(if $status == "fail" then "error" elif $status == "warn" then "warn" else "info" end),reason:"metrics_mapped_to_gate_action",gate:$gate,action:$action}
        ]) as $findings
      | {
          schema_version:$schema_version,
          status:$status,
          mission_anchor:$mission_anchor,
          scope:{session:$session,doctor:"ntm_metrics"},
          checked_at:$checked_at,
          native_surface:$native_surface,
          wrapper_surface:$wrapper_surface,
          quota_receipt_schema_version:($quota.schema_version // null),
          metrics:$m,
          findings:$findings,
          gate:$gate,
          action:$action,
          gate_action_mapped:($gate != null and $action != null),
          metrics_source_ready:($status != "fail"),
          dispatch_mutation_performed:false,
          l112_observed:$l112,
          rollback:$rollback,
          authorized_operations:($authorized_operations | split(",")),
          forbidden_operations:($forbidden_operations | split(",")),
          ttl_native:$ttl_native,
          ttl_wrapper:$ttl_wrapper,
          ttl_decision:$ttl_decision,
          native_wrapper_delta:$native_wrapper_delta,
          secret_values_observed:0
        }'
}

metrics_payload() {
  local raw
  if ! raw="$(read_quota_receipt)"; then
    fail_json 2 "quota_probe_failed"
  fi
  if ! jq empty >/dev/null 2>&1 <<<"$raw"; then
    fail_json 2 "quota_probe_non_json"
  fi

  local mapped status
  if ! mapped="$(map_metrics <<<"$raw")"; then
    fail_json 2 "metrics_mapping_failed"
  fi
  printf '%s\n' "$mapped"
  status="$(jq -r '.status // "fail"' <<<"$mapped")"
  [[ "$status" != "fail" ]]
}

run_metrics_command() {
  local mode="$1"
  local payload rc
  set +e
  payload="$(metrics_payload)"
  rc=$?
  set -e
  if [[ "$mode" == "audit" ]]; then
    payload="$(jq -c '. + {audit:{gate:.gate,action:.action,metrics_keys:(.metrics | keys),required_fields_present:(.metrics.status != null and .metrics.capacity_class != null and .metrics.source != null)}}' <<<"$payload")"
  fi
  printf '%s\n' "$payload"
  exit "$rc"
}

repair_json() {
  jq -cn \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg checked_at "$(now_utc)" \
    --arg l112 "$L112" \
    --arg authorized_operations "$AUTHORIZED_OPERATIONS" \
    --arg forbidden_operations "$FORBIDDEN_OPERATIONS" \
    '{
    schema_version:$schema_version,
    status:"ok",
    checked_at:$checked_at,
    repair_mode:"dry_run",
    mutation_performed:false,
    planned_actions:["inspect quota receipt","fix quota metrics source if required","rerun metrics doctor validate"],
    authorized_operations:($authorized_operations | split(",")),
    forbidden_operations:($forbidden_operations | split(",")),
    l112_observed:$l112
  }'
}

why_json() {
  jq -cn \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg reason "$reason" \
    --arg checked_at "$(now_utc)" \
    --arg l112 "$L112" \
    '{
      schema_version:$schema_version,
      status:"ok",
      checked_at:$checked_at,
      reason:$reason,
      explanations:{
        overview:"W1M keeps quota collection native in W1Q and adds doctor-visible gate/action mapping.",
        quota_warning:"A warning quota does not stop dispatch, but it maps to throttle_new_dispatches_and_monitor_reset.",
        unknown_provider:"Unknown provider is advisory by default so native quota JSON remains visible without a hard stop.",
        quota_critical:"Critical quota maps to dispatch_capacity_gate and pauses dispatch until reset or provider rotation.",
        metrics_missing_required_fields:"Malformed quota receipts map to metrics_contract_gate and fix_quota_metrics_source."
      },
      l112_observed:$l112
    }'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    doctor|health|repair|validate|audit|why|schema|quickstart) command="$1"; shift ;;
    --session) session="$2"; shift 2 ;;
    --quota-probe) quota_probe="$2"; shift 2 ;;
    --fixture) fixture="$2"; shift 2 ;;
    --ntm-bin) ntm_bin="$2"; shift 2 ;;
    --warning-threshold) warning_threshold="$2"; shift 2 ;;
    --critical-threshold) critical_threshold="$2"; shift 2 ;;
    --unknown-provider-policy) unknown_provider_policy="$2"; shift 2 ;;
    --reason) reason="$2"; shift 2 ;;
    --json) json=true; shift ;;
    --dry-run) shift ;;
    --apply) fail_json 3 "apply_not_supported_read_only_probe" ;;
    --explain) command="why"; shift ;;
    --info) info_json; exit 0 ;;
    --examples|examples) examples_json; exit 0 ;;
    --schema) schema_json; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) fail_json 3 "unknown_argument:$1" ;;
  esac
done

case "$unknown_provider_policy" in
  warn|fail) ;;
  *) fail_json 3 "invalid_unknown_provider_policy" ;;
esac

case "$command" in
  schema) schema_json ;;
  quickstart) jq -cn --arg schema_version "$SCHEMA_VERSION" '{schema_version:$schema_version,status:"ok",steps:["run --info --json","run --schema --json","run doctor --session flywheel --json","read gate/action before dispatch"]}' ;;
  doctor|health|validate) run_metrics_command "$command" ;;
  audit) run_metrics_command "audit" ;;
  repair) repair_json ;;
  why) why_json ;;
esac
