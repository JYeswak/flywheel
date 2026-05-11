#!/usr/bin/env bash
# tests/jeff-binary-version-watchtower-canonical-cli.sh
# flywheel-k8gcv.10 (wave-3-10).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/jeff-binary-version-watchtower.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# AG3
"$SCRIPT" --info --json 2>/dev/null | jq -e '.name and .version and .capabilities and (.subcommands | length >= 5)' >/dev/null && pass "AG3 --info" || fail "AG3 --info"
"$SCRIPT" --schema --json 2>/dev/null | jq -e '.input_schema and .output_schema' >/dev/null && pass "AG3 --schema" || fail "AG3 --schema"
"$SCRIPT" --examples --json 2>/dev/null | jq -e '.examples | length > 0' >/dev/null && pass "AG3 --examples" || fail "AG3 --examples"
"$SCRIPT" doctor --json 2>/dev/null | jq -e '.checks' >/dev/null && pass "AG3 doctor (canonical .checks)" || fail "AG3 doctor"

# Canonical subcommands
"$SCRIPT" health --json 2>/dev/null | jq -e '.command == "health" and has("ledger_row_count")' >/dev/null && pass "health envelope" || fail "health"
"$SCRIPT" validate --json 2>/dev/null | jq -e '.command == "validate"' >/dev/null && pass "validate envelope" || fail "validate"
"$SCRIPT" audit --json 2>/dev/null | jq -e '.command == "audit" and has("recent")' >/dev/null && pass "audit envelope" || fail "audit"
"$SCRIPT" why --json 2>/dev/null | jq -e '.command == "why" and has("body")' >/dev/null && pass "why default" || fail "why default"
"$SCRIPT" why canary-pattern --json 2>/dev/null | jq -e '.topic == "canary-pattern"' >/dev/null && pass "why canary-pattern" || fail "why canary-pattern"
"$SCRIPT" quickstart 2>/dev/null | jq -e '.command == "quickstart"' >/dev/null && pass "quickstart envelope" || fail "quickstart"

# Apply contract (L7 fix)
"$SCRIPT" --apply --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 3 ]] && pass "main --apply without --idempotency-key rc=3" || fail "main apply rc=$rc"
"$SCRIPT" repair --scope ledger-prime --apply --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 3 ]] && pass "repair --apply without --idempotency-key rc=3" || fail "repair apply rc=$rc"

# Magic comment + lint
grep -q '# flywheel-cli-surface: true' "$SCRIPT" && pass "L6 magic comment present" || fail "L6 missing"
"$ROOT/.flywheel/scripts/canonical-cli-lint.sh" "$SCRIPT" >/dev/null 2>&1 && rc=0 || rc=$?
[[ "$rc" -eq 0 ]] && pass "canonical-cli-lint RC=0 (was RC=1 with L6+L7 violations)" || fail "lint RC=$rc"

# Backward compat
out="$("$SCRIPT" --dry-run --json 2>/dev/null || true)"
printf '%s' "$out" | jq -e '.schema_version and .checked_at and .rows and .watchlists' >/dev/null \
  && pass "legacy --dry-run --json emits full watchtower envelope" || fail "legacy dry-run"

# Health subcommand WITHOUT --json should fall through to main path (legacy behavior)
out="$("$SCRIPT" health 2>/dev/null || true)"
printf '%s' "$out" | jq -e '.schema_version and has("status")' >/dev/null \
  && pass "legacy 'health' (no --json) falls through to main path" || fail "legacy health fall-through"

"$SCRIPT" completion 2>&1 | grep -q 'complete -W' && pass "legacy completion preserved" || fail "completion"
"$SCRIPT" --help 2>&1 | head -3 | grep -qE 'Usage|jeff-binary' && pass "--help shows usage" || fail "--help"

# --examples without --json emits text
"$SCRIPT" --examples 2>&1 | grep -q 'jeff-binary-version-watchtower' && pass "--examples text-mode preserved" || fail "--examples text"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
