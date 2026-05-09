#!/usr/bin/env bash
set -euo pipefail

cd /Users/josh/Developer/flywheel

test -s .flywheel/audit/flywheel-13u0.1/incidents-draft.md
test -s /Users/josh/.local/state/flywheel/fuckup-processed.jsonl

rg -n 'sidecar-processed-ledger-blindness|flywheel-17g9|flywheel-5bq7|/tmp/flywheel-17g9_findings\.md|/Users/josh/\.local/state/flywheel/fuckup-processed\.jsonl|Forever-Rule: Any UI, probe, list command' \
  .flywheel/audit/flywheel-13u0.1/incidents-draft.md >/dev/null

br show flywheel-17g9 --json \
  | jq -e '.[0].status == "closed" and (.[0].close_reason | contains("/tmp/flywheel-17g9_findings.md"))' >/dev/null

br show flywheel-5bq7 --json \
  | jq -e '.[0].status == "closed" and (.[0].close_reason | contains("fuckup-processed.jsonl"))' >/dev/null

! git diff --name-only -- .flywheel/audit/flywheel-13u0.1 .beads/issues.jsonl \
  | rg -x 'INCIDENTS\.md' >/dev/null

printf 'pass\n'
