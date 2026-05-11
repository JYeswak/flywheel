#!/usr/bin/env bash
# tests/canonical-root-drift-fleet-check-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/canonical-root-drift-fleet-check.sh (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green. TODO markers
# point at per-surface assertions the operator should fill in.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/canonical-root-drift-fleet-check.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: bash -n syntax
if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# Test 2: --info native PASSTHRU envelope (NUANCED-PARTIAL-BYPASS — emits
# canonical-root-drift-fleet-check/v1 + .canonical_source + .exit_codes)
if "$SCRIPT" --info 2>/dev/null | jq -e '.schema_version == "canonical-root-drift-fleet-check/v1" and .canonical_source' >/dev/null; then
  pass "--info emits native PASSTHRU envelope (canonical-root-drift-fleet-check/v1 + .canonical_source)"
else fail "--info native envelope"; fi

# Test 3: --schema scaffold envelope (NOT bypassed — native doesn't have
# --schema; scaffold owns it per NUANCED variant)
if "$SCRIPT" --schema 2>/dev/null | jq -e '.command == "schema"' >/dev/null; then
  pass "--schema emits scaffold envelope (NOT bypassed — native errors on this flag)"
else fail "--schema scaffold envelope"; fi

# Test 4: --examples native PASSTHRU (text invocations)
if "$SCRIPT" --examples 2>/dev/null | grep -q 'canonical-root-drift-fleet-check.sh'; then
  pass "--examples emits native PASSTHRU example invocations"
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
"$SCRIPT" validate >/tmp/1hshd-11-test9.json 2>&1
rc=$?
if [[ "$rc" -eq 64 ]] && jq -e '.command == "validate" and .status == "refused" and .reason == "missing_subject"' /tmp/1hshd-11-test9.json >/dev/null 2>&1; then
  pass "validate (bare) refuses with rc=64 + missing_subject envelope"
else fail "validate bare-refusal contract rc=$rc"; fi
rm -f /tmp/1hshd-11-test9.json

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
# This surface is wzjo9.1.7 NUANCED-PARTIAL-BYPASS: --info|--examples flags
# route to native; --schema + verbs route to scaffold. Wave-4 first
# (sister to wave-2's 5ke66.8 freshness-probe).

# Test 14: NUANCED-PARTIAL-BYPASS contract is annotated in the script
if grep -q 'NUANCED-PARTIAL-BYPASS' "$SCRIPT"; then
  pass "script annotates NUANCED-PARTIAL-BYPASS variant (discoverable via grep)"
else fail "NUANCED-PARTIAL-BYPASS annotation missing"; fi

# Test 15: dual-direction fidelity check — --info goes native (no .command)
# AND --schema goes scaffold (.command=schema)
INFO_NATIVE=0; SCHEMA_SCAFFOLD=0
if "$SCRIPT" --info 2>/dev/null | jq -e '.schema_version == "canonical-root-drift-fleet-check/v1" and (has("command") | not)' >/dev/null; then
  INFO_NATIVE=1
fi
if "$SCRIPT" --schema 2>/dev/null | jq -e '.command == "schema"' >/dev/null; then
  SCHEMA_SCAFFOLD=1
fi
if [[ "$INFO_NATIVE" -eq 1 && "$SCHEMA_SCAFFOLD" -eq 1 ]]; then
  pass "NUANCED bypass dual-direction: --info native (no .command), --schema scaffold (.command=schema)"
else fail "NUANCED bypass dual-direction (info_native=$INFO_NATIVE schema_scaffold=$SCHEMA_SCAFFOLD)"; fi

# Test 16: validate root-path REJECTS relative path (rc=1 + not_absolute_path)
"$SCRIPT" validate root-path "relative/path" >/tmp/1hshd-11-test16.json 2>&1
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.status == "reject" and .reason == "not_absolute_path"' /tmp/1hshd-11-test16.json >/dev/null 2>&1; then
  pass "validate root-path rejects relative path with rc=1 + not_absolute_path"
else fail "validate root-path reject rc=$rc"; fi
rm -f /tmp/1hshd-11-test16.json

# Test 17: validate timeout-seconds accepts default 10 (matches --timeout default)
if "$SCRIPT" validate timeout-seconds "10" 2>/dev/null \
   | jq -e '.subject == "timeout-seconds" and .status == "ok" and .value == 10' >/dev/null; then
  pass "validate timeout-seconds accepts default 10 (matches --timeout arg default)"
else fail "validate timeout-seconds default accept"; fi

# Test 18: validate timeout-seconds REJECTS 999 (out of [1,300]; rc=1)
"$SCRIPT" validate timeout-seconds "999" >/tmp/1hshd-11-test18.json 2>&1
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.status == "reject" and .reason == "out_of_range_or_not_integer"' /tmp/1hshd-11-test18.json >/dev/null 2>&1; then
  pass "validate timeout-seconds rejects 999 (out of [1,300]) with rc=1"
else fail "validate timeout-seconds range reject rc=$rc"; fi
rm -f /tmp/1hshd-11-test18.json

# Test 19: repair sync_helper_path is REPORT-ONLY (does NOT install; emits
# .status==report with .existed + .executable booleans)
if "$SCRIPT" repair --scope sync_helper_path --dry-run 2>/dev/null \
   | jq -e '.status == "report" and has("existed") and has("executable")' >/dev/null; then
  pass "repair sync_helper_path is REPORT-ONLY (emits .status=report + .existed + .executable)"
else fail "repair sync_helper_path report contract"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
