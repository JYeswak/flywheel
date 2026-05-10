#!/usr/bin/env bash
# tests/test-t0iur-fleet-l-rule-lag-probe-table-format.sh
#
# Regression test for flywheel-t0iur (probe regex matched H2 only, missing
# canonical table format). Asserts the post-fix probe matches BOTH:
#   1. H2 header form: "## L91 — ..." (legacy AGENTS.md)
#   2. Canonical table-row form: "| <num> | L91 — ..." (AGENTS-CANONICAL.md)
#
# Pre-fix: probe regex was H2-only, returning source_rule_count=0 on canonical
# (which uses table form). Post-fix: probe matches both formats; canonical
# returns its actual L-rule count.

set -euo pipefail

REPO="${REPO:-/Users/josh/Developer/flywheel}"
SCRIPT="${SCRIPT:-$REPO/.flywheel/scripts/fleet-l-rule-lag-probe.sh}"
CANONICAL="${CANONICAL:-$REPO/.flywheel/AGENTS-CANONICAL.md}"

[[ -x "$SCRIPT" ]] || { echo "FAIL probe missing: $SCRIPT" >&2; exit 1; }
[[ -f "$CANONICAL" ]] || { echo "FAIL canonical doctrine missing: $CANONICAL" >&2; exit 1; }

pass(){ printf 'PASS %s\n' "$1"; }
fail(){ printf 'FAIL %s\n' "$1" >&2; exit 1; }

# 1. Probe syntax
bash -n "$SCRIPT" && pass "probe syntax-clean" || fail "bash -n failed"

# 2. Probe defines BOTH patterns (H2 + table)
grep -qE 'compile\(r"\^## \(L\[0-9\]\+\)' "$SCRIPT" \
  || fail "probe missing H2 pattern compile"
grep -qE 'compile\(r"\^\\|\\s\*\\d\+\\s\*\\|\\s\*\(L\[0-9\]\+\)' "$SCRIPT" \
  || fail "probe missing table-row pattern compile"
pass "probe defines both H2 and table-row regex patterns"

# 3. Live probe: source_rule_count > 0 on real canonical (catches the H2-only regression)
out=$("$SCRIPT" --json 2>&1 | tail -1)
source_count=$(echo "$out" | jq -r '.source_rule_count // 0')
[[ "$source_count" -gt 0 ]] || fail "post-fix probe still returns source_rule_count=0 (regression of H2-only bug); got $out"
[[ "$source_count" -ge 50 ]] || fail "post-fix probe returns suspiciously low source_rule_count=$source_count (canonical has 100+ L-rules)"
pass "live probe returns source_rule_count=$source_count (>= 50, well above pre-fix 0)"

# 4. Probe schema_version + status fields present
echo "$out" | jq -e '.schema_version == "fleet-l-rule-lag/v1"' >/dev/null \
  || fail "probe missing canonical schema_version"
echo "$out" | jq -e '(.status == "pass" or .status == "fail")' >/dev/null \
  || fail "probe missing valid status field"
pass "probe envelope has canonical schema_version + status field"

# 5. Synthetic fixture: H2-only target should have rules detected
TMP="$(mktemp -d -t t0iur-fixture.XXXXXX)"
trap 'find "$TMP" -mindepth 1 -delete 2>/dev/null; rmdir "$TMP" 2>/dev/null || true' EXIT

mkdir -p "$TMP/source-only-h2/.flywheel"
cat > "$TMP/source-only-h2/AGENTS.md" <<'EOF'
# Synthetic AGENTS.md — H2 form

## L42 — TEST-ROOT-RULE-FORTY-TWO

## L43 — TEST-ROOT-RULE-FORTY-THREE
EOF
mkdir -p "$TMP/source-only-h2/.flywheel"
echo '# canonical placeholder' > "$TMP/source-only-h2/.flywheel/AGENTS-CANONICAL.md"

# Run probe with synthetic root + canonical that uses table form
cat > "$TMP/canonical-table.md" <<'EOF'
# Canonical doctrine in TABLE form

| # | id and title | status | path |
|---|---|---|---|
| 1 | L42 — TEST-ROOT-RULE-FORTY-TWO | long_term | `.flywheel/rules/L001-L42.md` |
| 2 | L43 — TEST-ROOT-RULE-FORTY-THREE | long_term | `.flywheel/rules/L002-L43.md` |
| 3 | L44 — TEST-EXTRA-RULE-MISSING-IN-TARGET | long_term | `.flywheel/rules/L003-L44.md` |
EOF

# Run the probe with these synthetic paths (rc=1 expected when lag detected)
set +e
fixture_out=$(FLEET_L_RULE_LAG_ROOT="$TMP" \
  FLEET_L_RULE_LAG_SOURCE="$TMP/canonical-table.md" \
  FLEET_L_RULE_LAG_LOOPS_DIR="$TMP/no-loops" \
  "$SCRIPT" --json 2>&1 | tail -1)
set -e

# The synthetic source has 3 L-rules in table form
fixture_source=$(echo "$fixture_out" | jq -r '.source_rule_count // 0')
[[ "$fixture_source" == "3" ]] || fail "fixture canonical (table form) should have 3 rules, got $fixture_source"
pass "synthetic canonical (table form) returns source_rule_count=3"

# The synthetic source-only-h2 target has L42, L43 in H2 form; missing L44
# (which exists in canonical). Lag count should be 1 with missing_rules=[L44]
fixture_lag=$(echo "$fixture_out" | jq -r '.fleet_repo_l_rule_lag_count // 0')
[[ "$fixture_lag" == "1" ]] || fail "fixture should report 1 lagging repo, got $fixture_lag"
fixture_missing=$(echo "$fixture_out" | jq -c '.lagging_repos[0].missing_rules')
[[ "$fixture_missing" == '["L44"]' ]] \
  || fail "fixture lagging repo should miss [L44], got $fixture_missing"
pass "synthetic H2-target detected as lagging on canonical-only L44 (mixed-format compat works)"

# 6. Pre-fix regression check: ensure H2-only behavior would NOT pass this test
# (sanity-check the test itself by inverse-asserting the table-form pattern works)
echo "## L99 — H2-FORM" > "$TMP/h2-only-source.md"
set +e
h2_out=$(FLEET_L_RULE_LAG_ROOT="$TMP/no-repos" \
  FLEET_L_RULE_LAG_SOURCE="$TMP/h2-only-source.md" \
  FLEET_L_RULE_LAG_LOOPS_DIR="$TMP/no-loops" \
  "$SCRIPT" --json 2>&1 | tail -1)
set -e
h2_count=$(echo "$h2_out" | jq -r '.source_rule_count // 0')
[[ "$h2_count" == "1" ]] || fail "H2-form source still detected: expected 1 rule, got $h2_count"
pass "H2-form source still detected post-fix (backward compat preserved)"

printf 'flywheel-t0iur fleet-l-rule-lag-probe table-format test passed (6 assertions)\n'
