#!/usr/bin/env bash
set -euo pipefail

cd /Users/josh/Developer/flywheel

br show flywheel-478g --json \
  | jq -e '.[0].status == "closed"
    and (.[0].close_reason | contains("~/.claude/skills/.flywheel/INCIDENTS.md"))
    and (.[0].close_reason | contains("r1-cross-session-reinforcing-loop-skillos-flywheel-foggybear"))' >/dev/null

rg -q 'r1-cross-session-reinforcing-loop-skillos-flywheel-foggybear' \
  /Users/josh/.claude/skills/.flywheel/INCIDENTS.md
rg -q '"task_id": "apply-r1-loop-incidents-write-2026_05_03"' \
  .flywheel/dispatch-log.jsonl
rg -q '"entry_appended": "yes"' .flywheel/dispatch-log.jsonl
rg -q '"markdown_valid": "yes"' .flywheel/dispatch-log.jsonl
rg -q '"bead_closed": "yes"' .flywheel/dispatch-log.jsonl

test -s .flywheel/audit/flywheel-2xdi.14/evidence.md
test -s .flywheel/audit/flywheel-2xdi.14/compliance-pack.md
test -s .flywheel/audit/flywheel-2xdi.14/validation-receipt.json
br show flywheel-2xdi.14 --json \
  | jq -e '.[0].status == "closed"
    and (.[0].close_reason | test("cross-surface false positive|global canonical"))' >/dev/null
bash .flywheel/validation-schema/v1/parse.sh \
  .flywheel/audit/flywheel-2xdi.14/validation-receipt.json >/dev/null

printf 'flywheel-2xdi.14-l112-pass\n'
