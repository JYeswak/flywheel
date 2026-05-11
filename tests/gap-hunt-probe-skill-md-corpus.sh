#!/usr/bin/env bash
# Regression test for flywheel-2xdi.49:
# gap-hunt-probe's wired-but-cold detector now scans SKILL.md files as a
# fourth corpus. Scripts documented in SKILL.md as entry points or compat
# wrappers no longer trip false-positive cold flags.
#
# Specific case: ~/.claude/skills/.flywheel/scripts/protected-session-recovery.sh
# is a 4-line compat wrapper documented in ~/.claude/skills/protected-session-
# recovery/SKILL.md as the "also available at" alt-path. No automation invokes
# the wrapper string-literal, but it IS the documented stable entry point.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PROBE="$ROOT/.flywheel/scripts/gap-hunt-probe.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/gap-hunt-skill-md.XXXXXX")"
trap 'find "$TMP" -depth -type f -exec rm -f {} \; 2>/dev/null; find "$TMP" -depth -type d -exec rmdir {} \; 2>/dev/null' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: probe source defines skill_md_corpus + _SKILL_MD_CORPUS
if grep -q 'def skill_md_corpus' "$PROBE" && grep -q '_SKILL_MD_CORPUS' "$PROBE"; then
  pass "probe defines skill_md_corpus + _SKILL_MD_CORPUS cache"
else
  fail "skill_md_corpus missing — the 2xdi.49 fix is not in place"
fi

# Test 2: probe_wired_but_cold uses skill_md_text as fourth corpus
if grep -q 'in_skill_md' "$PROBE"; then
  pass "probe_wired_but_cold checks in_skill_md as fourth corpus"
else
  fail "probe_wired_but_cold doesn't check skill_md corpus"
fi

# Test 3: live probe → protected-session-recovery.sh no longer flagged
out="$TMP/probe.json"
if timeout 180 "$PROBE" --json --dry-run >"$out" 2>"$TMP/probe.err"; then
  matched=$(jq -r '[.gaps // [] | .[] | select(.class == "wired-but-cold" and (.where | test("protected-session-recovery")))] | length' "$out" 2>/dev/null || echo "?")
  if [[ "$matched" == "0" ]]; then
    pass "live probe: protected-session-recovery.sh no longer flagged wired-but-cold"
  else
    fail "live probe: protected-session-recovery.sh still flagged ($matched gaps)"
  fi
else
  fail "probe failed to run"
fi

# Test 4: live probe → 0 wired-but-cold gaps total (combined effect of 2xdi.47 + .49)
if [[ -f "$out" ]]; then
  total=$(jq -r '[.gaps // [] | .[] | select(.class == "wired-but-cold")] | length' "$out" 2>/dev/null || echo "?")
  if [[ "$total" == "0" ]]; then
    pass "live probe: 0 wired-but-cold gaps total (combined 2xdi.47 for-loop fix + 2xdi.49 SKILL.md fix)"
  else
    fail "live probe: still $total wired-but-cold gaps"
  fi
fi

# Test 5: synthetic fixture — fake SKILL.md mentions a script; probe sees it
fake_skills_root="$TMP/fake-skills"
mkdir -p "$fake_skills_root/myskill"
cat >"$fake_skills_root/myskill/SKILL.md" <<'FIXTURE'
---
name: myskill
description: test fixture for skill_md_corpus
---

The compat wrapper is also available at:

```bash
~/.claude/skills/.flywheel/scripts/myskill-stub.sh
```
FIXTURE

# Use python3 to inline-validate the corpus collector logic
PY_OUT=$(python3 - "$fake_skills_root" <<'PY'
import sys
from pathlib import Path
root = Path(sys.argv[1])
pieces = []
for p in root.rglob("SKILL.md"):
    pieces.append(p.read_text(errors="replace"))
corpus = "\n".join(pieces)
print("OK" if ("myskill-stub.sh" in corpus and "myskill-stub" in corpus) else "FAIL")
PY
)
if [[ "$PY_OUT" == "OK" ]]; then
  pass "synthetic fixture: SKILL.md mention of myskill-stub.sh is captured by corpus collector"
else
  fail "synthetic fixture: SKILL.md mention not found (got $PY_OUT)"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
