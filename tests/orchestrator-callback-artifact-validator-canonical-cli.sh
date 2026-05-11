#!/usr/bin/env bash
# tests/orchestrator-callback-artifact-validator-canonical-cli.sh
# flywheel-k8gcv.25 (wave-3-25).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/orchestrator-callback-artifact-validator.sh"

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

# Canonical subcommands
"$SCRIPT" health --json 2>/dev/null | jq -e '.command == "health"' >/dev/null && pass "health envelope" || fail "health"
"$SCRIPT" validate --json 2>/dev/null | jq -e '.command == "validate"' >/dev/null && pass "validate envelope" || fail "validate"
"$SCRIPT" audit --json 2>/dev/null | jq -e '.command == "audit" and has("recent")' >/dev/null && pass "audit envelope" || fail "audit"
"$SCRIPT" why --json 2>/dev/null | jq -e '.command == "why" and has("body")' >/dev/null && pass "why default" || fail "why default"
"$SCRIPT" why fix-bead-opener-integration --json 2>/dev/null | jq -e '.topic == "fix-bead-opener-integration"' >/dev/null && pass "why fix-bead-opener-integration" || fail "why fix-bead-opener"
"$SCRIPT" quickstart --json 2>/dev/null | jq -e '.command == "quickstart"' >/dev/null && pass "quickstart envelope" || fail "quickstart"

# Repair apply contract
"$SCRIPT" repair --scope ledger-prime --apply --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 3 ]] && pass "repair --apply without --idempotency-key rc=3" || fail "repair apply rc=$rc"

# Magic comment + lint (was already clean)
grep -q '# flywheel-cli-surface: true' "$SCRIPT" && pass "L6 magic comment present" || fail "L6 missing"
"$ROOT/.flywheel/scripts/canonical-cli-lint.sh" "$SCRIPT" >/dev/null 2>&1 && rc=0 || rc=$?
[[ "$rc" -eq 0 ]] && pass "canonical-cli-lint RC=0" || fail "lint RC=$rc"

# Backward compat: legacy check command still emits .decision
out_legacy="$("$SCRIPT" check --callback-text 'DONE task-x evidence=nonexistent.sh' --dispatch-file /tmp/nope.md --json 2>&1 || true)"
printf '%s' "$out_legacy" | head -1 | jq -e '.decision' >/dev/null \
  && pass "legacy check command emits .decision envelope" || fail "legacy check"

# Legacy --info preserves min_bytes table
"$SCRIPT" --info --json 2>/dev/null | jq -e '.min_bytes.script and .min_bytes.markdown' >/dev/null \
  && pass "legacy --info min_bytes table preserved" || fail "legacy --info min_bytes"

# --help
"$SCRIPT" --help 2>&1 | head -3 | grep -qE 'usage|orchestrator-callback' && pass "--help shows usage" || fail "--help"

# --examples text-mode falls through to python (still works)
"$SCRIPT" --examples 2>&1 | grep -q 'orchestrator-callback-artifact-validator' && pass "--examples text-mode preserved (python fallthrough)" || fail "--examples text"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
