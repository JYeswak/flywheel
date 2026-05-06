#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/mission-lock-negative-invariants-validator.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/mission-lock-negative-invariants-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

write_fixture() {
  local path="$1" omit="${2:-NONE}"
  {
    printf '# Fixture Mission\n\n'
    printf '## Negative invariants (security)\n\n'
    if [[ "$omit" != "SEC-001" ]]; then
      printf -- '- SEC-001: secret_values_allowed=false; no token fragments, raw env output, or Agent Mail bearer material in dispatch packets.\n'
    fi
    if [[ "$omit" != "SEC-002" ]]; then
      printf -- '- SEC-002: skill_receipts[] require credential_touch, safe_wrapper, secret_value_allowed=false, rotation_approval_source, and joshua_explicit_rotation_approval for rotation.\n'
    fi
    if [[ "$omit" != "SEC-003" ]]; then
      printf -- '- SEC-003: skillos and peer orchestrators receive schema, aliases, templates, route health, and redacted evidence only; never customer-private evidence, raw pane captures, or env dumps.\n'
    fi
    if [[ "$omit" != "SEC-004" ]]; then
      printf -- '- SEC-004: close-validator may fail closure and demand receipts, but may not rotate tokens, edit .env, overwrite MCP secret config, or write vault values.\n'
    fi
    if [[ "$omit" != "SEC-005" ]]; then
      printf -- '- SEC-005: each touched surface declares secret source of truth, principal type, allowed operations, forbidden principals, and service-role/admin credential policy.\n'
    fi
    if [[ "$omit" != "SEC-006" ]]; then
      printf -- '- SEC-006: missing invariants on touched auth/credential/PII/customer-trust surfaces mean blocked readiness unless a no-touch proof exists.\n'
    fi
  } >"$path"
}

run_pass() {
  local name="$1" fixture="$2" out
  out="$TMP/${name// /_}.json"
  if "$SCRIPT" "$fixture" --json >"$out" && jq -e '.status == "pass" and ([.checks[].status] | all(. == "pass"))' "$out" >/dev/null; then
    pass "$name"
  else
    fail "$name"
    cat "$out" >&2 || true
  fi
}

run_fail_for() {
  local name="$1" fixture="$2" id="$3" out rc
  out="$TMP/${name// /_}.json"
  set +e
  "$SCRIPT" "$fixture" --json >"$out"
  rc=$?
  set -e
  if [[ "$rc" -eq 1 ]] && jq -e --arg id "$id" '.status == "fail" and (.checks[] | select(.id == $id and .status == "fail"))' "$out" >/dev/null; then
    pass "$name"
  else
    fail "$name"
    printf 'rc=%s\n' "$rc" >&2
    cat "$out" >&2 || true
  fi
}

bash -n "$SCRIPT"
"$SCRIPT" --help | rg -q '^usage:'
"$SCRIPT" --info --json | jq -e '.name == "mission-lock-negative-invariants-validator.sh" and .mutates == false' >/dev/null
"$SCRIPT" --examples --json | jq -e '.examples | length >= 3' >/dev/null
pass "canonical CLI metadata"

complete="$TMP/complete.md"
write_fixture "$complete"
run_pass "SEC-001 declared blocked passes" "$complete"

for id in SEC-001 SEC-002 SEC-003 SEC-004 SEC-005 SEC-006; do
  fixture="$TMP/${id}.missing.md"
  write_fixture "$fixture" "$id"
  run_fail_for "$id missing invariant fails" "$fixture" "$id"
done

"$SCRIPT" "$complete" --quiet
[[ -z "$("$SCRIPT" "$complete" --quiet)" ]]
pass "quiet pass emits no text"

run_pass "repo MISSION declares all security invariants" "$ROOT/.flywheel/MISSION.md"

printf 'RESULT test_cases=%s failures=%s\n' "$pass_count" "$fail_count"
[[ "$pass_count" -ge 10 && "$fail_count" == "0" ]]
