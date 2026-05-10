#!/usr/bin/env bash
# tests/validate-skill-discovery-callback-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/validate-skill-discovery-callback.sh (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green. TODO markers
# point at per-surface assertions the operator should fill in.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/validate-skill-discovery-callback.sh"

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

# ===== fillin-specific assertions (flywheel-wzjo9.3.9 — callback-validator surface) =====

# Test 14: --info schema_version matches surface pattern
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.schema_version | test("^validate-skill-discovery-callback/v[0-9]+$")' >/dev/null; then
  pass "--info schema_version matches validate-skill-discovery-callback/v1 pattern"
else fail "--info schema_version pattern"; fi

# Test 15: --schema repair lists 2 known scopes
if "$SCRIPT" --schema repair 2>/dev/null \
  | jq -e '.scopes | index("audit-log-rotate") and index("example-callback-prime")' >/dev/null; then
  pass "--schema repair lists audit-log-rotate + example-callback-prime"
else fail "--schema repair scopes"; fi

# Test 16: doctor 5 named probes incl. callback-validator-specific
if "$SCRIPT" doctor --json 2>/dev/null \
  | jq -e '.checks | length >= 5 and (any(.name == "jq_on_path")) and (any(.name == "awk_on_path")) and (any(.name == "bash_version_4_plus"))' >/dev/null; then
  pass "doctor: 5+ probes incl. jq_on_path + awk_on_path + bash_version_4_plus"
else fail "doctor substrate probes"; fi

# Test 17: repair example-callback-prime emits non-stub envelope with example template
if "$SCRIPT" repair --scope example-callback-prime --dry-run --json 2>/dev/null \
  | jq -e '.command == "repair" and .scope == "example-callback-prime" and (.status != "todo") and has("example_callback_with_discovery") and has("example_callback_zero_discoveries")' >/dev/null; then
  pass "repair --scope example-callback-prime emits non-stub envelope with 2 templates"
else fail "repair scope-specific"; fi

# Test 18: validate --row-json enforces row schema
if "$SCRIPT" validate --row-json='{"ts":"2026-05-10T00:00:00Z","command":"validate","schema_version":"x/v1"}' 2>/dev/null \
  | jq -e '.command == "validate" and .subject == "row" and .status == "pass" and (.valid == true)' >/dev/null; then
  pass "validate --row-json enforces row schema"
else fail "validate row schema"; fi

# Test 19: validate --envelope parses callback shape — callback-validator-specific subject
ENV='DONE flywheel-example task_id=ex skill_discoveries=1 sd_ids=sd-test-pattern'
if "$SCRIPT" validate --envelope="$ENV" 2>/dev/null \
  | jq -e '.command == "validate" and .subject == "envelope" and .status == "pass" and (.valid == true) and .skill_discoveries == "1" and .sd_ids == "sd-test-pattern"' >/dev/null; then
  pass "validate --envelope parses callback skill_discoveries + sd_ids (callback-validator-specific subject)"
else fail "validate envelope subject"; fi

# Test 20: validate --sd-id-format enforces sd-<token> regex — callback-validator-specific
SD_PASS_OK=0
SD_FAIL_OK=0
"$SCRIPT" validate --sd-id-format=sd-test-pattern 2>/dev/null \
  | jq -e '.command == "validate" and .subject == "sd-id-format" and .status == "pass" and (.valid == true)' >/dev/null && SD_PASS_OK=1
"$SCRIPT" validate --sd-id-format=bad-id-no-prefix 2>/dev/null \
  | jq -e '.status == "fail" and (.valid == false)' >/dev/null && SD_FAIL_OK=1
if [[ "$SD_PASS_OK" -eq 1 && "$SD_FAIL_OK" -eq 1 ]]; then
  pass "validate --sd-id-format enforces sd-<token> regex (pass+fail cases)"
else fail "validate sd-id-format subject (pass=$SD_PASS_OK fail=$SD_FAIL_OK)"; fi


if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
