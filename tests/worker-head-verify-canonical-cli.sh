#!/usr/bin/env bash
# tests/worker-head-verify-canonical-cli.sh
# Canonical-cli + integration tests for worker-head-verify.sh (bead flywheel-iro0k).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/worker-head-verify.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: bash -n syntax
if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# Test 2: --info envelope
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.schema_version | test("^worker-head-verify/v[0-9]+$")' >/dev/null; then
  pass "--info schema_version matches <surface>/v1"
else fail "--info schema_version"; fi

# Test 3: --schema returns valid JSON for verify surface
if "$SCRIPT" --schema verify 2>/dev/null | jq -e '.command == "schema" and .surface == "verify"' >/dev/null; then
  pass "--schema verify envelope"
else fail "--schema verify envelope"; fi

# Test 4: --examples returns valid JSON
if "$SCRIPT" --examples --json 2>/dev/null | jq -e '.command == "examples"' >/dev/null; then
  pass "--examples envelope"
else fail "--examples envelope"; fi

# Test 5: doctor envelope
if "$SCRIPT" doctor --json 2>/dev/null | jq -e '.command == "doctor"' >/dev/null; then
  pass "doctor envelope"
else fail "doctor envelope"; fi

# Test 6: health envelope
if "$SCRIPT" health --json 2>/dev/null | jq -e '.command == "health"' >/dev/null; then
  pass "health envelope"
else fail "health envelope"; fi

# Test 7: repair --dry-run envelope
if "$SCRIPT" repair --scope none --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .mode == "dry_run"' >/dev/null; then
  pass "repair --dry-run envelope"
else fail "repair --dry-run envelope"; fi

# Test 8: repair --apply without --idempotency-key returns rc=3
"$SCRIPT" repair --scope audit_log_dir --apply --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 3 ]]; then
  pass "repair --apply without idempotency-key returns rc=3"
else
  fail "repair --apply rc=$rc (expected 3)"
fi

# Test 9: validate envelope
if "$SCRIPT" validate --json 2>/dev/null | jq -e '.command == "validate"' >/dev/null; then
  pass "validate envelope"
else fail "validate envelope"; fi

# Test 10: audit envelope
if "$SCRIPT" audit --json 2>/dev/null | jq -e '.command == "audit"' >/dev/null; then
  pass "audit envelope"
else fail "audit envelope"; fi

# Test 11: why with id
if "$SCRIPT" why some-id 2>/dev/null | jq -e '.command == "why"' >/dev/null; then
  pass "why envelope"
else fail "why envelope"; fi

# Test 12: help <topic>
if "$SCRIPT" help verify 2>/dev/null | grep -q 'topic:'; then
  pass "help topic"
else fail "help topic"; fi

# Test 13: quickstart envelope
if "$SCRIPT" quickstart 2>/dev/null | jq -e '.command == "quickstart"' >/dev/null; then
  pass "quickstart envelope"
else fail "quickstart envelope"; fi

# ---- Per-surface fillin assertions ----

# Test 14: doctor returns concrete checks (>=5)
if "$SCRIPT" doctor --json 2>/dev/null \
    | jq -e '(.checks | length >= 5)
             and (.checks | all(.name and (.status | IN("pass","warn","fail"))))' >/dev/null; then
  pass "doctor returns >=5 concrete checks"
else fail "doctor concrete checks"; fi

# Test 15: doctor probes git_available (load-bearing)
if "$SCRIPT" doctor --json 2>/dev/null | jq -e '.checks | any(.name == "git_available")' >/dev/null; then
  pass "doctor probes git_available"
else fail "doctor git_available check missing"; fi

# Test 16: validate head-state emits head/branch/parent fields
if "$SCRIPT" validate head-state 2>/dev/null \
    | jq -e '(.subject == "head-state") and has("head") and has("branch") and has("parent")' >/dev/null; then
  pass "validate head-state emits head+branch+parent"
else fail "validate head-state contract"; fi

# Test 17: integration — verify on a fixture repo with --expected-branch=current
TEST_REPO="$(mktemp -d)/whv-fixture"
git init -q "$TEST_REPO" 2>&1 >/dev/null
(cd "$TEST_REPO" && git commit --allow-empty -m "init" -q 2>&1 && git checkout -q -b feature-test) >/dev/null
ACTUAL_BRANCH="$(git -C "$TEST_REPO" rev-parse --abbrev-ref HEAD)"
WORKER_HEAD_VERIFY_REPO="$TEST_REPO" "$SCRIPT" --expected-branch "$ACTUAL_BRANCH" --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 0 ]]; then
  pass "integration: verify pass on matching branch (rc=0)"
else
  fail "integration: verify pass rc=$rc (expected 0)"
fi

# Test 18: integration — branch mismatch returns rc=1
WORKER_HEAD_VERIFY_REPO="$TEST_REPO" "$SCRIPT" --expected-branch wrong-branch --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 1 ]]; then
  pass "integration: verify branch mismatch returns rc=1"
else
  fail "integration: branch mismatch rc=$rc (expected 1)"
fi

# Test 19: integration — parent mismatch returns rc=2
(cd "$TEST_REPO" && git commit --allow-empty -m "second" -q 2>&1) >/dev/null
WORKER_HEAD_VERIFY_REPO="$TEST_REPO" "$SCRIPT" --expected-branch "$ACTUAL_BRANCH" --expected-parent deadbeef0000 --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 2 ]]; then
  pass "integration: verify parent mismatch returns rc=2"
else
  fail "integration: parent mismatch rc=$rc (expected 2)"
fi

# Test 20: integration — substrate failure on non-git path returns rc=3
NON_REPO="$(mktemp -d)"
WORKER_HEAD_VERIFY_REPO="$NON_REPO" "$SCRIPT" --expected-branch any --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 3 ]]; then
  pass "integration: substrate failure on non-git returns rc=3"
else
  fail "integration: substrate failure rc=$rc (expected 3)"
fi

rm -rf "$TEST_REPO" "$NON_REPO" "$(dirname "$TEST_REPO")" "$NON_REPO" 2>/dev/null || true


if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
