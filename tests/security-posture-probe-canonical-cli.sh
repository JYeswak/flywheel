#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="${SECURITY_POSTURE_PROBE:-$ROOT/.flywheel/scripts/security-posture-probe.sh}"
FIXTURES="$ROOT/tests/fixtures/canary-secret-scan"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/security-posture-probe.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

assert_jq() {
  local file="$1"
  local filter="$2"
  local label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

if [[ -x "$SCRIPT" ]]; then
  pass "security-posture-probe.sh executable"
else
  fail "security-posture-probe.sh missing or not executable at $SCRIPT"
fi

if bash -n "$SCRIPT"; then
  pass "security-posture-probe.sh syntax clean"
else
  fail "security-posture-probe.sh syntax clean"
fi

"$SCRIPT" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" \
  '.schema_version == "security-posture-probe.info/v1" and .synthetic_only == true and .secret_values_emitted == false and .patterns_count >= 10' \
  "info proves synthetic-only redaction posture"

"$SCRIPT" --schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" \
  '.schema.properties.secret_values_emitted.const == false and .schema.properties.synthetic_only.const == true' \
  "schema locks no-secret-value contract"

"$SCRIPT" --json "$FIXTURES/clean" >"$TMP/clean.json"
assert_jq "$TMP/clean.json" \
  '.status == "pass" and .findings_count == 0 and .secret_values_emitted == false and .synthetic_only == true' \
  "clean fixture has no findings"

set +e
"$SCRIPT" --details --json "$FIXTURES/leaky" >"$TMP/leaky.json"
leaky_rc=$?
set -e
if [[ "$leaky_rc" -eq 1 ]]; then
  pass "leaky fixture exits with findings rc=1"
else
  fail "leaky fixture expected rc=1 got rc=$leaky_rc"
fi

assert_jq "$TMP/leaky.json" \
  '.status == "fail" and .findings_count >= 6 and (.classes | index("agent_mail_registration_token")) and (.classes | index("github_pat")) and .secret_values_emitted == false' \
  "leaky fixture reports classes and counts without values"

if jq -r '.. | strings' "$TMP/leaky.json" | grep -q 'CANARY_TEST_'; then
  fail "leaky output emitted raw canary secret material"
else
  pass "leaky output redacts raw canary secret material"
fi

"$SCRIPT" --validate --json "$FIXTURES/clean" >"$TMP/validate.json"
assert_jq "$TMP/validate.json" \
  '.schema_version == "security-posture-probe/v1" and .mode == "validate" and .status == "pass" and .secret_values_emitted == false' \
  "validate mode reuses safe scan contract"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
