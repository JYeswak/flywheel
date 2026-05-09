#!/usr/bin/env bash
set -euo pipefail

cd /Users/josh/Developer/flywheel

index=".flywheel/PLANS/memory-crosslinks-2026-05-09/hive-and-fleet-mail.md"
test -s "$index"

for pattern in \
  'flywheel-2ms' \
  'flywheel-3fa' \
  'Hive architecture' \
  'Fleet-mail coordination' \
  'ARCHITECTURE\.md:10-13' \
  'reference_lavenderglen_fleet_mail\.md:7-15' \
  'Do not assume historical memory phrase'
do
  rg -n "$pattern" "$index" >/dev/null
done

br show flywheel-2ms --json \
  | jq -e '.[0].status == "closed" and (.[0].description | contains("flywheel = brain"))' >/dev/null

br show flywheel-3fa --json \
  | jq -e '.[0].status == "closed" and (.[0].description | contains("fleet-mail-project"))' >/dev/null

rg -n 'flywheel-3fa|fleet-mail identity model' \
  .flywheel/PLANS/jeff-ecosystem-deep-dive-2026-05-01/04-our-needs-vs-stack.md \
  /Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/reference_lavenderglen_fleet_mail.md >/dev/null

printf 'pass\n'
