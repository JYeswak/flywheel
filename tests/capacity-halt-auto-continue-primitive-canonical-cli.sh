#!/usr/bin/env bash
# tests/capacity-halt-auto-continue-primitive-canonical-cli.sh
# flywheel-k8gcv.3 (wave-3-03).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/capacity-halt-auto-continue-primitive.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# AG3 — wave-3 acceptance gate
"$SCRIPT" --info --json 2>/dev/null | jq -e '.name and .version and .capabilities and (.subcommands | length >= 5)' >/dev/null && pass "AG3 --info" || fail "AG3 --info"
"$SCRIPT" --schema --json 2>/dev/null | jq -e '.input_schema and .output_schema' >/dev/null && pass "AG3 --schema" || fail "AG3 --schema"
"$SCRIPT" --examples --json 2>/dev/null | jq -e '.examples | length > 0' >/dev/null && pass "AG3 --examples" || fail "AG3 --examples"
"$SCRIPT" doctor --json 2>/dev/null | jq -e '.checks' >/dev/null && pass "AG3 doctor (mutates_state=yes)" || fail "AG3 doctor"

# Canonical subcommands
"$SCRIPT" health --json 2>/dev/null | jq -e '.command == "health" and has("fallback_row_count")' >/dev/null && pass "health envelope" || fail "health"
"$SCRIPT" validate --json 2>/dev/null | jq -e '.command == "validate" and has("row_count")' >/dev/null && pass "validate envelope" || fail "validate"
"$SCRIPT" audit --json 2>/dev/null | jq -e '.command == "audit" and has("recent")' >/dev/null && pass "audit envelope" || fail "audit"
"$SCRIPT" why --json 2>/dev/null | jq -e '.command == "why" and has("body")' >/dev/null && pass "why envelope (default topic)" || fail "why default"
"$SCRIPT" why apply-vs-dry-run --json 2>/dev/null | jq -e '.topic == "apply-vs-dry-run"' >/dev/null && pass "why apply-vs-dry-run topic" || fail "why apply-vs-dry-run"
"$SCRIPT" quickstart 2>/dev/null | jq -e '.command == "quickstart" and (.steps | length >= 3)' >/dev/null && pass "quickstart envelope" || fail "quickstart"

# Repair scope + apply contract
"$SCRIPT" repair --scope fallback-ledger-prime --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .scope == "fallback-ledger-prime" and .mode == "dry_run"' >/dev/null && pass "repair --dry-run" || fail "repair --dry-run"
"$SCRIPT" repair --scope fallback-ledger-prime --apply --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 3 ]] && pass "repair --apply without --idempotency-key returns rc=3" || fail "repair apply rc=$rc"

# Magic comment + lint
grep -q '# flywheel-cli-surface: true' "$SCRIPT" && pass "L6 magic comment present" || fail "L6 missing"
"$ROOT/.flywheel/scripts/canonical-cli-lint.sh" "$SCRIPT" >/dev/null 2>&1 && rc=0 || rc=$?
[[ "$rc" -eq 0 ]] && pass "canonical-cli-lint RC=0" || fail "lint RC=$rc"

# Backward-compat: legacy --dry-run flow with synthetic digest
SHA="$(printf 'fixture\n' | shasum -a 256 | awk '{print $1}')"
"$SCRIPT" --session flywheel --pane 3 --digest "$SHA" --dry-run --json 2>/dev/null \
  | jq -e '.status == "dry_run" and .would_send == true and .dry_run == true' >/dev/null \
  && pass "legacy --dry-run with --digest emits would_send" || fail "legacy --dry-run"

# Backward-compat: malformed input (missing pane) returns rc=3
"$SCRIPT" --session flywheel --apply --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 3 ]] && pass "legacy malformed (missing --pane + --apply) rc=3" || fail "legacy malformed rc=$rc"

# Backward-compat: --info still emits known fields (lease_bin, ntm_bin, exit_codes)
"$SCRIPT" --info --json 2>/dev/null | jq -e '.lease_bin and .ntm_bin and .exit_codes' >/dev/null && pass "legacy --info fields preserved" || fail "legacy --info fields"

# --help echoes argparse usage
"$SCRIPT" --help 2>&1 | grep -qE 'usage|primitive' && pass "--help shows usage" || fail "--help"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
