#!/usr/bin/env bash
# tests/fleet-coherence-lib-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/fleet-coherence-lib.sh
# (scaffolded by bead flywheel-ws02m / scaffold-canonical-cli.sh, filled-in by
# bead flywheel-5ke66.10 — wave-2-general-10).
#
# Tests 1-13: baseline AG1 canonical surface envelopes.
# Tests 14-20: fillin-specific assertions + source-vs-exec verification.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/fleet-coherence-lib.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: bash -n syntax
if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# Test 2: --info envelope
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.schema_version and .command == "info"' >/dev/null; then
  pass "--info emits canonical envelope"
else fail "--info envelope"; fi

# Test 3: --schema envelope
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

# ===== fillin-specific assertions (flywheel-5ke66.10 — fleet-coherence-lib) =====

# Test 14: --info schema_version
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.schema_version | test("^fleet-coherence-lib/v[0-9]+$")' >/dev/null; then
  pass "--info schema_version matches fleet-coherence-lib/v1 pattern"
else fail "--info schema_version pattern"; fi

# Test 15: --schema repair lists 2 known scopes
if "$SCRIPT" --schema repair 2>/dev/null \
  | jq -e '.scopes | index("audit-log-rotate") and index("state-dir-prime")' >/dev/null; then
  pass "--schema repair lists audit-log-rotate + state-dir-prime"
else fail "--schema repair scopes"; fi

# Test 16: doctor 5+ probes (substrate-specific)
if "$SCRIPT" doctor --json 2>/dev/null \
  | jq -e '.checks | length >= 5 and (any(.name == "jq_on_path")) and (any(.name == "date_on_path")) and (any(.name == "state_dir_writable")) and (any(.name == "events_jsonl_writable"))' >/dev/null; then
  pass "doctor: 5+ probes incl. jq + date + state_dir + events_jsonl"
else fail "doctor substrate probes"; fi

# Test 17: repair state-dir-prime emits non-stub envelope
if "$SCRIPT" repair --scope state-dir-prime --dry-run --json 2>/dev/null \
  | jq -e '.command == "repair" and .scope == "state-dir-prime" and (.status != "todo") and has("state_dir") and has("events_path") and has("latest_path") and has("archive_dir")' >/dev/null; then
  pass "repair --scope state-dir-prime emits non-stub envelope"
else fail "repair scope-specific"; fi

# Test 18: validate --row-json with event row schema (uses fc_validate_event_row contract)
if "$SCRIPT" validate --row-json='{"schema_version":2,"event_id":"e1","dedupe_key":"k1","class":"test","state":"open"}' 2>/dev/null \
  | jq -e '.command == "validate" and .subject == "row" and .status == "pass" and (.valid == true)' >/dev/null; then
  pass "validate --row-json enforces event row schema (5 required fields)"
else fail "validate row schema"; fi

# Test 19: validate --events probes events jsonl + state distribution
if "$SCRIPT" validate --events 2>/dev/null \
  | jq -e '.command == "validate" and .subject == "events" and has("events_path") and has("present") and has("row_count") and has("open_count") and has("closed_count")' >/dev/null; then
  pass "validate --events probes events jsonl + state distribution (surface-specific)"
else fail "validate events subject"; fi

# Test 20: SOURCE-VS-EXEC GUARD — verify the scaffold doesn't run on source.
# Source the lib in a subshell and check that no canonical envelope was emitted
# AND that fc_* functions are now defined.
GUARD_OUTPUT="$(bash -c "source '$SCRIPT'; declare -F fc_state_dir fc_events_path fc_validate_event_row | wc -l" 2>&1)"
GUARD_OUTPUT="$(printf '%s' "$GUARD_OUTPUT" | tr -d ' ')"
if [[ "$GUARD_OUTPUT" == "3" ]]; then
  pass "source-vs-exec guard: sourcing exposes fc_* functions without running scaffold"
else fail "source-vs-exec guard (got: '$GUARD_OUTPUT', expected 3 functions declared)"; fi


if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
