#!/usr/bin/env bash
# tests/gap-hunt-probe-doctrine-corpus.sh
#
# Regression test for flywheel-2xdi.54: probe_memory_without_cross_link()'s
# corpus must include `.flywheel/doctrine/*.md` files. Pre-fix the probe
# scanned only command-md + AGENTS/INCIDENTS/README + PLANS, missing the
# actual doctrine/ directory despite the gap message claiming "doctrine,
# incidents, or recent plan files".
#
# Combined fix:
#   1. Extend command_text() to scan .flywheel/doctrine/*.md
#   2. Create .flywheel/doctrine/bead-hypothesis-starting-point.md anchoring
#      the META-RULE memory file flagged by this bead

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/gap-hunt-probe.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

TMP="$(mktemp -d -t gap-hunt-doctrine-corpus.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

"$SCRIPT" --json >"$TMP/out.json" 2>/dev/null

# Test 1: gap-hunt-probe.sh scans .flywheel/doctrine/*.md in command_text()
if grep -q 'safe_iter_files(REPO_ROOT / "\.flywheel/doctrine"' "$SCRIPT"; then
  pass "T1: command_text() scans .flywheel/doctrine/*.md (the corpus extension)"
else
  fail "T1: command_text() missing doctrine/*.md branch"
fi

# Test 2: the named memory (feedback_bead_hypothesis_starting_point_not_conclusion.md)
# is NOT in memory-without-cross-link list — proves the doctrine anchor works
named_count="$(jq -r '[.gaps_by_class["memory-without-cross-link"][]?.name | select(contains("bead_hypothesis_starting_point"))] | length' "$TMP/out.json")"
if [[ "$named_count" == "0" ]]; then
  pass "T2: feedback_bead_hypothesis_starting_point_not_conclusion.md NOT in memory-without-cross-link (the bead's named target)"
else
  fail "T2: bead's named memory still flagged (count: $named_count)"
fi

# Test 3: the canonical doctrine file exists
if [[ -f "$ROOT/.flywheel/doctrine/bead-hypothesis-starting-point.md" ]]; then
  pass "T3: .flywheel/doctrine/bead-hypothesis-starting-point.md exists (the canonical anchor)"
else
  fail "T3: bead-hypothesis-starting-point.md doctrine file missing"
fi

# Test 4: the doctrine file cites the memory by name
if [[ -f "$ROOT/.flywheel/doctrine/bead-hypothesis-starting-point.md" ]] \
   && grep -q "feedback_bead_hypothesis_starting_point_not_conclusion" "$ROOT/.flywheel/doctrine/bead-hypothesis-starting-point.md"; then
  pass "T4: doctrine file cites the canonical memory by full filename"
else
  fail "T4: doctrine file does not cite the memory by name"
fi

# Test 5: gap_class_distribution["memory-without-cross-link"] is a non-negative integer
mwcl_count="$(jq -r '.gap_class_distribution["memory-without-cross-link"]' "$TMP/out.json")"
if [[ "$mwcl_count" =~ ^[0-9]+$ ]]; then
  pass "T5: gap_class_distribution['memory-without-cross-link'] is a non-negative integer ($mwcl_count)"
else
  fail "T5: count is not a number ($mwcl_count)"
fi

# Test 6: prior fixes preserved — step4i-coherence (2xdi.48) still NOT in wired-but-cold
step4i_count="$(jq -r '[.gaps_by_class["wired-but-cold"][]?.name | select(contains("step4i-coherence"))] | length' "$TMP/out.json")"
if [[ "$step4i_count" == "0" ]]; then
  pass "T6: step4i-coherence.sh NOT in wired-but-cold (2xdi.48 fix preserved)"
else
  fail "T6: 2xdi.48 fix regressed (step4i-coherence count: $step4i_count)"
fi

# Test 7: substrate-doctor-common.sh (2xdi.50) NOT in wired-but-cold
sdc_count="$(jq -r '[.gaps_by_class["wired-but-cold"][]?.name | select(contains("substrate-doctor-common"))] | length' "$TMP/out.json")"
if [[ "$sdc_count" == "0" ]]; then
  pass "T7: substrate-doctor-common.sh NOT in wired-but-cold (2xdi.50 fix preserved)"
else
  fail "T7: 2xdi.50 fix regressed (substrate-doctor-common count: $sdc_count)"
fi

# Test 8: doctrine corpus extension doesn't cause obvious crash — envelope shape valid
if jq -e '.gaps_by_class and .gap_class_distribution and .gaps_total' "$TMP/out.json" >/dev/null 2>&1; then
  pass "T8: gap-hunt-probe envelope shape preserved (no crash from new corpus)"
else
  fail "T8: gap-hunt-probe envelope shape broken"
fi

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
