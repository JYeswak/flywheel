#!/usr/bin/env bash
set -euo pipefail

HOOK="${HOOK:-$HOME/.claude/hooks/flywheel-loop-dispatch-transport-gate.sh}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/dispatch-skill-block.XXXXXX")"
cleanup() {
  find "$TMP" -depth -mindepth 1 -delete 2>/dev/null || true
  rmdir "$TMP" 2>/dev/null || true
}
trap cleanup EXIT

repo="$TMP/repo"
mkdir -p "$repo/.flywheel"
git -C "$repo" init -q

export FLYWHEEL_LOOP_HOOK_LOG="$TMP/hook-blocks.jsonl"
unset FLYWHEEL_DISPATCH_WRAPPER
unset FLYWHEEL_DISPATCH_ENFORCE
unset FLYWHEEL_DISPATCH_GATE_DISABLE
unset JOSHUA_OVERRIDE

cmd='ntm send flywheel --pane=2 "Read /tmp/dispatch_foo.md"'
out="$(jq -nc --arg cwd "$repo" --arg cmd "$cmd" '{tool_name:"Bash",cwd:$cwd,tool_input:{command:$cmd}}' | bash "$HOOK")"

jq -e '.hookSpecificOutput.permissionDecision == "deny"' <<<"$out" >/dev/null
grep -q 'dispatch_skill_required' <<<"$out"
jq -e 'select(.gate == "dispatch_skill_required" and .decision == "deny" and .actual_wrapper_proof == "missing" and (.command_hash | length == 12))' "$FLYWHEEL_LOOP_HOOK_LOG" >/dev/null

printf 'OK dispatch_skill_required raw send blocked\n'
