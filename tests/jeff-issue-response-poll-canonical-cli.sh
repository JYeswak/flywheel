#!/usr/bin/env bash
# tests/jeff-issue-response-poll-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/jeff-issue-response-poll.sh (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green. TODO markers
# point at per-surface assertions the operator should fill in.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/jeff-issue-response-poll.sh"

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
if "$SCRIPT" repair --scope registry_dir --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .mode == "dry_run" and .status == "ok"' >/dev/null; then
  pass "repair --dry-run emits canonical envelope (real scope)"
else fail "repair --dry-run envelope"; fi

# Test 8: repair --apply without --idempotency-key REFUSES (rc=3)
"$SCRIPT" repair --scope registry_dir --apply --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 3 ]]; then
  pass "repair --apply without --idempotency-key returns rc=3 (canonical refusal)"
else
  fail "repair --apply rc=$rc (expected 3)"
fi

# Test 9: validate envelope (bare validate refuses with rc=64 per actual contract;
# calibrated per feedback_calibrate_test_to_actual_contract META-RULE 2026-05-09)
"$SCRIPT" validate >/tmp/64hud-test9.json 2>&1
rc=$?
if [[ "$rc" -eq 64 ]] && jq -e '.command == "validate" and .status == "refused" and .reason == "missing_subject"' /tmp/64hud-test9.json >/dev/null 2>&1; then
  pass "validate (bare) refuses with rc=64 + missing_subject envelope"
else fail "validate bare-refusal contract rc=$rc"; fi
rm -f /tmp/64hud-test9.json

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

# Test 14: doctor probes load-bearing br_available + jeff_issues_status_available
if "$SCRIPT" doctor --json 2>/dev/null | jq -e '[.checks[].name] | contains(["br_available","jeff_issues_status_available"])' >/dev/null; then
  pass "doctor probes br + jeff_issues_status (load-bearing for bead-create + poll)"
else fail "doctor missing br/jeff_issues_status probes"; fi

# Test 15: validate jeff-issue-ref accepts canonical owner/repo#N form
if "$SCRIPT" validate jeff-issue-ref "dicklesworthstone/beads_rust#270" 2>/dev/null \
   | jq -e '.subject == "jeff-issue-ref" and .status == "ok"' >/dev/null; then
  pass "validate jeff-issue-ref accepts owner/repo#N (Jeff's canonical issue ref form)"
else fail "validate jeff-issue-ref canonical accept"; fi

# Test 16: validate jeff-issue-ref REJECTS without slash or hash (rc=1)
"$SCRIPT" validate jeff-issue-ref "noslash-no-hash" >/tmp/64hud-test16.json 2>&1
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.status == "reject" and .reason == "pattern_mismatch"' /tmp/64hud-test16.json >/dev/null 2>&1; then
  pass "validate jeff-issue-ref rejects malformed ref with rc=1"
else fail "validate jeff-issue-ref reject rc=$rc"; fi
rm -f /tmp/64hud-test16.json

# Test 17: validate registry-row accepts JSONL with required repo + number fields
TMPREG="$(mktemp -t jeff-issue-poll-reg-XXXXX)"
printf '{"repo":"dicklesworthstone/beads_rust","number":270,"state":"open"}\n' > "$TMPREG"
if "$SCRIPT" validate registry-row "$TMPREG" 2>/dev/null \
   | jq -e '.subject == "registry-row" and .status == "ok"' >/dev/null; then
  pass "validate registry-row accepts well-formed JSONL with repo + number"
else fail "validate registry-row accept"; fi
rm -f "$TMPREG"

# Test 18: validate registry-row REJECTS row missing required field (rc=1)
TMPREG="$(mktemp -t jeff-issue-poll-bad-XXXXX)"
printf '{"repo":"dicklesworthstone/beads_rust"}\n' > "$TMPREG"
"$SCRIPT" validate registry-row "$TMPREG" >/tmp/64hud-test18.json 2>&1
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.status == "reject" and .reason == "missing_required_fields"' /tmp/64hud-test18.json >/dev/null 2>&1; then
  pass "validate registry-row rejects row missing 'number' with rc=1"
else fail "validate registry-row reject rc=$rc"; fi
rm -f "$TMPREG" /tmp/64hud-test18.json

# Test 19: repair refuses unknown scope with rc=64 + canonical envelope
"$SCRIPT" repair --scope nope --dry-run >/tmp/64hud-test19.json 2>&1
rc=$?
if [[ "$rc" -eq 64 ]] && jq -e '.status == "refused" and .reason == "unknown_scope"' /tmp/64hud-test19.json >/dev/null 2>&1; then
  pass "repair refuses unknown scope with rc=64 + unknown_scope envelope"
else fail "repair unknown-scope rc=$rc"; fi
rm -f /tmp/64hud-test19.json

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
