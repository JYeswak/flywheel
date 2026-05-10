#!/usr/bin/env bash
# test-doctrine-ladder-promote-rules-coverage.sh
#
# flywheel-vl0c9 regression: assert doctrine-ladder-promote.sh
# default_incident_paths() now scans .flywheel/rules/*.md and
# treats L-rule-layer coverage as equivalent to INCIDENTS.md
# coverage for the ladder gate.
#
# Acceptance gates from the bead body:
#   1. doctrine-ladder-promote.sh skips classes that match L-rule body
#      text in .flywheel/rules/*.md
#   2. Synthetic trauma class with only L-rule coverage (no INCIDENTS
#      entry) returns skipped:incidents_covered
#   3. Existing INCIDENTS.md scan still works
#   4. bash -n clean
#
# Test design note: doctrine-ladder-promote.sh runs main flow at file
# end (no main guard). Sourcing the script triggers the main flow,
# which can create live beads off the live FUCKUP_LOG. To avoid
# spillage, every test invocation uses FUCKUP_LOG=<empty fixture>
# (so no classes accumulate) and INCIDENTS_SEARCH_PATHS=<fixture>
# (so the env override path is exercised). Static greps cover what
# subprocess-only checks can't.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
PROMOTE="${DOCTRINE_LADDER_PROMOTE_BIN:-$ROOT/.flywheel/scripts/doctrine-ladder-promote.sh}"

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

if [[ ! -f "$PROMOTE" ]]; then
  printf 'SKIP doctrine-ladder-promote.sh missing at %s\n' "$PROMOTE"
  exit 77
fi

FIXTURE_ROOT="$(mktemp -d -t doctrine-ladder-vl0c9.XXXXXX)"
trap 'rm -f "$FIXTURE_ROOT"/INCIDENTS.md "$FIXTURE_ROOT"/AGENTS.md "$FIXTURE_ROOT"/rules/*.md "$FIXTURE_ROOT"/state/*.jsonl "$FIXTURE_ROOT"/empty.jsonl 2>/dev/null; rmdir "$FIXTURE_ROOT/rules" "$FIXTURE_ROOT/state" "$FIXTURE_ROOT" 2>/dev/null' EXIT

mkdir -p "$FIXTURE_ROOT/rules" "$FIXTURE_ROOT/state"
EMPTY_FUCKUP="$FIXTURE_ROOT/empty.jsonl"
: > "$EMPTY_FUCKUP"
SYNTHETIC_CLASS="vl0c9-synthetic-class-token-2026"
SYNTHETIC_FUCKUP="$FIXTURE_ROOT/state/synth-fuckup.jsonl"
{
  for n in 1 2 3 4 5; do
    ts=$(date -u -v-"${n}"H +'%Y-%m-%dT%H:%M:%SZ' 2>/dev/null \
      || date -u -d "${n} hours ago" +'%Y-%m-%dT%H:%M:%SZ')
    printf '{"ts":"%s","trauma_class":"%s","severity":"high"}\n' "$ts" "$SYNTHETIC_CLASS"
  done
} > "$SYNTHETIC_FUCKUP"

touch "$FIXTURE_ROOT/INCIDENTS.md"
touch "$FIXTURE_ROOT/AGENTS.md"
cat <<'RULE' > "$FIXTURE_ROOT/rules/L999-test-fixture-rule.md"
# Lxxx — Test fixture rule (vl0c9 regression test only)

This rule's Why section explicitly cites trauma class
`vl0c9-synthetic-class-token-2026` to verify doctrine-ladder-promote's
default_incident_paths glob now scans .flywheel/rules/*.md as part of
its INCIDENTS coverage gate.
RULE

# T1: bash -n clean
bash -n "$PROMOTE" && pass "T1 doctrine-ladder-promote.sh passes bash -n" || fail "T1 syntax error"

# T2: static grep — function source contains rules-glob lines
T2_RULES_LINES=$(grep -cE 'printf .*\.flywheel/rules/\*\.md' "$PROMOTE")
if (( T2_RULES_LINES >= 2 )); then
  pass "T2 default_incident_paths source contains >=2 rules-glob lines (count=$T2_RULES_LINES)"
else
  fail "T2 rules-glob line count=$T2_RULES_LINES (want >=2)"
fi

# T3: end-to-end with empty FUCKUP_LOG → 0 created, 0 skipped (no classes)
T3_OUT=$(FUCKUP_LOG="$EMPTY_FUCKUP" \
  bash "$PROMOTE" "$FIXTURE_ROOT" 2>&1)
T3_CREATED=$(printf '%s' "$T3_OUT" | jq -r '.created | length' 2>/dev/null)
T3_SKIPPED=$(printf '%s' "$T3_OUT" | jq -r '.skipped | length' 2>/dev/null)
T3_ACTION=$(printf '%s' "$T3_OUT" | jq -r '.action' 2>/dev/null)
if [[ "$T3_CREATED" == "0" && "$T3_SKIPPED" == "0" ]]; then
  pass "T3 empty fuckup-log run creates 0, skips 0 (action=$T3_ACTION)"
else
  fail "T3 unexpected counts created=$T3_CREATED skipped=$T3_SKIPPED action=$T3_ACTION: $T3_OUT"
fi

# T4: synthetic class fixture — INCIDENTS_SEARCH_PATHS includes the
# L-rule fixture but NOT the live INCIDENTS.md. Class should be
# detected as covered via the L-rule body text.
T4_OUT=$(FUCKUP_LOG="$SYNTHETIC_FUCKUP" \
  INCIDENTS_SEARCH_PATHS="$FIXTURE_ROOT/INCIDENTS.md $FIXTURE_ROOT/AGENTS.md $FIXTURE_ROOT/rules/L999-test-fixture-rule.md" \
  bash "$PROMOTE" "$FIXTURE_ROOT" 2>&1)
T4_SKIPPED_INCIDENTS=$(printf '%s' "$T4_OUT" \
  | jq -r --arg c "$SYNTHETIC_CLASS" '.skipped // [] | any(. == ($c + ":incidents_covered"))' 2>/dev/null)
T4_CREATED=$(printf '%s' "$T4_OUT" | jq -r '.created | length' 2>/dev/null)
if [[ "$T4_SKIPPED_INCIDENTS" == "true" && "$T4_CREATED" == "0" ]]; then
  pass "T4 synthetic class with L-rule-only coverage returns skipped:incidents_covered"
else
  fail "T4 synthetic-class skipped_incidents=$T4_SKIPPED_INCIDENTS created=$T4_CREATED: $T4_OUT"
fi

# T5: same synthetic class, but INCIDENTS_SEARCH_PATHS excludes the
# L-rule fixture → class NOT covered. To avoid creating a real bead,
# point BR_BIN to a stub that lies about open beads (says one
# already exists) so the script falls through to skipped:bead_exists
# instead of create_candidate_bead.
T5_BR_STUB="$FIXTURE_ROOT/br-stub.sh"
cat <<'STUB' > "$T5_BR_STUB"
#!/usr/bin/env bash
# Stub br for vl0c9 test. Pretends an existing promotion-candidate
# bead exists for any class so the ladder hits skipped:bead_exists
# instead of creating a real bead.
case "$1" in
  list)
    cat <<'EOF'
{"issues":[{"id":"flywheel-stub","title":"[promotion-candidate] vl0c9-synthetic-class-token-2026 stub","status":"open"}]}
EOF
    ;;
  *) printf '' ;;
esac
STUB
chmod +x "$T5_BR_STUB"

T5_OUT=$(FUCKUP_LOG="$SYNTHETIC_FUCKUP" \
  INCIDENTS_SEARCH_PATHS="$FIXTURE_ROOT/INCIDENTS.md $FIXTURE_ROOT/AGENTS.md" \
  BR_BIN="$T5_BR_STUB" \
  bash "$PROMOTE" "$FIXTURE_ROOT" 2>&1)
T5_SKIPPED_INCIDENTS=$(printf '%s' "$T5_OUT" \
  | jq -r --arg c "$SYNTHETIC_CLASS" '.skipped // [] | any(. == ($c + ":incidents_covered"))' 2>/dev/null)
T5_BEAD_EXISTS=$(printf '%s' "$T5_OUT" \
  | jq -r --arg c "$SYNTHETIC_CLASS" '.skipped // [] | any(. == ($c + ":bead_exists"))' 2>/dev/null)
T5_CREATED=$(printf '%s' "$T5_OUT" | jq -r '.created | length' 2>/dev/null)
# Negative assertion: when L-rule coverage is excluded, class should
# NOT skip via incidents_covered (proves the rules glob is what made
# T4 pass).
if [[ "$T5_SKIPPED_INCIDENTS" == "false" ]]; then
  pass "T5 without rules fixture, synthetic class is NOT skipped:incidents_covered (proves rules-glob is the gate)"
else
  fail "T5 without rules fixture, class still falsely covered: $T5_OUT"
fi
# And the stub forces bead_exists path so no live bead is created.
if [[ "$T5_BEAD_EXISTS" == "true" && "$T5_CREATED" == "0" ]]; then
  pass "T5b stub br_bin forces bead_exists path (no live bead created)"
else
  fail "T5b expected bead_exists=true created=0; got $T5_BEAD_EXISTS / $T5_CREATED: $T5_OUT"
fi

# T6: existing INCIDENTS.md scan still works — give the synthetic
# class an INCIDENTS.md entry only (no rule fixture). Should also
# return covered. Confirms backward compat.
cat <<INC > "$FIXTURE_ROOT/INCIDENTS.md"
## Test entry citing $SYNTHETIC_CLASS

This is a fixture INCIDENTS entry to confirm backward compatibility
with the pre-vl0c9 INCIDENTS.md scan path.
INC
T6_OUT=$(FUCKUP_LOG="$SYNTHETIC_FUCKUP" \
  INCIDENTS_SEARCH_PATHS="$FIXTURE_ROOT/INCIDENTS.md $FIXTURE_ROOT/AGENTS.md" \
  bash "$PROMOTE" "$FIXTURE_ROOT" 2>&1)
T6_SKIPPED_INCIDENTS=$(printf '%s' "$T6_OUT" \
  | jq -r --arg c "$SYNTHETIC_CLASS" '.skipped // [] | any(. == ($c + ":incidents_covered"))' 2>/dev/null)
T6_CREATED=$(printf '%s' "$T6_OUT" | jq -r '.created | length' 2>/dev/null)
if [[ "$T6_SKIPPED_INCIDENTS" == "true" && "$T6_CREATED" == "0" ]]; then
  pass "T6 INCIDENTS.md-only fixture still returns covered (backward compat)"
else
  fail "T6 backward-compat skipped_incidents=$T6_SKIPPED_INCIDENTS created=$T6_CREATED: $T6_OUT"
fi

printf '\n=== test-doctrine-ladder-promote-rules-coverage.sh ===\n'
printf 'pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]] && exit 0 || exit 1
