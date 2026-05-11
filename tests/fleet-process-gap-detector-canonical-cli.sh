#!/usr/bin/env bash
# tests/fleet-process-gap-detector-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/fleet-process-gap-detector.sh
# (filled-in by bead flywheel-5ke66.12 — wave-2-general-12).
#
# Tests 1-13: baseline AG1 canonical envelopes.
# Tests 14-20: fillin-specific + backward-compat with existing tests.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/fleet-process-gap-detector.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: bash -n syntax
if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# Test 2: --info envelope (intercepted by bash scaffold; hand-rolled hybrid)
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.schema_version and .command == "info"' >/dev/null; then
  pass "--info emits canonical envelope"
else fail "--info envelope"; fi

# Test 3: --schema envelope (intercepted; preserves python's JSON-Schema shape)
if "$SCRIPT" --schema 2>/dev/null | jq -e '.schema_version and .command == "schema"' >/dev/null; then
  pass "--schema emits canonical envelope"
else fail "--schema envelope"; fi

# Test 4: --examples envelope
if "$SCRIPT" --examples --json 2>/dev/null | jq -e '.command == "examples"' >/dev/null; then
  pass "--examples emits canonical envelope"
else fail "--examples envelope"; fi

# Test 5: doctor envelope
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

# Test 12: help <topic>
if "$SCRIPT" help repair 2>/dev/null | grep -q 'topic:'; then
  pass "help repair returns topic header"
else fail "help topic"; fi

# Test 13: quickstart envelope
if "$SCRIPT" quickstart 2>/dev/null | jq -e '.command == "quickstart"' >/dev/null; then
  pass "quickstart emits canonical envelope"
else fail "quickstart envelope"; fi

# ===== fillin-specific assertions (flywheel-5ke66.12 — fleet-process-gap-detector) =====

# Test 14: BACKWARD-COMPAT — --info exposes .doctor_fields including fleet_process_health_score
# (existing tests/fleet-process-gap-detector.sh:87 assertion)
if "$SCRIPT" --info --json 2>/dev/null \
  | jq -e '.name == "fleet-process-gap-detector" and (.doctor_fields | index("fleet_process_health_score"))' >/dev/null; then
  pass "--info backward-compat: .name + .doctor_fields includes fleet_process_health_score"
else fail "--info backward-compat shape"; fi

# Test 15: BACKWARD-COMPAT — --schema preserves .properties.process_health_score.maximum=100
# (existing tests/fleet-process-gap-detector.sh:89 assertion)
if "$SCRIPT" --schema --json 2>/dev/null \
  | jq -e '.schema_version == "fleet-process-gap-detector/v1" and .properties.process_health_score.maximum == 100' >/dev/null; then
  pass "--schema backward-compat: JSON-Schema shape with health_score maximum=100"
else fail "--schema backward-compat shape"; fi

# Test 16: doctor 5+ probes (substrate-specific)
if "$SCRIPT" doctor --json 2>/dev/null \
  | jq -e '.checks | length >= 5 and (any(.name == "python3_on_path")) and (any(.name == "br_bin_executable")) and (any(.name == "fuckup_log_readable")) and (any(.name == "tick_dir_readable"))' >/dev/null; then
  pass "doctor: 5+ probes incl. python3 + br + fuckup-log + tick-dir"
else fail "doctor substrate probes"; fi

# Test 17: repair state-dir-prime emits non-stub envelope
if "$SCRIPT" repair --scope state-dir-prime --dry-run --json 2>/dev/null \
  | jq -e '.command == "repair" and .scope == "state-dir-prime" and (.status != "todo") and has("state_dir") and has("present") and has("run_count")' >/dev/null; then
  pass "repair --scope state-dir-prime emits non-stub envelope"
else fail "repair scope-specific"; fi

# Test 18: validate --row-json with gap-row schema
if "$SCRIPT" validate --row-json='{"schema_version":"fleet-process-gap-detector/v1","checked_at":"2026-05-11T00:00:00Z","open_gap_count":3,"top_gaps":[],"stuck_class_count":1,"process_health_score":85}' 2>/dev/null \
  | jq -e '.command == "validate" and .subject == "row" and .status == "pass" and (.valid == true)' >/dev/null; then
  pass "validate --row-json enforces gap-row schema (6 required fields)"
else fail "validate row schema"; fi

# Test 19: validate --fuckup-log probes shape
if "$SCRIPT" validate --fuckup-log 2>/dev/null \
  | jq -e '.command == "validate" and .subject == "fuckup-log" and has("fuckup_log") and has("present") and has("row_count")' >/dev/null; then
  pass "validate --fuckup-log probes fuckup-log.jsonl (surface-specific)"
else fail "validate fuckup-log subject"; fi

# Test 20: validate --tick-dir probes receipts
if "$SCRIPT" validate --tick-dir 2>/dev/null \
  | jq -e '.command == "validate" and .subject == "tick-dir" and has("tick_dir") and has("present") and has("receipt_count")' >/dev/null; then
  pass "validate --tick-dir probes tick-dir receipts (surface-specific)"
else fail "validate tick-dir subject"; fi


if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
