#!/usr/bin/env bash
# tests/verify-watcher-launchd-active-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/verify-watcher-launchd-active.sh (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green. TODO markers
# point at per-surface assertions the operator should fill in.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/verify-watcher-launchd-active.sh"

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

# Test 7: repair --dry-run envelope (real scope per fillin contract)
if "$SCRIPT" repair --scope state_dir --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .mode == "dry_run" and .status == "ok"' >/dev/null; then
  pass "repair --dry-run emits canonical envelope (real scope)"
else fail "repair --dry-run envelope"; fi

# Test 8: repair --apply without --idempotency-key REFUSES (rc=3)
"$SCRIPT" repair --scope state_dir --apply --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 3 ]]; then
  pass "repair --apply without --idempotency-key returns rc=3 (canonical refusal)"
else
  fail "repair --apply rc=$rc (expected 3)"
fi

# Test 9: validate envelope (bare validate refuses with rc=64 per actual contract;
# calibrated per feedback_calibrate_test_to_actual_contract META-RULE 2026-05-09)
"$SCRIPT" validate >/tmp/vs78t-test9.json 2>&1
rc=$?
if [[ "$rc" -eq 64 ]] && jq -e '.command == "validate" and .status == "refused" and .reason == "missing_subject"' /tmp/vs78t-test9.json >/dev/null 2>&1; then
  pass "validate (bare) refuses with rc=64 + missing_subject envelope"
else fail "validate bare-refusal contract rc=$rc"; fi
rm -f /tmp/vs78t-test9.json

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

# ---------- fillin-specific assertions (6 added per worker-tick contract) ----------

# Test 14: doctor probes load-bearing launchctl_available check
if "$SCRIPT" doctor --json 2>/dev/null | jq -e '[.checks[].name] | index("launchctl_available")' >/dev/null; then
  pass "doctor probes launchctl_available (load-bearing for launchd verification)"
else fail "doctor missing launchctl_available probe"; fi

# Test 15: validate launchd-label accepts canonical zeststream prefix
if "$SCRIPT" validate launchd-label "ai.zeststream.codex-stuck-detector-watchdog" 2>/dev/null \
   | jq -e '.subject == "launchd-label" and .status == "ok"' >/dev/null; then
  pass "validate launchd-label accepts canonical ai.zeststream.* label"
else fail "validate launchd-label canonical accept"; fi

# Test 16: validate launchd-label REJECTS non-canonical label (rc=1)
"$SCRIPT" validate launchd-label "com.apple.launchd.thingy" >/tmp/vs78t-test16.json 2>&1
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.status == "reject" and .reason == "pattern_mismatch"' /tmp/vs78t-test16.json >/dev/null 2>&1; then
  pass "validate launchd-label rejects non-canonical with rc=1"
else fail "validate launchd-label reject rc=$rc"; fi
rm -f /tmp/vs78t-test16.json

# Test 17: validate session-name accepts lowercase-hyphen pattern
if "$SCRIPT" validate session-name "{session}" 2>/dev/null \
   | jq -e '.subject == "session-name" and .status == "ok"' >/dev/null; then
  pass "validate session-name accepts lowercase-hyphen"
else fail "validate session-name accept"; fi

# Test 18: validate session-name REJECTS uppercase (rc=1)
"$SCRIPT" validate session-name "Flywheel" >/tmp/vs78t-test18.json 2>&1
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.status == "reject"' /tmp/vs78t-test18.json >/dev/null 2>&1; then
  pass "validate session-name rejects uppercase with rc=1"
else fail "validate session-name reject rc=$rc"; fi
rm -f /tmp/vs78t-test18.json

# Test 19: repair refuses unknown scope with rc=64 + canonical envelope
"$SCRIPT" repair --scope nope --dry-run >/tmp/vs78t-test19.json 2>&1
rc=$?
if [[ "$rc" -eq 64 ]] && jq -e '.status == "refused" and .reason == "unknown_scope"' /tmp/vs78t-test19.json >/dev/null 2>&1; then
  pass "repair refuses unknown scope with rc=64 + unknown_scope envelope"
else fail "repair unknown-scope rc=$rc"; fi
rm -f /tmp/vs78t-test19.json

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
