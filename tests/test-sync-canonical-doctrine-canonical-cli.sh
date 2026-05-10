#!/usr/bin/env bash
# tests/test-sync-canonical-doctrine-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/test-sync-canonical-doctrine.sh (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green.
# Per-surface assertions (tests 14-21) added by flywheel-zjm8v fillin.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/test-sync-canonical-doctrine.sh"

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

# ---- Per-surface assertions (filled in by flywheel-zjm8v) ----

# Test 14: doctor returns concrete checks (not status:todo) and aggregates pass/warn/fail
if "$SCRIPT" doctor --json 2>/dev/null \
    | jq -e '(.command == "doctor") and (.status | IN("pass","warn","fail"))
             and (.checks | length >= 6)
             and (.checks | all(.name and (.status | IN("pass","warn","fail"))))' >/dev/null; then
  pass "doctor returns >=6 concrete checks with valid statuses"
else fail "doctor concrete checks"; fi

# Test 15: doctor includes the load-bearing sync_binary check
if "$SCRIPT" doctor --json 2>/dev/null \
    | jq -e '.checks | any(.name == "sync_binary_executable")' >/dev/null; then
  pass "doctor probes sync_binary_executable"
else fail "doctor sync_binary check missing"; fi

# Test 16: health returns concrete envelope (not status:todo)
if "$SCRIPT" health --json 2>/dev/null \
    | jq -e '(.command == "health") and (.status | IN("pass","warn","empty"))
             and has("total_runs") and has("pass_rate") and has("window")' >/dev/null; then
  pass "health returns concrete envelope (status, total_runs, pass_rate, window)"
else fail "health concrete envelope"; fi

# Test 17: repair --scope audit_log_dir --dry-run lists planned actions array
if "$SCRIPT" repair --scope audit_log_dir --dry-run --json 2>/dev/null \
    | jq -e '(.command == "repair") and (.scope == "audit_log_dir") and (.mode == "dry_run")
             and (.status == "dry_run") and (.planned_actions | type == "array")' >/dev/null; then
  pass "repair --scope audit_log_dir --dry-run lists planned actions"
else fail "repair audit_log_dir dry-run"; fi

# Test 18: repair --scope audit_log_dir --apply --idempotency-key K mutates and writes audit row
TEST_LOG_DIR="$(mktemp -d)"
TEST_LOG="$TEST_LOG_DIR/test-runs.jsonl"
SCAFFOLD_AUDIT_LOG="$TEST_LOG" "$SCRIPT" repair --scope audit_log_dir --apply --idempotency-key zjm8v-test --json >/dev/null 2>&1
SCAFFOLD_AUDIT_LOG="$TEST_LOG" "$SCRIPT" repair --scope audit_log_truncate --apply --idempotency-key zjm8v-test2 --json >/dev/null 2>&1
if [[ -f "$TEST_LOG" ]] && grep -q '"action":"repair"' "$TEST_LOG" && grep -q '"status":"applied"' "$TEST_LOG"; then
  pass "repair --apply --idempotency-key writes audit-log row"
else fail "repair --apply audit-log row"; fi
rm -rf "$TEST_LOG_DIR"

# Test 19: validate sync-binary verifies the real sync-canonical-doctrine.sh
if "$SCRIPT" validate sync-binary 2>/dev/null \
    | jq -e '(.command == "validate") and (.subject == "sync-binary")
             and (.status | IN("pass","fail"))
             and has("syntax_ok") and has("flags_ok") and has("path")' >/dev/null; then
  pass "validate sync-binary returns concrete contract envelope"
else fail "validate sync-binary contract"; fi

# Test 20: audit envelope has row_count + recent fields (concrete, not status:todo)
if "$SCRIPT" audit --json 2>/dev/null \
    | jq -e '(.command == "audit") and (.status | IN("pass","empty","missing"))
             and has("row_count") and has("recent")' >/dev/null; then
  pass "audit envelope concrete (row_count + recent)"
else fail "audit concrete envelope"; fi

# Test 21: why with numeric id returns provenance envelope with match_count
if "$SCRIPT" why -1 2>/dev/null \
    | jq -e '(.command == "why") and (.id == "-1")
             and (.status | IN("pass","miss","missing"))
             and has("match_count") and has("matches")' >/dev/null; then
  pass "why with numeric id returns provenance envelope"
else fail "why numeric id provenance"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
