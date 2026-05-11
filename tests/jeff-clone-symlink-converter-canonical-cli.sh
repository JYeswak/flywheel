#!/usr/bin/env bash
# tests/jeff-clone-symlink-converter-canonical-cli.sh
# flywheel-k8gcv.11 (wave-3-11).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/jeff-clone-symlink-converter.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# AG3
"$SCRIPT" --info --json 2>/dev/null | jq -e '.name and .version and .capabilities and (.subcommands | length >= 5)' >/dev/null && pass "AG3 --info" || fail "AG3 --info"
"$SCRIPT" --schema --json 2>/dev/null | jq -e '.input_schema and .output_schema' >/dev/null && pass "AG3 --schema" || fail "AG3 --schema"
"$SCRIPT" --examples --json 2>/dev/null | jq -e '.examples | length > 0' >/dev/null && pass "AG3 --examples" || fail "AG3 --examples"
"$SCRIPT" doctor --json 2>/dev/null | jq -e '.checks' >/dev/null && pass "AG3 doctor" || fail "AG3 doctor"

# Canonical subcommands
"$SCRIPT" health --json 2>/dev/null | jq -e '.command == "health" and has("backup_tarball_count")' >/dev/null && pass "health envelope" || fail "health"
"$SCRIPT" validate --json 2>/dev/null | jq -e '.command == "validate"' >/dev/null && pass "validate envelope" || fail "validate"
"$SCRIPT" audit --json 2>/dev/null | jq -e '.command == "audit" and has("recent")' >/dev/null && pass "audit envelope" || fail "audit"
"$SCRIPT" why --json 2>/dev/null | jq -e '.command == "why" and has("body")' >/dev/null && pass "why default" || fail "why default"
"$SCRIPT" why safety-checks --json 2>/dev/null | jq -e '.topic == "safety-checks"' >/dev/null && pass "why safety-checks" || fail "why safety-checks"
"$SCRIPT" quickstart 2>/dev/null | jq -e '.command == "quickstart"' >/dev/null && pass "quickstart envelope" || fail "quickstart"

# Apply contract: both --mode apply and --apply must require --idempotency-key
out="$("$SCRIPT" --pair ntm --mode apply --json 2>&1 || true)"
printf '%s' "$out" | jq -e '.status == "refused"' >/dev/null && pass "--mode apply without --idempotency-key refuses" || fail "--mode apply refuse"
"$SCRIPT" --pair ntm --mode apply --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 3 ]] && pass "--mode apply without --idempotency-key rc=3" || fail "--mode apply rc=$rc"
"$SCRIPT" --pair ntm --apply --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 3 ]] && pass "--apply (alias) without --idempotency-key rc=3" || fail "--apply rc=$rc"
"$SCRIPT" repair --scope ledger-prime --apply --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 3 ]] && pass "repair --apply without --idempotency-key rc=3" || fail "repair apply rc=$rc"

# Magic comment + lint (was 1 violation: L5)
grep -q '# flywheel-cli-surface: true' "$SCRIPT" && pass "L6 magic comment present" || fail "L6 missing"
"$ROOT/.flywheel/scripts/canonical-cli-lint.sh" "$SCRIPT" >/dev/null 2>&1 && rc=0 || rc=$?
[[ "$rc" -eq 0 ]] && pass "canonical-cli-lint RC=0 (was L5 violation)" || fail "lint RC=$rc"

# Backward compat
out="$("$SCRIPT" --pair ntm --mode dry-run --json 2>&1 || true)"
printf '%s' "$out" | jq -e '.schema_version == "jeff-clone-symlink-receipt/v1"' >/dev/null \
  && pass "legacy --mode dry-run --json emits receipt envelope" || fail "legacy dry-run shape"

# Invalid args still return invalid_args envelope with rc=3
out="$("$SCRIPT" --pair "" --json 2>&1 || true)"
printf '%s' "$out" | jq -e '.status == "invalid_args"' >/dev/null \
  && pass "legacy invalid_args path preserved (empty pair)" || fail "legacy invalid_args"
"$SCRIPT" --pair "../bad/path" --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 3 ]] && pass "legacy invalid pair rc=3 preserved" || fail "legacy invalid pair rc=$rc"

# --help
"$SCRIPT" --help 2>&1 | head -3 | grep -qE 'usage|jeff-clone' && pass "--help shows usage" || fail "--help"

# --examples text-mode
"$SCRIPT" --examples 2>&1 | grep -q 'jeff-clone' && pass "--examples text-mode preserved" || fail "--examples text"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
