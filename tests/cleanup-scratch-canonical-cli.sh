#!/usr/bin/env bash
# tests/cleanup-scratch-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/cleanup-scratch.sh (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green. TODO markers
# point at per-surface assertions the operator should fill in.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/cleanup-scratch.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: bash -n syntax
if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# Test 2: --info native PASSTHRU envelope (SELECTIVE-FLAG-BYPASS)
if "$SCRIPT" --info 2>/dev/null | jq -e '.schema_version == "scratch-cleanup/v1" and .name == "flywheel-cleanup-scratch"' >/dev/null; then
  pass "--info emits native PASSTHRU envelope (scratch-cleanup/v1 + .name)"
else fail "--info native envelope"; fi

# Test 3: --schema scaffold envelope (NOT bypassed — native treats --schema
# as path arg; scaffold owns the flag form)
if "$SCRIPT" --schema 2>/dev/null | jq -e '.command == "schema"' >/dev/null; then
  pass "--schema emits scaffold envelope (NOT bypassed — native treats as path arg)"
else fail "--schema scaffold envelope"; fi

# Test 4: --examples scaffold envelope (NOT bypassed — same reason as --schema)
if "$SCRIPT" --examples --json 2>/dev/null | jq -e '.command == "examples"' >/dev/null; then
  pass "--examples emits scaffold envelope (NOT bypassed — native treats as path arg)"
else fail "--examples scaffold envelope"; fi

# Test 5: doctor BYPASSED to native (.command=doctor + .subsystems with
# script + python + jq probes)
if "$SCRIPT" doctor 2>/dev/null | jq -e '.command == "doctor" and .subsystems.script and .subsystems.python and .subsystems.jq' >/dev/null; then
  pass "doctor BYPASSED to native (subsystems.script + .python + .jq)"
else fail "doctor native envelope"; fi

# Test 6: health BYPASSED to native (.command=health)
if "$SCRIPT" health 2>/dev/null | jq -e '.command == "health"' >/dev/null; then
  pass "health BYPASSED to native (.command=health)"
else fail "health native envelope"; fi

# Test 7: repair --dry-run scaffold envelope (real scope; NOT bypassed)
if "$SCRIPT" repair --scope audit_log_dir --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .mode == "dry_run" and .status == "ok"' >/dev/null; then
  pass "repair --dry-run emits scaffold envelope (real scope audit_log_dir)"
else fail "repair --dry-run envelope"; fi

# Test 8: repair --apply without --idempotency-key REFUSES (rc=3)
"$SCRIPT" repair --scope audit_log_dir --apply --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 3 ]]; then
  pass "repair --apply without --idempotency-key returns rc=3 (canonical refusal)"
else
  fail "repair --apply rc=$rc (expected 3)"
fi

# Test 9: validate envelope (bare validate refuses with rc=64; calibrated)
"$SCRIPT" validate >/tmp/1hshd-13-test9.json 2>&1
rc=$?
if [[ "$rc" -eq 64 ]] && jq -e '.command == "validate" and .status == "refused" and .reason == "missing_subject"' /tmp/1hshd-13-test9.json >/dev/null 2>&1; then
  pass "validate (bare) refuses with rc=64 + missing_subject envelope"
else fail "validate bare-refusal contract rc=$rc"; fi
rm -f /tmp/1hshd-13-test9.json

# Test 10: audit envelope
if "$SCRIPT" audit --json 2>/dev/null | jq -e '.command == "audit"' >/dev/null; then
  pass "audit emits canonical envelope"
else fail "audit envelope"; fi

# Test 11: why with id BYPASSED to native — native why expects subject like
# `path-policy`; verify native canonical envelope returned
if "$SCRIPT" why path-policy 2>/dev/null | jq -e '.command == "why" and .subject == "path-policy"' >/dev/null; then
  pass "why BYPASSED to native (.command=why + .subject=path-policy)"
else fail "why native envelope"; fi

# Test 12: help <topic> returns text (intercepted only with topic arg)
if "$SCRIPT" help repair 2>/dev/null | grep -q 'topic:'; then
  pass "help repair returns topic header"
else fail "help topic"; fi

# Test 13: quickstart envelope
if "$SCRIPT" quickstart 2>/dev/null | jq -e '.command == "quickstart"' >/dev/null; then
  pass "quickstart emits canonical envelope"
else fail "quickstart envelope"; fi

# ---------- fillin-specific assertions (6 added per worker-tick contract) ----------
# This surface is wzjo9.1.7 SELECTIVE-VERB-BYPASS — NEW canonical sub-variant.
# Native owns 6 verbs (doctor/health/schema/info/examples/why) + --info flag;
# scaffold owns 4 verbs (repair/validate/audit/quickstart) + --schema/--examples flags.

# Test 14: SELECTIVE-VERB-BYPASS contract is annotated in the script
if grep -q 'SELECTIVE-VERB-BYPASS' "$SCRIPT"; then
  pass "script annotates SELECTIVE-VERB-BYPASS variant (NEW; discoverable via grep)"
else fail "SELECTIVE-VERB-BYPASS annotation missing"; fi

# Test 15: 4-direction fidelity check — native doctor (BYPASSED) AND
# scaffold repair (NOT bypassed) AND native --info (BYPASSED) AND scaffold
# --schema (NOT bypassed) all route correctly
NATIVE_DOCTOR=0; SCAFFOLD_REPAIR=0; NATIVE_INFO=0; SCAFFOLD_SCHEMA=0
if "$SCRIPT" doctor 2>/dev/null | jq -e '.subsystems' >/dev/null; then NATIVE_DOCTOR=1; fi
if "$SCRIPT" repair --scope audit_log_dir --dry-run --json 2>/dev/null | jq -e '.status == "ok"' >/dev/null; then SCAFFOLD_REPAIR=1; fi
if "$SCRIPT" --info 2>/dev/null | jq -e '.name == "flywheel-cleanup-scratch"' >/dev/null; then NATIVE_INFO=1; fi
if "$SCRIPT" --schema 2>/dev/null | jq -e '.command == "schema"' >/dev/null; then SCAFFOLD_SCHEMA=1; fi
if [[ "$NATIVE_DOCTOR" -eq 1 && "$SCAFFOLD_REPAIR" -eq 1 && "$NATIVE_INFO" -eq 1 && "$SCAFFOLD_SCHEMA" -eq 1 ]]; then
  pass "SELECTIVE 4-direction routing: native doctor + scaffold repair + native --info + scaffold --schema all correct"
else fail "SELECTIVE routing (native_doctor=$NATIVE_DOCTOR scaffold_repair=$SCAFFOLD_REPAIR native_info=$NATIVE_INFO scaffold_schema=$SCAFFOLD_SCHEMA)"; fi

# Test 16: validate scratch-path REJECTS relative path (rc=1)
"$SCRIPT" validate scratch-path "relative/path" >/tmp/1hshd-13-test16.json 2>&1
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.status == "reject" and .reason == "not_absolute_path"' /tmp/1hshd-13-test16.json >/dev/null 2>&1; then
  pass "validate scratch-path rejects relative path with rc=1 (4th occurrence of absolute-only pattern)"
else fail "validate scratch-path reject rc=$rc"; fi
rm -f /tmp/1hshd-13-test16.json

# Test 17: validate mode-name accepts both enum values (dry-run + apply)
ALL_OK=1
for M in dry-run apply; do
  if ! "$SCRIPT" validate mode-name "$M" 2>/dev/null \
       | jq -e --arg v "$M" '.subject == "mode-name" and .status == "ok" and .value == $v' >/dev/null; then
    ALL_OK=0; break
  fi
done
if [[ "$ALL_OK" -eq 1 ]]; then
  pass "validate mode-name accepts both canonical values (dry-run + apply matching --dry-run|--apply flags)"
else fail "validate mode-name full-enum sweep"; fi

# Test 18: validate mode-name REJECTS unknown enum (rc=1 + valid_modes)
"$SCRIPT" validate mode-name "fast" >/tmp/1hshd-13-test18.json 2>&1
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.status == "reject" and .reason == "not_in_enum" and (.valid_modes | length == 2)' /tmp/1hshd-13-test18.json >/dev/null 2>&1; then
  pass "validate mode-name rejects 'fast' with rc=1 + valid_modes enumeration"
else fail "validate mode-name reject rc=$rc"; fi
rm -f /tmp/1hshd-13-test18.json

# Test 19: native schema subcommand (BYPASSED) emits scratch-cleanup/v1
# envelope with the script's documented mutation_modes + stable_exit_codes
if "$SCRIPT" schema --json 2>/dev/null | jq -e '.schema_version == "scratch-cleanup/v1" and .mutation_modes and .stable_exit_codes' >/dev/null; then
  pass "schema BYPASSED to native (mutation_modes + stable_exit_codes documented)"
else fail "schema native envelope"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
