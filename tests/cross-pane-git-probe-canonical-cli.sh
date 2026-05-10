#!/usr/bin/env bash
# tests/cross-pane-git-probe-canonical-cli.sh
# Canonical-cli + integration tests for cross-pane-git-probe.sh (bead flywheel-iro0k).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/cross-pane-git-probe.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: bash -n syntax
if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# Test 2: --info envelope
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.schema_version | test("^cross-pane-git-probe/v[0-9]+$")' >/dev/null; then
  pass "--info schema_version matches <surface>/v1"
else fail "--info schema_version"; fi

# Test 3: --schema returns valid JSON for run surface
if "$SCRIPT" --schema run 2>/dev/null | jq -e '.command == "schema" and .surface == "run"' >/dev/null; then
  pass "--schema run envelope"
else fail "--schema run envelope"; fi

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

# Test 7: repair --dry-run envelope (no scope - refused with structured envelope)
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

# Test 9: validate refused envelope
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
if "$SCRIPT" help repair 2>/dev/null | grep -q 'topic:'; then
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

# Test 16: validate worktree-count returns count + verdict
if "$SCRIPT" validate worktree-count 2>/dev/null \
    | jq -e '(.subject == "worktree-count") and has("worktree_count") and has("status")' >/dev/null; then
  pass "validate worktree-count returns count+verdict"
else fail "validate worktree-count contract"; fi

# Test 17: validate reflog-window returns violation_count + window_sec
if "$SCRIPT" validate reflog-window 2>/dev/null \
    | jq -e '(.subject == "reflog-window") and has("violation_count") and has("window_sec")' >/dev/null; then
  pass "validate reflog-window returns violation_count+window"
else fail "validate reflog-window contract"; fi

# Test 18: default run emits composite envelope with all 3 probes
if "$SCRIPT" --json 2>/dev/null \
    | jq -e '(.command == "run") and has("worktree_census") and has("stale_worktree") and has("concurrent_commit_window")' >/dev/null; then
  pass "default run emits 3-probe composite envelope"
else fail "default run composite envelope"; fi

# Test 19: integration — fixture repo with synthetic worktrees
TEST_REPO="$(mktemp -d)/cpgp-fixture"
git init -q "$TEST_REPO" 2>&1 >/dev/null
(cd "$TEST_REPO" && git commit --allow-empty -m "init" -q 2>&1) >/dev/null
TEST_LOG_DIR="$(mktemp -d)"
TEST_LOG="$TEST_LOG_DIR/test-runs.jsonl"
SCAFFOLD_AUDIT_LOG="$TEST_LOG" CROSS_PANE_GIT_PROBE_REPO="$TEST_REPO" "$SCRIPT" --json >/dev/null 2>&1
if [[ -f "$TEST_LOG" ]] && grep -q '"action":"probe"' "$TEST_LOG"; then
  pass "integration: probe on fixture repo writes audit-log row"
else fail "integration: probe audit-log row"; fi
rm -rf "$TEST_LOG_DIR" "$TEST_REPO"


if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
