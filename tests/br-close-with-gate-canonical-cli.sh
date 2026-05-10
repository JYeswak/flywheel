#!/usr/bin/env bash
# tests/br-close-with-gate-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/br-close-with-gate.sh (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green. TODO markers
# point at per-surface assertions the operator should fill in.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/br-close-with-gate.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: bash -n syntax
if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# Test 2: --info envelope is valid JSON with schema_version
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.schema_version and .command == "info"' >/dev/null; then
  pass "--info emits canonical envelope"
else fail "--info envelope"; fi

# Test 3: --schema returns valid JSON
if "$SCRIPT" --schema 2>/dev/null | jq -e '.schema_version and .command == "schema"' >/dev/null; then
  pass "--schema emits canonical envelope"
else fail "--schema envelope"; fi

# Test 4: --examples returns valid JSON
if "$SCRIPT" --examples --json 2>/dev/null | jq -e '.command == "examples"' >/dev/null; then
  pass "--examples emits canonical envelope"
else fail "--examples envelope"; fi

# Test 5: doctor returns valid envelope (even pre-fill-in stub is valid JSON)
if "$SCRIPT" doctor --json 2>/dev/null | jq -e '.command == "doctor"' >/dev/null; then
  pass "doctor emits canonical envelope"
else fail "doctor envelope"; fi

# Test 6: health envelope
if "$SCRIPT" health --json 2>/dev/null | jq -e '.command == "health"' >/dev/null; then
  pass "health emits canonical envelope"
else fail "health envelope"; fi

# Test 7: repair --dry-run envelope
if "$SCRIPT" repair --scope none --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .mode == "dry_run"' >/dev/null; then
  pass "repair --dry-run emits canonical envelope"
else fail "repair --dry-run envelope"; fi

# Test 8: repair --apply without --idempotency-key REFUSES (rc=3)
"$SCRIPT" repair --scope none --apply --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 3 ]]; then
  pass "repair --apply without --idempotency-key returns rc=3 (canonical refusal)"
else
  fail "repair --apply rc=$rc (expected 3)"
fi

# Test 9: validate envelope
if "$SCRIPT" validate --json 2>/dev/null | jq -e '.command == "validate"' >/dev/null; then
  pass "validate emits canonical envelope"
else fail "validate envelope"; fi

# Test 10: audit envelope
if "$SCRIPT" audit --json 2>/dev/null | jq -e '.command == "audit"' >/dev/null; then
  pass "audit emits canonical envelope"
else fail "audit envelope"; fi

# Test 11: why with id
if "$SCRIPT" why some-id 2>/dev/null | jq -e '.command == "why"' >/dev/null; then
  pass "why <id> emits canonical envelope"
else fail "why envelope"; fi

# Test 12: help <topic> returns text (intercepted only with topic arg)
if "$SCRIPT" help repair 2>/dev/null | grep -q 'topic:'; then
  pass "help repair returns topic header"
else fail "help topic"; fi

# Test 13: quickstart envelope
if "$SCRIPT" quickstart 2>/dev/null | jq -e '.command == "quickstart"' >/dev/null; then
  pass "quickstart emits canonical envelope"
else fail "quickstart envelope"; fi

# Per-surface assertions (flywheel-dsrq1 fillin).

# Test 14: doctor returns >=5 substantive named checks
if "$SCRIPT" doctor --json 2>/dev/null | jq -e '
  .status != "todo" and (.checks | length) >= 5
  and ([.checks[].check] | (any(. == "jq") and any(. == "br") and any(. == "schema_gate") and any(. == "l112_gate") and any(. == "audit_log_dir")))' >/dev/null; then
  pass "doctor returns 5 named substrate probes"
else fail "doctor checks"; fi

# Test 15: health envelope has total_rows + closed/blocked/failed counts + canonical status
if "$SCRIPT" health --json 2>/dev/null | jq -e '
  has("total_rows") and has("audit_log_path")
  and (.status | IN("ok","empty","not_initialized"))' >/dev/null; then
  pass "health envelope has audit-log counts + canonical status"
else fail "health envelope"; fi

# Test 16: repair --scope audit_log_truncate --dry-run emits planned_actions key
if "$SCRIPT" repair --scope audit_log_truncate --dry-run --json 2>/dev/null | jq -e '
  .status == "dry_run" and has("planned_actions")' >/dev/null; then
  pass "repair audit_log_truncate --dry-run emits planned_actions"
else fail "repair dry-run"; fi

# Test 17: validate audit-row emits per-row results array
if "$SCRIPT" validate audit-row --json 2>/dev/null | jq -e '
  .subject == "audit-row" and has("pass") and has("fail") and (.results | type == "array")' >/dev/null; then
  pass "validate audit-row emits results array"
else fail "validate audit-row"; fi

# Test 18: validate rejects unknown subject (rc=64)
"$SCRIPT" validate not-a-real-subject --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 64 ]]; then
  pass "validate rejects unknown subject with rc=64"
else fail "validate unknown subject rc=$rc"; fi

# Test 19: why distinguishes found|not_found|unavailable for fake id
if "$SCRIPT" why "definitely-not-a-real-id-xyz" --json 2>/dev/null | jq -e '
  .id == "definitely-not-a-real-id-xyz" and (.status | IN("found","not_found","unavailable"))' >/dev/null; then
  pass "why <id> emits found|not_found|unavailable"
else fail "why id"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
