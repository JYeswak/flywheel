#!/usr/bin/env bash
set -euo pipefail

FLYWHEEL=/Users/josh/Developer/flywheel
NTM=/Users/josh/Developer/ntm

git -C "$NTM" rev-parse --verify upstream-track/flywheel-me08-pi >/dev/null
git -C "$NTM" rev-parse --verify local/bead-isolation-reconciled-20260502T170928 >/dev/null

git -C "$NTM" grep -n 'AgentTypePi' upstream-track/flywheel-me08-pi -- internal/agent/types.go >/dev/null
git -C "$NTM" grep -n 'pi-agent' upstream-track/flywheel-me08-pi -- internal/agent/types.go internal/tmux/session.go >/dev/null
if git -C "$NTM" grep -n 'cubcode\|AgentTypeCubcode' upstream-track/flywheel-me08-pi -- internal/agent/types.go internal/cli/ensemble.go internal/ensemble/assignment.go internal/swarm/agent_launcher.go internal/tmux/session.go >/dev/null 2>&1; then
  printf '%s\n' 'ERR_cubcode_present_on_upstream_track' >&2
  exit 1
fi

git -C "$NTM" grep -n 'cubcode\|AgentTypeCubcode' local/bead-isolation-reconciled-20260502T170928 -- internal/agent/types.go internal/cli/ensemble.go internal/swarm/agent_launcher.go >/dev/null
rg -n 'split it at the cherry-pick boundary' "$FLYWHEEL/.flywheel/doctrine/split-boundary.md" >/dev/null

printf '%s\n' 'OK_pi_cubcode_split_boundary'
