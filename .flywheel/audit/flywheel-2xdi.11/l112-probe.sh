#!/usr/bin/env bash
set -euo pipefail

cd /Users/josh/Developer/flywheel

br show flywheel-4izs --json \
  | jq -e '.[0].status == "closed" and (.[0].close_reason | contains("Digest complete"))' >/dev/null

test -s .flywheel/digests/joshua-decision-queue-2026-05-03-morning.md
rg -q 'No decisions were applied while preparing this digest' \
  .flywheel/digests/joshua-decision-queue-2026-05-03-morning.md
rg -q '"summary_bead": "flywheel-4izs"' .flywheel/dispatch-log.jsonl
rg -q '"decisions_enumerated": 5' .flywheel/dispatch-log.jsonl

test -s .flywheel/audit/flywheel-2xdi.11/evidence.md
test -s .flywheel/audit/flywheel-2xdi.11/compliance-pack.md
test -s .flywheel/audit/flywheel-2xdi.11/validation-receipt.json
br show flywheel-2xdi.11 --json \
  | jq -e '.[0].status == "closed" and (.[0].close_reason | test("false positive"))' >/dev/null
bash .flywheel/validation-schema/v1/parse.sh .flywheel/audit/flywheel-2xdi.11/validation-receipt.json >/dev/null

printf 'flywheel-2xdi.11-l112-pass\n'
