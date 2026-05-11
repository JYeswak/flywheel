#!/usr/bin/env bash
# tests/idempotency-replay-guard-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/idempotency-replay-guard.sh (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green. TODO markers
# point at per-surface assertions the operator should fill in.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/idempotency-replay-guard.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: bash -n syntax
if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# Test 2: --info envelope (PARTIAL-BYPASS — native rich info/v1 envelope with statuses + output_schema)
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.schema_version == "idempotency-replay-guard.info/v1" and .statuses and .output_schema' >/dev/null; then
  pass "--info emits canonical envelope (native PARTIAL-BYPASS — info/v1 + statuses array + output_schema)"
else fail "--info envelope"; fi

# Test 3: --schema returns valid JSON (SCAFFOLD owns — native lacked)
if "$SCRIPT" --schema 2>/dev/null | jq -e '.schema_version and .command == "schema"' >/dev/null; then
  pass "--schema emits canonical envelope (SCAFFOLD owns — native lacked)"
else fail "--schema envelope"; fi

# Test 4: --examples envelope (PARTIAL-BYPASS — native rich examples/v1 envelope)
if "$SCRIPT" --examples 2>/dev/null | jq -e '.schema_version == "idempotency-replay-guard.examples/v1" and .examples' >/dev/null; then
  pass "--examples emits canonical envelope (native PARTIAL-BYPASS — examples/v1)"
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
"$SCRIPT" validate >/tmp/1hshd-37-test9.json 2>&1
rc=$?
if [[ "$rc" -eq 64 ]] && jq -e '.command == "validate" and .status == "refused" and .reason == "missing_subject"' /tmp/1hshd-37-test9.json >/dev/null 2>&1; then
  pass "validate (bare) refuses with rc=64 + missing_subject envelope"
else fail "validate bare-refusal contract rc=$rc"; fi
rm -f /tmp/1hshd-37-test9.json

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

# Test 14: doctor probes load-bearing sha256/flock/ledger/lock_dir
if "$SCRIPT" doctor --json 2>/dev/null \
   | jq -e '[.checks[].name] | contains(["sha256_hasher_available","ledger_dir_writable","lock_dir_writable","audit_log_dir_writable"])' >/dev/null; then
  pass "doctor probes sha256_hasher (load-bearing) + ledger_dir + lock_dir + audit_log_dir"
else fail "doctor missing load-bearing probes"; fi

# Test 15: validate status full-enum sweep (4 states from native --info .statuses[])
sweep_pass=0
for s in already_completed in_flight not_seen completed; do
  if "$SCRIPT" validate status "$s" 2>/dev/null | jq -e '.status == "ok"' >/dev/null; then
    sweep_pass=$((sweep_pass + 1))
  fi
done
"$SCRIPT" validate status "phantom_status" >/tmp/1hshd-37-test15.json 2>&1
rc=$?
if [[ "$sweep_pass" -eq 4 ]] && [[ "$rc" -eq 1 ]] \
   && jq -e '.status == "reject" and .reason == "not_in_enum"' /tmp/1hshd-37-test15.json >/dev/null 2>&1; then
  pass "validate status full-enum sweep (4 accept + 1 reject; cross-source native --info .statuses[])"
else fail "validate status sweep accept=$sweep_pass/4 reject_rc=$rc"; fi
rm -f /tmp/1hshd-37-test15.json

# Test 16: validate receipt-ref accepts file#L pattern
if "$SCRIPT" validate receipt-ref ".beads/issues.jsonl#L1" 2>/dev/null \
   | jq -e '.subject == "receipt-ref" and .status == "ok"' >/dev/null; then
  pass "validate receipt-ref accepts file#L pattern (.beads/issues.jsonl#L1)"
else fail "validate receipt-ref accept"; fi

# Test 17: validate receipt-ref REJECTS too-short value
"$SCRIPT" validate receipt-ref "ab" >/tmp/1hshd-37-test17.json 2>&1
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.status == "reject" and .reason == "pattern_or_length_mismatch"' /tmp/1hshd-37-test17.json >/dev/null 2>&1; then
  pass "validate receipt-ref rejects too-short value with rc=1 + pattern_or_length_mismatch"
else fail "validate receipt-ref reject rc=$rc"; fi
rm -f /tmp/1hshd-37-test17.json

# Test 18: validate input-mode full-enum sweep — 3 states from native --input/--input-file flags
sweep_pass2=0
for m in text file stdin; do
  if "$SCRIPT" validate input-mode "$m" 2>/dev/null | jq -e '.status == "ok"' >/dev/null; then
    sweep_pass2=$((sweep_pass2 + 1))
  fi
done
if [[ "$sweep_pass2" -eq 3 ]]; then
  pass "validate input-mode full-enum sweep (3 accept; cross-source native --input/--input-file flags)"
else fail "validate input-mode sweep accept=$sweep_pass2/3"; fi

# Test 19: 4-direction fidelity — PARTIAL-BYPASS: native --info/--examples + scaffold --schema/doctor
native_info_ok="false"; native_examples_ok="false"; scaffold_schema_ok="false"; scaffold_doctor_ok="false"
"$SCRIPT" --info --json 2>/dev/null | jq -e '.schema_version == "idempotency-replay-guard.info/v1"' >/dev/null && native_info_ok="true"
"$SCRIPT" --examples 2>/dev/null | jq -e '.schema_version == "idempotency-replay-guard.examples/v1"' >/dev/null && native_examples_ok="true"
"$SCRIPT" --schema 2>/dev/null | jq -e '.command == "schema"' >/dev/null && scaffold_schema_ok="true"
"$SCRIPT" doctor --json 2>/dev/null | jq -e '.command == "doctor" and (.checks | length) >= 5' >/dev/null && scaffold_doctor_ok="true"
if [[ "$native_info_ok" == "true" && "$native_examples_ok" == "true" && "$scaffold_schema_ok" == "true" && "$scaffold_doctor_ok" == "true" ]]; then
  pass "4-direction fidelity (native --info+--examples both preserved + scaffold --schema/doctor active) — PARTIAL-BYPASS intact"
else fail "4-direction fidelity native_info=$native_info_ok native_examples=$native_examples_ok scaffold_schema=$scaffold_schema_ok scaffold_doctor=$scaffold_doctor_ok"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
