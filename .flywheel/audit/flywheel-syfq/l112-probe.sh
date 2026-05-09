#!/usr/bin/env bash
set -euo pipefail

cd /Users/josh/Developer/flywheel

jsm validate /Users/josh/.claude/skills/agent-fleet-management --json \
  | jq -e '.success == true and .skill_name == "agent-fleet-management" and (.errors | length) == 0' >/dev/null

br show flywheel-th8w --json \
  | jq -e '.[0].status == "closed" and (.[0].close_reason | contains("JSM push remains explicitly tracked by flywheel-syfq"))' >/dev/null

rg -n 'Decision: keep `agent-fleet-management` local-only|No `jsm push` command was run' \
  .flywheel/audit/flywheel-syfq/compliance-pack.md >/dev/null

.flywheel/scripts/skill-enhance-jsm-discipline.sh \
  --validate-packet /tmp/dispatch_flywheel-syfq-0272b3.md \
  --jsm-list-json .flywheel/audit/flywheel-syfq/jsm-list-fixture.json \
  --json \
  | jq -e '.status == "pass"' >/dev/null

printf 'pass\n'

