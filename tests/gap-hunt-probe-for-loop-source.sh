#!/usr/bin/env bash
# tests/gap-hunt-probe-for-loop-source.sh
#
# Regression test for flywheel-2xdi.48: runtime_source_corpus() must
# capture for-loop indirect-source patterns driven by extension-less
# bash wrappers (e.g., `bin/flywheel-loop`'s `for module in ...; do
# source "$LIB/$module.sh"; done` pattern that loads 20+ sibling
# library modules).
#
# Pre-fix symptom: 3 modules sourced by flywheel-loop's for-loop
# (step4i-coherence.sh, drift-status.sh, skill-discovery.sh — among
# others) were flagged wired-but-cold even though they're loaded on
# every flywheel tick. Root cause: safe_iter_files used "*.sh" glob
# which skipped extension-less wrappers like `bin/flywheel-loop`.
#
# Fix: add a candidate-source for `bin/*` extension-less files under
# CLAUDE_ROOT/skills. The existing for-loop continuation capture
# (per flywheel-2xdi.47) then sees the module-name list.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/gap-hunt-probe.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

TMP="$(mktemp -d -t gap-hunt-for-loop-source.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

# Run gap-hunt-probe and capture envelope.
"$SCRIPT" --json >"$TMP/out.json" 2>/dev/null

# Test 1: envelope is valid JSON with expected top-level keys
if jq -e '.gaps_by_class and .gap_class_distribution and .gaps_total' "$TMP/out.json" >/dev/null 2>&1; then
  pass "T1: envelope shape valid (gaps_by_class + gap_class_distribution + gaps_total)"
else
  fail "T1: envelope shape valid"
fi

# Test 2: step4i-coherence.sh is NOT in wired-but-cold (was the bead's named gap)
step4i_count="$(jq -r '[.gaps_by_class["wired-but-cold"][]?.name | select(contains("step4i-coherence"))] | length' "$TMP/out.json")"
if [[ "$step4i_count" == "0" ]]; then
  pass "T2: step4i-coherence.sh NOT in wired-but-cold (was the false-positive named by 2xdi.48)"
else
  fail "T2: step4i-coherence.sh still in wired-but-cold (count: $step4i_count)"
fi

# Test 3: drift-status.sh is NOT in wired-but-cold (same false-positive class)
drift_count="$(jq -r '[.gaps_by_class["wired-but-cold"][]?.name | select(contains("drift-status"))] | length' "$TMP/out.json")"
if [[ "$drift_count" == "0" ]]; then
  pass "T3: drift-status.sh NOT in wired-but-cold (sister false-positive)"
else
  fail "T3: drift-status.sh still in wired-but-cold (count: $drift_count)"
fi

# Test 4: skill-discovery.sh is NOT in wired-but-cold (third sister false-positive)
sd_count="$(jq -r '[.gaps_by_class["wired-but-cold"][]?.name | select(contains("skill-discovery"))] | length' "$TMP/out.json")"
if [[ "$sd_count" == "0" ]]; then
  pass "T4: skill-discovery.sh NOT in wired-but-cold (third sister false-positive)"
else
  fail "T4: skill-discovery.sh still in wired-but-cold (count: $sd_count)"
fi

# Test 5: any other module from flywheel-loop's for-loop list also not flagged.
# The for-loop names 27 modules; spot-check a few that exist as lib/<name>.sh:
for_loop_module_check="$(jq -r '[.gaps_by_class["wired-but-cold"][]?.name | select(contains("lib/misc.sh") or contains("lib/parse.sh") or contains("lib/repo.sh") or contains("lib/canonical.sh") or contains("lib/reconcile.sh") or contains("lib/doctor.sh"))] | length' "$TMP/out.json")"
if [[ "$for_loop_module_check" == "0" ]]; then
  pass "T5: no flywheel-loop for-loop module (misc/parse/repo/canonical/reconcile/doctor) flagged wired-but-cold"
else
  fail "T5: for-loop modules still flagged wired-but-cold (count: $for_loop_module_check)"
fi

# Test 6: gap_class_distribution["wired-but-cold"] is a non-negative integer
wbc_count="$(jq -r '.gap_class_distribution["wired-but-cold"]' "$TMP/out.json")"
if [[ "$wbc_count" =~ ^[0-9]+$ ]]; then
  pass "T6: gap_class_distribution['wired-but-cold'] is a non-negative integer ($wbc_count)"
else
  fail "T6: wired-but-cold count is not a number ($wbc_count)"
fi

# Test 7: the corpus probe actually scans extension-less bin/ wrappers.
# Direct check: assert the gap-hunt-probe script contains the bin/* candidate
# branch (so future refactor doesn't accidentally remove it).
if grep -q "safe_iter_files(CLAUDE_ROOT / \"skills\", \"bin/\\*\"" "$SCRIPT"; then
  pass "T7: gap-hunt-probe scans CLAUDE_ROOT/skills/bin/* for extension-less wrappers"
else
  fail "T7: gap-hunt-probe missing bin/* candidate branch"
fi

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
