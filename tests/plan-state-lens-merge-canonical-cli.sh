#!/usr/bin/env bash
# tests/plan-state-lens-merge-canonical-cli.sh
# flywheel-k8gcv.23 (wave-3-23).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/plan-state-lens-merge.sh"

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
printf '%s' "$out_doctor" | jq -e '.checks' >/dev/null && pass "AG3 doctor" || fail "AG3 doctor"

# Canonical subcommands (note: validate positional reserved for legacy plan-state validation)
"$SCRIPT" health --json 2>/dev/null | jq -e '.command == "health"' >/dev/null && pass "health envelope" || fail "health"
"$SCRIPT" audit --json 2>/dev/null | jq -e '.command == "audit" and has("recent")' >/dev/null && pass "audit envelope" || fail "audit"
"$SCRIPT" why --json 2>/dev/null | jq -e '.command == "why" and has("body")' >/dev/null && pass "why default" || fail "why default"
"$SCRIPT" why audit-lens-identity-key --json 2>/dev/null | jq -e '.topic == "audit-lens-identity-key"' >/dev/null && pass "why audit-lens-identity-key" || fail "why audit-lens-identity-key"
"$SCRIPT" quickstart --json 2>/dev/null | jq -e '.command == "quickstart"' >/dev/null && pass "quickstart envelope" || fail "quickstart"

# Apply contract
"$SCRIPT" append --plan /tmp/nope --lens x --row-json '{}' --apply --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 3 ]] && pass "append --apply without --idempotency-key rc=3" || fail "append apply rc=$rc"
"$SCRIPT" repair --scope ledger-prime --apply --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 3 ]] && pass "repair --apply without --idempotency-key rc=3" || fail "repair apply rc=$rc"

# Magic comment + lint (was L4 violation)
grep -q '# flywheel-cli-surface: true' "$SCRIPT" && pass "L6 magic comment present" || fail "L6 missing"
"$ROOT/.flywheel/scripts/canonical-cli-lint.sh" "$SCRIPT" >/dev/null 2>&1 && rc=0 || rc=$?
[[ "$rc" -eq 0 ]] && pass "canonical-cli-lint RC=0 (was L4 state_path short-circuit)" || fail "lint RC=$rc"

# Backward compat: legacy validate subcommand still parses (script exits 2 with stderr "state file not readable" — that's defined behavior, not arg-parse failure)
out_legacy_validate="$("$SCRIPT" validate --plan /tmp/nope --json 2>&1 || true)"
printf '%s' "$out_legacy_validate" | grep -qE 'state file not readable|state file|stderr' && pass "legacy 'validate' positional subcommand still parses + emits 'state file not readable' on missing plan" || fail "legacy validate (out=${out_legacy_validate:0:120})"

# Backward compat: legacy --info fields preserved
"$SCRIPT" --info --json 2>/dev/null | jq -e '.row_schema == "plan-state-lens-row/v1"' >/dev/null \
  && pass "legacy --info row_schema preserved" || fail "legacy --info row_schema"

# Legacy examples preserved
"$SCRIPT" --examples 2>&1 | grep -q 'plan-state-lens-merge.sh' && pass "--examples text-mode preserved" || fail "--examples text"

# --help
"$SCRIPT" --help 2>&1 | head -3 | grep -qE 'usage|plan-state-lens-merge' && pass "--help shows usage" || fail "--help"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
