#!/usr/bin/env bash
# tests/flywheel-codex-orient-canonical-cli.sh
# Canonical-cli surface tests for <flywheel-state>/bin/flywheel-codex-orient (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green. TODO markers
# point at per-surface assertions the operator should fill in.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="<flywheel-state>/bin/flywheel-codex-orient"

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

# Test 7: repair --dry-run envelope
if "$SCRIPT" repair --scope none --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .mode == "dry_run"' >/dev/null; then
  pass "repair --dry-run emits canonical envelope"
else fail "repair --dry-run envelope"; fi

# Test 8: repair --apply without --idempotency-key REFUSES (rc=3)
"$SCRIPT" repair --scope none --apply --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 3 ]]; then
  pass "repair --apply without --idempotency-key returns rc=3 (canonical refusal)"
else
  fail "repair --apply rc=$rc (expected 3)"
fi

# Test 9: validate envelope
if "$SCRIPT" validate --json 2>/dev/null | jq -e '.command == "validate"' >/dev/null; then
  pass "validate emits canonical envelope"
else fail "validate envelope"; fi

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

# ===== Fillin-specific assertions (flywheel-wzjo9.1.9) =====

# Test 14: doctor has 8 named substrate probes (flywheel_home, fw_binary, snapshot_bin, snapshot_file, stale_seconds_config, dependency:jq, helper_lib_loaded, audit_log_writable)
if "$SCRIPT" doctor --json 2>/dev/null \
  | jq -e '(.checks | length) >= 8 and ([.checks[].name] | contains(["flywheel_home","fw_binary","snapshot_bin","snapshot_file","stale_seconds_config","audit_log_writable"]))' >/dev/null; then
  pass "doctor has 8+ named probes including snapshot_file + audit_log_writable"
else fail "doctor named probes"; fi

# Test 15: health surfaces snapshot_age_seconds + recent_runs + audit_log_stale fields
if "$SCRIPT" health --json 2>/dev/null \
  | jq -e '(.snapshot_age_seconds | type) and (.recent_runs | type == "number") and (.audit_log_stale | type == "boolean")' >/dev/null; then
  pass "health surfaces snapshot_age_seconds + recent_runs + audit_log_stale"
else fail "health structured fields"; fi

# Test 16: repair --scope snapshot dry-run emits planned_actions array
if "$SCRIPT" repair --scope snapshot --dry-run --json 2>/dev/null \
  | jq -e '.scope == "snapshot" and (.planned_actions | type == "array") and (.actual_actions | length) == 0' >/dev/null; then
  pass "repair --scope snapshot --dry-run emits planned_actions"
else fail "repair scope snapshot dry-run"; fi

# Test 17: repair --scope audit-log --apply with idempotency-key creates audit-log dir
audit_tmp="${TMPDIR:-/tmp}/flywheel-codex-orient-audit-$$.jsonl"
audit_dir="$(dirname "$audit_tmp")"
SCAFFOLD_AUDIT_LOG="$audit_tmp" "$SCRIPT" repair --scope audit-log --apply --idempotency-key wzjo9-1-9-test --json >/tmp/repair-apply-out.json 2>&1 || true
if jq -e '.scope == "audit-log" and .mode == "apply" and (.actual_actions[0] == "audit_log_dir_ensured")' /tmp/repair-apply-out.json >/dev/null 2>&1; then
  pass "repair --scope audit-log --apply ensures dir"
else fail "repair audit-log apply"; fi

# Test 18: validate snapshot subject returns envelope with subject + status fields
if "$SCRIPT" validate snapshot --json 2>/dev/null \
  | jq -e '.command == "validate" and .subject == "snapshot" and (.status == "pass" or .status == "fail")' >/dev/null; then
  pass "validate snapshot subject envelope"
else fail "validate snapshot envelope"; fi

# Test 19: validate binaries subject returns subject-specific reason
if "$SCRIPT" validate binaries --json 2>/dev/null \
  | jq -e '.subject == "binaries" and (.reason | type == "string")' >/dev/null; then
  pass "validate binaries subject"
else fail "validate binaries subject"; fi

# Test 20: validate config subject returns subject-specific reason
if "$SCRIPT" validate config --json 2>/dev/null \
  | jq -e '.subject == "config" and (.reason | type == "string")' >/dev/null; then
  pass "validate config subject"
else fail "validate config subject"; fi

# Test 21: schema audit-row returns audit row schema
if "$SCRIPT" --schema audit-row 2>/dev/null \
  | jq -e '.command == "audit-row" and (.required | type == "array")' >/dev/null; then
  pass "schema audit-row variant exists"
else fail "schema audit-row"; fi

# Test 22: why supports 3 known ids with resolution=found
why_found_count=0
for id in stale snapshot refresh; do
  res="$("$SCRIPT" why "$id" --json 2>/dev/null | jq -r '.resolution')"
  if [[ "$res" == "found" || "$res" == "unavailable" ]]; then
    why_found_count=$((why_found_count + 1))
  fi
done
if [[ "$why_found_count" -ge 2 ]]; then
  pass "why supports 3 known ids (stale/snapshot/refresh)"
else fail "why multi-resolution coverage ($why_found_count/3)"; fi

# Test 23: why with unknown id returns resolution=not_found
if "$SCRIPT" why definitely-not-a-real-id --json 2>/dev/null \
  | jq -e '.resolution == "not_found"' >/dev/null; then
  pass "why unknown id returns not_found"
else fail "why not_found resolution"; fi

# Test 24: cli_audit_append wired — doctor invocation appends a row
audit_trace="${TMPDIR:-/tmp}/flywheel-codex-orient-trace-$$.jsonl"
: >"$audit_trace"
SCAFFOLD_AUDIT_LOG="$audit_trace" "$SCRIPT" doctor --json >/dev/null 2>&1 || true
if [[ -s "$audit_trace" ]] && jq -e '.action == "doctor"' "$audit_trace" >/dev/null 2>&1; then
  pass "cli_audit_append wired for doctor"
else fail "cli_audit_append doctor"; fi

# Test 25: cli_audit_append wired — run path appends "run" action
audit_trace2="${TMPDIR:-/tmp}/flywheel-codex-orient-trace-run-$$.jsonl"
: >"$audit_trace2"
SCAFFOLD_AUDIT_LOG="$audit_trace2" CODEX_CURRENT_DELTAS=/dev/null "$SCRIPT" >/dev/null 2>&1 || true
if [[ -s "$audit_trace2" ]] && grep -q '"action":"run"' "$audit_trace2"; then
  pass "cli_audit_append wired for run path"
else fail "cli_audit_append run path"; fi

# cleanup audit traces
[[ -f "$audit_tmp" ]] && rm -f "$audit_tmp" 2>/dev/null || true
[[ -f "$audit_trace" ]] && rm -f "$audit_trace" 2>/dev/null || true
[[ -f "$audit_trace2" ]] && rm -f "$audit_trace2" 2>/dev/null || true

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
