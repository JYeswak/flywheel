#!/usr/bin/env bash
set -euo pipefail

HOOK="${HOOK:-$HOME/.claude/hooks/flywheel-loop-dispatch-transport-gate.sh}"
TMP="$(mktemp -d -t u1x3.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

repo="$TMP/repo"
mkdir -p "$repo/.flywheel"
git -C "$repo" init -q
topology="$TMP/session-topology.jsonl"
jq -nc '{session:"flywheel",orchestrator_pane:1,callback_pane:1,human_pane:0,worker_panes:[2],effective_at:"2026-05-08T00:00:00Z"}' >"$topology"
export FLYWHEEL_SESSION_TOPOLOGY="$topology"
export FLYWHEEL_LOOP_HOOK_LOG="$TMP/hook-blocks.jsonl"
unset FLYWHEEL_DISPATCH_ENFORCE
unset FLYWHEEL_DISPATCH_GATE_DISABLE
unset FLYWHEEL_DISPATCH_WRAPPER
unset JOSHUA_OVERRIDE

cmd='ntm send flywheel --pane=1 "DONE fixture task_id=fixture did=1/1 didnt=none gaps=none socraticode_queries=unknown indexed_chunks_observed=unknown"'

out="$(jq -nc --arg cwd "$repo" --arg cmd "$cmd" '{tool_name:"Bash",cwd:$cwd,tool_input:{command:$cmd}}' | bash "$HOOK")"
jq -e '.hookSpecificOutput.permissionDecision == "deny"' <<<"$out" >/dev/null || fail "callback contract should block before rollback"

export FLYWHEEL_DISPATCH_GATE_DISABLE=callback_contract_required
out="$(jq -nc --arg cwd "$repo" --arg cmd "$cmd" '{tool_name:"Bash",cwd:$cwd,tool_input:{command:$cmd}}' | bash "$HOOK")"
[ -z "$out" ] || fail "per-gate rollback should allow callback"
jq -e 'select(.gate == "callback_contract_required" and .decision == "skip" and .actual_wrapper_proof == "disabled")' "$FLYWHEEL_LOOP_HOOK_LOG" >/dev/null || fail "per-gate skip not logged"

unset FLYWHEEL_DISPATCH_GATE_DISABLE
touch "$repo/.flywheel/no-enforce-dispatch"
out="$(jq -nc --arg cwd "$repo" --arg cmd "$cmd" '{tool_name:"Bash",cwd:$cwd,tool_input:{command:$cmd}}' | bash "$HOOK")"
[ -z "$out" ] || fail "repo sentinel rollback should allow callback"

mkdir -p "$HOME/.local/state/flywheel/dispatch-gates-disabled"
sentinel="$HOME/.local/state/flywheel/dispatch-gates-disabled/callback_contract_required"
touch "$sentinel"
trap 'rm -f "$sentinel"; rm -rf "$TMP"' EXIT
rm -f "$repo/.flywheel/no-enforce-dispatch"
out="$(jq -nc --arg cwd "$repo" --arg cmd "$cmd" '{tool_name:"Bash",cwd:$cwd,tool_input:{command:$cmd}}' | bash "$HOOK")"
[ -z "$out" ] || fail "global sentinel rollback should allow callback"

printf 'OK dispatch enforcement rollback knobs\n'
