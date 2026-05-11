#!/usr/bin/env bash
# tests/jeffrey-comment-watchtower-canonical-cli.sh
# flywheel-k8gcv.21 (wave-3-21).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/jeffrey-comment-watchtower.sh"

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
printf '%s' "$out_doctor" | jq -e '.checks' >/dev/null && pass "AG3 doctor (canonical .checks)" || fail "AG3 doctor"

# Canonical subcommands
"$SCRIPT" health --json 2>/dev/null | jq -e '.command == "health"' >/dev/null && pass "health envelope" || fail "health"
"$SCRIPT" validate --json 2>/dev/null | jq -e '.command == "validate"' >/dev/null && pass "validate envelope" || fail "validate"
"$SCRIPT" audit --json 2>/dev/null | jq -e '.command == "audit" and has("recent")' >/dev/null && pass "audit envelope" || fail "audit"
"$SCRIPT" why --json 2>/dev/null | jq -e '.command == "why" and has("body")' >/dev/null && pass "why default" || fail "why default"
"$SCRIPT" why reseed-bootstrap --json 2>/dev/null | jq -e '.topic == "reseed-bootstrap"' >/dev/null && pass "why reseed-bootstrap" || fail "why reseed-bootstrap"
"$SCRIPT" quickstart --json 2>/dev/null | jq -e '.command == "quickstart"' >/dev/null && pass "quickstart envelope" || fail "quickstart"

# Apply contract (L7 fix): explicit --apply requires --idempotency-key
"$SCRIPT" --apply --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 3 ]] && pass "explicit --apply without --idempotency-key rc=3" || fail "explicit apply rc=$rc"
"$SCRIPT" repair --scope ledger-prime --apply --json >/dev/null 2>&1; rc=$?
[[ "$rc" -eq 3 ]] && pass "repair --apply without --idempotency-key rc=3" || fail "repair apply rc=$rc"

# Magic comment + lint (was 3 violations: L5+L6+L7)
grep -q '# flywheel-cli-surface: true' "$SCRIPT" && pass "L6 magic comment present" || fail "L6 missing"
"$ROOT/.flywheel/scripts/canonical-cli-lint.sh" "$SCRIPT" >/dev/null 2>&1 && rc=0 || rc=$?
[[ "$rc" -eq 0 ]] && pass "canonical-cli-lint RC=0 (was L5+L6+L7)" || fail "lint RC=$rc"

# Backward compat: legacy --doctor flag
"$SCRIPT" --doctor --json 2>/dev/null | jq -e '.mode == "doctor" and has("status")' >/dev/null \
  && pass "legacy --doctor flag preserved (mode:doctor envelope)" || fail "legacy --doctor"

# Legacy --info preserves owns/sla_hours/cadence_minutes
"$SCRIPT" --info --json 2>/dev/null | jq -e '.owns == "flywheel-d6tz0" and .sla_hours == 4 and .cadence_minutes == 15' >/dev/null \
  && pass "legacy --info fields preserved (owns + sla_hours + cadence_minutes)" || fail "legacy --info fields"

# --help
"$SCRIPT" --help 2>&1 | head -3 | grep -qE 'Usage|jeffrey-comment' && pass "--help shows usage" || fail "--help"

# --examples text-mode
"$SCRIPT" --examples 2>&1 | grep -q 'jeffrey-comment-watchtower' && pass "--examples text-mode preserved" || fail "--examples text"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
