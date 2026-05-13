#!/usr/bin/env bash
# tests/{proof-product}-end-user-health-probe-canonical-cli.sh
# flywheel-k8gcv.8 (wave-3-08).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/{proof-product}-end-user-health-probe.sh"

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
"$SCRIPT" health --json 2>/dev/null | jq -e '.command == "health"' >/dev/null && pass "health envelope" || fail "health"
"$SCRIPT" validate --json 2>/dev/null | jq -e '.command == "validate"' >/dev/null && pass "validate envelope" || fail "validate"
"$SCRIPT" audit --json 2>/dev/null | jq -e '.command == "audit" and has("recent")' >/dev/null && pass "audit envelope" || fail "audit"
"$SCRIPT" why --json 2>/dev/null | jq -e '.command == "why" and has("body")' >/dev/null && pass "why default" || fail "why default"
"$SCRIPT" why proxy-metrics --json 2>/dev/null | jq -e '.topic == "proxy-metrics"' >/dev/null && pass "why proxy-metrics" || fail "why proxy-metrics"
"$SCRIPT" quickstart 2>/dev/null | jq -e '.command == "quickstart"' >/dev/null && pass "quickstart envelope" || fail "quickstart"

# Apply contract (L7 fix)
"$SCRIPT" --apply --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 3 ]] && pass "main --apply without --idempotency-key returns rc=3" || fail "main apply rc=$rc"
"$SCRIPT" repair --scope ledger-prime --apply --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 3 ]] && pass "repair --apply without --idempotency-key returns rc=3" || fail "repair apply rc=$rc"

# Apply WITH idem-key emits probe row
TMP_LEDGER="$(mktemp -t k8gcv8-led.XXXXXX)"
MOBILE_EATS_HEALTH_LEDGER="$TMP_LEDGER" "$SCRIPT" --apply --idempotency-key meu-test-2026-05-11 --json 2>/dev/null \
  | jq -e '.schema_version == "{proof-product}-end-user-health/v1" and has("freshness_status") and has("kpi_surfaces_present_count")' >/dev/null \
  && pass "--apply --idempotency-key writes probe row" || fail "--apply with idem-key"
# Verify ledger row exists
[[ -s "$TMP_LEDGER" ]] && pass "apply mode appended to ledger" || fail "ledger not written"
rm -f "$TMP_LEDGER"

# Magic comment + lint (was 3 violations before fix)
grep -q '# flywheel-cli-surface: true' "$SCRIPT" && pass "L6 magic comment present" || fail "L6 missing"
"$ROOT/.flywheel/scripts/canonical-cli-lint.sh" "$SCRIPT" >/dev/null 2>&1 && rc=0 || rc=$?
[[ "$rc" -eq 0 ]] && pass "canonical-cli-lint RC=0 (was RC=1 with 3 violations: L5+L6+L7)" || fail "lint RC=$rc"

# Backward compat
"$SCRIPT" --doctor --json 2>/dev/null | jq -e '.schema_version == "{proof-product}-end-user-health/v1" and .mode == "doctor"' >/dev/null && pass "legacy --doctor flag preserved (different shape from canonical doctor subcommand)" || fail "legacy --doctor"
"$SCRIPT" --info --json 2>/dev/null | jq -e '.kpi_surfaces and .freshness_budget_hours and .owns' >/dev/null && pass "legacy --info fields preserved (kpi_surfaces+freshness_budget+owns)" || fail "legacy --info fields"
"$SCRIPT" --schema --json 2>/dev/null | jq -e '.ledger_row_required_fields and .proxy_metrics' >/dev/null && pass "legacy --schema fields preserved (ledger_row_required_fields+proxy_metrics)" || fail "legacy --schema fields"
"$SCRIPT" --help 2>&1 | head -3 | grep -qE 'Usage|{proof-product}' && pass "--help shows usage" || fail "--help"
"$SCRIPT" --bogus >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 64 ]] && pass "unknown arg rc=64 (preserved)" || fail "unknown arg rc=$rc"

# --examples without --json emits text
"$SCRIPT" --examples 2>&1 | grep -q '{proof-product}-end-user-health' && pass "--examples text-mode preserved" || fail "--examples text"

# Dry-run default (no --apply, no --dry-run) emits probe row without writing ledger
TMP_LEDGER2="$(mktemp -t k8gcv8-led2.XXXXXX)"
MOBILE_EATS_HEALTH_LEDGER="$TMP_LEDGER2" "$SCRIPT" --json 2>/dev/null \
  | jq -e '.mode == "dry-run" and has("freshness_status")' >/dev/null \
  && pass "default mode is dry-run (no --apply needed)" || fail "default dry-run mode"
[[ ! -s "$TMP_LEDGER2" ]] && pass "dry-run does NOT write ledger" || fail "dry-run wrote ledger"
rm -f "$TMP_LEDGER2"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
