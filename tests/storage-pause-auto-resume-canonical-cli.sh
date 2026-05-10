#!/usr/bin/env bash
# tests/storage-pause-auto-resume-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/storage-pause-auto-resume.sh (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green. TODO markers
# point at per-surface assertions the operator should fill in.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/storage-pause-auto-resume.sh"

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

# Per-surface assertions (flywheel-j0zuh fillin).

# Test 14: doctor returns substantive checks (>=3, not status:todo)
if "$SCRIPT" doctor --json 2>/dev/null | jq -e '.status != "todo" and (.checks | length) >= 3' >/dev/null; then
  pass "doctor returns >=3 substantive checks"
else fail "doctor checks"; fi

# Test 15: doctor enumerates state_file + reclaim_dir + df + kill_bin + core_deps
if "$SCRIPT" doctor --json 2>/dev/null | jq -e '
  [.checks[].check] | (any(. == "state_file") and any(. == "reclaim_dir") and any(. == "df") and any(. == "kill_bin") and any(. == "core_deps"))' >/dev/null; then
  pass "doctor checks include 5 named substrate probes"
else fail "doctor probe names"; fi

# Test 16: health emits pause_active + reclaim_count + canonical status
if "$SCRIPT" health --json 2>/dev/null | jq -e '
  has("pause_active") and has("reclaim_count") and (.status | IN("ok","empty","not_initialized","paused"))' >/dev/null; then
  pass "health envelope has pause_active/reclaim_count + canonical status"
else fail "health envelope"; fi

# Test 17: repair --scope state --dry-run emits planned_actions
if "$SCRIPT" repair --scope state --dry-run --json 2>/dev/null | jq -e '
  .status == "dry_run" and has("planned_actions")' >/dev/null; then
  pass "repair --dry-run emits planned_actions"
else fail "repair dry-run"; fi

# Test 18: validate state_file enforces 4-check contract w/ accepts arrays
if "$SCRIPT" validate state_file --json 2>/dev/null | jq -e '
  .subject == "state_file" and (.results | length) >= 1' >/dev/null; then
  pass "validate state_file emits results array"
else fail "validate state_file"; fi

# Test 19: why <id> distinguishes found vs not_found
if "$SCRIPT" why "20260101T000000Z_definitely_not_a_real_receipt" --json 2>/dev/null | jq -e '
  .id == "20260101T000000Z_definitely_not_a_real_receipt" and (.status | IN("found","not_found"))' >/dev/null; then
  pass "why <id> emits found|not_found"
else fail "why id"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
