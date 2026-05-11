#!/usr/bin/env bash
# tests/codex-queued-not-submitted-bare-enter-primitive-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/codex-queued-not-submitted-bare-enter-primitive.sh (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green. TODO markers
# point at per-surface assertions the operator should fill in.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/codex-queued-not-submitted-bare-enter-primitive.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: bash -n syntax
if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# Test 2: --info native PASSTHRU envelope (NUANCED-PARTIAL-BYPASS — emits
# codex-queued-not-submitted-bare-enter.info.v1 with verbs + exit_codes)
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.schema_version == "codex-queued-not-submitted-bare-enter.info.v1" and (.exit_codes | length == 9)' >/dev/null; then
  pass "--info emits native PASSTHRU envelope (info.v1 + 9 exit_codes)"
else fail "--info native envelope"; fi

# Test 3: --schema scaffold envelope (NOT bypassed)
if "$SCRIPT" --schema 2>/dev/null | jq -e '.command == "schema"' >/dev/null; then
  pass "--schema emits scaffold envelope (NOT bypassed — native errors)"
else fail "--schema scaffold envelope"; fi

# Test 4: --examples native PASSTHRU envelope (examples.v1)
if "$SCRIPT" --examples --json 2>/dev/null | jq -e '.schema_version == "codex-queued-not-submitted-bare-enter.examples.v1" and (.examples | length > 0)' >/dev/null; then
  pass "--examples emits native PASSTHRU envelope (examples.v1)"
else fail "--examples native envelope"; fi

# Test 5: doctor scaffold envelope (>=5 named probes)
if "$SCRIPT" doctor --json 2>/dev/null | jq -e '.command == "doctor" and (.checks | length >= 5)' >/dev/null; then
  pass "doctor emits scaffold envelope with >=5 checks"
else fail "doctor envelope"; fi

# Test 6: health envelope (scaffold)
if "$SCRIPT" health --json 2>/dev/null | jq -e '.command == "health"' >/dev/null; then
  pass "health emits scaffold envelope"
else fail "health envelope"; fi

# Test 7: repair --dry-run envelope (real scope)
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
"$SCRIPT" validate >/tmp/1hshd-16-test9.json 2>&1
rc=$?
if [[ "$rc" -eq 64 ]] && jq -e '.command == "validate" and .status == "refused" and .reason == "missing_subject"' /tmp/1hshd-16-test9.json >/dev/null 2>&1; then
  pass "validate (bare) refuses with rc=64 + missing_subject envelope"
else fail "validate bare-refusal contract rc=$rc"; fi
rm -f /tmp/1hshd-16-test9.json

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

# Test 14: NUANCED-PARTIAL-BYPASS contract is annotated in the script
if grep -q 'NUANCED-PARTIAL-BYPASS' "$SCRIPT"; then
  pass "script annotates NUANCED-PARTIAL-BYPASS variant (discoverable via grep)"
else fail "NUANCED-PARTIAL-BYPASS annotation missing"; fi

# Test 15: doctor probes load-bearing capacity_halt trio (lease + auth + budget)
if "$SCRIPT" doctor --json 2>/dev/null \
   | jq -e '[.checks[].name] | contains(["capacity_halt_lease_executable","capacity_halt_auth_executable","capacity_halt_budget_executable"])' >/dev/null; then
  pass "doctor probes capacity_halt trio (lease + auth + budget — load-bearing for recovery coordination)"
else fail "doctor missing capacity_halt trio"; fi

# Test 16: validate exit-code accepts each of 9 native exit codes
ALL_OK=1
for C in 0 1 2 3 4 5 6 7 8; do
  if ! "$SCRIPT" validate exit-code "$C" 2>/dev/null \
       | jq -e --argjson v "$C" '.subject == "exit-code" and .status == "ok" and .value == $v' >/dev/null; then
    ALL_OK=0; break
  fi
done
if [[ "$ALL_OK" -eq 1 ]]; then
  pass "validate exit-code accepts all 9 native exit codes (0-8 per script docstring L20-L29)"
else fail "validate exit-code full-enum sweep"; fi

# Test 17: validate exit-code REJECTS 9 (out of native enum; rc=1)
"$SCRIPT" validate exit-code "9" >/tmp/1hshd-16-test17.json 2>&1
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.status == "reject" and .reason == "not_in_enum" and (.valid_codes | length == 9)' /tmp/1hshd-16-test17.json >/dev/null 2>&1; then
  pass "validate exit-code rejects 9 (out of [0,8] native enum) with rc=1 + valid_codes list"
else fail "validate exit-code reject rc=$rc"; fi
rm -f /tmp/1hshd-16-test17.json

# Test 18: validate pane-index accepts 0 + 99 (boundary values matching --pane semantic)
if "$SCRIPT" validate pane-index "0" 2>/dev/null | jq -e '.status == "ok" and .value == 0' >/dev/null \
   && "$SCRIPT" validate pane-index "99" 2>/dev/null | jq -e '.status == "ok" and .value == 99' >/dev/null; then
  pass "validate pane-index accepts both range boundaries (0 and 99)"
else fail "validate pane-index boundary accept"; fi

# Test 19: cross-source consistency — native --info exit_codes (9 codes 0-8)
# matches scaffold validate exit-code valid_codes list; catches enum drift
TMP_NATIVE_CODES="$(mktemp -t bare-enter-test19-XXXXXX)"
"$SCRIPT" --info --json >"$TMP_NATIVE_CODES" 2>/dev/null
NATIVE_CODES_SORTED="$(jq -r '.exit_codes | keys | sort | join(",")' "$TMP_NATIVE_CODES" 2>/dev/null)"
SCAFFOLD_CODES_SORTED="$("$SCRIPT" validate exit-code "__probe_unknown__" 2>/dev/null | jq -r '.valid_codes | sort | map(tostring) | join(",")' 2>/dev/null)"
if [[ -n "$NATIVE_CODES_SORTED" ]] && [[ "$NATIVE_CODES_SORTED" == "$SCAFFOLD_CODES_SORTED" ]]; then
  pass "cross-source consistency: native --info .exit_codes keys == scaffold validate .valid_codes ($NATIVE_CODES_SORTED)"
else fail "exit_codes drift: native='$NATIVE_CODES_SORTED' scaffold='$SCAFFOLD_CODES_SORTED'"; fi
rm -f "$TMP_NATIVE_CODES"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
