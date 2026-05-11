#!/usr/bin/env bash
# test-gap-hunt-probe-cross-source-silos-cap-and-name-match.sh
#
# Regression test for flywheel-nq5ns: gap-hunt-probe cross-source-silos
# class now uses 3-form name matching:
#   1. Full ledger basename (e.g. "X-runs.jsonl")
#   2. Path stem (e.g. "X-runs")
#   3. NEW: producer-script-stem (strip "-runs" suffix → "X")
#
# This catches the canonical scaffold pattern where:
#   - Producer script is `X.sh`
#   - Ledger is `X-runs.jsonl`
#   - Doctrine/INCIDENTS cites `X.sh` (the script), not `X-runs.jsonl`
#
# Without producer-stem match, `X-runs.jsonl` is falsely flagged silo
# even though X.sh is doctrine-cited.
#
# Run: bash .flywheel/tests/test-gap-hunt-probe-cross-source-silos-cap-and-name-match.sh

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PROBE="$ROOT/scripts/gap-hunt-probe.sh"

PASS=0; FAIL=0
pass() { PASS=$((PASS + 1)); printf 'PASS %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Build isolated environment
TMP="$(mktemp -d -t cssi.XXXXXX)" || { echo "ERR: mktemp failed" >&2; exit 1; }
FAKE_CLAUDE_ROOT="$TMP/.claude"
FAKE_REPO_ROOT="$TMP/repo"
FAKE_HOME="$TMP/home"
STATE_DIR="$FAKE_HOME/.local/state/flywheel"
mkdir -p "$FAKE_CLAUDE_ROOT/commands/flywheel" "$FAKE_REPO_ROOT/.flywheel/scripts" "$FAKE_REPO_ROOT/.flywheel/doctrine" "$STATE_DIR"
mkdir -p "$FAKE_HOME/.local/state/flywheel-loop"

# Create 3 fake ledgers under STATE_DIR
# Ledger A: producer-script-name cited in INCIDENTS.md (SHOULD NOT be flagged)
printf '%s\n' '{"ts":"2026-05-11T00:00:00Z"}' > "$STATE_DIR/test-producer-cited-runs.jsonl"
# Ledger B: not cited anywhere (SHOULD be flagged silo)
printf '%s\n' '{"ts":"2026-05-11T00:00:00Z"}' > "$STATE_DIR/test-genuinely-orphan-runs.jsonl"
# Ledger C: full basename cited (SHOULD NOT be flagged)
printf '%s\n' '{"ts":"2026-05-11T00:00:00Z"}' > "$STATE_DIR/test-full-basename-cited-runs.jsonl"

# Build minimal corpus surfaces — INCIDENTS.md cites A's producer; tick.md cites C's full basename
printf '# Receivers\n' > "$FAKE_CLAUDE_ROOT/commands/flywheel/tick.md"
printf '# Status\n' > "$FAKE_CLAUDE_ROOT/commands/flywheel/status.md"
printf '# Synth\n' > "$FAKE_CLAUDE_ROOT/commands/flywheel/synth.md"
printf '# Agents\n' > "$FAKE_REPO_ROOT/AGENTS.md"
printf '# README\n' > "$FAKE_REPO_ROOT/README.md"
# INCIDENTS.md cites A's producer (.sh), not the ledger filename
cat > "$FAKE_REPO_ROOT/INCIDENTS.md" <<'EOF'
# INCIDENTS

## Some incident
Refer to `.flywheel/scripts/test-producer-cited.sh` for the validator.
EOF
# tick.md cites C's full basename
cat >> "$FAKE_CLAUDE_ROOT/commands/flywheel/tick.md" <<'EOF'

Self-logs to ~/.local/state/flywheel/test-full-basename-cited-runs.jsonl on every run.
EOF

# Run gap-hunt-probe with env overrides
out="$(GAP_HUNT_CLAUDE_ROOT="$FAKE_CLAUDE_ROOT" \
       GAP_HUNT_REPO_ROOT="$FAKE_REPO_ROOT" \
       GAP_HUNT_STATE_DIR="$STATE_DIR" \
       HOME="$FAKE_HOME" \
       "$PROBE" --json 2>/dev/null || true)"

# Assert ledger A (producer-cited) is NOT flagged
if jq -e --arg p "cross-source-silos:test-producer-cited-runs.jsonl" '.gap_ids // [] | any(. == $p)' <<<"$out" >/dev/null; then
  fail "01 A (producer-cited) IS flagged cross-source-silos — producer-stem fallback NOT working"
else
  pass "01 A (producer-cited via INCIDENTS.md) NOT flagged — producer-stem fallback works"
fi

# Assert ledger B (genuinely orphan) IS flagged
if jq -e --arg p "cross-source-silos:test-genuinely-orphan-runs.jsonl" '.gap_ids // [] | any(. == $p)' <<<"$out" >/dev/null; then
  pass "02 B (genuinely orphan) IS flagged cross-source-silos — TP preserved"
else
  fail "02 B (genuinely orphan) NOT flagged — TP discrimination broken (over-correction)"
fi

# Assert ledger C (full basename cited) is NOT flagged
if jq -e --arg p "cross-source-silos:test-full-basename-cited-runs.jsonl" '.gap_ids // [] | any(. == $p)' <<<"$out" >/dev/null; then
  fail "03 C (full basename cited) IS flagged — original behavior regressed"
else
  pass "03 C (full basename cited in tick.md) NOT flagged — original match preserved"
fi

if [[ "$FAIL" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$PASS" "$FAIL" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$PASS"
