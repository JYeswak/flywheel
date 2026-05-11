#!/usr/bin/env bash
# tests/capacity-halt-lease-primitive-canonical-cli.sh
# flywheel-k8gcv.4 (wave-3-04).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/capacity-halt-lease-primitive.sh"

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
TMP_LEDGER="$(mktemp -t k8gcv4-led.XXXXXX)"
CAPACITY_HALT_LEASE_LEDGER="$TMP_LEDGER" "$SCRIPT" health --json 2>/dev/null | jq -e '.command == "health" and has("active_lease_count")' >/dev/null && pass "health envelope" || fail "health"
CAPACITY_HALT_LEASE_LEDGER="$TMP_LEDGER" "$SCRIPT" validate --json 2>/dev/null | jq -e '.command == "validate"' >/dev/null && pass "validate envelope" || fail "validate"
CAPACITY_HALT_LEASE_LEDGER="$TMP_LEDGER" "$SCRIPT" audit --json 2>/dev/null | jq -e '.command == "audit" and has("recent")' >/dev/null && pass "audit envelope" || fail "audit"
"$SCRIPT" why --json 2>/dev/null | jq -e '.command == "why" and has("body")' >/dev/null && pass "why envelope (default topic)" || fail "why default"
"$SCRIPT" why digest-keying --json 2>/dev/null | jq -e '.topic == "digest-keying"' >/dev/null && pass "why digest-keying topic" || fail "why digest-keying"
"$SCRIPT" quickstart 2>/dev/null | jq -e '.command == "quickstart" and (.steps | length >= 3)' >/dev/null && pass "quickstart envelope" || fail "quickstart"

# Repair + apply contract
"$SCRIPT" repair --scope ledger-prime --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .scope == "ledger-prime" and .mode == "dry_run"' >/dev/null && pass "repair --dry-run" || fail "repair --dry-run"
"$SCRIPT" repair --scope ledger-prime --apply --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 3 ]] && pass "repair --apply without --idempotency-key returns rc=3" || fail "repair apply rc=$rc"

# Magic comment + lint
grep -q '# flywheel-cli-surface: true' "$SCRIPT" && pass "L6 magic comment present" || fail "L6 missing"
"$ROOT/.flywheel/scripts/canonical-cli-lint.sh" "$SCRIPT" >/dev/null 2>&1 && rc=0 || rc=$?
[[ "$rc" -eq 0 ]] && pass "canonical-cli-lint RC=0" || fail "lint RC=$rc"

# Backward-compat: --list still works
CAPACITY_HALT_LEASE_LEDGER="$TMP_LEDGER" "$SCRIPT" --list --json 2>/dev/null | jq -e '.status == "ok" and has("leases")' >/dev/null && pass "legacy --list emits leases array" || fail "legacy --list"

# Backward-compat: acquire + release round-trip
DIGEST="$(printf 'fixture\n' | shasum -a 256 | awk '{print $1}')"
CAPACITY_HALT_LEASE_LEDGER="$TMP_LEDGER" "$SCRIPT" --acquire --session flywheel --pane 3 --digest "$DIGEST" --ttl 60 --json 2>/dev/null \
  | jq -e '.status == "acquired" and .ledger_written == true' >/dev/null \
  && pass "legacy --acquire writes ledger row" || fail "legacy --acquire"

# already-held returns rc=1
CAPACITY_HALT_LEASE_LEDGER="$TMP_LEDGER" "$SCRIPT" --acquire --session flywheel --pane 3 --digest "$DIGEST" --ttl 60 --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 1 ]] && pass "legacy --acquire already-held returns rc=1" || fail "legacy already-held rc=$rc"

# Release
CAPACITY_HALT_LEASE_LEDGER="$TMP_LEDGER" "$SCRIPT" --release --session flywheel --pane 3 --digest "$DIGEST" --result success --json 2>/dev/null \
  | jq -e '.status == "released" and .result == "success"' >/dev/null \
  && pass "legacy --release writes release row" || fail "legacy --release"

# Malformed (missing digest) returns rc=2
CAPACITY_HALT_LEASE_LEDGER="$TMP_LEDGER" "$SCRIPT" --acquire --session flywheel --pane 3 --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 2 ]] && pass "legacy malformed (missing --digest) rc=2" || fail "legacy malformed rc=$rc"

# --help
"$SCRIPT" --help 2>&1 | grep -qE 'usage|primitive' && pass "--help shows usage" || fail "--help"

# Cleanup tmp ledger (safe path, mktemp)
rm -f "$TMP_LEDGER"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
