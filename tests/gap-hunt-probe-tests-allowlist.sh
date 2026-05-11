#!/usr/bin/env bash
# tests/gap-hunt-probe-tests-allowlist.sh
#
# Regression test for flywheel-2xdi.58 (patch landed via convergent fix in
# commit 4370b78 / flywheel-e7lxv corrective): on_demand_script_allowlist()
# auto-allowlists tests/test_*.sh + tests/run-tests.sh under both
# CLAUDE_ROOT/skills and REPO_ROOT.
#
# Pre-fix: 6 sibling test files + run-tests.sh were flagged wired-but-cold
# because the heuristic treats *.sh files as continuous-probe candidates.
# They're actually on-demand test surfaces invoked by run-tests.sh harness
# (CI / manual operator).
#
# This test locks in the fix and prevents future regression.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/gap-hunt-probe.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

TMP="$(mktemp -d -t gap-hunt-tests-allowlist.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

"$SCRIPT" --json >"$TMP/out.json" 2>/dev/null

# Test 1: the structural fix is present in source
if grep -qE 'auto-allowlist any \*\.sh file under a `tests/`' "$SCRIPT"; then
  pass "T1: gap-hunt-probe.sh contains the 2xdi.58 tests/ allowlist comment block"
else
  fail "T1: tests/ allowlist comment block missing from source"
fi

# Test 2: the for-loop that adds tests/test_*.sh is present
if grep -qE 'tests/\*\*/test_\*\.sh' "$SCRIPT"; then
  pass "T2: gap-hunt-probe.sh scans tests/**/test_*.sh glob"
else
  fail "T2: tests/**/test_*.sh glob missing"
fi

# Test 3: run-tests.sh harness is also added to allowlist
if grep -qE 'tests/run-tests\.sh' "$SCRIPT"; then
  pass "T3: gap-hunt-probe.sh scans tests/run-tests.sh harness"
else
  fail "T3: tests/run-tests.sh harness scan missing"
fi

# Test 4: the bead's named target is NOT in wired-but-cold
named_count="$(jq -r '[.gaps_by_class["wired-but-cold"][]?.name | select(contains("test_bulk_mutation_surgical_bound"))] | length' "$TMP/out.json")"
if [[ "$named_count" == "0" ]]; then
  pass "T4: test_bulk_mutation_surgical_bound.sh NOT flagged (2xdi.58 named target)"
else
  fail "T4: 2xdi.58 named target still flagged (count: $named_count)"
fi

# Test 5: zero test_*.sh files under tests/ in wired-but-cold
test_count="$(jq -r '.gaps_by_class["wired-but-cold"][]?.name | select(contains("tests/test_"))' "$TMP/out.json" | wc -l | tr -d ' ')"
if [[ "$test_count" == "0" ]]; then
  pass "T5: zero tests/test_*.sh files flagged wired-but-cold (full class fix)"
else
  fail "T5: tests/test_*.sh files still flagged (count: $test_count)"
fi

# Test 6: run-tests.sh harness is NOT in wired-but-cold
harness_count="$(jq -r '[.gaps_by_class["wired-but-cold"][]?.name | select(contains("tests/run-tests"))] | length' "$TMP/out.json")"
if [[ "$harness_count" == "0" ]]; then
  pass "T6: tests/run-tests.sh harness NOT flagged"
else
  fail "T6: tests/run-tests.sh harness still flagged (count: $harness_count)"
fi

# Test 7: prior gap-hunt-probe corpus fixes preserved
step4i_count="$(jq -r '[.gaps_by_class["wired-but-cold"][]?.name | select(contains("step4i-coherence"))] | length' "$TMP/out.json")"
if [[ "$step4i_count" == "0" ]]; then
  pass "T7: step4i-coherence.sh still NOT flagged (2xdi.48 fix preserved)"
else
  fail "T7: 2xdi.48 fix regressed (count: $step4i_count)"
fi

sdc_count="$(jq -r '[.gaps_by_class["wired-but-cold"][]?.name | select(contains("substrate-doctor-common"))] | length' "$TMP/out.json")"
if [[ "$sdc_count" == "0" ]]; then
  pass "T8: substrate-doctor-common.sh still NOT flagged (2xdi.50 fix preserved)"
else
  fail "T8: 2xdi.50 fix regressed (count: $sdc_count)"
fi

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
