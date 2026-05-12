#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/ntm-metrics-doctor-probe.sh"
QUOTA_SCRIPT="$ROOT/.flywheel/scripts/ntm-quota-proactive-probe.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/ntm-metrics-doctor-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

make_fake_quota_probe() {
  local path="$TMP/ntm-quota-proactive-probe"
  cat >"$path" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${FAKE_QUOTA_LOG:?}"
mode="${FAKE_QUOTA_MODE:?}"
case "$mode" in
  ok) jq -nc '{schema_version:"ntm-quota-proactive-probe.v1",status:"ok",capacity_class:"ok",remaining_units:74,window_reset_at:"2026-05-07T16:00:00Z",source:"fixture-native",findings:[]}' ;;
  warning) jq -nc '{schema_version:"ntm-quota-proactive-probe.v1",status:"warn",capacity_class:"warning",remaining_units:18,window_reset_at:"2026-05-07T16:00:00Z",source:"fixture-native",findings:[{severity:"warn",reason:"quota_warning"}]}' ;;
  unknown) jq -nc '{schema_version:"ntm-quota-proactive-probe.v1",status:"warn",capacity_class:"unknown",remaining_units:null,window_reset_at:null,source:"fixture-native",findings:[{severity:"warn",reason:"unknown_provider",policy:"warn"}]}' ;;
  critical) jq -nc '{schema_version:"ntm-quota-proactive-probe.v1",status:"fail",capacity_class:"critical",remaining_units:4,window_reset_at:"2026-05-07T16:00:00Z",source:"fixture-native",findings:[{severity:"error",reason:"quota_critical"}]}' ;;
  missing) jq -nc '{schema_version:"ntm-quota-proactive-probe.v1",status:"ok",remaining_units:44,findings:[]}' ;;
  nonjson) printf 'not json\n' ;;
  fail) exit 9 ;;
esac
SH
  chmod +x "$path"
  printf '%s\n' "$path"
}

run_doctor() {
  local name="$1" mode="$2"; shift 2
  local fake log out
  fake="$(make_fake_quota_probe)"
  log="$TMP/$name.quota.log"
  out="$TMP/$name.json"
  : >"$log"
  set +e
  FAKE_QUOTA_MODE="$mode" FAKE_QUOTA_LOG="$log" "$SCRIPT" doctor --quota-probe "$fake" --session flywheel --json "$@" >"$out"
  rc=$?
  set -e
  printf '%s\n' "$rc" >"$TMP/$name.rc"
  printf '%s\n' "$out"
}

bash -n "$SCRIPT" && pass "script_syntax" || fail "script_syntax"

"$SCRIPT" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.name == "ntm-metrics-doctor-probe" and .native_surface == "ntm quota" and .wrapper_surface == "flywheel metrics doctor" and .canonical_cli.doctor == true and .canonical_cli.repair == true and (.authorized_operations | index("metrics_gate_mapping"))' "info_json_contract"

"$SCRIPT" --schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.schema_version == "ntm-metrics-doctor-probe.v1" and (.required | index("gate")) and (.required | index("action")) and .default_mode == "read_only"' "schema_json_contract"

"$SCRIPT" --examples --json >"$TMP/examples.json"
assert_jq "$TMP/examples.json" '(.examples | length) >= 4' "examples_json_contract"

"$SCRIPT" why --reason quota_warning --json >"$TMP/why.json"
assert_jq "$TMP/why.json" '.status == "ok" and .reason == "quota_warning" and (.explanations.quota_warning | contains("throttle_new_dispatches"))' "why_json_contract"

"$SCRIPT" repair --dry-run --json >"$TMP/repair.json"
assert_jq "$TMP/repair.json" '.status == "ok" and .repair_mode == "dry_run" and .mutation_performed == false and (.planned_actions | index("rerun metrics doctor validate"))' "repair_dry_run_contract"

ok_out="$(run_doctor ok ok)"
assert_jq "$ok_out" '.status == "ok" and .metrics.capacity_class == "ok" and .metrics.remaining_units == 74 and .gate == "none" and .action == "continue_dispatch" and .gate_action_mapped == true and .l112_observed == "OK_ntm_migrate_W1M" and .dispatch_mutation_performed == false' "ok_metrics_gate_mapping"
grep -q '^validate --session flywheel --warning-threshold 25 --critical-threshold 10 --unknown-provider-policy warn --json --ntm-bin ntm$' "$TMP/ok.quota.log" && pass "quota_probe_invoked" || fail "quota_probe_invoked"

warn_out="$(run_doctor warning warning)"
assert_jq "$warn_out" '.status == "warn" and .gate == "quota_warning_advisory" and .action == "throttle_new_dispatches_and_monitor_reset" and any(.findings[]; .reason == "metrics_mapped_to_gate_action")' "warning_metrics_gate_mapping"

unknown_out="$(run_doctor unknown unknown)"
unknown_rc="$(cat "$TMP/unknown.rc")"
if [[ "$unknown_rc" == "0" ]]; then pass "unknown_provider_warn_not_hard_stop"; else fail "unknown_provider_warn_not_hard_stop_rc=$unknown_rc"; fi
assert_jq "$unknown_out" '.status == "warn" and .gate == "metrics_source_advisory" and .action == "configure_provider_or_keep_native_quota_receipt"' "unknown_provider_metrics_mapping"

critical_out="$(run_doctor critical critical)"
critical_rc="$(cat "$TMP/critical.rc")"
if [[ "$critical_rc" == "1" ]]; then pass "critical_gate_exits_nonzero"; else fail "critical_gate_exits_nonzero_rc=$critical_rc"; fi
assert_jq "$critical_out" '.status == "fail" and .gate == "dispatch_capacity_gate" and .action == "pause_dispatch_until_reset_or_rotate_provider" and .metrics_source_ready == false and .rollback == "remove_metrics_doctor_section_quota_still_emits_local_json"' "critical_metrics_gate_mapping"

missing_out="$(run_doctor missing missing)"
missing_rc="$(cat "$TMP/missing.rc")"
if [[ "$missing_rc" == "1" ]]; then pass "missing_metric_fields_exit_nonzero"; else fail "missing_metric_fields_exit_nonzero_rc=$missing_rc"; fi
assert_jq "$missing_out" '.status == "fail" and .gate == "metrics_contract_gate" and .action == "fix_quota_metrics_source" and any(.findings[]; .reason == "metrics_missing_required_fields")' "missing_metric_fields_receipt"

nonjson_out="$(run_doctor nonjson nonjson)"
nonjson_rc="$(cat "$TMP/nonjson.rc")"
if [[ "$nonjson_rc" == "2" ]]; then pass "non_json_quota_probe_fails_stable"; else fail "non_json_quota_probe_fails_stable_rc=$nonjson_rc"; fi
assert_jq "$nonjson_out" '.status == "fail" and .findings[0].reason == "quota_probe_non_json" and .gate == "metrics_contract_gate"' "non_json_quota_receipt"

set +e
"$SCRIPT" --apply --json >"$TMP/apply.json"
apply_rc=$?
set -e
if [[ "$apply_rc" == "3" ]]; then pass "apply_refused_stable"; else fail "apply_refused_stable_rc=$apply_rc"; fi
assert_jq "$TMP/apply.json" '.status == "fail" and .findings[0].reason == "apply_not_supported_read_only_probe"' "apply_refusal_receipt"

fixture="$TMP/quota-fixture.json"
jq -nc '{provider:"codex",remaining_units:55,window_reset_at:"2026-05-07T17:00:00Z",source:"fixture-file"}' >"$fixture"
"$SCRIPT" validate --quota-probe "$QUOTA_SCRIPT" --fixture "$fixture" --json >"$TMP/raw_quota_fixture.json"
assert_jq "$TMP/raw_quota_fixture.json" '.status == "ok" and .metrics.remaining_units == 55 and .gate == "none" and .action == "continue_dispatch" and .metrics.source == "fixture-file"' "raw_quota_fixture_mapping"

FAKE_QUOTA_MODE=ok FAKE_QUOTA_LOG="$TMP/audit2.log" "$SCRIPT" audit --quota-probe "$(make_fake_quota_probe)" --json >"$TMP/audit.json"
assert_jq "$TMP/audit.json" '.audit.gate == .gate and (.audit.metrics_keys | index("remaining_units")) and .audit.required_fields_present == true' "audit_json_contract"

if ! rg -n "(sk-[A-Za-z0-9]{20,}|Bearer [A-Za-z0-9._-]{20,}|refresh_token\"[[:space:]]*:[[:space:]]*\"[^\"]{8,}|BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY)" "$SCRIPT" "$0" >/dev/null; then
  pass "secret_scan_clean"
else
  fail "secret_scan_clean"
fi

printf 'ntm_metrics_doctor_probe_tests pass=%d fail=%d total=%d\n' "$pass_count" "$fail_count" "$((pass_count + fail_count))"
[[ "$fail_count" == 0 ]]
