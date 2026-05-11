#!/usr/bin/env bash
# tests/hub-blocker-detect-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/hub-blocker-detect.sh (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green. TODO markers
# point at per-surface assertions the operator should fill in.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/hub-blocker-detect.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: bash -n syntax
if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# Test 2: --info envelope (PARTIAL-BYPASS — native owns rich envelope with .commands array)
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.schema_version == "hub-blocker-detect/v1" and .commands' >/dev/null; then
  pass "--info emits canonical envelope (native PARTIAL-BYPASS — rich v1 envelope w/ commands array)"
else fail "--info envelope"; fi

# Test 3: --schema returns valid JSON (scaffold owns — native lacked --schema)
if "$SCRIPT" --schema 2>/dev/null | jq -e '.schema_version and .command == "schema"' >/dev/null; then
  pass "--schema emits canonical envelope (SCAFFOLD owns — native lacked)"
else fail "--schema envelope"; fi

# Test 4: --examples (PARTIAL-BYPASS — native prints text examples)
if "$SCRIPT" --examples 2>/dev/null | grep -q "hub-blocker-detect"; then
  pass "--examples emits canonical text (native PARTIAL-BYPASS)"
else fail "--examples envelope"; fi

# Test 5: doctor verb routes to NATIVE (SELECTIVE-VERB-BYPASS — legacy contract)
if "$SCRIPT" doctor --json 2>/dev/null | jq -e '.signal and .dashboard_line and .hub_blocker_count != null' >/dev/null; then
  pass "doctor verb routes to NATIVE (SELECTIVE-VERB-BYPASS — emits signal/dashboard_line/hub_blocker_count)"
else fail "doctor verb native bypass broken"; fi

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
"$SCRIPT" validate >/tmp/1hshd-36-test9.json 2>&1
rc=$?
if [[ "$rc" -eq 64 ]] && jq -e '.command == "validate" and .status == "refused" and .reason == "missing_subject"' /tmp/1hshd-36-test9.json >/dev/null 2>&1; then
  pass "validate (bare) refuses with rc=64 + missing_subject envelope"
else fail "validate bare-refusal contract rc=$rc"; fi
rm -f /tmp/1hshd-36-test9.json

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

# Test 14: SELECTIVE-VERB-BYPASS — native doctor verb emits load-bearing fields
if "$SCRIPT" doctor --json 2>/dev/null \
   | jq -e '.hub_blocker_count != null and .max_parent_block_count != null and .signal' >/dev/null; then
  pass "SELECTIVE-VERB-BYPASS: native doctor verb emits hub_blocker_count + signal + max_parent_block_count (legacy v1 contract)"
else fail "native doctor verb shape broken"; fi

# Test 15: validate signal full-enum sweep (cross-source native doctor .signal field)
sweep_pass=0
for s in GREEN YELLOW RED; do
  if "$SCRIPT" validate signal "$s" 2>/dev/null | jq -e '.status == "ok"' >/dev/null; then
    sweep_pass=$((sweep_pass + 1))
  fi
done
"$SCRIPT" validate signal "phantom_signal" >/tmp/1hshd-36-test15.json 2>&1
rc=$?
if [[ "$sweep_pass" -eq 3 ]] && [[ "$rc" -eq 1 ]] \
   && jq -e '.status == "reject" and .reason == "not_in_enum"' /tmp/1hshd-36-test15.json >/dev/null 2>&1; then
  pass "validate signal full-enum sweep (3 accept + 1 reject; cross-source native doctor .signal)"
else fail "validate signal sweep accept=$sweep_pass/3 reject_rc=$rc"; fi
rm -f /tmp/1hshd-36-test15.json

# Test 16: validate threshold accepts default 3 (cross-source native --threshold flag)
if "$SCRIPT" validate threshold "3" 2>/dev/null \
   | jq -e '.subject == "threshold" and .status == "ok" and .default == 3' >/dev/null; then
  pass "validate threshold accepts default 3 (cross-source native --threshold flag)"
else fail "validate threshold accept"; fi

# Test 17: validate bead-id accepts canonical bead shape
if "$SCRIPT" validate bead-id "flywheel-1hshd.36" 2>/dev/null \
   | jq -e '.subject == "bead-id" and .status == "ok"' >/dev/null; then
  pass "validate bead-id accepts canonical bead-id shape (flywheel-1hshd.36)"
else fail "validate bead-id accept"; fi

# Test 18: validate bead-id REJECTS malformed
"$SCRIPT" validate bead-id "BadBeadID" >/tmp/1hshd-36-test18.json 2>&1
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.status == "reject" and .reason == "pattern_mismatch"' /tmp/1hshd-36-test18.json >/dev/null 2>&1; then
  pass "validate bead-id rejects malformed with rc=1 + pattern_mismatch"
else fail "validate bead-id reject rc=$rc"; fi
rm -f /tmp/1hshd-36-test18.json

# Test 19: 4-direction fidelity — SELECTIVE-VERB-BYPASS preserves native --info/doctor + scaffold --schema/repair
native_info_ok="false"; native_doctor_ok="false"; scaffold_schema_ok="false"; scaffold_repair_ok="false"
"$SCRIPT" --info --json 2>/dev/null | jq -e '.commands' >/dev/null && native_info_ok="true"
"$SCRIPT" doctor --json 2>/dev/null | jq -e '.signal' >/dev/null && native_doctor_ok="true"
"$SCRIPT" --schema 2>/dev/null | jq -e '.command == "schema"' >/dev/null && scaffold_schema_ok="true"
"$SCRIPT" repair --scope audit_log_dir --dry-run --json 2>/dev/null | jq -e '.status == "ok"' >/dev/null && scaffold_repair_ok="true"
if [[ "$native_info_ok" == "true" && "$native_doctor_ok" == "true" && "$scaffold_schema_ok" == "true" && "$scaffold_repair_ok" == "true" ]]; then
  pass "4-direction fidelity (native --info/doctor + scaffold --schema/repair) — SELECTIVE-VERB-BYPASS intact"
else fail "4-direction fidelity native_info=$native_info_ok native_doctor=$native_doctor_ok scaffold_schema=$scaffold_schema_ok scaffold_repair=$scaffold_repair_ok"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
