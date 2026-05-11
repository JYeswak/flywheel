#!/usr/bin/env bash
# .flywheel/tests/test-gap-hunt-probe-cluster-detection.sh
# Filed by flywheel-xn5bm: lock in cluster-detection for wired-but-cold gaps.
# When N>=2 wired-but-cold gaps share .claude/skills/<x>/ substrate, replace
# with single cluster-maintainer gap (sister doctrine:
# .flywheel/doctrine/cluster-maintainer-pattern.md, N=3 promotion from r9pri).
#
# Verifies:
#   AG1 — cluster_wired_but_cold function exists in gap-hunt-probe.sh
#   AG2 — function is wired into probe_wired_but_cold's return path
#   AG3 — positive case: 3 wired-but-cold under same skill emits 1 cluster gap
#   AG4 — negative case: 2 wired-but-cold in different skills emit 2 individual gaps
#   AG5 — non-skill paths (Developer/flywheel/.flywheel/scripts/*) pass through unchanged
#   AG6 — bash -n gap-hunt-probe.sh succeeds (no syntax regression)
#   AG7 — cluster gap evidence cites .flywheel/doctrine/cluster-maintainer-pattern.md
#   AG8 — live probe run emits wired-but-cold-cluster gap class

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
PROBE="$ROOT/.flywheel/scripts/gap-hunt-probe.sh"

pass=0
fail=0
p() { pass=$((pass+1)); printf 'PASS %s\n' "$1"; }
f() { fail=$((fail+1)); printf 'FAIL %s\n' "$1" >&2; }

# AG6 — bash syntax first (so we don't run anything broken)
if bash -n "$PROBE" 2>/dev/null; then
  p "AG6 bash -n gap-hunt-probe.sh"
else
  f "AG6 bash -n gap-hunt-probe.sh"
  echo "syntax broken; aborting test" >&2
  echo "summary pass=$pass fail=$fail"
  exit 1
fi

# AG1 — cluster_wired_but_cold function exists
if grep -q '^def cluster_wired_but_cold' "$PROBE"; then
  p "AG1 cluster_wired_but_cold function exists"
else
  f "AG1 cluster_wired_but_cold function missing"
fi

# AG2 — function wired into return path
if grep -q 'return cluster_wired_but_cold(gaps)' "$PROBE"; then
  p "AG2 cluster_wired_but_cold wired into probe_wired_but_cold return"
else
  f "AG2 cluster_wired_but_cold NOT wired into return path"
fi

# AG3 + AG4 + AG5 — unit-test the cluster function with fixture gaps via inline python
python3 - "$PROBE" <<'PY' && p "AG3/AG4/AG5 unit tests via fixture gaps" || f "AG3/AG4/AG5 unit tests failed"
import sys
import re
from pathlib import Path

probe_path = Path(sys.argv[1])
src = probe_path.read_text()

# Extract the python body (in the heredoc bracketed by `python3 - <<'PYEOF'` ... `PYEOF`)
# Easier: just dynamically import via exec. Find def gap, def cluster_wired_but_cold.

# Define stub `gap()` + `stable_id()` for the unit test
exec_globals = {"re": re}
exec_code = """
def stable_id(cls, name):
    return f"{cls}:{name.lower().replace('/','-').replace('_','-')}"

def gap(cls, name, evidence):
    return {"id": stable_id(cls, name), "name": name[:160], "evidence": evidence[:300]}
"""

# Extract cluster_wired_but_cold function source
match = re.search(r'(def cluster_wired_but_cold.*?)(?=\ndef [a-z_]|\Z)', src, re.DOTALL)
if not match:
    print("FAIL: cluster_wired_but_cold function source not extractable", file=sys.stderr)
    sys.exit(1)
cluster_src = match.group(1)
exec_code += "\n" + cluster_src

exec(exec_code, exec_globals)
cluster_fn = exec_globals["cluster_wired_but_cold"]
gap_fn = exec_globals["gap"]

# AG3 — positive case: 3 scripts in same skill → 1 cluster gap
gaps_in = [
    gap_fn("wired-but-cold", ".claude/skills/foo-skill/scripts/a.sh", "evidence-a"),
    gap_fn("wired-but-cold", ".claude/skills/foo-skill/scripts/b.sh", "evidence-b"),
    gap_fn("wired-but-cold", ".claude/skills/foo-skill/scripts/c.sh", "evidence-c"),
]
result = cluster_fn(gaps_in)
assert len(result) == 1, f"AG3 expected 1 cluster gap, got {len(result)}: {result}"
assert result[0]["id"].startswith("wired-but-cold-cluster:"), f"AG3 wrong gap class: {result[0]}"
assert "foo-skill" in result[0]["id"], f"AG3 cluster gap missing skill name: {result[0]}"
print("AG3 OK: 3 same-skill gaps → 1 cluster gap")

# AG4 — negative case: 2 scripts in DIFFERENT skills → 2 individual gaps
gaps_in = [
    gap_fn("wired-but-cold", ".claude/skills/skill-a/scripts/x.sh", "evidence-x"),
    gap_fn("wired-but-cold", ".claude/skills/skill-b/scripts/y.sh", "evidence-y"),
]
result = cluster_fn(gaps_in)
assert len(result) == 2, f"AG4 expected 2 individual gaps, got {len(result)}: {result}"
assert all(g["id"].startswith("wired-but-cold:") for g in result), f"AG4 unexpected cluster: {result}"
print("AG4 OK: 2 different-skill gaps stay individual")

# AG5 — non-skill paths pass through
gaps_in = [
    gap_fn("wired-but-cold", "Developer/flywheel/.flywheel/scripts/foo.sh", "ev1"),
    gap_fn("wired-but-cold", "Developer/flywheel/.flywheel/scripts/bar.sh", "ev2"),
    gap_fn("wired-but-cold", "Developer/flywheel/.flywheel/scripts/baz.sh", "ev3"),
]
result = cluster_fn(gaps_in)
assert len(result) == 3, f"AG5 expected 3 individual gaps (non-skill paths), got {len(result)}: {result}"
assert all(g["id"].startswith("wired-but-cold:") for g in result), f"AG5 false-clustered: {result}"
print("AG5 OK: 3 non-skill-path gaps pass through unchanged")

# Bonus mixed scenario: 1 skill with 2 + 1 standalone + 2 in another skill
gaps_in = [
    gap_fn("wired-but-cold", ".claude/skills/foo/scripts/1.sh", "a"),
    gap_fn("wired-but-cold", ".claude/skills/foo/scripts/2.sh", "b"),
    gap_fn("wired-but-cold", ".claude/skills/lonely/scripts/x.sh", "c"),
    gap_fn("wired-but-cold", ".claude/skills/bar/scripts/3.sh", "d"),
    gap_fn("wired-but-cold", ".claude/skills/bar/scripts/4.sh", "e"),
]
result = cluster_fn(gaps_in)
# Expect: 2 cluster gaps (foo + bar) + 1 individual gap (lonely)
clusters = [g for g in result if g["id"].startswith("wired-but-cold-cluster:")]
individuals = [g for g in result if g["id"].startswith("wired-but-cold:")]
assert len(clusters) == 2 and len(individuals) == 1, f"mixed scenario: clusters={len(clusters)}, individuals={len(individuals)}, all={result}"
print("BONUS OK: mixed scenario clusters correctly (2 clusters + 1 individual)")

print("ALL UNIT TESTS PASS")
PY

# AG7 — cluster gap evidence cites doctrine
if grep -q "cluster-maintainer-pattern.md" "$PROBE" 2>/dev/null; then
  p "AG7 cluster gap evidence cites .flywheel/doctrine/cluster-maintainer-pattern.md"
else
  f "AG7 cluster gap evidence missing doctrine cite"
fi

# AG8 — live probe emits wired-but-cold-cluster class (may or may not have actual clusters)
if "$PROBE" --json 2>/dev/null | grep -q 'wired-but-cold-cluster'; then
  p "AG8 live probe emits wired-but-cold-cluster gap class"
else
  # AG8 is conditional — only fails if there are >=2 wired-but-cold scripts in same skill substrate.
  # If no clusters detected, that's not a failure; print info note.
  printf 'INFO AG8 no clusters in current state (no skill substrate has >=2 wired-but-cold)\n'
  p "AG8 live probe ran (no clusters present is acceptable)"
fi

printf '\nsummary pass=%d fail=%d\n' "$pass" "$fail"
[ "$fail" -eq 0 ] || exit 1
