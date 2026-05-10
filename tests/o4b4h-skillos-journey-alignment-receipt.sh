#!/usr/bin/env bash
# tests/o4b4h-skillos-journey-alignment-receipt.sh
# Bead flywheel-o4b4h: alignment-receipt regression for the
# skillos:1 / BrightLake cross-orch journey-writing 4-layer
# architecture proposal.
#
# Bead body explicitly states "No action required this tick —
# informational alignment ask." This test asserts the alignment
# artifacts cited in the proposal are intact AND that a concrete
# Layer-1 implementation follow-up bead has been filed
# (flywheel-r0rox).
#
# When the 4-layer architecture lands (AG1-AG6 across multiple
# follow-up beads), the regression should be inverted/replaced —
# the substrate landing IS the lifecycle advance.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: cross-referenced skills exist
required_skills=(
  "$HOME/.claude/skills/readme-writing/SKILL.md"
  "$HOME/.claude/skills/changelog-md-workmanship/SKILL.md"
  "$HOME/.claude/skills/living-documentation/SKILL.md"
)
missing_skills=()
for s in "${required_skills[@]}"; do
  [[ -f "$s" ]] || missing_skills+=("$s")
done
if [[ "${#missing_skills[@]}" -eq 0 ]]; then
  pass "all 3 cross-referenced skill SKILL.md files exist (readme-writing + changelog-md-workmanship + living-documentation)"
else
  fail "missing skills: ${missing_skills[*]}"
fi

# Test 2: cross-referenced AGENTS.md L-rules are indexed
AGENTS_MD="$ROOT/AGENTS.md"
required_l_rules=("L61" "L77" "L91")
missing_rules=()
for rule in "${required_l_rules[@]}"; do
  grep -qE "^\| [0-9]+ \| ${rule} —" "$AGENTS_MD" || missing_rules+=("$rule")
done
if [[ "${#missing_rules[@]}" -eq 0 ]]; then
  pass "AGENTS.md L-rule index has all 3 cross-referenced rules (L61 + L77 + L91)"
else
  fail "AGENTS.md missing index rows: ${missing_rules[*]}"
fi

# Test 3: daily-report.sh substrate (Layer 3 base) intact
DAILY_REPORT_SCRIPT="$ROOT/.flywheel/scripts/daily-report.sh"
if [[ -x "$DAILY_REPORT_SCRIPT" ]]; then
  pass "daily-report.sh substrate intact (Layer 3 extension target)"
else
  fail "daily-report.sh missing or non-executable at $DAILY_REPORT_SCRIPT"
fi

# Test 4: validation-schema/v1 directory exists (Layer 1 target dir)
SCHEMA_DIR="$ROOT/.flywheel/validation-schema/v1"
if [[ -d "$SCHEMA_DIR" ]]; then
  pass "validation-schema/v1 directory exists (Layer 1 schema target dir)"
else
  fail "validation-schema/v1 directory missing"
fi

# Test 5: journey-entry.v1.schema.json NOT YET present — alignment
# bead is informational; Layer 1 implementation lives in
# flywheel-r0rox. INVERTS when r0rox lands.
JOURNEY_SCHEMA="$SCHEMA_DIR/journey-entry.v1.schema.json"
if [[ -f "$JOURNEY_SCHEMA" ]]; then
  fail "LIFECYCLE ADVANCED: journey-entry.v1.schema.json now exists at $JOURNEY_SCHEMA — Layer 1 has landed; invert this assertion or close as superseded"
else
  pass "journey-entry.v1.schema.json absent (Layer 1 pending; flywheel-r0rox will land it)"
fi

# Test 6: .flywheel/journal/ NOT YET present — Layer 1 deliverable.
# INVERTS when r0rox + onboarding wiring (AG6) lands.
JOURNAL_DIR="$ROOT/.flywheel/journal"
if [[ -d "$JOURNAL_DIR" ]]; then
  fail "LIFECYCLE ADVANCED: .flywheel/journal/ now exists — onboarding wiring has landed; invert this assertion or close as superseded"
else
  pass ".flywheel/journal/ absent (onboarding wiring AG6 pending; another follow-up bead will land it)"
fi

# Test 7: concrete Layer-1 follow-up bead flywheel-r0rox exists with the canonical scope
if br show flywheel-r0rox 2>&1 | head -3 | grep -q "flywheel-r0rox"; then
  if br show flywheel-r0rox 2>&1 | grep -qE 'journey-entry|Layer 1|AG1.*AG2'; then
    pass "flywheel-r0rox follow-up bead exists with Layer-1 scope citation (AG1+AG2)"
  else
    fail "flywheel-r0rox exists but does not cite Layer 1 scope"
  fi
else
  fail "Layer-1 follow-up bead flywheel-r0rox missing — alignment-receipt close failed to route concrete work"
fi

# Test 8: bead body explicitly says "No action required this tick" — alignment posture preserved
BEAD_BODY="$(br show flywheel-o4b4h 2>&1)"
if grep -qE 'No action required this tick|informational alignment' <<<"$BEAD_BODY"; then
  pass "bead body explicitly frames as alignment-only (no implementation expected this tick)"
else
  fail "bead body does not frame as alignment-only — risk of scope drift"
fi

# Test 9: Layer 4 prototype reference (skillos session-2026-05-08-flywheel-spin.md) is cited
# in the bead body cross-references
if grep -qE 'session-2026-05-08-flywheel-spin' <<<"$BEAD_BODY"; then
  pass "bead body cites Layer 4 prototype (skillos session-2026-05-08-flywheel-spin.md) — cross-reference trail intact"
else
  fail "bead body missing Layer 4 prototype citation"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
