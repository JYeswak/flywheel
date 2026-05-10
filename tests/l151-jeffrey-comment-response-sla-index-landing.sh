#!/usr/bin/env bash
# tests/l151-jeffrey-comment-response-sla-index-landing.sh
# Bead flywheel-3h6f5: regression coverage that L151 (jeffrey-comment-
# response-sla) is canonically landed in the AGENTS.md / AGENTS-CANONICAL.md
# L-rule index after the d6tz0 watchtower ship.
#
# Trigger: future doctrine-sync, fleet-propagation, or AGENTS-canonical
# rewrite must NOT drop L151. The test fires the moment the index entry,
# rule file, or filename convention drifts.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
AGENTS_MD="${AGENTS_MD:-$ROOT/AGENTS.md}"
AGENTS_CANONICAL="${AGENTS_CANONICAL:-$ROOT/.flywheel/AGENTS-CANONICAL.md}"
RULE_FILE="${L151_RULE_FILE:-$ROOT/.flywheel/rules/L102-L151-jeffrey-comment-response-sla.md}"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

# Test 1: rule file exists with required frontmatter (id=L151)
if [[ -f "$RULE_FILE" ]] \
  && grep -qE '^id:\s*L151\b' "$RULE_FILE" \
  && grep -q "watchtower-driven" "$RULE_FILE" \
  && grep -q "4hr waking-hour" "$RULE_FILE"; then
  pass "L151 rule file exists with id=L151 + watchtower-driven + 4hr SLA"
else
  fail "L151 rule file missing or frontmatter malformed at $RULE_FILE"
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

# Test 2: AGENTS.md L-rule index has the L151 row at sequence 102
EXPECTED_ROW='| 102 | L151 — JEFFREY-COMMENT-RESPONSE-SLA | long_term | `.flywheel/rules/L102-L151-jeffrey-comment-response-sla.md` |'
if grep -qF "$EXPECTED_ROW" "$AGENTS_MD"; then
  pass "AGENTS.md index row matches canonical shape (seq 102, L151, long_term, rule path)"
else
  fail "AGENTS.md row missing or shape drift; expected: $EXPECTED_ROW"
fi

# Test 3: AGENTS-CANONICAL.md mirrors AGENTS.md row
if grep -qF "$EXPECTED_ROW" "$AGENTS_CANONICAL"; then
  pass "AGENTS-CANONICAL.md mirrors AGENTS.md L151 row"
else
  fail "AGENTS-CANONICAL.md row drifts from AGENTS.md or is missing"
fi

# Test 4: index sequence numbers strictly increase across L151's neighbors
# (L150 → L151 → L152 in seq 101 → 102 → 103)
agents_extract() {
  awk '/^\| [0-9]+ \| L1(50|51|52) /' "$AGENTS_MD"
}
NEIGHBOR_ROWS="$(agents_extract)"
expected_neighbors=$'| 101 | L150 — SKILL-NAMING-CONSTRAINT | long_term | `.flywheel/rules/L101-L150-skill-naming-constraint.md` |\n| 102 | L151 — JEFFREY-COMMENT-RESPONSE-SLA | long_term | `.flywheel/rules/L102-L151-jeffrey-comment-response-sla.md` |\n| 103 | L152 — COORDINATOR-DAEMON-CANONICAL-DISPATCH | long_term | `.flywheel/rules/L103-L152-coordinator-daemon-canonical-dispatch.md` |'
if [[ "$NEIGHBOR_ROWS" == "$expected_neighbors" ]]; then
  pass "L150 → L151 → L152 neighbor rows are contiguous and correctly sequenced"
else
  fail "neighbor rows drift; got:\n$NEIGHBOR_ROWS"
fi

# Test 5: rule file path in AGENTS.md matches actual filesystem path
ROW_PATH="$(grep -oE '\.flywheel/rules/L102-L151[a-z0-9-]*\.md' "$AGENTS_MD" | head -1)"
if [[ -n "$ROW_PATH" ]] && [[ -f "$ROOT/$ROW_PATH" ]]; then
  pass "AGENTS.md row's rule path resolves to an actual file"
else
  fail "AGENTS.md row path does not resolve; row_path=$ROW_PATH"
fi

# Test 6: rule body cites Joshua's 2026-05-09 directive (the load-bearing reason)
# Use grep -z (null-separated) to match across line breaks since the
# Joshua quote spans multiple lines.
if grep -q "2026-05-09" "$RULE_FILE" \
  && grep -qz "Joshua directive" "$RULE_FILE" \
  && grep -q "EVERY" "$RULE_FILE" \
  && grep -q "JEFFREY_COMMENT_NEW" "$RULE_FILE"; then
  pass "rule body cites Joshua 2026-05-09 directive + JEFFREY_COMMENT_NEW signal"
else
  fail "rule body missing Joshua directive or JEFFREY_COMMENT_NEW signal"
fi

# Test 7: rule body cross-links L70 (orch-no-punt — dispatch on receipt, not next tick)
if grep -qE 'L70\b' "$RULE_FILE"; then
  pass "rule body cross-links L70 orch-no-punt (dispatch on receipt)"
else
  fail "rule body missing L70 cross-link"
fi

# Test 8: index region delimiters intact (END-RULES-INDEX + END-CANONICAL-FLYWHEEL-DOCTRINE)
if grep -q "END-RULES-INDEX" "$AGENTS_MD" \
  && grep -q "END-CANONICAL-FLYWHEEL-DOCTRINE" "$AGENTS_MD"; then
  pass "AGENTS.md index region delimiters intact"
else
  fail "AGENTS.md region delimiters missing or drifted"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
