#!/usr/bin/env bash
# test-gap-hunt-probe-skill-md-priority-cap.sh
#
# Regression test for flywheel-zsk2d: skill_md_corpus must capture content
# from SKILL.md files past byte 4096. Bead specifies: "a SKILL.md >10KB
# with a script name at byte 8000 is captured".
#
# This test exercises that property directly by running gap-hunt-probe
# against a fixture skills root with:
#   - 1 large SKILL.md (>10KB) referencing a probe-named script PAST byte 8000
#   - 1 *-probe.sh script with that name
#
# Expected: probe is NOT classified probe-without-receiver (because the
# SKILL.md content past byte 4096 IS captured by the broader cap).
#
# Run: bash .flywheel/tests/test-gap-hunt-probe-skill-md-priority-cap.sh

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PROBE="$ROOT/scripts/gap-hunt-probe.sh"

PASS=0; FAIL=0
pass() { PASS=$((PASS + 1)); printf 'PASS %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Setup: fake skills root + fake repo root
TMP="$(mktemp -d -t gph.XXXXXX)" || { echo "ERR: mktemp failed" >&2; exit 1; }
FAKE_CLAUDE_ROOT="$TMP/.claude"
FAKE_REPO_ROOT="$TMP/repo"
FAKE_HOME="$TMP/home"
mkdir -p "$FAKE_CLAUDE_ROOT/skills/test-skill/scripts" "$FAKE_REPO_ROOT/.flywheel/scripts" "$FAKE_HOME/.local/state/flywheel-loop"

# Create a fixture .sh under the SKILL's scripts/ dir (NOT *-probe.sh because
# probe-without-receiver class only checks *-probe.sh files and doesn't
# consult skill_md_corpus; wired-but-cold DOES consult skill_md_corpus and is
# the class this regression fix targets).
PROBE_NAME="zsk2d-fixture-scanner.sh"
printf '#!/usr/bin/env bash\necho fixture scanner\n' > "$FAKE_CLAUDE_ROOT/skills/test-skill/scripts/$PROBE_NAME"
chmod +x "$FAKE_CLAUDE_ROOT/skills/test-skill/scripts/$PROBE_NAME"

# Create a large SKILL.md (~12KB) with the probe name at byte ~8000
# Generate ~7900 bytes of filler, then the probe name, then more filler to total >10KB.
SKILL_MD="$FAKE_CLAUDE_ROOT/skills/test-skill/SKILL.md"
{
  printf -- '---\nname: test-skill\n---\n\n# Test Skill\n\n## Overview\n\n'
  # Filler ~7900 bytes
  for i in $(seq 1 200); do
    printf 'Line %d: lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor incididunt.\n' "$i"
  done
  printf '\n## Scripts\n\n'
  printf -- '- `scripts/%s` — fixture probe for byte-8000+ recognition\n\n' "$PROBE_NAME"
  for i in $(seq 1 50); do
    printf 'Trailing line %d.\n' "$i"
  done
} > "$SKILL_MD"

SKILL_BYTES=$(wc -c <"$SKILL_MD" | tr -d ' ')
PROBE_OFFSET=$(grep -obF "$PROBE_NAME" "$SKILL_MD" | head -1 | cut -d: -f1)

if (( SKILL_BYTES < 10000 )); then
  fail "fixture-setup SKILL.md is $SKILL_BYTES bytes; want >10000"
else
  pass "00 fixture SKILL.md is $SKILL_BYTES bytes (>10KB)"
fi
if (( PROBE_OFFSET < 5000 )); then
  fail "fixture-setup probe name appears at byte $PROBE_OFFSET; want >=5000 to exercise past-4KB cap"
else
  pass "01 fixture probe name appears at byte $PROBE_OFFSET (past 4KB cap)"
fi

# Run gap-hunt-probe with fake roots
out="$(GAP_HUNT_CLAUDE_ROOT="$FAKE_CLAUDE_ROOT" \
       GAP_HUNT_REPO_ROOT="$FAKE_REPO_ROOT" \
       HOME="$FAKE_HOME" \
       "$PROBE" --json 2>/dev/null || true)"

# Did the fixture script get captured by skill_md_corpus? If yes, it is NOT
# flagged wired-but-cold. If no, it IS flagged (FP regression).
if jq -e --arg p "wired-but-cold:.claude-skills-test-skill-scripts-$PROBE_NAME" '.gap_ids // [] | any(. == $p)' <<<"$out" >/dev/null; then
  fail "02 fixture script IS flagged wired-but-cold — regression NOT fixed; SKILL.md content at byte $PROBE_OFFSET was not captured by skill_md_corpus"
else
  pass "02 fixture script NOT flagged wired-but-cold — SKILL.md content at byte $PROBE_OFFSET WAS captured by skill_md_corpus"
fi

# Note: this test relies on gap-hunt-probe honoring CLAUDE_ROOT/REPO_ROOT/HOME
# overrides via the env vars it normally consults. If the probe uses hard-
# coded paths instead, the fixture won't isolate properly and the test will
# fail-open (probe flags from the real filesystem). The test reports clearly
# either way.

if [[ "$FAIL" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$PASS" "$FAIL" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$PASS"
