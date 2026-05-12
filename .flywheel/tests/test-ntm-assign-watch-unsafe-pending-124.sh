#!/usr/bin/env bash
# test-ntm-assign-watch-unsafe-pending-124.sh
# Structural gate coverage test for META-RULE: ntm-assign-watch-unsafe-pending-124
# Verifies the live memory file is registered and classified WIRED by the parity detector.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
RULE="ntm-assign-watch-unsafe-pending-124"
MEMORY_DIR="${MEMORY_RULE_GATE_PARITY_MEMORY_DIR:-$HOME/.claude/projects/-Users-josh-Developer-flywheel/memory}"
MEMORY_FILE="$MEMORY_DIR/feedback_ntm_assign_watch_unsafe_pending_124.md"
GATE="$ROOT/.flywheel/scripts/meta-rule-structural-batch-gate.sh"
DETECTOR="$ROOT/.flywheel/scripts/memory-rule-gate-parity-detector.sh"
TMP="$(mktemp -d -t ntm-assign-watch-gate.XXXXXX)"

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
