#!/usr/bin/env bash
# tests/flywheel-stale-canonical-cli.sh
# Canonical-cli surface tests for <flywheel-state>/bin/flywheel-stale (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green. TODO markers
# point at per-surface assertions the operator should fill in.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="<flywheel-state>/bin/flywheel-stale"

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

# ===== fillin-specific assertions (flywheel-wzjo9.3.7 — stale stdout-emitter) =====

# Test 14: --info schema_version matches surface pattern
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.schema_version | test("^flywheel-stale/v[0-9]+$")' >/dev/null; then
  pass "--info schema_version matches flywheel-stale/v1 pattern"
else fail "--info schema_version pattern"; fi

# Test 15: --schema repair lists 2 known scopes
if "$SCRIPT" --schema repair 2>/dev/null \
  | jq -e '.scopes | index("audit-log-rotate") and index("jsm-list-prime")' >/dev/null; then
  pass "--schema repair lists audit-log-rotate + jsm-list-prime"
else fail "--schema repair scopes"; fi

# Test 16: doctor 5+ probes incl. stdout-emitter-specific
if "$SCRIPT" doctor --json 2>/dev/null \
  | jq -e '.checks | length >= 5 and (any(.name == "bash_version_4_plus")) and (any(.name == "flywheel_skills_dir_present")) and (any(.name == "sources_table_accessible")) and (any(.name == "deltas_table_accessible"))' >/dev/null; then
  pass "doctor: 5+ probes incl. bash_version_4_plus + flywheel_skills_dir_present + sources_table + deltas_table"
else fail "doctor substrate probes"; fi

# Test 17: repair jsm-list-prime emits non-stub envelope with jsm_list_path + jsm_list_count
if "$SCRIPT" repair --scope jsm-list-prime --dry-run --json 2>/dev/null \
  | jq -e '.command == "repair" and .scope == "jsm-list-prime" and (.status != "todo") and has("jsm_list_path") and has("jsm_list_count") and has("jsm_list_present")' >/dev/null; then
  pass "repair --scope jsm-list-prime emits non-stub envelope with jsm_list_path + jsm_list_count"
else fail "repair scope-specific"; fi

# Test 18: validate --row-json enforces row schema
if "$SCRIPT" validate --row-json='{"ts":"2026-05-10T00:00:00Z","command":"stale","schema_version":"x/v1"}' 2>/dev/null \
  | jq -e '.command == "validate" and .subject == "row" and .status == "pass" and (.valid == true)' >/dev/null; then
  pass "validate --row-json enforces row schema"
else fail "validate row schema"; fi

# Test 19: validate --invariants replays cmd_run DB-backed probes — stdout-emitter-specific
if "$SCRIPT" validate --invariants 2>/dev/null \
  | jq -e '.command == "validate" and .subject == "invariants" and has("sources_fail_streak_3") and has("skill_zero_deltas") and has("deltas_unsurfaced_7d")' >/dev/null; then
  pass "validate --invariants replays cmd_run DB probes (stdout-emitter-specific subject)"
else fail "validate invariants subject"; fi

# Test 20: validate --jsm-list probes JSM exclusion list — stdout-emitter-specific
if "$SCRIPT" validate --jsm-list 2>/dev/null \
  | jq -e '.command == "validate" and .subject == "jsm-list" and has("jsm_list_path") and has("jsm_count")' >/dev/null; then
  pass "validate --jsm-list probes JSM exclusion list (stdout-emitter-specific subject)"
else fail "validate jsm-list subject"; fi


if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
