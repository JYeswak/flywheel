#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/ntm-policy-contracts.sh"
POLICY="$ROOT/.ntm/policy.yaml"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/ntm-policy-contracts.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

run_case() {
  local name="$1"
  shift
  local out="$TMP/$name.json"
  local rc=0
  set +e
  "$SCRIPT" "$@" --json >"$out"
  rc=$?
  set -e
  printf '%s\n' "$rc" >"$TMP/$name.rc"
  printf '%s\n' "$out"
}

copy_policy() {
  local dest="$1"
  cp "$POLICY" "$dest"
}

bash -n "$SCRIPT" && pass "script_syntax" || fail "script_syntax"
bash -n "$0" && pass "test_syntax" || fail "test_syntax"

info_out="$(run_case info --info)"
assert_jq "$info_out" '.status == "ok" and .name == "ntm-policy-contracts" and .l112_observed == "OK_ntm_migrate_W3bP"' "info_json_contract"
assert_jq "$info_out" '.canonical_cli.doctor == true and .canonical_cli.repair == true and .canonical_cli.audit == true and .canonical_cli.apply_requires_idempotency_key == true' "canonical_cli_surface"

schema_out="$(run_case schema schema)"
assert_jq "$schema_out" '.malformed_policy_behavior == "fail_closed_allowed_false" and .dry_run_default == true and (.apply_requires | index("--idempotency-key"))' "schema_documents_fail_closed_and_mutation_discipline"

doctor_out="$(run_case doctor doctor --policy "$POLICY")"
[[ "$(cat "$TMP/doctor.rc")" == "0" ]] && pass "doctor_exit_zero" || fail "doctor_exit_zero"
assert_jq "$doctor_out" '.status == "pass" and .checks.policy.default_decision_deny == true and .checks.policy.policy_as_gate_disabled == true' "doctor_policy_contract_healthy"

audit_out="$(run_case audit audit --policy "$POLICY")"
[[ "$(cat "$TMP/audit.rc")" == "0" ]] && pass "audit_exit_zero" || fail "audit_exit_zero"
assert_jq "$audit_out" '.status == "pass" and .malformed_policy_escalates_privilege == false and .no_auto_push == true and .no_force_release == true and .no_auto_commit == true' "audit_blocks_privilege_escalation"
assert_jq "$audit_out" '([.forbidden_probe_results[] | select(.allowed == false and .reason_code == "forbidden_operation")] | length) == 3' "audit_forbidden_probe_results"

validate_out="$(run_case validate validate --policy "$POLICY" --operation policy.validate --session flywheel)"
[[ "$(cat "$TMP/validate.rc")" == "0" ]] && pass "validate_exit_zero" || fail "validate_exit_zero"
assert_jq "$validate_out" '.status == "pass" and .allowed == true and .reason_code == "authorized_operation" and .policy.policy_as_gate_enabled == false' "validate_authorized_operation"

for op in auto_push force_release auto_commit; do
  out="$(run_case "forbidden-$op" validate --policy "$POLICY" --operation "$op" --session flywheel)"
  [[ "$(cat "$TMP/forbidden-$op.rc")" == "1" ]] && pass "forbidden_${op}_exit_1" || fail "forbidden_${op}_exit_1"
  assert_jq "$out" '.status == "fail" and .allowed == false and .would_block == true and .reason_code == "forbidden_operation"' "forbidden_${op}_blocked"
done

unknown_out="$(run_case unknown-operation validate --policy "$POLICY" --operation dispatch.spawn --session flywheel)"
[[ "$(cat "$TMP/unknown-operation.rc")" == "1" ]] && pass "unknown_operation_exit_1" || fail "unknown_operation_exit_1"
assert_jq "$unknown_out" '.allowed == false and .reason_code == "operation_not_authorized"' "unknown_operation_denied"

session_out="$(run_case wrong-session validate --policy "$POLICY" --operation policy.validate --session skillos)"
[[ "$(cat "$TMP/wrong-session.rc")" == "1" ]] && pass "wrong_session_exit_1" || fail "wrong_session_exit_1"
assert_jq "$session_out" '.allowed == false and .reason_code == "session_not_authorized"' "wrong_session_denied"

apply_no_key_out="$(run_case apply-no-key validate --policy "$POLICY" --operation policy.validate --apply)"
[[ "$(cat "$TMP/apply-no-key.rc")" == "2" ]] && pass "apply_requires_idempotency_key_exit_2" || fail "apply_requires_idempotency_key_exit_2"
assert_jq "$apply_no_key_out" '.status == "fail" and .reason_code == "missing_idempotency_key" and .source_policy_mutated == false' "apply_requires_idempotency_key_json"

repair_out="$(run_case repair repair --dry-run)"
[[ "$(cat "$TMP/repair.rc")" == "0" ]] && pass "repair_exit_zero" || fail "repair_exit_zero"
assert_jq "$repair_out" '.status == "pass" and .repair_action == "validate_warn_only_and_keep_policy_as_gate_disabled" and .source_policy_mutated == false' "repair_warn_only_no_source_mutation"

malformed="$TMP/malformed-policy.yaml"
copy_policy "$malformed"
printf 'unexpected_privilege: true\n' >>"$malformed"
malformed_out="$(run_case malformed validate --policy "$malformed" --operation policy.validate --session flywheel)"
[[ "$(cat "$TMP/malformed.rc")" == "3" ]] && pass "malformed_exit_3" || fail "malformed_exit_3"
assert_jq "$malformed_out" '.status == "fail" and .reason_code == "malformed_policy" and .allowed == false and .malformed_policy_escalates_privilege == false' "malformed_policy_fails_closed"

bad_required="$TMP/bad-required.yaml"
copy_policy "$bad_required"
perl -0pi -e 's/  - auto_push\n//g' "$bad_required"
bad_required_out="$(run_case bad-required audit --policy "$bad_required")"
[[ "$(cat "$TMP/bad-required.rc")" == "3" ]] && pass "missing_required_forbidden_exit_3" || fail "missing_required_forbidden_exit_3"
assert_jq "$bad_required_out" '.status == "fail" and .allowed == false and ([.findings[].reason_code] | index("required_forbidden_operations_missing"))' "missing_required_forbidden_fails_closed"

why_out="$(run_case why why malformed-policy)"
assert_jq "$why_out" '.status == "ok" and (.selected | test("fail-closed"))' "why_explains_malformed_policy"

completion_out="$TMP/completion.bash"
"$SCRIPT" completion bash >"$completion_out"
rg -q 'complete -W' "$completion_out" && pass "completion_bash" || fail "completion_bash"

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
