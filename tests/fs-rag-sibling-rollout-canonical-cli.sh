#!/usr/bin/env bash
# tests/fs-rag-sibling-rollout-canonical-cli.sh
#
# Regression test for flywheel-2xdi.150: receiver wire-in for
# .flywheel/scripts/fs-rag-sibling-rollout.sh. Same recipe shape as the
# test-receiver wire-in pattern (N=4 promoted at 2xdi.146) — test file
# under canonical-cli naming = corpus #5 hit clears wired-but-cold.
#
# RECIPE-EXTENSION NOTE: this script is a MUTATION TOOL, not a probe.
# It does NOT have full canonical-cli triad (no --info / --schema /
# --doctor). Assertions test mutation-discipline + exit-codes + owner-
# bead citation instead of canonical-cli envelope assertions.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/fs-rag-sibling-rollout.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: syntax
if bash -n "$SCRIPT" 2>/dev/null; then pass "syntax"; else fail "syntax"; fi

# Test 2: VERSION constant present and stable
if grep -q '^VERSION="fs-rag-sibling-rollout/v1"' "$SCRIPT"; then
  pass "VERSION constant = fs-rag-sibling-rollout/v1"
else fail "VERSION constant missing or drifted"; fi

# Test 3: --help shows usage
help_out="$("$SCRIPT" --help 2>&1 | head -10)"
if printf '%s' "$help_out" | grep -qE "Usage:|fs-rag-sibling-rollout.sh"; then
  pass "--help shows usage"
else fail "--help usage missing"; fi

# Test 4: --apply refuses without --idempotency-key (mutation discipline)
out="$("$SCRIPT" --apply 2>&1 | head -1)"
if printf '%s' "$out" | grep -qE "ERR:.*--apply requires.*--idempotency-key"; then
  pass "mutation discipline: --apply refused without --idempotency-key"
else fail "mutation discipline broken: --apply allowed without idempotency-key ($out)"; fi

# Test 5: --apply with --idempotency-key is allowed (no immediate refusal)
# Note: actual apply would mutate sibling repos; we verify the args ARE
# accepted by checking that the script proceeds past the argument-parse
# stage (e.g., emits some output OTHER than the refusal error).
out="$("$SCRIPT" --apply --idempotency-key test-key-2xdi.150 --sibling /tmp/nonexistent-sibling 2>&1 | head -3)"
if ! printf '%s' "$out" | grep -qE "ERR:.*--apply requires.*--idempotency-key"; then
  pass "--apply --idempotency-key accepted (passes arg-parse)"
else fail "--apply --idempotency-key still refused"; fi

# Test 6: default is --dry-run (script comment + behavior)
if grep -q "Default --dry-run" "$SCRIPT"; then
  pass "default --dry-run discipline documented in script"
else fail "--dry-run default not documented"; fi

# Test 7: stable exit codes documented in header
if grep -qE "exit codes:.*0[^0-9]+ok.*1[^0-9]+rollout.*64[^0-9]+usage" "$SCRIPT"; then
  pass "stable exit codes documented (0 ok / 1 rollout / 64 usage)"
else fail "exit codes contract not documented in script header"; fi

# Test 8: cites owning bead flywheel-uwqf0
if grep -q "flywheel-uwqf0" "$SCRIPT"; then
  pass "script header cites owning bead flywheel-uwqf0"
else fail "script doesn't cite owning bead"; fi

# Test 9: cites parent bead flywheel-hi4e6 (Meadows #5 refinement context)
if grep -q "flywheel-hi4e6" "$SCRIPT"; then
  pass "script header cites parent bead flywheel-hi4e6 (Meadows #5 context)"
else fail "script doesn't cite parent bead"; fi

# Test 10: doctrine cross-ref present (apply-spec.md AG3)
if grep -q "apply-spec.md" "$SCRIPT"; then
  pass "script cites doctrine apply-spec.md AG3"
else fail "doctrine cross-ref missing"; fi

# Test 11: unknown arg returns ERR (defensive arg parse)
out="$("$SCRIPT" --bogus-flag 2>&1 | head -1)"
if printf '%s' "$out" | grep -qiE "ERR:|unknown|usage"; then
  pass "unknown arg rejected with ERR/unknown/usage"
else fail "unknown arg silently accepted ($out)"; fi

# Test 12: --json flag accepted (machine-readable output)
out="$("$SCRIPT" --json --help 2>&1 | head -3)"
# --json + --help combo: --help wins (shows usage); the --json flag should not error
if [[ $? -eq 0 ]] || printf '%s' "$out" | grep -qE "Usage:|fs-rag"; then
  pass "--json flag accepted (no parse error)"
else fail "--json flag triggers parse error"; fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
