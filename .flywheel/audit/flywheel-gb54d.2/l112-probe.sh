#!/usr/bin/env bash
set -euo pipefail

repo="${1:-/Users/josh/Developer/flywheel}"
cd "$repo"

test -f .flywheel/doctrine/skill-self-application-1000-pattern.md
rg -q 'Phase 1: Quick Wins' .flywheel/doctrine/skill-self-application-1000-pattern.md
rg -q 'Phase 2: Validator Or Subagent Contract' .flywheel/doctrine/skill-self-application-1000-pattern.md
rg -q 'Phase 3: Regression Ladder' .flywheel/doctrine/skill-self-application-1000-pattern.md
rg -q 'Phase 4: Asymptote And Fresh-Agent Simulation' .flywheel/doctrine/skill-self-application-1000-pattern.md
rg -q 'composite_score=992|skill-score.json' .flywheel/doctrine/skill-self-application-1000-pattern.md

test -f .flywheel/receipts/flywheel-gb54d.1/evidence.md
test -f .flywheel/audit/flywheel-gb54d.1/skill-score.json
jq -e '.status == "pass" and .composite_score >= 990' .flywheel/audit/flywheel-gb54d.1/skill-score.json >/dev/null
.flywheel/audit/flywheel-gb54d.1/l112-probe.sh | grep -q '^OK_canonical_cli_scoping_990$'

printf 'OK_skill_self_application_1000_pattern\n'
