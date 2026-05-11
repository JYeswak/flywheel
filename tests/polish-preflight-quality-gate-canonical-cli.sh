#!/usr/bin/env bash
# tests/polish-preflight-quality-gate-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/polish-preflight-quality-gate.sh (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green. TODO markers
# point at per-surface assertions the operator should fill in.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/polish-preflight-quality-gate.sh"

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

# ===== fillin-specific assertions (flywheel-k46et — polish-preflight-quality-gate) =====

# Test 14: --info schema_version matches surface pattern
if "$SCRIPT" --info --json 2>/dev/null | jq -e '.schema_version | test("^polish-preflight-quality-gate/v[0-9]+$")' >/dev/null; then
  pass "--info schema_version matches polish-preflight-quality-gate/v1 pattern"
else fail "--info schema_version pattern"; fi

# Test 15: --schema repair lists 2 known scopes
if "$SCRIPT" --schema repair 2>/dev/null \
  | jq -e '.scopes | index("audit-log-rotate") and index("lock-dir-prune")' >/dev/null; then
  pass "--schema repair lists audit-log-rotate + lock-dir-prune"
else fail "--schema repair scopes"; fi

# Test 16: doctor 5 named probes
if "$SCRIPT" doctor --json 2>/dev/null \
  | jq -e '.checks | length >= 5 and (any(.name == "jq_on_path")) and (any(.name == "ledger_dir_writable")) and (any(.name == "lock_dir_writable"))' >/dev/null; then
  pass "doctor: 5+ probes incl. jq_on_path + ledger_dir_writable + lock_dir_writable"
else fail "doctor substrate probes"; fi

# Test 17: repair lock-dir-prune emits non-stub envelope with lock_count + stale_count
if "$SCRIPT" repair --scope lock-dir-prune --dry-run --json 2>/dev/null \
  | jq -e '.command == "repair" and .scope == "lock-dir-prune" and (.status != "todo") and has("lock_dir") and has("lock_count") and has("stale_count")' >/dev/null; then
  pass "repair --scope lock-dir-prune emits non-stub envelope with lock_count + stale_count"
else fail "repair scope-specific"; fi

# Test 18: validate --row-json enforces row schema
if "$SCRIPT" validate --row-json='{"ts":"2026-05-11T00:00:00Z","command":"preflight","schema_version":"x/v1"}' 2>/dev/null \
  | jq -e '.command == "validate" and .subject == "row" and .status == "pass" and (.valid == true)' >/dev/null; then
  pass "validate --row-json enforces row schema"
else fail "validate row schema"; fi

# Test 19: validate --plan-slug probes plan dir — surface-specific
if "$SCRIPT" validate --plan-slug=bogus-slug 2>/dev/null \
  | jq -e '.command == "validate" and .subject == "plan-slug" and has("plan_dir") and has("plan_dir_present") and has("state_file_present")' >/dev/null; then
  pass "validate --plan-slug probes plan dir (preflight-specific subject)"
else fail "validate plan-slug subject"; fi

# Test 20: validate --gate-state emits ledger snapshot — surface-specific
if "$SCRIPT" validate --gate-state 2>/dev/null \
  | jq -e '.command == "validate" and .subject == "gate-state" and has("polish_preflight_ledger") and has("ledger_present") and has("gates_count")' >/dev/null; then
  pass "validate --gate-state emits ledger snapshot (preflight-specific subject)"
else fail "validate gate-state subject"; fi


if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
