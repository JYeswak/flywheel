#!/usr/bin/env bash
# test-validator-uses-isolated-tmpdir.sh
# Structural gate coverage test for META-RULE: validator-uses-isolated-tmpdir
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
RULE="validator-uses-isolated-tmpdir"
MEMORY_DIR="${MEMORY_RULE_GATE_PARITY_MEMORY_DIR:-$HOME/.claude/projects/-Users-josh-Developer-flywheel/memory}"
MEMORY_FILE="$MEMORY_DIR/feedback_validator_uses_isolated_tmpdir.md"
GATE="$ROOT/.flywheel/scripts/meta-rule-structural-batch-gate.sh"
DETECTOR="$ROOT/.flywheel/scripts/memory-rule-gate-parity-detector.sh"
TMP="$(mktemp -d -t validator-isolated-tmpdir-parity.XXXXXX)"

cleanup() {
  find "$TMP" -mindepth 1 -maxdepth 1 -delete 2>/dev/null || true
  rmdir "$TMP" 2>/dev/null || true
}
trap cleanup EXIT

fail() {
  printf 'FAIL %s\n' "$*" >&2
  exit 1
}

[[ -x "$GATE" ]] || fail "gate script not executable: $GATE"
[[ -x "$DETECTOR" ]] || fail "detector script not executable: $DETECTOR"
[[ -f "$MEMORY_FILE" ]] || fail "memory file missing: $MEMORY_FILE"

gate_output="$("$GATE" "$RULE" 2>&1)" || fail "rule not registered (output=$gate_output)"
[[ "$gate_output" == *"REGISTERED"* ]] || fail "missing REGISTERED marker (output=$gate_output)"

rg -q 'mktemp -d -t <toolname>.XXXXXX' "$MEMORY_FILE" \
  || fail "memory rule missing isolated mktemp guidance"
rg -q 'Bare `/tmp/<fixed-name>.json`' "$MEMORY_FILE" \
  || fail "memory rule missing fixed tmp anti-pattern"

MEMORY_RULE_GATE_PARITY_LEDGER="$TMP/ledger.jsonl" \
  "$DETECTOR" check --memory-dir "$MEMORY_DIR" --json >"$TMP/parity.json"

jq -e --arg rule "$RULE" --arg path "$MEMORY_FILE" '
  any(.rules[];
    .rule_id == $rule
    and .memory_path == $path
    and .classification == "WIRED"
    and .evidence_count >= 3
    and (.missing_evidence | length) == 0
  )
' "$TMP/parity.json" >/dev/null || {
  jq --arg rule "$RULE" '.rules[] | select(.rule_id == $rule)' "$TMP/parity.json" >&2 || true
  fail "parity detector did not classify $RULE as WIRED"
}

printf 'PASS %s registered and parity-classified WIRED\n' "$RULE"
