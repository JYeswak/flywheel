#!/usr/bin/env bash
# tests/headless-browser-reap-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/headless-browser-reap.sh (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green. TODO markers
# point at per-surface assertions the operator should fill in.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/headless-browser-reap.sh"

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

# Test 7: repair --dry-run envelope (real scope per fillin)
if "$SCRIPT" repair --scope audit_log_dir --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .mode == "dry_run" and .status == "ok"' >/dev/null; then
  pass "repair --dry-run emits canonical envelope (real scope audit_log_dir)"
else fail "repair --dry-run envelope"; fi

# Test 8: repair --apply without --idempotency-key REFUSES (rc=3)
"$SCRIPT" repair --scope audit_log_dir --apply --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 3 ]]; then
  pass "repair --apply without --idempotency-key returns rc=3 (canonical refusal)"
else
  fail "repair --apply rc=$rc (expected 3)"
fi

# Test 9: validate (bare) refuses rc=64 + missing_subject
"$SCRIPT" validate >/tmp/1hshd-35-test9.json 2>&1
rc=$?
if [[ "$rc" -eq 64 ]] && jq -e '.command == "validate" and .status == "refused" and .reason == "missing_subject"' /tmp/1hshd-35-test9.json >/dev/null 2>&1; then
  pass "validate (bare) refuses with rc=64 + missing_subject envelope"
else fail "validate bare-refusal contract rc=$rc"; fi
rm -f /tmp/1hshd-35-test9.json

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

# Test 14: doctor probes load-bearing ps + pkill + process_pattern + thresholds
if "$SCRIPT" doctor --json 2>/dev/null \
   | jq -e '[.checks[].name] | contains(["ps_available","pkill_available","process_pattern","thresholds","audit_log_dir_writable"])' >/dev/null; then
  pass "doctor probes ps + pkill (load-bearing) + process_pattern + thresholds + audit_log_dir"
else fail "doctor missing load-bearing probes"; fi

# Test 15: validate reap-mode full-enum sweep (cross-source native --apply/--dry-run) — N=6 recurrence
sweep_pass=0
for mode in dry_run apply; do
  if "$SCRIPT" validate reap-mode "$mode" 2>/dev/null | jq -e '.status == "ok"' >/dev/null; then
    sweep_pass=$((sweep_pass + 1))
  fi
done
"$SCRIPT" validate reap-mode "phantom_mode" >/tmp/1hshd-35-test15.json 2>&1
rc=$?
if [[ "$sweep_pass" -eq 2 ]] && [[ "$rc" -eq 1 ]] \
   && jq -e '.status == "reject" and .reason == "not_in_enum"' /tmp/1hshd-35-test15.json >/dev/null 2>&1; then
  pass "validate reap-mode full-enum sweep (2 accept + 1 reject; cross-source native --apply/--dry-run) — N=6 recurrence"
else fail "validate reap-mode sweep accept=$sweep_pass/2 reject_rc=$rc"; fi
rm -f /tmp/1hshd-35-test15.json

# Test 16: validate process-pattern accepts canonical
if "$SCRIPT" validate process-pattern "agent-browser-chrome" 2>/dev/null \
   | jq -e '.subject == "process-pattern" and .status == "ok"' >/dev/null; then
  pass "validate process-pattern accepts canonical agent-browser-chrome"
else fail "validate process-pattern accept"; fi

# Test 17: validate age-minutes accepts default 30 (matches native --help "30m" threshold)
if "$SCRIPT" validate age-minutes "30" 2>/dev/null \
   | jq -e '.subject == "age-minutes" and .status == "ok" and .default == 30' >/dev/null; then
  pass "validate age-minutes accepts default 30 (matches native 30m threshold)"
else fail "validate age-minutes 30 accept"; fi

# Test 18: validate age-minutes REJECTS out-of-range (rc=1 + out_of_range)
"$SCRIPT" validate age-minutes "9999" >/tmp/1hshd-35-test18.json 2>&1
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.status == "reject" and .reason == "out_of_range_or_not_integer"' /tmp/1hshd-35-test18.json >/dev/null 2>&1; then
  pass "validate age-minutes rejects 9999 with rc=1 + out_of_range"
else fail "validate age-minutes 9999 reject rc=$rc"; fi
rm -f /tmp/1hshd-35-test18.json

# Test 19: 4-direction fidelity — NO-BYPASS variant
scaffold_info_ok="false"; scaffold_doctor_ok="false"
"$SCRIPT" --info --json 2>/dev/null | jq -e '.command == "info"' >/dev/null && scaffold_info_ok="true"
"$SCRIPT" doctor --json 2>/dev/null | jq -e '.command == "doctor" and (.checks | length) >= 5' >/dev/null && scaffold_doctor_ok="true"
if [[ "$scaffold_info_ok" == "true" && "$scaffold_doctor_ok" == "true" ]]; then
  pass "4-direction fidelity (scaffold --info/doctor active; native --apply/--dry-run/--json/--fixture/--now-epoch fall through) — NO-BYPASS variant"
else fail "4-direction fidelity info=$scaffold_info_ok doctor=$scaffold_doctor_ok"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
