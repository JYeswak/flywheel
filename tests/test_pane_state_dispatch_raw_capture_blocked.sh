#!/usr/bin/env bash
set -euo pipefail

HOOK="${HOOK:-$HOME/.claude/hooks/flywheel-loop-dispatch-transport-gate.sh}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/pane-state-dispatch-block.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

repo="$TMP/repo"
mkdir -p "$repo/.flywheel"
git -C "$repo" init -q

export FLYWHEEL_LOOP_HOOK_LOG="$TMP/hook-blocks.jsonl"
export FLYWHEEL_DISPATCH_WRAPPER=1
unset FLYWHEEL_DISPATCH_ENFORCE
unset FLYWHEEL_DISPATCH_GATE_DISABLE
unset FLYWHEEL_NTM_HEALTH_PROOF
unset FLYWHEEL_PANE_STATE_SOURCE
unset JOSHUA_OVERRIDE

cmd='tmux capture-pane -t flywheel:2 -p'
out="$(jq -nc --arg cwd "$repo" --arg cmd "$cmd" '{tool_name:"Bash",cwd:$cwd,tool_input:{command:$cmd}}' | bash "$HOOK")"

jq -e '.hookSpecificOutput.permissionDecision == "deny"' <<<"$out" >/dev/null
grep -Eq 'ntm_only_pane_state|pane_state_via_raw_capture' <<<"$out"
jq -e 'select(.gate == "ntm_only_pane_state" and .reason == "pane_state_via_raw_capture" and .decision == "deny" and .pane_state_source == "raw_capture")' "$FLYWHEEL_LOOP_HOOK_LOG" >/dev/null

printf 'OK ntm_only_pane_state hard deny in dispatch context\n'
