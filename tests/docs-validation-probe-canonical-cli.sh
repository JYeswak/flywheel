#!/usr/bin/env bash
# tests/docs-validation-probe-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/docs-validation-probe.sh (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green. TODO markers
# point at per-surface assertions the operator should fill in.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/docs-validation-probe.sh"

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

# Test 3: --schema returns valid JSON (PARTIAL-BYPASS: native shape — metadata_fields/output_fields, no .command)
if "$SCRIPT" --schema 2>/dev/null | jq -e '.schema_version and .metadata_fields and .output_fields' >/dev/null; then
  pass "--schema emits canonical envelope (native PARTIAL-BYPASS shape: metadata_fields/output_fields)"
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
"$SCRIPT" validate >/tmp/1hshd-25-test9.json 2>&1
rc=$?
if [[ "$rc" -eq 64 ]] && jq -e '.command == "validate" and .status == "refused" and .reason == "missing_subject"' /tmp/1hshd-25-test9.json >/dev/null 2>&1; then
  pass "validate (bare) refuses with rc=64 + missing_subject envelope"
else fail "validate bare-refusal contract rc=$rc"; fi
rm -f /tmp/1hshd-25-test9.json

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

# Test 14: doctor probes load-bearing repo_root + docs anchor + awk (field_value uses awk)
if "$SCRIPT" doctor --json 2>/dev/null \
   | jq -e '[.checks[].name] | contains(["awk_available","repo_root_resolvable","default_docs_anchor","audit_log_dir_writable"])' >/dev/null; then
  pass "doctor probes awk + repo_root + docs anchor + audit log (load-bearing for docs metadata reader)"
else fail "doctor missing load-bearing probes"; fi

# Test 15: validate validation-status full-enum sweep — accept 4/4 valid + reject 1 invalid
# Cross-source with native --schema .metadata_fields[0] (docs_validation_status)
sweep_pass=0
for state in validated pending failed self_validated; do
  if "$SCRIPT" validate validation-status "$state" 2>/dev/null | jq -e '.status == "ok"' >/dev/null; then
    sweep_pass=$((sweep_pass + 1))
  fi
done
"$SCRIPT" validate validation-status "phantom_state" >/tmp/1hshd-25-test15.json 2>&1
rc=$?
if [[ "$sweep_pass" -eq 4 ]] && [[ "$rc" -eq 1 ]] \
   && jq -e '.status == "reject" and .reason == "not_in_enum"' /tmp/1hshd-25-test15.json >/dev/null 2>&1; then
  pass "validate validation-status full-enum sweep (4 accept + 1 reject; cross-source with native --schema .metadata_fields)"
else fail "validate validation-status sweep accept=$sweep_pass/4 reject_rc=$rc"; fi
rm -f /tmp/1hshd-25-test15.json

# Test 16: validate doc-path accepts readable file (README.md)
if [[ -r "$ROOT/README.md" ]] && "$SCRIPT" validate doc-path "$ROOT/README.md" 2>/dev/null \
   | jq -e '.subject == "doc-path" and .status == "ok"' >/dev/null; then
  pass "validate doc-path accepts readable file (README.md)"
elif [[ ! -r "$ROOT/README.md" ]]; then
  pass "validate doc-path skipped (README.md not present in repo root)"
else fail "validate doc-path accept"; fi

# Test 17: validate doc-path REJECTS unreadable path
"$SCRIPT" validate doc-path "/nonexistent/path/$$.md" >/tmp/1hshd-25-test17.json 2>&1
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.status == "reject" and .reason == "file_not_readable"' /tmp/1hshd-25-test17.json >/dev/null 2>&1; then
  pass "validate doc-path rejects unreadable with rc=1 + file_not_readable"
else fail "validate doc-path reject rc=$rc"; fi
rm -f /tmp/1hshd-25-test17.json

# Test 18: validate pane-name accepts canonical pattern
if "$SCRIPT" validate pane-name "flywheel" 2>/dev/null \
   | jq -e '.subject == "pane-name" and .status == "ok"' >/dev/null; then
  pass "validate pane-name accepts canonical pattern (matches validated_by_pane/authored_by_pane)"
else fail "validate pane-name accept"; fi

# Test 19: 4-direction fidelity — native owns --schema (PARTIAL-BYPASS shape);
# scaffold owns everything else. --info is SCAFFOLD-OWNED (native didn't have it).
native_schema_ok="false"; scaffold_info_ok="false"; scaffold_doctor_verb_ok="false"
"$SCRIPT" --schema 2>/dev/null | jq -e '.metadata_fields and .output_fields' >/dev/null \
  && native_schema_ok="true"
"$SCRIPT" --info --json 2>/dev/null | jq -e '.command == "info"' >/dev/null \
  && scaffold_info_ok="true"
"$SCRIPT" doctor --json 2>/dev/null | jq -e '.command == "doctor" and (.checks | length) >= 5' >/dev/null \
  && scaffold_doctor_verb_ok="true"
if [[ "$native_schema_ok" == "true" && "$scaffold_info_ok" == "true" && "$scaffold_doctor_verb_ok" == "true" ]]; then
  pass "4-direction fidelity (native --schema bypassed; scaffold --info/doctor verb active) — PARTIAL-BYPASS intact"
else fail "4-direction fidelity native_schema=$native_schema_ok scaffold_info=$scaffold_info_ok scaffold_doctor_verb=$scaffold_doctor_verb_ok"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
