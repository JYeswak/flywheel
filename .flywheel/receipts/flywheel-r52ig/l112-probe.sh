#!/usr/bin/env bash
set -euo pipefail

repo="/Users/josh/Developer/flywheel"
cd "$repo"

bash -n .flywheel/scripts/dispatch-and-verify.sh
bash tests/dispatch-and-verify.sh >/dev/null

.flywheel/scripts/dispatch-and-verify.sh --help >/dev/null
.flywheel/scripts/dispatch-and-verify.sh --info --json \
  | jq -e '.command == "info" and .schema_version == "dispatch-and-verify.info.v1"' >/dev/null
.flywheel/scripts/dispatch-and-verify.sh --examples --json \
  | jq -e '.command == "examples" and (.examples | length) >= 3' >/dev/null
.flywheel/scripts/dispatch-and-verify.sh --schema \
  | jq -e '.schema_version == "dispatch-and-verify.schema.v1" and (.exit_codes."2" | test("usage"))' >/dev/null

jq -s 'length == 10 and .[0].tool == "flywheel-loop" and .[1].tool == "dispatch-and-verify" and .[2].tool == "sync-canonical-doctrine"' \
  .flywheel/receipts/flywheel-r52ig/audit/top_10_cli_inventory.jsonl >/dev/null

test -s .flywheel/receipts/flywheel-r52ig/audit/flywheel-loop/agent_surfaces.jsonl
test -s .flywheel/receipts/flywheel-r52ig/audit/dispatch-and-verify/agent_surfaces.jsonl
test -s .flywheel/receipts/flywheel-r52ig/audit/sync-canonical-doctrine/agent_surfaces.jsonl
test -s .flywheel/receipts/flywheel-r52ig/audit/flywheel-loop/recommendations.jsonl
test -s .flywheel/receipts/flywheel-r52ig/audit/dispatch-and-verify/recommendations.jsonl
test -s .flywheel/receipts/flywheel-r52ig/audit/sync-canonical-doctrine/recommendations.jsonl

rg -q 'Quarterly Cadence' .flywheel/doctrine/agent-ergonomics-application-baseline-2026-05-08.md
rg -q 'next_due=2026-08-08' .flywheel/doctrine/agent-ergonomics-application-baseline-2026-05-08.md

printf '%s\n' 'L112_PASS_flywheel-r52ig_agent_ergonomics_baseline'
