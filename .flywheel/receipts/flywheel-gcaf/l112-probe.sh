#!/usr/bin/env bash
set -euo pipefail

repo="/Users/josh/Developer/flywheel"
routed="/Users/josh/.local/state/flywheel/skillos-routed.jsonl"
skills="/Users/josh/.claude/skills"

cd "$repo"

br show flywheel-mdry --json | jq -e '.[0].status == "closed"' >/dev/null
br show flywheel-vd2c --json | jq -e '.[0].priority == 3 and .[0].status == "closed" and (.[0].close_reason | test("skill updated"))' >/dev/null
br show flywheel-a2eo --json | jq -e '.[0].priority == 3 and .[0].status == "closed" and (.[0].close_reason | test("skill updated"))' >/dev/null

jq -e -s '
  map(select(
    (.original_row_ref == "line:4:sha256:85717547fcbc4b1a")
    or (.original_row_ref == "line:5:sha256:1342593f3bc1917f")
  ))
  | (map(select(.candidate_domain == "nango-social-actions")) | length >= 1)
  and (map(select(.candidate_domain == "railway-nango-selfhost-runbook")) | length >= 1)
  and (map(select(.event == "notification_status_update" and .notification_status == "notified")) | length >= 2)
' "$routed" >/dev/null

grep -Eq "action|Actions" "$skills/nango-integrations/SKILL.md"
grep -Eq "Nango on Railway Runbook" "$skills/nango-integrations/references/SELF-HOSTED.md"
grep -Eq "Nango on Railway Runbook" "$skills/railway-api/SKILL.md"
grep -Eq "Handoff to .?nango-integrations" "$skills/railway-api/SKILL.md"

printf 'pass\n'
