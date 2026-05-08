#!/usr/bin/env bash
set -euo pipefail

LOOP_MD="${LOOP_MD:-$HOME/.claude/commands/flywheel/loop.md}"

grep -Fq 'Team roster authorization pre-flight' "$LOOP_MD"
grep -Fq 'reason=team_roster_row_missing' "$LOOP_MD"
grep -Fq '~/.local/state/flywheel/team-roster.jsonl' "$LOOP_MD"

printf 'PASS loop_missing_roster_refusal_documented\n'
