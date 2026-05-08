#!/usr/bin/env bash
set -euo pipefail

LOOP_MD="${LOOP_MD:-$HOME/.claude/commands/flywheel/loop.md}"

grep -Fq 'reason=pulse_not_scheduled' "$LOOP_MD"
grep -Fq 'reason=pulse_stale' "$LOOP_MD"
grep -Fq 'greater than 15 minutes' "$LOOP_MD"
grep -Fq '~/.local/state/flywheel/team-pulse.jsonl' "$LOOP_MD"

printf 'PASS loop_stale_pulse_refusal_documented\n'
