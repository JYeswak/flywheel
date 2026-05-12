#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/ntm-quota-proactive-probe.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/ntm-quota-probe-test.XXXXXX")"
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

make_fake_ntm() {
  local mode="$1" path="$TMP/ntm-$mode"
  cat >"$path" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${FAKE_NTM_LOG:?}"
mode="${FAKE_NTM_MODE:?}"
case "$mode" in
  ok) jq -nc '{provider:"codex",remaining_units:74,window_reset_at:"2026-05-07T16:00:00Z",source:"fixture-native"}' ;;
  warning) jq -nc '{provider:"codex",remaining_units:18,window_reset_at:"2026-05-07T16:00:00Z",source:"fixture-native"}' ;;
  critical) jq -nc '{provider:"codex",remaining_units:4,window_reset_at:"2026-05-07T16:00:00Z",source:"fixture-native"}' ;;
  unknown) jq -nc '{remaining_units:null,source:"fixture-native"}' ;;
  nonjson) printf 'not json\n' ;;
  fail) exit 9 ;;
esac
SH
  chmod +x "$path"
  printf '%s\n' "$path"
}

run_probe() {
  local name="$1" mode="$2"; shift 2
  local fake log out
  fake="$(make_fake_ntm "$mode")"
  log="$TMP/$name.ntm.log"
  out="$TMP/$name.json"
  : >"$log"
  set +e
  FAKE_NTM_MODE="$mode" FAKE_NTM_LOG="$log" "$SCRIPT" --ntm-bin "$fake" --session flywheel --json "$@" >"$out"
  rc=$?
  set -e
  printf '%s\n' "$rc" >"$TMP/$name.rc"
  printf '%s\n' "$out"
}

bash -n "$SCRIPT" && pass "script_syntax" || fail "script_syntax"

"$SCRIPT" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.name == "ntm-quota-proactive-probe" and .native_surface == "ntm quota" and (.canonical_cli.doctor == true) and (.authorized_operations | index("ntm_quota_read"))' "info_json_contract"

"$SCRIPT" --schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.schema_version == "ntm-quota-proactive-probe.v1" and (.required | index("remaining_units")) and .default_mode == "read_only"' "schema_json_contract"

"$SCRIPT" --examples --json >"$TMP/examples.json"
assert_jq "$TMP/examples.json" '(.examples | length) >= 4' "examples_json_contract"

"$SCRIPT" doctor --json >"$TMP/doctor.json"
assert_jq "$TMP/doctor.json" '.status == "ok" and (.doctor_fields | index("ntm_quota_remaining_units"))' "doctor_json_contract"

ok_out="$(run_probe ok ok)"
assert_jq "$ok_out" '.status == "ok" and .capacity_class == "ok" and .remaining_units == 74 and .metrics_source_ready == true and .dispatch_mutation_performed == false' "ok_capacity_probe"
grep -q '^quota flywheel --json$' "$TMP/ok.ntm.log" && pass "native_ntm_quota_invoked" || fail "native_ntm_quota_invoked"

warn_out="$(run_probe warning warning)"
assert_jq "$warn_out" '.status == "warn" and .capacity_class == "warning" and any(.findings[]; .reason == "quota_warning")' "warning_capacity_probe"

crit_out="$(run_probe critical critical)"
crit_rc="$(cat "$TMP/critical.rc")"
if [[ "$crit_rc" == "0" ]]; then pass "critical_probe_is_visible_not_mutating"; else fail "critical_probe_is_visible_not_mutating_rc=$crit_rc"; fi
assert_jq "$crit_out" '.status == "fail" and .capacity_class == "critical" and any(.findings[]; .reason == "quota_critical") and .rollback == "disable_quota_gate_and_leave_metrics_source_unset"' "critical_capacity_receipt"

unknown_out="$(run_probe unknown unknown)"
unknown_rc="$(cat "$TMP/unknown.rc")"
if [[ "$unknown_rc" == "0" ]]; then pass "unknown_provider_warns_without_hard_stop"; else fail "unknown_provider_warns_without_hard_stop_rc=$unknown_rc"; fi
assert_jq "$unknown_out" '.status == "warn" and any(.findings[]; .reason == "unknown_provider" and .policy == "warn")' "unknown_provider_warn_receipt"

unknown_fail_out="$(run_probe unknown_fail unknown --unknown-provider-policy fail)"
assert_jq "$unknown_fail_out" '.status == "fail" and any(.findings[]; .reason == "unknown_provider" and .policy == "fail")' "unknown_provider_fail_policy_receipt"

nonjson_out="$(run_probe nonjson nonjson)"
nonjson_rc="$(cat "$TMP/nonjson.rc")"
if [[ "$nonjson_rc" == "2" ]]; then pass "non_json_native_fails_stable"; else fail "non_json_native_fails_stable_rc=$nonjson_rc"; fi
assert_jq "$nonjson_out" '.status == "fail" and .findings[0].reason == "ntm_quota_non_json"' "non_json_native_receipt"

set +e
"$SCRIPT" --apply --json >"$TMP/apply.json"
apply_rc=$?
set -e
if [[ "$apply_rc" == "3" ]]; then pass "apply_refused_stable"; else fail "apply_refused_stable_rc=$apply_rc"; fi
assert_jq "$TMP/apply.json" '.status == "fail" and .findings[0].reason == "apply_not_supported_read_only_probe"' "apply_refusal_receipt"

fixture="$TMP/fixture.json"
jq -nc '{provider:"claude",quota:{remaining:55,reset_at:"2026-05-07T17:00:00Z"},source:"fixture-file"}' >"$fixture"
"$SCRIPT" validate --fixture "$fixture" --json >"$TMP/fixture.json.out"
assert_jq "$TMP/fixture.json.out" '.status == "ok" and .scope.provider == "claude" and .remaining_units == 55 and .source == "fixture-file"' "fixture_validate_probe"

if ! rg -n "(sk-[A-Za-z0-9]{20,}|Bearer [A-Za-z0-9._-]{20,}|refresh_token\"[[:space:]]*:[[:space:]]*\"[^\"]{8,}|BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY)" "$SCRIPT" "$0" >/dev/null; then
  pass "secret_scan_clean"
else
  fail "secret_scan_clean"
fi

printf 'ntm_quota_proactive_probe_tests pass=%d fail=%d total=%d\n' "$pass_count" "$fail_count" "$((pass_count + fail_count))"
[[ "$fail_count" == 0 ]]
