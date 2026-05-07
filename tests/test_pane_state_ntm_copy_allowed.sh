#!/usr/bin/env bash
set -euo pipefail

HOOK="${HOOK:-$HOME/.claude/hooks/flywheel-loop-dispatch-transport-gate.sh}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/pane-state-ntm-copy.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

repo="$TMP/repo"
mkdir -p "$repo/.flywheel"
git -C "$repo" init -q

export FLYWHEEL_LOOP_HOOK_LOG="$TMP/hook-blocks.jsonl"
export FLYWHEEL_DISPATCH_WRAPPER=1
unset FLYWHEEL_DISPATCH_ENFORCE
unset FLYWHEEL_DISPATCH_GATE_DISABLE
unset JOSHUA_OVERRIDE

cmd='ntm copy flywheel:2 -l 50'
out="$(jq -nc --arg cwd "$repo" --arg cmd "$cmd" '{tool_name:"Bash",cwd:$cwd,tool_input:{command:$cmd}}' | bash "$HOOK")"

if [[ -n "$out" ]]; then
  printf 'expected allow with no hook output, got: %s\n' "$out" >&2
  exit 1
fi

printf 'OK ntm copy allowed in dispatch context\n'
