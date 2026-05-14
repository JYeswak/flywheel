#!/usr/bin/env bash
# tests/aic04-flywheel-plans-case-portability.sh
# Bead flywheel-aic04: regression for the .flywheel/plans →
# .flywheel/PLANS case-normalization sweep.
#
# Per memory rule feedback_basename_keying_collision_class.md:
# paths must be unambiguous across filesystems. macOS APFS aliases
# the lowercase form transparently (core.ignorecase=true), but
# Linux ext4 is case-sensitive — code that hardcodes lowercase
# .flywheel/plans/ will FAIL with "No such file or directory".
#
# This test asserts:
# 1. All 4 edited flywheel-repo files use canonical PLANS uppercase
# 2. The 2 documented case-fallback files (jeff-pattern-citation-probe,
#    ntm-surface-coverage-trend) preserve their case-fallback logic
# 3. The 1 test fixture (test-escalate-capsule-plan-consumer) stays
#    lowercase because it's a synthetic temp-fixture path
# 4. bash -n on all touched scripts is clean
# 5. Canonical PLANS/ directory exists and is the load-bearing tree
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: canonical .flywheel/PLANS/ tree exists and has substantive content
if [[ -d "$ROOT/.flywheel/PLANS" ]] && [[ "$(find "$ROOT/.flywheel/PLANS" -maxdepth 2 -name '*.md' | wc -l | tr -d '[:space:]')" -gt 50 ]]; then
  pass ".flywheel/PLANS/ canonical tree exists with substantive content (>50 .md files)"
else
  fail ".flywheel/PLANS/ canonical tree missing or empty"
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

# Test 2: 4 normalized in-repo files have ZERO lowercase refs
normalized_files=(
  "$ROOT/.flywheel/scripts/fleet-coherence-quality-report.sh"
  "$ROOT/.flywheel/scripts/emit-polish-round-telemetry.py"
  "$ROOT/.flywheel/scripts/gap-hunt-probe.sh"
  "$ROOT/.flywheel/scripts/plan-state-lens-merge.sh"
)
total_lowercase=0
for f in "${normalized_files[@]}"; do
  count="$(grep -c '\.flywheel/plans' "$f" 2>/dev/null || echo 0)"
  count="${count//[^0-9]/}"
  count="${count:-0}"
  total_lowercase=$((total_lowercase + count))
done
if [[ "$total_lowercase" -eq 0 ]]; then
  pass "4 normalized in-repo files have ZERO lowercase .flywheel/plans/ refs"
else
  fail "found $total_lowercase remaining lowercase refs in normalized files"
fi

# Test 3: 4 normalized in-repo files have at least 4 PLANS uppercase refs
total_uppercase=0
for f in "${normalized_files[@]}"; do
  count="$(grep -c '\.flywheel/PLANS' "$f" 2>/dev/null || echo 0)"
  count="${count//[^0-9]/}"
  count="${count:-0}"
  total_uppercase=$((total_uppercase + count))
done
if [[ "$total_uppercase" -ge 4 ]]; then
  pass "4 normalized in-repo files have ≥4 PLANS uppercase refs (sweep landed)"
else
  fail "expected ≥4 PLANS refs across normalized files; got $total_uppercase"
fi

# Test 4: bash -n is clean on all touched .sh scripts
shell_files=(
  "$ROOT/.flywheel/scripts/fleet-coherence-quality-report.sh"
  "$ROOT/.flywheel/scripts/gap-hunt-probe.sh"
  "$ROOT/.flywheel/scripts/plan-state-lens-merge.sh"
)
syntax_failures=()
for f in "${shell_files[@]}"; do
  bash -n "$f" 2>/dev/null || syntax_failures+=("$f")
done
if [[ "${#syntax_failures[@]}" -eq 0 ]]; then
  pass "bash -n clean on all 3 touched .sh scripts"
else
  fail "syntax errors in: ${syntax_failures[*]}"
fi

# Test 5: emit-polish-round-telemetry.py parses cleanly
if python3 -c "import ast; ast.parse(open('$ROOT/.flywheel/scripts/emit-polish-round-telemetry.py').read())" 2>/dev/null; then
  pass "emit-polish-round-telemetry.py parses cleanly (Python syntax ok)"
else
  fail "emit-polish-round-telemetry.py has Python syntax error"
fi

# Test 6: jeff-pattern-citation-probe.sh PRESERVES the case-fallback
# pattern (intentional defensive walk per flywheel-4rmc) — refs must
# remain because they document the conditional-fallback shape.
JEFF_PROBE="$ROOT/.flywheel/scripts/jeff-pattern-citation-probe.sh"
if [[ -f "$JEFF_PROBE" ]] \
  && grep -qE 'if \[\[ -d "\$REPO/\.flywheel/plans" && ! -d "\$REPO/\.flywheel/PLANS" \]\]' "$JEFF_PROBE" \
  && grep -q 'duplicate when both trees exist' "$JEFF_PROBE"; then
  pass "jeff-pattern-citation-probe.sh preserves case-fallback pattern (per flywheel-4rmc; intentional)"
else
  fail "jeff-pattern-citation-probe.sh case-fallback pattern regressed"
fi

# Test 7: ntm-surface-coverage-trend.sh PRESERVES its replace-on-not-found
# fallback (default path is lowercase but transparently switches to
# uppercase via .replace() if alt path exists)
NTM_TREND="$ROOT/.flywheel/scripts/ntm-surface-coverage-trend.sh"
if [[ -f "$NTM_TREND" ]] \
  && grep -qE 'replace.*\.flywheel/plans/.*\.flywheel/PLANS/' "$NTM_TREND"; then
  pass "ntm-surface-coverage-trend.sh preserves replace-on-not-found fallback"
else
  fail "ntm-surface-coverage-trend.sh fallback pattern regressed"
fi

# Test 8: test fixture in test-escalate-capsule-plan-consumer.sh
# remains lowercase because it's a synthetic mktemp path, NOT a
# canonical PLANS reference. Asserting the test creates its own
# fixture rather than touching the canonical PLANS tree.
TEST_CONSUMER="$ROOT/.flywheel/tests/test-escalate-capsule-plan-consumer.sh"
if [[ -f "$TEST_CONSUMER" ]] \
  && grep -qE 'mkdir -p "\$repo/\.flywheel/plans"' "$TEST_CONSUMER" \
  && grep -qE 'repo=\$\(mktemp|mktemp -d' "$TEST_CONSUMER"; then
  pass "test-escalate-capsule-plan-consumer.sh uses synthetic mktemp fixture (lowercase intentional in fixture)"
else
  fail "test fixture pattern regressed or test does not use mktemp"
fi

# Test 9: 3 ~/.claude files (INCIDENTS.md / flywheel-autoloop / data/README.md)
# have zero lowercase refs to <flywheel-repo>/.flywheel/plans/
home_files=(
  "$HOME/.claude/skills/.flywheel/INCIDENTS.md"
  "$HOME/.claude/skills/.flywheel/bin/flywheel-autoloop"
  "$HOME/.claude/skills/.flywheel/data/README.md"
)
home_lowercase=0
for f in "${home_files[@]}"; do
  count="$(grep -c '\.flywheel/plans' "$f" 2>/dev/null || echo 0)"
  count="${count//[^0-9]/}"
  count="${count:-0}"
  home_lowercase=$((home_lowercase + count))
done
if [[ "$home_lowercase" -eq 0 ]]; then
  pass "3 ~/.claude/skills/.flywheel/* files have ZERO lowercase refs"
else
  fail "found $home_lowercase remaining lowercase refs in ~/.claude files"
fi

# Test 10: gap-hunt-probe edit cites flywheel-aic04 (audit trail intact)
if grep -q "flywheel-aic04" "$ROOT/.flywheel/scripts/gap-hunt-probe.sh"; then
  pass "gap-hunt-probe.sh edit cites flywheel-aic04 (audit trail in source comment)"
else
  fail "gap-hunt-probe.sh edit missing flywheel-aic04 audit-trail comment"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
