#!/usr/bin/env bash
# tests/flywheel-sync-canonical-cli.sh
# Canonical-cli surface tests for /Users/josh/.claude/skills/.flywheel/bin/flywheel-sync (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green. TODO markers
# point at per-surface assertions the operator should fill in.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="/Users/josh/.claude/skills/.flywheel/bin/flywheel-sync"

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

# Test 7: repair --dry-run envelope (use real scope: log_dir is the safe one)
if "$SCRIPT" repair --scope log_dir --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .mode == "dry_run" and .scope == "log_dir"' >/dev/null; then
  pass "repair --scope log_dir --dry-run emits canonical envelope"
else fail "repair --dry-run envelope"; fi

# Test 8: repair --apply without --idempotency-key REFUSES (rc=3)
"$SCRIPT" repair --scope log_dir --apply --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 3 ]]; then
  pass "repair --apply without --idempotency-key returns rc=3 (canonical refusal)"
else
  fail "repair --apply rc=$rc (expected 3)"
fi

# Test 9: validate envelope (subject required; bare validate refuses with rc=64,
# emitting a canonical "refused" envelope — that IS the canonical contract)
"$SCRIPT" validate --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 64 ]]; then
  pass "validate without subject refuses with rc=64 (canonical contract)"
else
  fail "validate without subject rc=$rc (expected 64)"
fi

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

# ---- Fillin-specific assertions (flywheel-wzjo9.1.2) ----

# Test 14 (load-bearing): doctor emits >=5 named substrate checks
if "$SCRIPT" doctor --json 2>/dev/null \
    | jq -e '(.checks | length >= 5) and (.checks | all(.name and (.status | IN("pass","warn","fail"))))' >/dev/null; then
  pass "doctor returns >=5 named checks with valid statuses"
else fail "doctor concrete checks <5 or shape invalid"; fi

# Test 15 (load-bearing): doctor probes the load-bearing flock_available check
if "$SCRIPT" doctor --json 2>/dev/null | jq -e '.checks | any(.name == "flock_available")' >/dev/null; then
  pass "doctor probes flock_available (load-bearing for sync lock discipline)"
else fail "doctor missing flock_available check"; fi

# Test 16 (load-bearing): validate config returns concrete pass/fail (NOT 'todo')
# When the config doesn't exist, expect status=fail with a reason (canonical contract)
"$SCRIPT" validate config /tmp/__flywheel-sync-test-noexist__.env >/tmp/__sync-validate-test.json 2>&1
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.subject == "config" and .status == "fail" and (.reason // "" | length > 0)' /tmp/__sync-validate-test.json >/dev/null 2>&1; then
  pass "validate config rejects missing config with rc=1 + reason (concrete contract, not 'todo')"
else
  fail "validate config missing config returned rc=$rc (expected 1) or wrong shape"
fi
rm -f /tmp/__sync-validate-test.json

# Test 17 (load-bearing): repair scope=log_dir with --apply + --idempotency-key returns concrete action (not 'todo')
ACTION="$("$SCRIPT" repair --scope log_dir --apply --idempotency-key flywheel-sync-test-key --json 2>/dev/null | jq -r '.action // ""')"
case "$ACTION" in
  log_dir_exists_noop|log_dir_created)
    pass "repair --scope log_dir --apply emits concrete action ($ACTION)"
    ;;
  *)
    fail "repair --scope log_dir --apply emitted action='$ACTION' (expected log_dir_exists_noop or log_dir_created)"
    ;;
esac

# Test 18 (load-bearing): why returns one of {found, not_found, unavailable}
WHY_STATUS="$("$SCRIPT" why nonexistent-id-12345 2>/dev/null | jq -r '.status // ""')"
case "$WHY_STATUS" in
  found|not_found|unavailable)
    pass "why <id> returns canonical state: $WHY_STATUS"
    ;;
  *)
    fail "why returned unexpected status: '$WHY_STATUS'"
    ;;
esac

# Test 19: schema doctor surface returns rich shape (not 'todo')
if "$SCRIPT" --schema doctor 2>/dev/null | jq -e '.surface == "doctor" and .fields and .fields.thresholds' >/dev/null; then
  pass "schema doctor returns concrete shape (fields + thresholds)"
else
  fail "schema doctor missing concrete shape"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
