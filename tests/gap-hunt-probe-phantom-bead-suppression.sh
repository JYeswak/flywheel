#!/usr/bin/env bash
# tests/gap-hunt-probe-phantom-bead-suppression.sh
#
# Regression test for flywheel-2xdi.69: bead_followup_false_positive_reason
# must suppress phantom-bead test-pollution artifacts from the
# bead-without-followup detector. Phantom beads (close_reason contains
# both "phantom bead" and "test-pollution") never represent real
# doctrine/canonical/promotion work even when their close text contains
# the keywords doctrine|canonical|promote|promotion.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/gap-hunt-probe.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

TMP="$(mktemp -d -t gap-hunt-phantom-bead.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

"$SCRIPT" --json >"$TMP/out.json" 2>/dev/null

# Test 1: the phantom-bead-test-pollution suppression is present in source
if grep -q '"phantom-bead-test-pollution"' "$SCRIPT"; then
  pass "T1: phantom-bead-test-pollution suppression key present in source"
else
  fail "T1: phantom-bead-test-pollution suppression missing from source"
fi

# Test 2: needles list contains 'phantom bead' and 'test-pollution'
if grep -A4 '"phantom-bead-test-pollution"' "$SCRIPT" | grep -q '"phantom bead"' \
   && grep -A4 '"phantom-bead-test-pollution"' "$SCRIPT" | grep -q '"test-pollution"'; then
  pass "T2: suppression needles include both 'phantom bead' and 'test-pollution'"
else
  fail "T2: suppression needles incomplete"
fi

# Test 3: flywheel-0u9ch (the bead's named target) is NOT in bead-without-followup
named_count="$(jq -r '[.gaps_by_class["bead-without-followup"][]?.id | select(contains("0u9ch"))] | length' "$TMP/out.json")"
if [[ "$named_count" == "0" ]]; then
  pass "T3: flywheel-0u9ch NOT flagged bead-without-followup (the bead's named target)"
else
  fail "T3: flywheel-0u9ch still flagged (count: $named_count)"
fi

# Test 4: gap_class_distribution["bead-without-followup"] is a non-negative integer
bwf_count="$(jq -r '.gap_class_distribution["bead-without-followup"]' "$TMP/out.json")"
if [[ "$bwf_count" =~ ^[0-9]+$ ]]; then
  pass "T4: gap_class_distribution['bead-without-followup'] is a non-negative integer ($bwf_count)"
else
  fail "T4: count is not a number ($bwf_count)"
fi

# Test 5: prior 2xdi.37 suppression preserved (flywheel-0h0b upstream-issue-draft)
h0b_count="$(jq -r '[.gaps_by_class["bead-without-followup"][]?.id | select(contains("0h0b"))] | length' "$TMP/out.json")"
if [[ "$h0b_count" == "0" ]]; then
  pass "T5: flywheel-0h0b still suppressed (prior 2xdi.37 fix preserved)"
else
  fail "T5: flywheel-0h0b regressed (count: $h0b_count)"
fi

# Test 6: verify the suppression doesn't over-match (a synthetic bead with
# "phantom bead" but no "test-pollution" should NOT be suppressed). Implicit
# in the all(needle in text) match — verify the python regex logic in source.
if grep -q 'all(needle in text for needle in needles)' "$SCRIPT"; then
  pass "T6: suppression uses all-needles match (prevents partial keyword false-suppression)"
else
  fail "T6: suppression match logic not all-needles"
fi

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
