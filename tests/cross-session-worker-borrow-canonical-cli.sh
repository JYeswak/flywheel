#!/usr/bin/env bash
# tests/cross-session-worker-borrow-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/cross-session-worker-borrow.sh (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green. TODO markers
# point at per-surface assertions the operator should fill in.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/cross-session-worker-borrow.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: bash -n syntax
if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# Test 2: --info envelope is valid JSON with schema_version (native uses .mode field, not .command)
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.schema_version and .mode == "info"' >/dev/null; then
  pass "--info emits canonical envelope (native .mode shape, NUANCED-PARTIAL-BYPASS)"
else fail "--info envelope"; fi

# Test 3: --schema returns valid JSON (native uses .mode field, not .command)
if "$SCRIPT" --schema 2>/dev/null | jq -e '.schema_version and .mode == "schema"' >/dev/null; then
  pass "--schema emits canonical envelope (native .mode shape, NUANCED-PARTIAL-BYPASS)"
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
if "$SCRIPT" repair --scope roster_dir --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .mode == "dry_run" and .status == "ok"' >/dev/null; then
  pass "repair --dry-run emits canonical envelope (real scope roster_dir)"
else fail "repair --dry-run envelope"; fi

# Test 8: repair --apply without --idempotency-key REFUSES (rc=3)
"$SCRIPT" repair --scope roster_dir --apply --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 3 ]]; then
  pass "repair --apply without --idempotency-key returns rc=3 (canonical refusal)"
else
  fail "repair --apply rc=$rc (expected 3)"
fi

# Test 9: validate envelope (bare validate refuses with rc=64; calibrated)
"$SCRIPT" validate >/tmp/1hshd-22-test9.json 2>&1
rc=$?
if [[ "$rc" -eq 64 ]] && jq -e '.command == "validate" and .status == "refused" and .reason == "missing_subject"' /tmp/1hshd-22-test9.json >/dev/null 2>&1; then
  pass "validate (bare) refuses with rc=64 + missing_subject envelope"
else fail "validate bare-refusal contract rc=$rc"; fi
rm -f /tmp/1hshd-22-test9.json

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

# Test 14: doctor probes load-bearing ntm_executable + ledger paths
if "$SCRIPT" doctor --json 2>/dev/null \
   | jq -e '[.checks[].name] | contains(["ntm_executable","roster_readable","ledger_dir_writable","audit_log_dir_writable"])' >/dev/null; then
  pass "doctor probes ntm_executable + ledger dirs + audit log (load-bearing for borrow protocol)"
else fail "doctor missing ntm/ledger probes"; fi

# Test 15: schema state_machine enumerates all 10 borrow states
if "$SCRIPT" --schema 2>/dev/null \
   | jq -e '(.state_machine.states | length) == 10
            and (.state_machine.states | contains(["requested","approved","in_use","released","refused","timed_out","declined","reclaimed_pre_approve","reclaimed_in_use","worker_died"]))' >/dev/null; then
  pass "--schema state_machine.states enumerates all 10 borrow states"
else fail "--schema state_machine missing or incomplete"; fi

# Test 16: validate borrow-state full-enum sweep — accept 10/10 valid states, reject 1 invalid
sweep_pass=0
for state in requested approved in_use released refused timed_out declined reclaimed_pre_approve reclaimed_in_use worker_died; do
  if "$SCRIPT" validate borrow-state "$state" 2>/dev/null | jq -e '.status == "ok"' >/dev/null; then
    sweep_pass=$((sweep_pass + 1))
  fi
done
"$SCRIPT" validate borrow-state "phantom_state" >/tmp/1hshd-22-test16.json 2>&1
rc=$?
if [[ "$sweep_pass" -eq 10 ]] && [[ "$rc" -eq 1 ]] \
   && jq -e '.status == "reject" and .reason == "not_in_enum"' /tmp/1hshd-22-test16.json >/dev/null 2>&1; then
  pass "validate borrow-state full-enum sweep (10 accept + 1 reject; cross-source with --schema)"
else fail "validate borrow-state sweep accept=$sweep_pass/10 reject_rc=$rc"; fi
rm -f /tmp/1hshd-22-test16.json

# Test 17: validate ttl-minutes accepts default 60 (matches --ttl-minutes arg semantic)
if "$SCRIPT" validate ttl-minutes "60" 2>/dev/null \
   | jq -e '.subject == "ttl-minutes" and .status == "ok"' >/dev/null; then
  pass "validate ttl-minutes accepts default 60 (matches --ttl-minutes contract)"
else fail "validate ttl-minutes 60 accept"; fi

# Test 18: validate ttl-minutes REJECTS out-of-range (rc=1 + out_of_range_or_not_integer)
"$SCRIPT" validate ttl-minutes "9999" >/tmp/1hshd-22-test18.json 2>&1
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.status == "reject" and .reason == "out_of_range_or_not_integer"' /tmp/1hshd-22-test18.json >/dev/null 2>&1; then
  pass "validate ttl-minutes rejects 9999 with rc=1 + out_of_range"
else fail "validate ttl-minutes 9999 reject rc=$rc"; fi
rm -f /tmp/1hshd-22-test18.json

# Test 19: 4-direction fidelity — native owns --info, --schema; scaffold owns doctor, repair
# (NUANCED-PARTIAL-BYPASS variant: --info/--schema bypass to native, scaffold verbs unchanged)
native_info_ok="false"; scaffold_doctor_ok="false"
"$SCRIPT" --info --json 2>/dev/null | jq -e '.mode == "info" and .roster_ledger and .borrow_ledger' >/dev/null \
  && native_info_ok="true"
"$SCRIPT" doctor --json 2>/dev/null | jq -e '.command == "doctor" and (.checks | length) >= 5' >/dev/null \
  && scaffold_doctor_ok="true"
if [[ "$native_info_ok" == "true" && "$scaffold_doctor_ok" == "true" ]]; then
  pass "4-direction fidelity (native --info bypassed; scaffold doctor active) — NUANCED-PARTIAL-BYPASS variant intact"
else fail "4-direction fidelity native_info=$native_info_ok scaffold_doctor=$scaffold_doctor_ok"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
