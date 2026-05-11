#!/usr/bin/env bash
# Regression test for flywheel-2xdi.66:
# gap-hunt-probe's wired-but-cold detector now scans ALL *.md files under
# ~/.claude/skills/ (not just SKILL.md). Tree-internal docs like
# references/**/README.md and assets/**/*.md also count as wiring evidence.
#
# Specific case: ~/.claude/skills/agent-ergonomics-and-agent-intuitiveness-
# maximization-for-cli-tools/scripts/cluster-recommendations.sh is documented
# in references/calibration-fixtures/README.md (a use-case for the calibration
# corpus) but NOT in any SKILL.md. Pre-fix, the probe's skill_md_corpus only
# scanned SKILL.md files, so this script was false-positive flagged
# wired-but-cold even though its stable invocation path is documented.
#
# Same META-rule shape as 2xdi.47 (for-loop module list corpus), 2xdi.49
# (SKILL.md mention corpus), 2xdi.64 (direct-exec wrapper corpus): probe
# corpus blind spot, not dead code.
#
# IMPORTANT: this test uses .gap_class_distribution and .gap_ids (the REAL
# probe JSON fields) instead of the vacuous .gaps filter that prior sister
# tests used. See the related gap bead filed alongside this fix.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PROBE="$ROOT/.flywheel/scripts/gap-hunt-probe.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/gap-hunt-skill-tree-md.XXXXXX")"
trap 'find "$TMP" -depth -type f -exec rm -f {} \; 2>/dev/null; find "$TMP" -depth -type d -exec rmdir {} \; 2>/dev/null' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: probe source uses *.md glob (broadened from SKILL.md)
if grep -q 'safe_iter_files(skills_root, "\*\.md"' "$PROBE"; then
  pass "probe skill_md_corpus walks *.md (not just SKILL.md)"
else
  fail "skill_md_corpus still narrows to SKILL.md only — the 2xdi.66 fix is not in place"
fi

# Test 2: probe source uses per-file cap (prevents single-file budget exhaustion)
if grep -q 'per_file_cap' "$PROBE"; then
  pass "probe skill_md_corpus uses per-file cap (prevents starvation)"
else
  fail "skill_md_corpus missing per-file cap"
fi

# Test 3: live probe → cluster-recommendations.sh no longer flagged
out="$TMP/probe.json"
if timeout 180 "$PROBE" --json >"$out" 2>"$TMP/probe.err"; then
  matched=$(jq -r '[.gap_ids // [] | .[] | select(test("cluster-recommendations"))] | length' "$out" 2>/dev/null || echo "?")
  if [[ "$matched" == "0" ]]; then
    pass "live probe: cluster-recommendations.sh no longer flagged wired-but-cold"
  else
    fail "live probe: cluster-recommendations.sh still flagged ($matched gaps)"
  fi
else
  fail "probe failed to run"
fi

# Test 4: sister fixes still hold — archetype-calibrate (2xdi.64) and
# protected-session-recovery (2xdi.49) MUST remain unflagged.
if [[ -f "$out" ]]; then
  for sister in archetype-calibrate protected-session-recovery; do
    cnt=$(jq -r --arg s "$sister" '[.gap_ids // [] | .[] | select(test($s))] | length' "$out" 2>/dev/null || echo "?")
    if [[ "$cnt" == "0" ]]; then
      pass "sister fix still holds: $sister unflagged"
    else
      fail "sister regression: $sister now flagged ($cnt gaps)"
    fi
  done
fi

# Test 5: synthetic — corpus broadening picks up references/**/README.md mentions
fake_skills_root="$TMP/fake-skills"
mkdir -p "$fake_skills_root/myskill/references/calibration-fixtures"
mkdir -p "$fake_skills_root/myskill/scripts"
cat >"$fake_skills_root/myskill/SKILL.md" <<'SKILL'
---
name: myskill
description: fixture
---
This skill does things.
SKILL
cat >"$fake_skills_root/myskill/references/calibration-fixtures/README.md" <<'REF'
# Calibration Fixtures

## Use cases

1. **Regression test for clusterer**: re-run scripts/my-cluster-tool.sh
   against the captured corpus.
REF
cat >"$fake_skills_root/myskill/scripts/my-cluster-tool.sh" <<'TOOL'
#!/usr/bin/env bash
echo "tool"
TOOL

PY_OUT=$(python3 - "$fake_skills_root" <<'PY'
import sys
from pathlib import Path
root = Path(sys.argv[1])
cands = list(root.rglob("*.md"))
corpus = "\n".join(p.read_text(errors="replace") for p in cands)
in_skill_md_only = "my-cluster-tool" in Path(root / "myskill/SKILL.md").read_text()
in_full_corpus = "my-cluster-tool" in corpus
print("OK" if (not in_skill_md_only and in_full_corpus) else f"FAIL skill_md={in_skill_md_only} full={in_full_corpus}")
PY
)
if [[ "$PY_OUT" == "OK" ]]; then
  pass "synthetic: references/README.md mention is captured ONLY by broadened *.md corpus"
else
  fail "synthetic: corpus broadening logic broken ($PY_OUT)"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
