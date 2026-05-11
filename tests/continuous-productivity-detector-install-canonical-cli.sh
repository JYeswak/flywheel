#!/usr/bin/env bash
# tests/continuous-productivity-detector-install-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/continuous-productivity-detector-install.sh (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green. TODO markers
# point at per-surface assertions the operator should fill in.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/continuous-productivity-detector-install.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: bash -n syntax
if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# Test 2: --info native PASSTHRU envelope (NUANCED-PARTIAL-BYPASS)
if "$SCRIPT" --info 2>/dev/null | jq -e '.schema_version == "continuous-productivity-detector-install/v1" and .label' >/dev/null; then
  pass "--info emits native PASSTHRU envelope (continuous-productivity-detector-install/v1 + .label)"
else fail "--info native envelope"; fi

# Test 3: --schema scaffold envelope (NOT bypassed)
if "$SCRIPT" --schema 2>/dev/null | jq -e '.command == "schema"' >/dev/null; then
  pass "--schema emits scaffold envelope (NOT bypassed — native errors)"
else fail "--schema scaffold envelope"; fi

# Test 4: --examples native PASSTHRU (text invocations)
if "$SCRIPT" --examples 2>/dev/null | grep -q 'continuous-productivity-detector-install.sh'; then
  pass "--examples emits native PASSTHRU example invocations"
else fail "--examples native envelope"; fi

# Test 5: doctor scaffold envelope (>=5 named probes)
if "$SCRIPT" doctor --json 2>/dev/null | jq -e '.command == "doctor" and (.checks | length >= 5)' >/dev/null; then
  pass "doctor emits scaffold envelope with >=5 checks"
else fail "doctor envelope"; fi

# Test 6: health envelope (scaffold)
if "$SCRIPT" health --json 2>/dev/null | jq -e '.command == "health"' >/dev/null; then
  pass "health emits scaffold envelope"
else fail "health envelope"; fi

# Test 7: repair --dry-run envelope (real scope)
if "$SCRIPT" repair --scope launch_agents_dir --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .mode == "dry_run" and .status == "ok"' >/dev/null; then
  pass "repair --dry-run emits scaffold envelope (real scope launch_agents_dir)"
else fail "repair --dry-run envelope"; fi

# Test 8: repair --apply without --idempotency-key REFUSES (rc=3)
"$SCRIPT" repair --scope launch_agents_dir --apply --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 3 ]]; then
  pass "repair --apply without --idempotency-key returns rc=3 (canonical refusal)"
else
  fail "repair --apply rc=$rc (expected 3)"
fi

# Test 9: validate envelope (bare validate refuses with rc=64; calibrated)
"$SCRIPT" validate >/tmp/1hshd-18-test9.json 2>&1
rc=$?
if [[ "$rc" -eq 64 ]] && jq -e '.command == "validate" and .status == "refused" and .reason == "missing_subject"' /tmp/1hshd-18-test9.json >/dev/null 2>&1; then
  pass "validate (bare) refuses with rc=64 + missing_subject envelope"
else fail "validate bare-refusal contract rc=$rc"; fi
rm -f /tmp/1hshd-18-test9.json

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

# Test 14: NUANCED-PARTIAL-BYPASS contract is annotated in the script
if grep -q 'NUANCED-PARTIAL-BYPASS' "$SCRIPT"; then
  pass "script annotates NUANCED-PARTIAL-BYPASS variant (4th application)"
else fail "NUANCED-PARTIAL-BYPASS annotation missing"; fi

# Test 15: doctor probes load-bearing python3 + launchctl + detector
if "$SCRIPT" doctor --json 2>/dev/null \
   | jq -e '[.checks[].name] | contains(["python3_available","launchctl_available","detector_executable"])' >/dev/null; then
  pass "doctor probes python3 + launchctl + detector (load-bearing for plist install + launchd bootstrap)"
else fail "doctor missing load-bearing probes"; fi

# Test 16: validate launchd-label accepts canonical ai.zeststream.* form
if "$SCRIPT" validate launchd-label "ai.zeststream.continuous-productivity-detector" 2>/dev/null \
   | jq -e '.subject == "launchd-label" and .status == "ok"' >/dev/null; then
  pass "validate launchd-label accepts canonical ai.zeststream.* (matches \$CPD_LABEL default)"
else fail "validate launchd-label canonical accept"; fi

# Test 17: validate launchd-label REJECTS non-canonical (com.apple.*) with rc=1
"$SCRIPT" validate launchd-label "com.apple.invalid" >/tmp/1hshd-18-test17.json 2>&1
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.status == "reject" and .reason == "pattern_mismatch"' /tmp/1hshd-18-test17.json >/dev/null 2>&1; then
  pass "validate launchd-label rejects non-canonical with rc=1 (5th occurrence of label-pattern check, sister to vs78t)"
else fail "validate launchd-label reject rc=$rc"; fi
rm -f /tmp/1hshd-18-test17.json

# Test 18: validate interval-seconds accepts default 300 + boundary 30/3600
ALL_OK=1
for V in 30 300 3600; do
  if ! "$SCRIPT" validate interval-seconds "$V" 2>/dev/null \
       | jq -e --argjson v "$V" '.status == "ok" and .value == $v' >/dev/null; then
    ALL_OK=0; break
  fi
done
if [[ "$ALL_OK" -eq 1 ]]; then
  pass "validate interval-seconds accepts boundary + default values (30/300/3600)"
else fail "validate interval-seconds boundary accept"; fi

# Test 19: validate interval-seconds REJECTS 10 (below 30s minimum) with rc=1
"$SCRIPT" validate interval-seconds "10" >/tmp/1hshd-18-test19.json 2>&1
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.status == "reject" and .reason == "out_of_range_or_not_integer"' /tmp/1hshd-18-test19.json >/dev/null 2>&1; then
  pass "validate interval-seconds rejects 10 (below [30,3600] range) with rc=1"
else fail "validate interval-seconds reject rc=$rc"; fi
rm -f /tmp/1hshd-18-test19.json

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
