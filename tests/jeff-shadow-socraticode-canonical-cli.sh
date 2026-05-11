#!/usr/bin/env bash
# tests/jeff-shadow-socraticode-canonical-cli.sh
# flywheel-k8gcv.19 (wave-3-19).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/jeff-shadow-socraticode.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# AG3
"$SCRIPT" --info --json 2>/dev/null | jq -e '.name and .version and .capabilities and (.subcommands | length >= 5)' >/dev/null && pass "AG3 --info" || fail "AG3 --info"
"$SCRIPT" --schema --json 2>/dev/null | jq -e '.input_schema and .output_schema' >/dev/null && pass "AG3 --schema" || fail "AG3 --schema"
"$SCRIPT" --examples --json 2>/dev/null | jq -e '.examples | length > 0' >/dev/null && pass "AG3 --examples" || fail "AG3 --examples"
out_doctor="$("$SCRIPT" doctor --json 2>/dev/null || true)"
printf '%s' "$out_doctor" | jq -e '.checks' >/dev/null && pass "AG3 doctor (.checks)" || fail "AG3 doctor"

# Canonical subcommands
"$SCRIPT" health --json 2>/dev/null | jq -e '.schema_version' >/dev/null && pass "health envelope" || fail "health"
"$SCRIPT" status --json 2>/dev/null | jq -e '.dashboard_line' >/dev/null && pass "status envelope" || fail "status"
"$SCRIPT" validate --json 2>/dev/null | jq -e '.schema_version' >/dev/null && pass "validate envelope" || fail "validate"
"$SCRIPT" audit --json 2>/dev/null | jq -e '.schema_version' >/dev/null && pass "audit envelope" || fail "audit"

# Apply contract
"$SCRIPT" refresh --apply --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 3 ]] && pass "refresh --apply without --idempotency-key rc=3" || fail "refresh apply rc=$rc"
"$SCRIPT" repair --apply --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 3 ]] && pass "repair --apply without --idempotency-key rc=3" || fail "repair apply rc=$rc"

# Magic comment + lint (was 2 violations: L6+L7)
grep -q '# flywheel-cli-surface: true' "$SCRIPT" && pass "L6 magic comment present" || fail "L6 missing"
"$ROOT/.flywheel/scripts/canonical-cli-lint.sh" "$SCRIPT" >/dev/null 2>&1 && rc=0 || rc=$?
[[ "$rc" -eq 0 ]] && pass "canonical-cli-lint RC=0 (was L6+L7)" || fail "lint RC=$rc"

# Backward compat
out_status="$("$SCRIPT" status --json 2>/dev/null || true)"
printf '%s' "$out_status" | jq -e '.repo_count and .indexed_count and has("last_refresh_age_hours") and .dashboard_line' >/dev/null \
  && pass "legacy status envelope preserved (repo_count+indexed_count+age+dashboard_line)" || fail "legacy status"

printf '%s' "$out_doctor" | jq -e '.repos and .canonical_repos' >/dev/null \
  && pass "doctor preserves repos + canonical_repos arrays" || fail "doctor legacy fields"

# --doctor flag still works
"$SCRIPT" --doctor --json 2>/dev/null | jq -e '.dashboard_line' >/dev/null && pass "legacy --doctor flag preserved" || fail "legacy --doctor"

# refresh --dry-run still works (no idem-key required)
"$SCRIPT" refresh --dry-run --json 2>/dev/null | jq -e '.schema_version or has("rows")' >/dev/null \
  && pass "refresh --dry-run does NOT require --idempotency-key" || fail "refresh dry-run"

"$SCRIPT" --help 2>&1 | head -3 | grep -qE 'Usage|jeff-shadow' && pass "--help shows usage" || fail "--help"
"$SCRIPT" completion 2>&1 | grep -q 'complete -W' && pass "completion preserved" || fail "completion"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
