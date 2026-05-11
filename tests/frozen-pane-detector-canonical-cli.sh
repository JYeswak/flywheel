#!/usr/bin/env bash
# tests/frozen-pane-detector-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/frozen-pane-detector.sh (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green. TODO markers
# point at per-surface assertions the operator should fill in.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/frozen-pane-detector.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: bash -n syntax
if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# Test 2: --info envelope is valid JSON (PARTIAL-BYPASS — native shape: schema_version=v2, mode=info, native_surface)
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.schema_version == "frozen-pane-detector.v2" and .mode == "info" and .native_surface' >/dev/null; then
  pass "--info emits canonical envelope (native PARTIAL-BYPASS shape: v2 + mode + native_surface)"
else fail "--info envelope"; fi

# Test 3: --schema returns valid JSON (PARTIAL-BYPASS — native shape: properties)
if "$SCRIPT" --schema 2>/dev/null | jq -e '.schema_version == "frozen-pane-detector.v2" and .properties' >/dev/null; then
  pass "--schema emits canonical envelope (native PARTIAL-BYPASS shape: v2 + properties)"
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
"$SCRIPT" validate >/tmp/1hshd-32-test9.json 2>&1
rc=$?
if [[ "$rc" -eq 64 ]] && jq -e '.command == "validate" and .status == "refused" and .reason == "missing_subject"' /tmp/1hshd-32-test9.json >/dev/null 2>&1; then
  pass "validate (bare) refuses with rc=64 + missing_subject envelope"
else fail "validate bare-refusal contract rc=$rc"; fi
rm -f /tmp/1hshd-32-test9.json

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

# Test 14: doctor probes load-bearing ntm_executable + tmux
if "$SCRIPT" doctor --json 2>/dev/null \
   | jq -e '[.checks[].name] | contains(["ntm_executable","tmux_available","audit_log_dir_writable"])' >/dev/null; then
  pass "doctor probes ntm_executable (load-bearing — wraps ntm grep/errors/activity/wait) + tmux + audit_log_dir"
else fail "doctor missing load-bearing probes"; fi

# Test 15: validate recovery-mode full-enum sweep — 2 accept + 1 reject (cross-source native --auto-recover)
sweep_pass=0
for mode in report_only auto_recover; do
  if "$SCRIPT" validate recovery-mode "$mode" 2>/dev/null | jq -e '.status == "ok"' >/dev/null; then
    sweep_pass=$((sweep_pass + 1))
  fi
done
"$SCRIPT" validate recovery-mode "phantom_mode" >/tmp/1hshd-32-test15.json 2>&1
rc=$?
if [[ "$sweep_pass" -eq 2 ]] && [[ "$rc" -eq 1 ]] \
   && jq -e '.status == "reject" and .reason == "not_in_enum"' /tmp/1hshd-32-test15.json >/dev/null 2>&1; then
  pass "validate recovery-mode full-enum sweep (2 accept + 1 reject; cross-source native --auto-recover)"
else fail "validate recovery-mode sweep accept=$sweep_pass/2 reject_rc=$rc"; fi
rm -f /tmp/1hshd-32-test15.json

# Test 16: validate session-name accepts canonical pattern
if "$SCRIPT" validate session-name "flywheel" 2>/dev/null \
   | jq -e '.subject == "session-name" and .status == "ok"' >/dev/null; then
  pass "validate session-name accepts canonical pattern"
else fail "validate session-name accept"; fi

# Test 17: validate ntm-bin accepts executable
if [[ -x /Users/josh/.local/bin/ntm ]] && "$SCRIPT" validate ntm-bin "/Users/josh/.local/bin/ntm" 2>/dev/null \
   | jq -e '.subject == "ntm-bin" and .status == "ok"' >/dev/null; then
  pass "validate ntm-bin accepts executable ntm binary"
else fail "validate ntm-bin accept"; fi

# Test 18: PARTIAL-BYPASS — native --doctor and --health both still emit native envelope (v2 schema, mode field, source_health)
native_doctor_ok="false"; native_health_ok="false"
"$SCRIPT" --doctor --json 2>/dev/null | jq -e '.schema_version == "frozen-pane-detector.v2" and .mode == "doctor" and .source_health' >/dev/null && native_doctor_ok="true"
"$SCRIPT" --health 2>/dev/null | jq -e '.schema_version == "frozen-pane-detector.v2" and .source_health' >/dev/null && native_health_ok="true"
if [[ "$native_doctor_ok" == "true" && "$native_health_ok" == "true" ]]; then
  pass "PARTIAL-BYPASS: native --doctor + --health both preserved (legacy v2 envelopes with source_health)"
else fail "PARTIAL-BYPASS native_doctor=$native_doctor_ok native_health=$native_health_ok"; fi

# Test 19: 4-direction fidelity — native --info/--schema/--doctor/--health bypass; scaffold owns --examples + doctor verb + validate
scaffold_examples_ok="false"; scaffold_doctor_verb_ok="false"; native_info_ok="false"
"$SCRIPT" --examples --json 2>/dev/null | jq -e '.command == "examples"' >/dev/null && scaffold_examples_ok="true"
"$SCRIPT" doctor --json 2>/dev/null | jq -e '.command == "doctor" and (.checks | length) >= 5' >/dev/null && scaffold_doctor_verb_ok="true"
"$SCRIPT" --info --json 2>/dev/null | jq -e '.schema_version == "frozen-pane-detector.v2"' >/dev/null && native_info_ok="true"
if [[ "$scaffold_examples_ok" == "true" && "$scaffold_doctor_verb_ok" == "true" && "$native_info_ok" == "true" ]]; then
  pass "4-direction fidelity (scaffold --examples/doctor verb + native --info v2 preserved) — PARTIAL-BYPASS intact"
else fail "4-direction fidelity examples=$scaffold_examples_ok doctor_verb=$scaffold_doctor_verb_ok native_info=$native_info_ok"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
