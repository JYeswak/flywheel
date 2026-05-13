#!/usr/bin/env bash
# tests/cross-repo-trauma-aggregator-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/cross-repo-trauma-aggregator.sh (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green. TODO markers
# point at per-surface assertions the operator should fill in.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/cross-repo-trauma-aggregator.sh"

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
if "$SCRIPT" repair --scope output_dir --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .mode == "dry_run" and .status == "ok"' >/dev/null; then
  pass "repair --dry-run emits canonical envelope (real scope output_dir)"
else fail "repair --dry-run envelope"; fi

# Test 8: repair --apply without --idempotency-key REFUSES (rc=3)
"$SCRIPT" repair --scope output_dir --apply --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 3 ]]; then
  pass "repair --apply without --idempotency-key returns rc=3 (canonical refusal)"
else
  fail "repair --apply rc=$rc (expected 3)"
fi

# Test 9: validate envelope (bare validate refuses with rc=64; calibrated)
"$SCRIPT" validate >/tmp/1hshd-21-test9.json 2>&1
rc=$?
if [[ "$rc" -eq 64 ]] && jq -e '.command == "validate" and .status == "refused" and .reason == "missing_subject"' /tmp/1hshd-21-test9.json >/dev/null 2>&1; then
  pass "validate (bare) refuses with rc=64 + missing_subject envelope"
else fail "validate bare-refusal contract rc=$rc"; fi
rm -f /tmp/1hshd-21-test9.json

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

# Test 14: doctor probes default roots (~/Developer + ~/Desktop/Projects)
if "$SCRIPT" doctor --json 2>/dev/null \
   | jq -e '[.checks[].name] | contains(["default_root1_exists","default_root2_exists","output_dir_writable"])' >/dev/null; then
  pass "doctor probes default roots + output_dir (load-bearing for aggregation)"
else fail "doctor missing default roots/output_dir probes"; fi

# Test 15: validate root-path accepts absolute path (5th occurrence of pattern)
if "$SCRIPT" validate root-path "$HOME/Developer" 2>/dev/null \
   | jq -e '.subject == "root-path" and .status == "ok"' >/dev/null; then
  pass "validate root-path accepts absolute (5th occurrence of fleet absolute-path validator pattern)"
else fail "validate root-path absolute accept"; fi

# Test 16: validate root-path REJECTS relative path (rc=1 + not_absolute_path)
"$SCRIPT" validate root-path "relative/path" >/tmp/1hshd-21-test16.json 2>&1
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.status == "reject" and .reason == "not_absolute_path"' /tmp/1hshd-21-test16.json >/dev/null 2>&1; then
  pass "validate root-path rejects relative with rc=1 + not_absolute_path"
else fail "validate root-path reject rc=$rc"; fi
rm -f /tmp/1hshd-21-test16.json

# Test 17: validate output-path accepts .jsonl (matches default global-trauma-log.jsonl)
if "$SCRIPT" validate output-path "/some/dir/log.jsonl" 2>/dev/null \
   | jq -e '.subject == "output-path" and .status == "ok"' >/dev/null; then
  pass "validate output-path accepts .jsonl (matches default global-trauma-log.jsonl)"
else fail "validate output-path .jsonl accept"; fi

# Test 18: validate output-path REJECTS .txt (rc=1 + unsupported_extension)
"$SCRIPT" validate output-path "/some/dir/log.txt" >/tmp/1hshd-21-test18.json 2>&1
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.status == "reject" and .reason == "unsupported_extension"' /tmp/1hshd-21-test18.json >/dev/null 2>&1; then
  pass "validate output-path rejects .txt with rc=1 + unsupported_extension"
else fail "validate output-path .txt reject rc=$rc"; fi
rm -f /tmp/1hshd-21-test18.json

# Test 19: 5TH occurrence of absolute-path validator pattern is documented in
# the topic help — fleet-wide canonical pattern. Strong META-RULE candidate.
if "$SCRIPT" help validate 2>/dev/null | grep -q '5th occurrence'; then
  pass "topic help cites 5th occurrence of fleet absolute-path validator pattern (canonical)"
else fail "topic help missing 5th-occurrence citation"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
