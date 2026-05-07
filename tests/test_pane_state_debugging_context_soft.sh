#!/usr/bin/env bash
set -euo pipefail

HOOK="${HOOK:-$HOME/.claude/hooks/flywheel-loop-dispatch-transport-gate.sh}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/pane-state-debug-soft.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

repo="$TMP/repo"
mkdir -p "$repo/.flywheel"
git -C "$repo" init -q

export FLYWHEEL_LOOP_HOOK_LOG="$TMP/hook-blocks.jsonl"
unset FLYWHEEL_DISPATCH_WRAPPER
unset FLYWHEEL_DISPATCH_ENFORCE
unset FLYWHEEL_DISPATCH_GATE_DISABLE
unset FLYWHEEL_NTM_HEALTH_PROOF
unset FLYWHEEL_PANE_STATE_SOURCE
unset JOSHUA_OVERRIDE

cmd='tmux capture-pane -t flywheel:2 -p'
out="$(jq -nc --arg cwd "$repo" --arg cmd "$cmd" '{tool_name:"Bash",cwd:$cwd,tool_input:{command:$cmd}}' | bash "$HOOK")"

if [[ -n "$out" ]]; then
  printf 'expected soft allow with no hook output, got: %s\n' "$out" >&2
  exit 1
fi
jq -e 'select(.gate == "ntm_only_pane_state" and .reason == "pane_state_via_raw_capture" and .decision == "soft_allow" and .pane_state_source == "raw_capture")' "$FLYWHEEL_LOOP_HOOK_LOG" >/dev/null

printf 'OK pane_state_via_raw_capture soft violation logged\n'
