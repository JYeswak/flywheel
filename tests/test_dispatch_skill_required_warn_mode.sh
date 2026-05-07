#!/usr/bin/env bash
set -euo pipefail

HOOK="${HOOK:-$HOME/.claude/hooks/flywheel-loop-dispatch-transport-gate.sh}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/dispatch-skill-warn.XXXXXX")"
cleanup() {
  find "$TMP" -depth -mindepth 1 -delete 2>/dev/null || true
  rmdir "$TMP" 2>/dev/null || true
}
trap cleanup EXIT

repo="$TMP/repo"
mkdir -p "$repo/.flywheel"
git -C "$repo" init -q

topology="$TMP/session-topology.jsonl"
jq -nc '{session:"flywheel",orchestrator_pane:1,callback_pane:1,human_pane:0,worker_panes:[2],effective_at:"2026-05-07T00:00:00Z"}' > "$topology"

export FLYWHEEL_SESSION_TOPOLOGY="$topology"
export FLYWHEEL_LOOP_HOOK_LOG="$TMP/hook-blocks.jsonl"
export FLYWHEEL_DISPATCH_ENFORCE=warn
unset FLYWHEEL_DISPATCH_WRAPPER
unset FLYWHEEL_DISPATCH_GATE_DISABLE
unset JOSHUA_OVERRIDE

cmd='ntm send flywheel --pane=2 "Read /tmp/dispatch_foo.md"'
out="$(jq -nc --arg cwd "$repo" --arg cmd "$cmd" '{tool_name:"Bash",cwd:$cwd,tool_input:{command:$cmd}}' | bash "$HOOK")"

[[ -z "$out" ]] || {
  printf 'expected warn-mode pass, got hook output: %s\n' "$out" >&2
  exit 1
}
jq -e 'select(.gate == "dispatch_skill_required" and .decision == "warn" and .actual_wrapper_proof == "missing")' "$FLYWHEEL_LOOP_HOOK_LOG" >/dev/null

printf 'OK dispatch_skill_required warn mode allowed and logged\n'
