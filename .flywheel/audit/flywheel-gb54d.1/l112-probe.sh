#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SKILL="/Users/josh/.claude/skills/canonical-cli-scoping"

test -f "$ROOT/receipts/flywheel-gb54d.1/evidence.md"
test -f "$ROOT/audit/flywheel-gb54d.1/compliance.md"
test -f "$SKILL/scripts/canonical-cli-scorecard.sh"
test -f "$SKILL/tests/test_canonical_cli_scorecard.sh"

bash "$SKILL/scripts/canonical-cli-scorecard.sh" skill-score canonical-cli-scoping --json \
  | jq -e '.status == "pass" and .composite_score >= 990 and .dimensions.regression_ladder == 1000' >/dev/null

jq -e '.status == "pass" and (.skills | length) == 10 and .audited_after_score >= 990' \
  "$ROOT/audit/flywheel-gb54d.1/top10-audit.json" >/dev/null

grep -q 'Phase 2-4 Scorer And Regression Ladder' "$SKILL/SKILL.md"
grep -q 'SUMMARY pass=10 fail=0' "$ROOT/audit/flywheel-gb54d.1/test-output.txt"

printf 'OK_canonical_cli_scoping_990\n'
