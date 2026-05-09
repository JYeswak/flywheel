#!/usr/bin/env bash
set -euo pipefail

cd /Users/josh/Developer/flywheel

br show flywheel-2xdi --json \
  | jq -e '.[0].status == "closed" and (.[0].close_reason | contains("gap-hunt-probe shipped")) and (.[0].close_reason | contains("Auto-beads filed"))' >/dev/null

br show flywheel-2xdi.1 --json | jq -e '.[0].status == "closed"' >/dev/null
br show flywheel-2xdi.2 --json | jq -e '.[0].status == "closed"' >/dev/null
br show flywheel-2xdi.3 --json | jq -e '.[0].status == "closed"' >/dev/null

rg -n 'gap-hunt-probe\.sh|gap-hunt JSON|gap-hunt' \
  INCIDENTS.md \
  .flywheel/audit/flywheel-lqsy/gap-hunt-triage.md \
  .flywheel/receipts/flywheel-67v1/67v1-af2a36-evidence.md >/dev/null

printf 'pass\n'

