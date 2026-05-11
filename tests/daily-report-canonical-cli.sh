#!/usr/bin/env bash
# tests/daily-report-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/daily-report.sh (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green. TODO markers
# point at per-surface assertions the operator should fill in.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/daily-report.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: bash -n syntax
if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# Test 2: --info native PASSTHRU envelope (PARTIAL-BYPASS — flag form goes
# to native python; calibrated per feedback_calibrate_test_to_actual_contract
# META-RULE 2026-05-09)
if "$SCRIPT" --info 2>/dev/null | jq -e '.version == "daily-report.v1" and .script' >/dev/null; then
  pass "--info emits native PASSTHRU envelope (.version + .script)"
else fail "--info native envelope"; fi

# Test 3: --schema native PASSTHRU envelope (full JSON-Schema for daily-report
# result envelope; richer than scaffold per-surface schemas)
if "$SCRIPT" --schema 2>/dev/null | jq -e '.["$schema"] and .title == "flywheel daily report result"' >/dev/null; then
  pass "--schema emits native PASSTHRU JSON-Schema (.title == flywheel daily report result)"
else fail "--schema native envelope"; fi

# Test 4: --examples native PASSTHRU (emits text examples lines, not canonical
# envelope; calibrated per actual native behavior)
if "$SCRIPT" --examples 2>/dev/null | grep -q -- '--repo'; then
  pass "--examples emits native PASSTHRU example invocations"
else fail "--examples native envelope"; fi

# Test 5: doctor scaffold envelope (NOT bypassed — verb form goes scaffold)
if "$SCRIPT" doctor --json 2>/dev/null | jq -e '.command == "doctor" and (.checks | length >= 5)' >/dev/null; then
  pass "doctor emits scaffold envelope with >=5 checks"
else fail "doctor envelope"; fi

# Test 6: health envelope (scaffold)
if "$SCRIPT" health --json 2>/dev/null | jq -e '.command == "health"' >/dev/null; then
  pass "health emits scaffold envelope"
else fail "health envelope"; fi

# Test 7: repair --dry-run envelope (scaffold; real scope per fillin contract)
if "$SCRIPT" repair --scope scratch_dir --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .mode == "dry_run" and .status == "ok"' >/dev/null; then
  pass "repair --dry-run emits scaffold envelope (real scope)"
else fail "repair --dry-run envelope"; fi

# Test 8: repair --apply without --idempotency-key REFUSES (rc=3)
"$SCRIPT" repair --scope scratch_dir --apply --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 3 ]]; then
  pass "repair --apply without --idempotency-key returns rc=3 (canonical refusal)"
else
  fail "repair --apply rc=$rc (expected 3)"
fi

# Test 9: validate envelope (bare validate refuses with rc=64 per actual
# contract; calibrated per feedback_calibrate_test_to_actual_contract META-RULE)
"$SCRIPT" validate >/tmp/5ke66-6-test9.json 2>&1
rc=$?
if [[ "$rc" -eq 64 ]] && jq -e '.command == "validate" and .status == "refused" and .reason == "missing_subject"' /tmp/5ke66-6-test9.json >/dev/null 2>&1; then
  pass "validate (bare) refuses with rc=64 + missing_subject envelope"
else fail "validate bare-refusal contract rc=$rc"; fi
rm -f /tmp/5ke66-6-test9.json

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
# This surface is wzjo9.1.7 PARTIAL-BYPASS: --info/--schema/--examples flags
# route to native python PASSTHRU; verb subcommands route to scaffold.

# Test 14: PARTIAL-BYPASS contract is annotated in the script
if grep -q 'WZJO9.1.7 PARTIAL-BYPASS' "$SCRIPT"; then
  pass "script annotates WZJO9.1.7 PARTIAL-BYPASS pattern (discoverable via grep)"
else fail "PARTIAL-BYPASS annotation missing"; fi

# Test 15: doctor probes load-bearing ntm + daily_report_py + python3
if "$SCRIPT" doctor --json 2>/dev/null \
   | jq -e '[.checks[].name] | contains(["python3_available","ntm_available","daily_report_py_executable"])' >/dev/null; then
  pass "doctor probes python3 + ntm + daily_report_py (load-bearing for this surface)"
else fail "doctor missing load-bearing probes"; fi

# Test 16: validate session-name accepts default (basename of repo)
if "$SCRIPT" validate session-name "flywheel" 2>/dev/null \
   | jq -e '.subject == "session-name" and .status == "ok"' >/dev/null; then
  pass "validate session-name accepts canonical session name (matches default)"
else fail "validate session-name accept"; fi

# Test 17: validate session-name REJECTS uppercase (rc=1)
"$SCRIPT" validate session-name "Flywheel" >/tmp/5ke66-6-test17.json 2>&1
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.status == "reject" and .reason == "pattern_mismatch"' /tmp/5ke66-6-test17.json >/dev/null 2>&1; then
  pass "validate session-name rejects uppercase with rc=1"
else fail "validate session-name uppercase reject rc=$rc"; fi
rm -f /tmp/5ke66-6-test17.json

# Test 18: validate report-path accepts BOTH .md AND .json (matches the
# script's actual report output formats — .md by default, .json via --json)
ALL_OK=1
for EXT in md json; do
  if ! "$SCRIPT" validate report-path "/some/daily.$EXT" 2>/dev/null \
       | jq -e --arg ext "$EXT" '.subject == "report-path" and .status == "ok"' >/dev/null; then
    ALL_OK=0; break
  fi
done
if [[ "$ALL_OK" -eq 1 ]]; then
  pass "validate report-path accepts both .md and .json (matches daily-report.py output formats)"
else fail "validate report-path multi-extension"; fi

# Test 19: PARTIAL-BYPASS preserved — --info still goes to native, NOT scaffold
# (functional check: native emits .version + .script; scaffold would emit .command)
if "$SCRIPT" --info 2>/dev/null | jq -e '.version == "daily-report.v1" and (has("command") | not)' >/dev/null; then
  pass "PARTIAL-BYPASS preserved — --info routes to native (no .command field)"
else fail "PARTIAL-BYPASS broken (--info hit scaffold)"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
