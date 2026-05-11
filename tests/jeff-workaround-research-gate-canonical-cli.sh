#!/usr/bin/env bash
# tests/jeff-workaround-research-gate-canonical-cli.sh
# flywheel-k8gcv.20 (wave-3-20).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/jeff-workaround-research-gate.sh"

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
"$SCRIPT" health --json 2>/dev/null | jq -e '.command == "health"' >/dev/null && pass "health envelope" || fail "health"
"$SCRIPT" validate --json 2>/dev/null | jq -e '.command == "validate"' >/dev/null && pass "validate envelope" || fail "validate"
"$SCRIPT" audit --json 2>/dev/null | jq -e '.command == "audit" and has("recent")' >/dev/null && pass "audit envelope" || fail "audit"
"$SCRIPT" why --json 2>/dev/null | jq -e '.command == "why" and has("body")' >/dev/null && pass "why default" || fail "why default"
"$SCRIPT" why pattern-scan-keywords --json 2>/dev/null | jq -e '.topic == "pattern-scan-keywords"' >/dev/null && pass "why pattern-scan-keywords" || fail "why pattern-scan"
"$SCRIPT" quickstart --json 2>/dev/null | jq -e '.command == "quickstart"' >/dev/null && pass "quickstart envelope" || fail "quickstart"

# Repair apply contract
"$SCRIPT" repair --scope ledger-prime --apply --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 3 ]] && pass "repair --apply without --idempotency-key rc=3" || fail "repair apply rc=$rc"

# Magic comment + lint (was already clean)
grep -q '# flywheel-cli-surface: true' "$SCRIPT" && pass "L6 magic comment present" || fail "L6 missing"
"$ROOT/.flywheel/scripts/canonical-cli-lint.sh" "$SCRIPT" >/dev/null 2>&1 && rc=0 || rc=$?
[[ "$rc" -eq 0 ]] && pass "canonical-cli-lint RC=0" || fail "lint RC=$rc"

# Backward compat: legacy --schema preserves required_receipt_fields + doctor_fields
"$SCRIPT" --schema --json 2>/dev/null | jq -e '.required_receipt_fields and .doctor_fields' >/dev/null \
  && pass "legacy --schema fields preserved (required_receipt_fields + doctor_fields)" || fail "legacy --schema"

# Backward compat: default scan emits envelope
out="$("$SCRIPT" --json 2>/dev/null || true)"
printf '%s' "$out" | jq -e '.schema_version == "jeff-workaround-research-gate/v1" and has("jeff_issue_pending_without_workaround_research_count") and has("required_predicate")' >/dev/null \
  && pass "legacy default scan emits gate envelope (predicate + pending count)" || fail "legacy default scan"

# --help shows usage
"$SCRIPT" --help 2>&1 | head -3 | grep -qE 'usage|jeff-workaround' && pass "--help shows usage" || fail "--help"

# --examples text-mode
"$SCRIPT" --examples 2>&1 | grep -q 'jeff-workaround-research-gate' && pass "--examples text-mode preserved" || fail "--examples text"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
