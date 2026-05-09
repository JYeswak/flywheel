#!/usr/bin/env bash
set -euo pipefail

repo=/Users/josh/Developer/flywheel
leverage=/Users/josh/.local/state/flywheel/leverage-ceiling.jsonl
gap=/Users/josh/.local/state/flywheel/gap-hunt.jsonl
triage="$repo/.flywheel/audit/flywheel-lqsy/gap-hunt-triage.md"
decision="$repo/.flywheel/digests/joshua-decision-queue-2026-05-09-lqsy.md"
compliance="$repo/.flywheel/audit/flywheel-lqsy/compliance-pack.md"

jq -s 'length >= 7' "$leverage" >/dev/null
tail -1 "$gap" | jq -e '.gaps_total >= 129 and .gap_class_distribution["bead-without-followup"] == 20' >/dev/null
rg -Fq '| actionable | 3 | `flywheel-17g9`, `flywheel-1fso`, `flywheel-1naj.1` |' "$triage"
rg -Fq '| doctrine-debt | 9 |' "$triage"
rg -Fq '| noise | 8 |' "$triage"
rg -Fq 'Approve Option A: do not run daily Jeff ingest manually while storage is FIRE' "$decision"
rg -Fq 'Compliance score: 840/1000' "$compliance"

printf 'pass\n'
