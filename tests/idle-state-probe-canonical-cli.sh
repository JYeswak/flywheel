#!/usr/bin/env bash
# tests/idle-state-probe-canonical-cli.sh
# flywheel-k8gcv.7 (wave-3-07).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/idle-state-probe.sh"

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
"$SCRIPT" why per-session-config --json 2>/dev/null | jq -e '.topic == "per-session-config"' >/dev/null && pass "why per-session-config" || fail "why per-session-config"
"$SCRIPT" quickstart 2>/dev/null | jq -e '.command == "quickstart" and (.steps | length >= 3)' >/dev/null && pass "quickstart envelope" || fail "quickstart"

# Repair + apply contract
"$SCRIPT" repair --scope ledger-prime --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .scope == "ledger-prime"' >/dev/null && pass "repair --dry-run" || fail "repair --dry-run"
"$SCRIPT" repair --scope ledger-prime --apply --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 3 ]] && pass "repair --apply without --idempotency-key returns rc=3" || fail "repair apply rc=$rc"

# Magic comment + lint
grep -q '# flywheel-cli-surface: true' "$SCRIPT" && pass "L6 magic comment present" || fail "L6 missing"
"$ROOT/.flywheel/scripts/canonical-cli-lint.sh" "$SCRIPT" >/dev/null 2>&1 && rc=0 || rc=$?
[[ "$rc" -eq 0 ]] && pass "canonical-cli-lint RC=0" || fail "lint RC=$rc"

# Backward compat
"$SCRIPT" --help 2>&1 | head -3 | grep -qE 'usage|idle-state' && pass "--help shows usage" || fail "--help"
"$SCRIPT" --version 2>&1 | grep -qE 'idle-state-probe' && pass "--version emits version" || fail "--version"
"$SCRIPT" --bogus >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 64 ]] && pass "unknown arg rc=64 (preserved)" || fail "unknown arg rc=$rc"

# Legacy --doctor flag still works (separate from positional doctor subcommand)
"$SCRIPT" --doctor --json --session flywheel 2>/dev/null | jq -e '.schema_version == "idle-state-probe/v1" and has("status") and has("idle_state_summary")' >/dev/null && pass "legacy --doctor flag preserved (full envelope)" || fail "legacy --doctor flag"

# Legacy default probe
"$SCRIPT" --json 2>/dev/null | jq -e '.session and .repo and has("br_ready_count")' >/dev/null && pass "legacy default probe preserved" || fail "legacy default probe"

# --examples without --json emits text
"$SCRIPT" --examples 2>&1 | grep -q 'idle-state-probe.sh --json' && pass "--examples text-mode preserved" || fail "--examples text"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
