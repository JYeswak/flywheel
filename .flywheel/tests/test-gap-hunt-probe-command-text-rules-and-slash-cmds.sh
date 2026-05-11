#!/usr/bin/env bash
# test-gap-hunt-probe-command-text-rules-and-slash-cmds.sh
#
# Regression test for flywheel-2f4br: gap-hunt-probe command_text() now
# samples 2 additional canonical receiver surfaces:
#   1. .flywheel/rules/*.md  — L-rule directory (sibling to doctrine/)
#   2. ~/.claude/commands/flywheel/*.md — ALL slash commands (not just
#      tick/status/synth)
#
# Without these samples, ledgers cited in L-rules OR in non-hardcoded
# slash commands (fleet-doctor, onboard, jeff-*, etc.) appear as
# cross-source-silos false positives.
#
# Run: bash .flywheel/tests/test-gap-hunt-probe-command-text-rules-and-slash-cmds.sh

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PROBE="$ROOT/scripts/gap-hunt-probe.sh"

PASS=0; FAIL=0
pass() { PASS=$((PASS + 1)); printf 'PASS %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Build isolated environment
TMP="$(mktemp -d -t ctrs.XXXXXX)" || { echo "ERR: mktemp failed" >&2; exit 1; }
FAKE_CLAUDE_ROOT="$TMP/.claude"
FAKE_REPO_ROOT="$TMP/repo"
FAKE_HOME="$TMP/home"
STATE_DIR="$FAKE_HOME/.local/state/flywheel"
mkdir -p \
  "$FAKE_CLAUDE_ROOT/commands/flywheel" \
  "$FAKE_REPO_ROOT/.flywheel/scripts" \
  "$FAKE_REPO_ROOT/.flywheel/doctrine" \
  "$FAKE_REPO_ROOT/.flywheel/rules" \
  "$STATE_DIR" \
  "$FAKE_HOME/.local/state/flywheel-loop"

# Minimal corpus stubs
printf '# Tick\n' > "$FAKE_CLAUDE_ROOT/commands/flywheel/tick.md"
printf '# Status\n' > "$FAKE_CLAUDE_ROOT/commands/flywheel/status.md"
printf '# Synth\n' > "$FAKE_CLAUDE_ROOT/commands/flywheel/synth.md"
printf '# Agents\n' > "$FAKE_REPO_ROOT/AGENTS.md"
printf '# Incidents\n' > "$FAKE_REPO_ROOT/INCIDENTS.md"
printf '# README\n' > "$FAKE_REPO_ROOT/README.md"

# Create 4 fake ledgers
# A: cited in L-rule (SHOULD NOT be flagged after fix)
printf '%s\n' '{"ts":"2026-05-11T00:00:00Z"}' > "$STATE_DIR/test-rule-cited-runs.jsonl"
# B: cited in NEW slash command (fleet-doctor) (SHOULD NOT be flagged after fix)
printf '%s\n' '{"ts":"2026-05-11T00:00:00Z"}' > "$STATE_DIR/test-slash-cmd-cited-runs.jsonl"
# C: cited in BOTH tick.md (existing hardcoded) and elsewhere (SHOULD NOT be flagged; sanity)
printf '%s\n' '{"ts":"2026-05-11T00:00:00Z"}' > "$STATE_DIR/test-tick-cited-runs.jsonl"
# D: genuinely orphan (SHOULD be flagged silo)
printf '%s\n' '{"ts":"2026-05-11T00:00:00Z"}' > "$STATE_DIR/test-genuinely-orphan-runs.jsonl"

# A: cite producer-stem in a fake L-rule
cat > "$FAKE_REPO_ROOT/.flywheel/rules/L999-test-fixture.md" <<'EOF'
# L999 Test Fixture

Refers to `.flywheel/scripts/test-rule-cited.sh` for the rule-cited fixture.
EOF

# B: cite producer-stem in a fake slash command (NOT hardcoded; tests glob)
cat > "$FAKE_CLAUDE_ROOT/commands/flywheel/fleet-doctor.md" <<'EOF'
# /flywheel:fleet-doctor

Invokes `.flywheel/scripts/test-slash-cmd-cited.sh --json` per its TODO.
EOF

# C: cite in tick.md (existing hardcoded receiver)
cat >> "$FAKE_CLAUDE_ROOT/commands/flywheel/tick.md" <<'EOF'

Tick invokes test-tick-cited-runs.jsonl ledger.
EOF

# Run gap-hunt-probe with env overrides
out="$(GAP_HUNT_CLAUDE_ROOT="$FAKE_CLAUDE_ROOT" \
       GAP_HUNT_REPO_ROOT="$FAKE_REPO_ROOT" \
       GAP_HUNT_STATE_DIR="$STATE_DIR" \
       HOME="$FAKE_HOME" \
       "$PROBE" --json 2>/dev/null || true)"

# Assert A (L-rule cited) NOT flagged
if jq -e --arg p "cross-source-silos:test-rule-cited-runs.jsonl" '.gap_ids // [] | any(. == $p)' <<<"$out" >/dev/null; then
  fail "01 A (L-rule cited) IS flagged — rules/ dir sample NOT working"
else
  pass "01 A (L-rule cited in .flywheel/rules/L999-test-fixture.md) NOT flagged — rules/ sample works"
fi

# Assert B (slash-command cited) NOT flagged
if jq -e --arg p "cross-source-silos:test-slash-cmd-cited-runs.jsonl" '.gap_ids // [] | any(. == $p)' <<<"$out" >/dev/null; then
  fail "02 B (slash-cmd cited in fleet-doctor.md) IS flagged — slash-cmd glob NOT working"
else
  pass "02 B (slash-cmd cited in fleet-doctor.md) NOT flagged — all-slash-cmds glob works"
fi

# Assert C (tick.md cited; sanity) NOT flagged
if jq -e --arg p "cross-source-silos:test-tick-cited-runs.jsonl" '.gap_ids // [] | any(. == $p)' <<<"$out" >/dev/null; then
  fail "03 C (tick.md cited) IS flagged — existing hardcoded sample regressed"
else
  pass "03 C (tick.md cited; sanity) NOT flagged — original behavior preserved"
fi

# Assert D (genuinely orphan) IS flagged
if jq -e --arg p "cross-source-silos:test-genuinely-orphan-runs.jsonl" '.gap_ids // [] | any(. == $p)' <<<"$out" >/dev/null; then
  pass "04 D (genuinely orphan) IS flagged — TP preserved"
else
  fail "04 D (genuinely orphan) NOT flagged — TP discrimination broken (over-correction)"
fi

if [[ "$FAIL" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$PASS" "$FAIL" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$PASS"
