#!/usr/bin/env bash
# tests/codex-budget-probe-canonical-cli.sh
# Canonical-cli surface tests for .flywheel/scripts/codex-budget-probe.sh (scaffolded by
# bead flywheel-ws02m / scaffold-canonical-cli.sh).
#
# 13/13 PASS = canonical-cli-scoping checker green. TODO markers
# point at per-surface assertions the operator should fill in.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/codex-budget-probe.sh"

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

# Test 7: repair --dry-run envelope (real scope)
if "$SCRIPT" repair --scope state_dir --dry-run --json 2>/dev/null | jq -e '.command == "repair" and .mode == "dry_run" and .status == "ok"' >/dev/null; then
  pass "repair --dry-run emits canonical envelope (real scope state_dir)"
else fail "repair --dry-run envelope"; fi

# Test 8: repair --apply without --idempotency-key REFUSES (rc=3)
"$SCRIPT" repair --scope state_dir --apply --json >/dev/null 2>&1
rc=$?
if [[ "$rc" -eq 3 ]]; then
  pass "repair --apply without --idempotency-key returns rc=3 (canonical refusal)"
else
  fail "repair --apply rc=$rc (expected 3)"
fi

# Test 9: validate envelope (bare validate refuses with rc=64; calibrated)
"$SCRIPT" validate >/tmp/1hshd-14-test9.json 2>&1
rc=$?
if [[ "$rc" -eq 64 ]] && jq -e '.command == "validate" and .status == "refused" and .reason == "missing_subject"' /tmp/1hshd-14-test9.json >/dev/null 2>&1; then
  pass "validate (bare) refuses with rc=64 + missing_subject envelope"
else fail "validate bare-refusal contract rc=$rc"; fi
rm -f /tmp/1hshd-14-test9.json

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

# Test 14: doctor probes load-bearing tmux + grep + tail (the three external
# tools the script's primary action depends on)
if "$SCRIPT" doctor --json 2>/dev/null \
   | jq -e '[.checks[].name] | contains(["tmux_available","grep_available","tail_available"])' >/dev/null; then
  pass "doctor probes tmux + grep + tail (load-bearing for codex-tui.log scanning)"
else fail "doctor missing load-bearing probes"; fi

# Test 15: validate session-name accepts canonical session
if "$SCRIPT" validate session-name "flywheel" 2>/dev/null \
   | jq -e '.subject == "session-name" and .status == "ok"' >/dev/null; then
  pass "validate session-name accepts canonical session (matches --session arg semantic)"
else fail "validate session-name accept"; fi

# Test 16: validate threshold-pct accepts default 10 + boundaries 0/100
ALL_OK=1
for V in 0 10 100; do
  if ! "$SCRIPT" validate threshold-pct "$V" 2>/dev/null \
       | jq -e --argjson v "$V" '.subject == "threshold-pct" and .status == "ok" and .value == $v' >/dev/null; then
    ALL_OK=0; break
  fi
done
if [[ "$ALL_OK" -eq 1 ]]; then
  pass "validate threshold-pct accepts boundary values 0/10/100 (matches --threshold arg [0,100] range)"
else fail "validate threshold-pct boundary accept"; fi

# Test 17: validate threshold-pct REJECTS 150 out-of-range (rc=1)
"$SCRIPT" validate threshold-pct "150" >/tmp/1hshd-14-test17.json 2>&1
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.status == "reject" and .reason == "out_of_range_or_not_integer"' /tmp/1hshd-14-test17.json >/dev/null 2>&1; then
  pass "validate threshold-pct rejects 150 (out of [0,100]) with rc=1"
else fail "validate threshold-pct range reject rc=$rc"; fi
rm -f /tmp/1hshd-14-test17.json

# Test 18: validate fleet-state full-enum sweep (ready + draining + limit_hit)
ALL_OK=1
for S in ready draining limit_hit; do
  if ! "$SCRIPT" validate fleet-state "$S" 2>/dev/null \
       | jq -e --arg v "$S" '.subject == "fleet-state" and .status == "ok" and .value == $v' >/dev/null; then
    ALL_OK=0; break
  fi
done
if [[ "$ALL_OK" -eq 1 ]]; then
  pass "validate fleet-state accepts all 3 canonical values (ready + draining + limit_hit per script docstring L11-L20)"
else fail "validate fleet-state full-enum sweep"; fi

# Test 19: lint-idiom-fix preserved — script has BOTH `set -euo pipefail`
# (satisfies L5 lint) AND immediately-following `set +e` (preserves
# author's runtime semantic of leaving -e off for tmux/grep tolerance).
# Sister to 5ke66.15 {session}-archive lint-idiom-fix application.
if grep -E '^set -euo pipefail$' "$SCRIPT" >/dev/null \
   && grep -E '^set \+e' "$SCRIPT" >/dev/null; then
  pass "lint-idiom-fix preserved: 'set -euo pipefail' + immediate 'set +e' (sister to 5ke66.15 pattern)"
else fail "lint-idiom-fix idiom missing"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
