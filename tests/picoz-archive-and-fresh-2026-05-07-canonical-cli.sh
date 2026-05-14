#!/usr/bin/env bash
# tests/{session}-archive-and-fresh-2026-05-07-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/{session}-archive-and-fresh-2026-05-07.sh (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green. TODO markers
# point at per-surface assertions the operator should fill in.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/{session}-archive-and-fresh-2026-05-07.sh"

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
if "$SCRIPT" repair --scope archive_dir --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .mode == "dry_run" and .status == "ok"' >/dev/null; then
  pass "repair --dry-run emits canonical envelope (real scope archive_dir)"
else fail "repair --dry-run envelope"; fi

# Test 8: repair --apply without --idempotency-key REFUSES (rc=3)
"$SCRIPT" repair --scope archive_dir --apply --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 3 ]]; then
  pass "repair --apply without --idempotency-key returns rc=3 (canonical refusal)"
else
  fail "repair --apply rc=$rc (expected 3)"
fi

# Test 9: validate envelope (bare validate refuses with rc=64; calibrated)
"$SCRIPT" validate >/tmp/5ke66-15-test9.json 2>&1
rc=$?
if [[ "$rc" -eq 64 ]] && jq -e '.command == "validate" and .status == "refused" and .reason == "missing_subject"' /tmp/5ke66-15-test9.json >/dev/null 2>&1; then
  pass "validate (bare) refuses with rc=64 + missing_subject envelope"
else fail "validate bare-refusal contract rc=$rc"; fi
rm -f /tmp/5ke66-15-test9.json

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

# Test 14: doctor probes load-bearing sqlite3 + zstd + launchctl + lsof
# (the four external programs that gate the destructive archival sequence)
if "$SCRIPT" doctor --json 2>/dev/null \
   | jq -e '[.checks[].name] | contains(["sqlite3_available","zstd_available","launchctl_available","lsof_available"])' >/dev/null; then
  pass "doctor probes sqlite3 + zstd + launchctl + lsof (load-bearing for destructive archival)"
else fail "doctor missing load-bearing probes"; fi

# Test 15: validate phase-name accepts canonical phase_<N>_ok pattern
if "$SCRIPT" validate phase-name "phase_3_ok" 2>/dev/null \
   | jq -e '.subject == "phase-name" and .status == "ok"' >/dev/null; then
  pass "validate phase-name accepts phase_3_ok (matches script log() emit pattern)"
else fail "validate phase-name accept"; fi

# Test 16: validate phase-name REJECTS hyphen variant (rc=1)
"$SCRIPT" validate phase-name "phase-3-bad" >/tmp/5ke66-15-test16.json 2>&1
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.status == "reject" and .reason == "pattern_mismatch"' /tmp/5ke66-15-test16.json >/dev/null 2>&1; then
  pass "validate phase-name rejects hyphen variant with rc=1 (underscore-only contract)"
else fail "validate phase-name reject rc=$rc"; fi
rm -f /tmp/5ke66-15-test16.json

# Test 17: validate action-name accepts terminal action `phase_10_done`
if "$SCRIPT" validate action-name "phase_10_done" 2>/dev/null \
   | jq -e '.subject == "action-name" and .status == "ok"' >/dev/null; then
  pass "validate action-name accepts phase_10_done (terminal success action)"
else fail "validate action-name terminal accept"; fi

# Test 18: validate action-name REJECTS invented action (rc=1)
"$SCRIPT" validate action-name "phase_99_invented" >/tmp/5ke66-15-test18.json 2>&1
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.status == "reject" and .reason == "not_in_enum"' /tmp/5ke66-15-test18.json >/dev/null 2>&1; then
  pass "validate action-name rejects invented action with rc=1"
else fail "validate action-name reject rc=$rc"; fi
rm -f /tmp/5ke66-15-test18.json

# Test 19: repair has FOUR scopes (archive_dir + schema_dir + ledger_dir +
# audit_log_dir) — this surface uses 4-scope pattern because it manages
# THREE distinct production directories (archive, schema, ledger) PLUS
# the canonical audit log dir. EXTENDS the 3-scope pattern from 5ke66.13
# with a third production scope.
SCOPES_LISTED="$("$SCRIPT" repair --scope none --dry-run 2>/dev/null | jq -r '.valid_scopes[]?' 2>/dev/null | sort | tr '\n' ',' | sed 's/,$//')"
if [[ "$SCOPES_LISTED" == "archive_dir,audit_log_dir,ledger_dir,schema_dir" ]]; then
  pass "repair has 4 distinct scopes (archive_dir + schema_dir + ledger_dir + audit_log_dir per multi-production-dir pattern)"
else fail "repair scopes drift: got '$SCOPES_LISTED'"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
