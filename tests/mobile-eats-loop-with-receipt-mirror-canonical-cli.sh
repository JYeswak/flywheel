#!/usr/bin/env bash
# tests/mobile-eats-loop-with-receipt-mirror-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/mobile-eats-loop-with-receipt-mirror.sh (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green. TODO markers
# point at per-surface assertions the operator should fill in.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/mobile-eats-loop-with-receipt-mirror.sh"

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
if "$SCRIPT" repair --scope out_dir --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .mode == "dry_run" and .status == "ok"' >/dev/null; then
  pass "repair --dry-run emits canonical envelope (real scope out_dir)"
else fail "repair --dry-run envelope"; fi

# Test 8: repair --apply without --idempotency-key REFUSES (rc=3)
"$SCRIPT" repair --scope out_dir --apply --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 3 ]]; then
  pass "repair --apply without --idempotency-key returns rc=3 (canonical refusal)"
else
  fail "repair --apply rc=$rc (expected 3)"
fi

# Test 9: validate envelope (bare validate refuses with rc=64; calibrated)
"$SCRIPT" validate >/tmp/5ke66-13-test9.json 2>&1
rc=$?
if [[ "$rc" -eq 64 ]] && jq -e '.command == "validate" and .status == "refused" and .reason == "missing_subject"' /tmp/5ke66-13-test9.json >/dev/null 2>&1; then
  pass "validate (bare) refuses with rc=64 + missing_subject envelope"
else fail "validate bare-refusal contract rc=$rc"; fi
rm -f /tmp/5ke66-13-test9.json

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

# Test 14: doctor probes load-bearing product_tick + bridge + jsonl_append_lib
if "$SCRIPT" doctor --json 2>/dev/null \
   | jq -e '[.checks[].name] | contains(["product_tick_executable","bridge_executable","jsonl_append_lib_sourceable"])' >/dev/null; then
  pass "doctor probes product_tick + bridge + jsonl_append_lib (load-bearing for receipt mirror)"
else fail "doctor missing load-bearing probes"; fi

# Test 15: validate receipt-event accepts BOTH canonical events
ALL_OK=1
for E in receipt_mirrored receipt_mirror_failed; do
  if ! "$SCRIPT" validate receipt-event "$E" 2>/dev/null \
       | jq -e --arg v "$E" '.subject == "receipt-event" and .status == "ok" and .value == $v' >/dev/null; then
    ALL_OK=0; break
  fi
done
if [[ "$ALL_OK" -eq 1 ]]; then
  pass "validate receipt-event accepts both canonical events (receipt_mirrored + receipt_mirror_failed)"
else fail "validate receipt-event full-enum sweep"; fi

# Test 16: validate receipt-event REJECTS unknown event (rc=1 + valid_events)
"$SCRIPT" validate receipt-event "unknown_event" >/tmp/5ke66-13-test16.json 2>&1
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.status == "reject" and .reason == "not_in_enum" and (.valid_events | length == 2)' /tmp/5ke66-13-test16.json >/dev/null 2>&1; then
  pass "validate receipt-event rejects unknown_event with rc=1 + valid_events enumeration"
else fail "validate receipt-event reject rc=$rc"; fi
rm -f /tmp/5ke66-13-test16.json

# Test 17: validate exit-code accepts boundary values (0 + 255)
if "$SCRIPT" validate exit-code "0" 2>/dev/null | jq -e '.status == "ok" and .value == 0' >/dev/null \
   && "$SCRIPT" validate exit-code "255" 2>/dev/null | jq -e '.status == "ok" and .value == 255' >/dev/null; then
  pass "validate exit-code accepts both range boundaries (0 and 255)"
else fail "validate exit-code boundary accept"; fi

# Test 18: validate exit-code REJECTS 256 (out of range; rc=1)
"$SCRIPT" validate exit-code "256" >/tmp/5ke66-13-test18.json 2>&1
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.status == "reject" and .reason == "out_of_range_or_not_integer"' /tmp/5ke66-13-test18.json >/dev/null 2>&1; then
  pass "validate exit-code rejects 256 (out of [0,255]) with rc=1"
else fail "validate exit-code 256 reject rc=$rc"; fi
rm -f /tmp/5ke66-13-test18.json

# Test 19: repair has THREE scopes (out_dir + log_dir + audit_log_dir) — this
# surface uses 3-scope pattern because it has both production state dir
# AND a separate event log dir AND the canonical audit log dir
SCOPES_LISTED="$("$SCRIPT" repair --scope none --dry-run 2>/dev/null | jq -r '.valid_scopes[]?' 2>/dev/null | sort | tr '\n' ',' | sed 's/,$//')"
if [[ "$SCOPES_LISTED" == "audit_log_dir,log_dir,out_dir" ]]; then
  pass "repair has 3 distinct scopes (out_dir + log_dir + audit_log_dir per dual-state-+-event-log pattern)"
else fail "repair scopes drift: got '$SCOPES_LISTED'"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
