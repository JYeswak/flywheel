#!/usr/bin/env bash
# tests/auto-refill-decision-log-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/auto-refill-decision-log.sh
# (scaffolded by bead flywheel-ws02m / scaffold-canonical-cli.sh, filled-in by
# bead flywheel-5ke66.3 — wave-2-general-3).
#
# Tests 1-13: baseline AG1 canonical surface envelopes.
# Tests 14-20: fillin-specific assertions (auto-refill-decision-log surface).
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/auto-refill-decision-log.sh"

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

# Test 5: doctor returns valid envelope
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

# ===== fillin-specific assertions (flywheel-5ke66.3 — auto-refill-decision-log) =====

# Test 14: --info schema_version
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.schema_version | test("^auto-refill-decision-log/v[0-9]+$")' >/dev/null; then
  pass "--info schema_version matches auto-refill-decision-log/v1 pattern"
else fail "--info schema_version pattern"; fi

# Test 15: --schema repair lists 2 known scopes
if "$SCRIPT" --schema repair 2>/dev/null \
  | jq -e '.scopes | index("audit-log-rotate") and index("capacity-file-prime")' >/dev/null; then
  pass "--schema repair lists audit-log-rotate + capacity-file-prime"
else fail "--schema repair scopes"; fi

# Test 16: doctor 5+ probes (substrate-specific)
if "$SCRIPT" doctor --json 2>/dev/null \
  | jq -e '.checks | length >= 5 and (any(.name == "python3_on_path")) and (any(.name == "ntm_bin_executable")) and (any(.name == "br_bin_executable")) and (any(.name == "dispatch_log_writable"))' >/dev/null; then
  pass "doctor: 5+ probes incl. python3 + ntm + br + dispatch_log"
else fail "doctor substrate probes"; fi

# Test 17: repair capacity-file-prime emits non-stub envelope
if "$SCRIPT" repair --scope capacity-file-prime --dry-run --json 2>/dev/null \
  | jq -e '.command == "repair" and .scope == "capacity-file-prime" and (.status != "todo") and has("capacity_file") and has("present") and has("parseable")' >/dev/null; then
  pass "repair --scope capacity-file-prime emits non-stub envelope"
else fail "repair scope-specific"; fi

# Test 18: validate --row-json with auto-refill row schema
if "$SCRIPT" validate --row-json='{"ts":"2026-05-11T00:00:00Z","event":"auto_refill_after_reap","schema_version":"auto-refill-decision/v1"}' 2>/dev/null \
  | jq -e '.command == "validate" and .subject == "row" and .status == "pass" and (.valid == true)' >/dev/null; then
  pass "validate --row-json enforces row schema (ts/event/schema_version)"
else fail "validate row schema"; fi

# Test 19: validate --dispatch-log probes ledger
if "$SCRIPT" validate --dispatch-log 2>/dev/null \
  | jq -e '.command == "validate" and .subject == "dispatch-log" and has("dispatch_log") and has("present") and has("row_count") and has("auto_refill_row_count")' >/dev/null; then
  pass "validate --dispatch-log probes ledger file (surface-specific)"
else fail "validate dispatch-log subject"; fi

# Test 20: validate --capacity-file probes fleet-capacity.json
if "$SCRIPT" validate --capacity-file 2>/dev/null \
  | jq -e '.command == "validate" and .subject == "capacity-file" and has("capacity_file") and has("present") and has("parseable") and has("has_budget_field")' >/dev/null; then
  pass "validate --capacity-file probes fleet-capacity.json (surface-specific)"
else fail "validate capacity-file subject"; fi


if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
