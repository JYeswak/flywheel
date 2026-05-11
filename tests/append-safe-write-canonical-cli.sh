#!/usr/bin/env bash
# tests/append-safe-write-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/append-safe-write.sh (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green. TODO markers
# point at per-surface assertions the operator should fill in.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/append-safe-write.sh"

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
if "$SCRIPT" repair --scope scratch_dir --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .mode == "dry_run" and .status == "ok"' >/dev/null; then
  pass "repair --dry-run emits canonical envelope (real scope)"
else fail "repair --dry-run envelope"; fi

# Test 8: repair --apply without --idempotency-key REFUSES (rc=3)
"$SCRIPT" repair --scope scratch_dir --apply --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 3 ]]; then
  pass "repair --apply without --idempotency-key returns rc=3 (canonical refusal)"
else
  fail "repair --apply rc=$rc (expected 3)"
fi

# Test 9: validate envelope (bare validate refuses with rc=64 per actual contract;
# calibrated per feedback_calibrate_test_to_actual_contract META-RULE 2026-05-09)
"$SCRIPT" validate >/tmp/5ke66-2-test9.json 2>&1
rc=$?
if [[ "$rc" -eq 64 ]] && jq -e '.command == "validate" and .status == "refused" and .reason == "missing_subject"' /tmp/5ke66-2-test9.json >/dev/null 2>&1; then
  pass "validate (bare) refuses with rc=64 + missing_subject envelope"
else fail "validate bare-refusal contract rc=$rc"; fi
rm -f /tmp/5ke66-2-test9.json

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

# Test 14: doctor probes load-bearing python3 with detail describing the
# lock/lease/append heredoc dependency
if "$SCRIPT" doctor --json 2>/dev/null | jq -e '.checks[] | select(.name == "python3_available") | .detail | contains("lock")' >/dev/null; then
  pass "doctor python3_available probe annotates lock/lease/append heredoc dependency"
else fail "doctor python3 detail annotation"; fi

# Test 15: validate target-path accepts absolute path
if "$SCRIPT" validate target-path "/var/log/foo.log" 2>/dev/null \
   | jq -e '.subject == "target-path" and .status == "ok"' >/dev/null; then
  pass "validate target-path accepts absolute path"
else fail "validate target-path absolute accept"; fi

# Test 16: validate target-path REJECTS relative path (rc=1 + not_absolute_path)
"$SCRIPT" validate target-path "relative/path.log" >/tmp/5ke66-2-test16.json 2>&1
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.status == "reject" and .reason == "not_absolute_path"' /tmp/5ke66-2-test16.json >/dev/null 2>&1; then
  pass "validate target-path rejects relative path with rc=1 + not_absolute_path"
else fail "validate target-path relative reject rc=$rc"; fi
rm -f /tmp/5ke66-2-test16.json

# Test 17: validate lease-ms accepts default value 300 (matches --lease-ms default)
if "$SCRIPT" validate lease-ms "300" 2>/dev/null \
   | jq -e '.subject == "lease-ms" and .status == "ok" and .value == 300' >/dev/null; then
  pass "validate lease-ms accepts default 300 (matches --lease-ms default in cmd_run)"
else fail "validate lease-ms default accept"; fi

# Test 18: validate lease-ms REJECTS out-of-range value 99999 (rc=1)
"$SCRIPT" validate lease-ms "99999" >/tmp/5ke66-2-test18.json 2>&1
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.status == "reject" and .reason == "out_of_range_or_not_integer"' /tmp/5ke66-2-test18.json >/dev/null 2>&1; then
  pass "validate lease-ms rejects 99999 (out of [1,60000] range) with rc=1"
else fail "validate lease-ms range reject rc=$rc"; fi
rm -f /tmp/5ke66-2-test18.json

# Test 19: backward-compat — original cmd_run still appends + emits status:ok
TARGET="$(mktemp -t append-safe-write-test19-XXXXXX)"
echo "test payload row 19" | "$SCRIPT" --target "$TARGET" --json 2>/dev/null | jq -e '.status == "ok" and .bytes_appended > 0' >/dev/null
rc=$?
if [[ "$rc" -eq 0 ]] && grep -q "test payload row 19" "$TARGET"; then
  pass "backward-compat: cmd_run appends payload to --target and emits status=ok"
else fail "backward-compat run-mode rc=$rc"; fi
rm -f "$TARGET"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
