#!/usr/bin/env bash
# tests/fuckup-coverage-join-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/fuckup-coverage-join.sh (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green. TODO markers
# point at per-surface assertions the operator should fill in.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/fuckup-coverage-join.sh"

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

# Test 3: --schema returns valid JSON (PARTIAL-BYPASS — native shape: joins + output_fields, no .command)
if "$SCRIPT" --schema 2>/dev/null | jq -e '.schema_version and .joins and .output_fields' >/dev/null; then
  pass "--schema emits canonical envelope (native PARTIAL-BYPASS shape: joins + output_fields)"
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
"$SCRIPT" validate >/tmp/1hshd-33-test9.json 2>&1
rc=$?
if [[ "$rc" -eq 64 ]] && jq -e '.command == "validate" and .status == "refused" and .reason == "missing_subject"' /tmp/1hshd-33-test9.json >/dev/null 2>&1; then
  pass "validate (bare) refuses with rc=64 + missing_subject envelope"
else fail "validate bare-refusal contract rc=$rc"; fi
rm -f /tmp/1hshd-33-test9.json

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

# Test 14: doctor probes load-bearing fuckup_log + 5 join targets
if "$SCRIPT" doctor --json 2>/dev/null \
   | jq -e '[.checks[].name] | contains(["fuckup_log_readable","memory_dir_present","incidents_md_present","canonical_l_rule_dir_present","audit_log_dir_writable"])' >/dev/null; then
  pass "doctor probes fuckup_log (load-bearing) + 3 of 5 join layers (memory/incidents/canonical L-rule)"
else fail "doctor missing load-bearing probes"; fi

# Test 15: validate join-layer full-enum sweep (5 layers — cross-source native --schema .joins[])
sweep_pass=0
for layer in memory incident canonical_l_rule probe dashboard; do
  if "$SCRIPT" validate join-layer "$layer" 2>/dev/null | jq -e '.status == "ok"' >/dev/null; then
    sweep_pass=$((sweep_pass + 1))
  fi
done
"$SCRIPT" validate join-layer "phantom_layer" >/tmp/1hshd-33-test15.json 2>&1
rc=$?
if [[ "$sweep_pass" -eq 5 ]] && [[ "$rc" -eq 1 ]] \
   && jq -e '.status == "reject" and .reason == "not_in_enum"' /tmp/1hshd-33-test15.json >/dev/null 2>&1; then
  pass "validate join-layer full-enum sweep (5 accept + 1 reject; cross-source native --schema .joins[])"
else fail "validate join-layer sweep accept=$sweep_pass/5 reject_rc=$rc"; fi
rm -f /tmp/1hshd-33-test15.json

# Test 16: validate fuckup-class accepts canonical snake_case
if "$SCRIPT" validate fuckup-class "stuck_pane_detector_freeze" 2>/dev/null \
   | jq -e '.subject == "fuckup-class" and .status == "ok"' >/dev/null; then
  pass "validate fuckup-class accepts canonical snake_case"
else fail "validate fuckup-class accept"; fi

# Test 17: validate fuckup-class REJECTS non-snake_case
"$SCRIPT" validate fuckup-class "BadClass" >/tmp/1hshd-33-test17.json 2>&1
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.status == "reject" and .reason == "pattern_mismatch"' /tmp/1hshd-33-test17.json >/dev/null 2>&1; then
  pass "validate fuckup-class rejects PascalCase with rc=1 + pattern_mismatch"
else fail "validate fuckup-class reject rc=$rc"; fi
rm -f /tmp/1hshd-33-test17.json

# Test 18: validate limit accepts in-range + rejects out-of-range (cross-source native --limit)
ok="false"; bad_rc=0
"$SCRIPT" validate limit "100" 2>/dev/null | jq -e '.status == "ok"' >/dev/null && ok="true"
"$SCRIPT" validate limit "99999" >/tmp/1hshd-33-test18.json 2>&1; bad_rc=$?
if [[ "$ok" == "true" && "$bad_rc" -eq 1 ]] && jq -e '.status == "reject" and .reason == "out_of_range_or_not_integer"' /tmp/1hshd-33-test18.json >/dev/null 2>&1; then
  pass "validate limit accepts 100 + rejects 99999 (cross-source native --limit; range [1,10000])"
else fail "validate limit ok=$ok bad_rc=$bad_rc"; fi
rm -f /tmp/1hshd-33-test18.json

# Test 19: 4-direction fidelity — scaffold owns --info + doctor verb; native --schema preserved (joins+output_fields)
scaffold_info_ok="false"; scaffold_doctor_ok="false"; native_schema_ok="false"
"$SCRIPT" --info --json 2>/dev/null | jq -e '.command == "info"' >/dev/null && scaffold_info_ok="true"
"$SCRIPT" doctor --json 2>/dev/null | jq -e '.command == "doctor" and (.checks | length) >= 5' >/dev/null && scaffold_doctor_ok="true"
"$SCRIPT" --schema 2>/dev/null | jq -e '.joins and .output_fields' >/dev/null && native_schema_ok="true"
if [[ "$scaffold_info_ok" == "true" && "$scaffold_doctor_ok" == "true" && "$native_schema_ok" == "true" ]]; then
  pass "4-direction fidelity (scaffold --info/doctor + native --schema joins+output_fields preserved) — PARTIAL-BYPASS intact"
else fail "4-direction fidelity info=$scaffold_info_ok doctor=$scaffold_doctor_ok native_schema=$native_schema_ok"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
