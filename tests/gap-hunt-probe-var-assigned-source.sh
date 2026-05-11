#!/usr/bin/env bash
# tests/gap-hunt-probe-var-assigned-source.sh
#
# Regression test for flywheel-2xdi.50: runtime_source_corpus() must capture
# variable-assignment lines that resolve to `.sh` paths, e.g.
#   COMMON="${SUBSTRATE_DOCTOR_COMMON:-$HOME/.../substrate-doctor-common.sh}"
#   source "$COMMON"
#
# Pre-fix symptom: substrate-doctor-common.sh was flagged wired-but-cold
# even though substrate-doctor-critical-gaps-test.sh sources it via a
# variable-default-substitution. The corpus only captured lines starting with
# `source ` or `. `, missing the variable-assignment line that contains the
# literal basename.
#
# Fix: added var_assign_sh_re pattern that captures lines matching
# `<var-name>=...<.sh>` shape — catches the basename in the assignment line.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/gap-hunt-probe.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

TMP="$(mktemp -d -t gap-hunt-var-assigned.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

"$SCRIPT" --json >"$TMP/out.json" 2>/dev/null

# Test 1: substrate-doctor-common.sh is NOT in wired-but-cold (was the bead's named target)
common_count="$(jq -r '[.gaps_by_class["wired-but-cold"][]?.name | select(contains("substrate-doctor-common"))] | length' "$TMP/out.json")"
if [[ "$common_count" == "0" ]]; then
  pass "T1: substrate-doctor-common.sh NOT in wired-but-cold (the false-positive named by 2xdi.50)"
else
  fail "T1: substrate-doctor-common.sh still in wired-but-cold (count: $common_count)"
fi

# Test 2: gap-hunt-probe.sh contains the var-assignment-sh regex
if grep -q "var_assign_sh_re" "$SCRIPT"; then
  pass "T2: gap-hunt-probe.sh contains var_assign_sh_re regex (the fix is present in source)"
else
  fail "T2: gap-hunt-probe.sh missing var_assign_sh_re regex"
fi

# Test 3: the regex pattern shape matches `VAR=...sh` literal — test in Python
python3 - <<'PY' "$SCRIPT"
import sys, re, pathlib
src = pathlib.Path(sys.argv[1]).read_text()
# Find the regex definition
m = re.search(r'var_assign_sh_re\s*=\s*re\.compile\(r"([^"]+)"\)', src)
assert m, "var_assign_sh_re regex definition not found"
pattern = re.compile(m.group(1))
fixtures = [
    ('COMMON="${SUBSTRATE_DOCTOR_COMMON:-$HOME/foo.sh}"', True),
    ('DOCTOR="$HOME/bar.sh"', True),
    ('local FOO=$HOME/baz.sh', True),
    ('source "$LIB/qux.sh"', False),  # not assignment, already caught elsewhere
    ('# comment about foo.sh', False),
    ('echo "running"', False),
]
for inp, expected in fixtures:
    got = bool(pattern.search(inp))
    assert got == expected, f"regex fixture failed: {inp!r} expected={expected} got={got}"
print("T3-regex: all 6 regex fixtures pass")
PY
if [[ $? -eq 0 ]]; then
  pass "T3: var_assign_sh_re pattern correctly classifies 6 fixture shapes"
else
  fail "T3: var_assign_sh_re fixture classification failed"
fi

# Test 4: ensure the 3 substrate-doctor-*-test.sh files DO source common.sh via the
# variable-assignment pattern (proves the fixture pattern is real)
for f in substrate-doctor-critical-gaps-test.sh substrate-doctor-infisical-test.sh substrate-doctor-vercel-test.sh; do
  full="/Users/josh/.claude/skills/.flywheel/scripts/$f"
  if [[ -f "$full" ]] && grep -qE '^[A-Z_]+=.*\.sh' "$full"; then
    pass "T4: $f uses var-assignment-sh pattern (real-world driver of the bug)"
  else
    fail "T4: $f does not use var-assignment-sh pattern (or file missing)"
  fi
done

# Test 5: prior 2xdi.48 regression assertions still hold (step4i-coherence)
step4i_count="$(jq -r '[.gaps_by_class["wired-but-cold"][]?.name | select(contains("step4i-coherence"))] | length' "$TMP/out.json")"
if [[ "$step4i_count" == "0" ]]; then
  pass "T5: step4i-coherence.sh still NOT in wired-but-cold (2xdi.48 fix preserved)"
else
  fail "T5: step4i-coherence.sh re-flagged in wired-but-cold (2xdi.48 regression)"
fi

# Test 6: gap_class_distribution["wired-but-cold"] is still a non-negative integer
wbc_count="$(jq -r '.gap_class_distribution["wired-but-cold"]' "$TMP/out.json")"
if [[ "$wbc_count" =~ ^[0-9]+$ ]]; then
  pass "T6: gap_class_distribution['wired-but-cold'] is a non-negative integer ($wbc_count)"
else
  fail "T6: wired-but-cold count is not a number ($wbc_count)"
fi

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
