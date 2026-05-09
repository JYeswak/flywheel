#!/usr/bin/env bash
set -euo pipefail

repo="/Users/josh/Developer/flywheel"
tick="/Users/josh/.claude/commands/flywheel/tick.md"
pack="$repo/.flywheel/audit/flywheel-13u0.3/compliance-pack.md"

cd "$repo"

br show flywheel-38o --json \
  | jq -e '.[0].status == "closed" and (.[0].description | test("stale `/flywheel:tick` protocol|/flywheel:tick is stale"))' >/dev/null

grep -Fq 'skill_version: 2' "$tick"
grep -Fq 'tick-skill-version-check.sh' "$tick"
grep -Fq '/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop tick --repo "$PWD" --json' "$tick"
grep -Fq 'awareness_check' "$tick"
grep -Fq 'inbox_messages_handled' "$tick"
grep -Fq 'fuckups_to_beads' "$tick"
grep -Fq 'pagerank_top_5_blockers' "$tick"
grep -Fq 'dual_channel_pct' "$tick"

grep -Fq 'bypass-canonical-substrate-cluster' INCIDENTS.md
grep -Fq 'three-surface-drift-detected' INCIDENTS.md
grep -Fq 'tick-driver-primitive-failed' INCIDENTS.md

grep -Fq 'Recommendation: promote a new INCIDENTS class, `stale-command-protocol-drift`' "$pack"
grep -Fq 'Command/runbook surfaces must either be generated from canonical doctrine or carry a freshness/protocol-version check.' "$pack"
grep -Fq 'This worker did not edit `INCIDENTS.md`.' "$pack"

printf 'pass\n'
