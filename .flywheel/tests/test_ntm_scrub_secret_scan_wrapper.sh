#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
BIN="$ROOT/.flywheel/scripts/ntm-scrub-secret-scan-wrapper.sh"
CHECKER="${CANONICAL_CLI_CHECKER:-/Users/josh/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh}"
FIXTURES="$ROOT/.flywheel/tests/fixtures/ntm-scrub-secret-scan"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/ntm-scrub-secret-scan.XXXXXX")"
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

bash -n "$BIN" && pass "syntax" || fail "syntax"

"$BIN" --help >"$TMP/help.txt"
rg -q 'doctor.*health.*repair|scan' "$TMP/help.txt" && pass "help_surface" || fail "help_surface"

"$BIN" doctor --json >"$TMP/doctor.json"
assert_jq "$TMP/doctor.json" '.command=="doctor" and .status=="pass" and .dependencies.python3==true' "doctor_json"

"$BIN" health --json >"$TMP/health.json"
assert_jq "$TMP/health.json" '.command=="health" and .status=="pass"' "health_json"

"$BIN" validate --scope fixtures --json >"$TMP/validate.json"
assert_jq "$TMP/validate.json" '.command=="validate" and .status=="pass"' "validate_json"

"$BIN" audit --json >"$TMP/audit.json"
assert_jq "$TMP/audit.json" '.command=="audit" and .rows==[]' "audit_json"

"$BIN" why --json >"$TMP/why.json"
assert_jq "$TMP/why.json" '.command=="why" and (.explanation|contains("before dispatch"))' "why_json"

"$BIN" schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.stable_exit_codes.findings==1 and (.output.required|index("native_wrapper_delta"))' "schema_json"

"$BIN" repair --dry-run --json >"$TMP/repair-dry.json"
assert_jq "$TMP/repair-dry.json" '.command=="repair" and .status=="pass" and (.actual_actions|length)==0' "repair_dry_run"

if "$BIN" repair --apply --json >"$TMP/repair-apply-no-key.json"; then
  fail "repair_apply_requires_key"
else
  assert_jq "$TMP/repair-apply-no-key.json" '.status=="fail" and (.reason|contains("idempotency-key"))' "repair_apply_requires_key"
fi

"$BIN" --file "$FIXTURES/safe-dispatch.txt" --json >"$TMP/safe.json"
assert_jq "$TMP/safe.json" '.status=="pass" and .findings_count==0 and .secret_scan_before_callback=="yes"' "safe_dispatch_passes"

if "$BIN" --file "$FIXTURES/secret-bank.txt" --json >"$TMP/secret-bank.json"; then
  fail "secret_bank_fails_closed"
else
  assert_jq "$TMP/secret-bank.json" '
    .status=="fail"
    and .findings_count >= 10
    and ([.findings[].classes[]] | index("private_key"))
    and ([.findings[].classes[]] | index("bearer_token"))
    and ([.findings[].classes[]] | index("github_token"))
    and ([.findings[].classes[]] | index("google_api_key"))
    and ([.findings[].classes[]] | index("jwt"))
    and ([.findings[].classes[]] | index("infisical_secret_value"))
    and ([.findings[].classes[]] | index("agent_mail_registration_token"))
  ' "secret_bank_fails_closed"
fi

if jq -r '.findings[].redacted_context' "$TMP/secret-bank.json" | rg -q 'sk-ant|ghp_|AKIA|AIza|xoxb-|eyJ|Bearer fixture|secretValue.*fixture|fixture-registration-token'; then
  fail "redacted_output_does_not_leak_raw_synthetic_values"
else
  pass "redacted_output_does_not_leak_raw_synthetic_values"
fi

assert_jq "$TMP/secret-bank.json" '
  .authorized_operations == ["read_input","classify_secret_family","emit_redacted_evidence"]
  and (.forbidden_operations|index("emit_secret_value"))
  and .ttl_native
  and .ttl_wrapper
  and .ttl_decision
  and .native_wrapper_delta
' "acceptance_template_fields"

bash "$CHECKER" "$BIN" >/dev/null && pass "canonical_cli_scoping" || fail "canonical_cli_scoping"

printf '\nResults: %d PASS %d FAIL\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
