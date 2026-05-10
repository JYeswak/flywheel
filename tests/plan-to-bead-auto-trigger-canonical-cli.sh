#!/usr/bin/env bash
# tests/plan-to-bead-auto-trigger-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/plan-to-bead-auto-trigger.sh (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green. TODO markers
# point at per-surface assertions the operator should fill in.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/plan-to-bead-auto-trigger.sh"

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

# Test 7: repair --dry-run envelope (use real scope: plans_dir)
if "$SCRIPT" repair --scope plans_dir --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .mode == "dry_run" and .scope == "plans_dir"' >/dev/null; then
  pass "repair --scope plans_dir --dry-run emits canonical envelope"
else fail "repair --dry-run envelope"; fi

# Test 8: repair --apply without --idempotency-key REFUSES (rc=3)
"$SCRIPT" repair --scope plans_dir --apply --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 3 ]]; then
  pass "repair --apply without --idempotency-key returns rc=3 (canonical refusal)"
else
  fail "repair --apply rc=$rc (expected 3)"
fi

# Test 9: validate without subject refuses with rc=64 (canonical contract)
"$SCRIPT" validate --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 64 ]]; then
  pass "validate without subject refuses with rc=64 (canonical contract)"
else
  fail "validate without subject rc=$rc (expected 64)"
fi

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

# ---- Fillin-specific assertions (flywheel-gbfpo) ----

# Test 14 (load-bearing): doctor concrete checks (>=5 named substrate probes per AG5)
if "$SCRIPT" doctor --json 2>/dev/null \
    | jq -e '(.checks | length >= 5) and (.checks | all(.name and (.status | IN("pass","warn","fail"))))' >/dev/null; then
  pass "doctor returns >=5 named checks with valid statuses"
else fail "doctor concrete checks <5 or wrong shape"; fi

# Test 15 (load-bearing): doctor probes load-bearing br + jq + plans_dir
if "$SCRIPT" doctor --json 2>/dev/null \
    | jq -e '(.checks | any(.name == "br_executable")) and (.checks | any(.name == "jq_available")) and (.checks | any(.name == "plans_dir_present"))' >/dev/null; then
  pass "doctor probes br + jq + plans_dir (load-bearing for plan-to-bead pipeline)"
else fail "doctor missing load-bearing checks"; fi

# Test 16 (load-bearing): validate plan-path enforces .flywheel/PLANS/ + .md constraints
"$SCRIPT" validate plan-path /tmp/__not-under-plans__.md >/tmp/__pbat-validate.json 2>&1
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.subject == "plan-path" and .status == "fail" and .reason == "not_under_plans_dir"' /tmp/__pbat-validate.json >/dev/null 2>&1; then
  pass "validate plan-path rejects path outside .flywheel/PLANS/ with rc=1"
else
  fail "validate plan-path outside-PLANS rc=$rc shape may be wrong"
fi
rm -f /tmp/__pbat-validate.json

# Test 17 (load-bearing): validate plan-path rejects non-.md with rc=1
"$SCRIPT" validate plan-path .flywheel/PLANS/not-markdown.txt >/tmp/__pbat-validate2.json 2>&1
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.subject == "plan-path" and .status == "fail" and .reason == "not_markdown_extension"' /tmp/__pbat-validate2.json >/dev/null 2>&1; then
  pass "validate plan-path rejects non-.md extension with rc=1"
else
  fail "validate plan-path non-.md rc=$rc shape may be wrong"
fi
rm -f /tmp/__pbat-validate2.json

# Test 18 (load-bearing): validate bead-id accepts dotted sub-bead pattern
if "$SCRIPT" validate bead-id "flywheel-wzjo9.1.2" 2>/dev/null \
    | jq -e '.subject == "bead-id" and .status == "pass"' >/dev/null; then
  pass "validate bead-id accepts dotted sub-bead pattern (flywheel-X.N.M)"
else fail "validate bead-id rejected dotted sub-bead pattern"; fi

# Test 19: schema doctor returns concrete shape (not 'todo')
if "$SCRIPT" --schema doctor 2>/dev/null | jq -e '.surface == "doctor" and .fields' >/dev/null; then
  pass "schema doctor returns concrete shape"
else fail "schema doctor missing concrete shape"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
