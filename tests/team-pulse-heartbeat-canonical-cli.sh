#!/usr/bin/env bash
# tests/team-pulse-heartbeat-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/team-pulse-heartbeat.sh (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# Native run/doctor/status/schema/validate own their verbs; scaffold owns
# introspection plus repair/audit/why helpers.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/team-pulse-heartbeat.sh"

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

# Test 5: doctor returns native doctor envelope
if "$SCRIPT" doctor --json 2>/dev/null | jq -e '.schema_version == "team-pulse-doctor/v1" and (.status | IN("pass","warn","fail"))' >/dev/null; then
  pass "doctor emits native doctor envelope"
else fail "doctor envelope"; fi

# Test 6: health/status returns native status envelope
if "$SCRIPT" health --json 2>/dev/null | jq -e '.schema_version == "team-pulse-status/v1" and (.status | IN("pass","warn","fail"))' >/dev/null; then
  pass "health emits native status envelope"
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

# Test 9: validate plist returns native validation envelope
if "$SCRIPT" validate plist --json 2>/dev/null | jq -e '.schema_version == "team-pulse-plist-validation/v1" and (.status | IN("pass","fail"))' >/dev/null; then
  pass "validate plist emits native validation envelope"
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

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
