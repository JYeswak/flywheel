#!/usr/bin/env bash
# tests/mission-lock-readiness-doctor-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/mission-lock-readiness-doctor.sh (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# Base checks prove canonical-cli-scoping. Fill-in checks prove the mission-lock
# readiness surface has concrete doctor/health/repair/validate/audit/why logic.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/mission-lock-readiness-doctor.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/mission-lock-readiness-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

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

# Test 5: doctor returns valid envelope.
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

# Fill-in assertions for flywheel-5wuhe.

# Test 14: doctor has concrete load-bearing checks.
if "$SCRIPT" doctor --json 2>/dev/null \
  | jq -e '.command == "doctor"
           and (.status | IN("pass","warn","fail"))
           and (.checks | length >= 8)
           and (.checks | any(.name == "mission_default_readable"))
           and (.checks | any(.name == "schema_validator_executable"))
           and (.checks | any(.name == "scaffold_validator_executable"))
           and (.checks | any(.name == "lens_merge_executable"))' >/dev/null; then
  pass "doctor returns concrete mission-lock substrate checks"
else fail "doctor concrete mission-lock checks"; fi

# Test 15: repair has real scopes and apply writes an audit row.
TEST_LOG="$TMP/readiness-runs.jsonl"
SCAFFOLD_AUDIT_LOG="$TEST_LOG" "$SCRIPT" repair --scope audit_log_dir --apply --idempotency-key 5wuhe-test --json >/dev/null 2>&1
if [[ -f "$TEST_LOG" ]] && jq -e 'select(.action == "repair" and .status == "applied")' "$TEST_LOG" >/dev/null; then
  pass "repair --apply writes audit row for audit_log_dir"
else fail "repair apply audit row"; fi

# Test 16: health summarizes audit rows.
if SCAFFOLD_AUDIT_LOG="$TEST_LOG" "$SCRIPT" health --json 2>/dev/null \
  | jq -e '.command == "health" and .total_runs >= 1 and .last_status == "applied" and (.pass_rate | type == "number")' >/dev/null; then
  pass "health summarizes mission-lock readiness audit rows"
else fail "health audit summary"; fi

# Test 17: validate readiness-state accepts the native doctor payload shape.
READINESS_FIXTURE='{"mission_lock_readiness_health_score":0.7,"blocked_surfaces":["mission-lock-scaffold"],"phase0_scaffold_bead_suggestions":[],"repair_receipt_identity_fields":{"repair_idempotency_key":"sha256:test"},"audit_only":true}'
if "$SCRIPT" validate readiness-state "$READINESS_FIXTURE" 2>/dev/null \
  | jq -e '.command == "validate" and .subject == "readiness-state" and .status == "pass"' >/dev/null; then
  pass "validate readiness-state accepts native payload shape"
else fail "validate readiness-state"; fi

# Test 18: validate audit-row rejects hash-only or arbitrary rows.
set +e
"$SCRIPT" validate audit-row '{"sha256":"abc"}' >/dev/null 2>&1
rc=$?
set -e
if [[ "$rc" -eq 1 ]]; then
  pass "validate audit-row rejects hash-only rows"
else fail "validate audit-row hash-only rc=$rc"; fi

# Test 19: audit tails concrete rows.
if SCAFFOLD_AUDIT_LOG="$TEST_LOG" "$SCRIPT" audit --json 2>/dev/null \
  | jq -e '.command == "audit" and .status == "pass" and .row_count >= 1 and (.recent | length >= 1)' >/dev/null; then
  pass "audit tails mission-lock readiness audit rows"
else fail "audit tail"; fi

# Test 20: why can explain audit rows by substring.
if SCAFFOLD_AUDIT_LOG="$TEST_LOG" "$SCRIPT" why repair 2>/dev/null \
  | jq -e '.command == "why" and .status == "pass" and .match_count >= 1' >/dev/null; then
  pass "why explains repair audit provenance"
else fail "why audit provenance"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
