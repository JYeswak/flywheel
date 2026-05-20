#!/usr/bin/env bash
set -euo pipefail

GOAL="/Users/josh/Desktop/zeststream-goals/flywheel/substrate-compounding-primary-20260520.txt"

GOAL_BUILD_REPO_NAME=flywheel /Users/josh/.claude/skills/goal-build/bin/goal-build validate "$GOAL" --strict --json \
  | jq -e '.success == true and .char_count <= 4000 and .canonical_location.status == "pass"' >/dev/null

grep -q 'substrate_compounding_rate' "$GOAL"
grep -q 'Jeff-Pattern Quality Anchor coverage' "$GOAL"
grep -q 'flywheel-as-meta-substrate' "$GOAL"
grep -q 'on or after H1 day-60' "$GOAL"
grep -q '2026-07-17' "$GOAL"
grep -q 'lock_hash 4f90a45d22b52c0e1ad6f1a251618cc921de8e471c3ea35b7fba07872be8904d' "$GOAL"

/Users/josh/.local/bin/ntm grep 'HANDOFF flywheel-bvdr2' skillos -n 2000 --json \
  | jq -e '.match_count >= 1' >/dev/null

printf 'PASS flywheel-bvdr2 l112-probe\n'
