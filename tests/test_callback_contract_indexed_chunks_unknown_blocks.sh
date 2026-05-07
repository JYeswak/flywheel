#!/usr/bin/env bash
set -euo pipefail

HOOK="${HOOK:-$HOME/.claude/hooks/flywheel-loop-dispatch-transport-gate.sh}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/callback-contract-unknown.XXXXXX")"

repo="$TMP/repo"
mkdir -p "$repo/.flywheel"
git -C "$repo" init -q

topology="$TMP/session-topology.jsonl"
jq -nc '{session:"flywheel",orchestrator_pane:1,callback_pane:1,human_pane:0,worker_panes:[2],effective_at:"2026-05-07T00:00:00Z"}' > "$topology"
export FLYWHEEL_SESSION_TOPOLOGY="$topology"
export FLYWHEEL_LOOP_HOOK_LOG="$TMP/hook-blocks.jsonl"

jq -nc '{schema_version:2,event:"worker_dispatch",task_id:"fixture-unknown",socraticode_required:true,file_reservation_required:true,ts:"2026-05-07T00:00:00Z"}' > "$repo/.flywheel/dispatch-log.jsonl"

cmd='ntm send flywheel --pane=1 "DONE fixture task_id=fixture-unknown did=4/4 didnt=none gaps=none socraticode_queries=5 indexed_chunks_observed=unknown files_reserved=tests/a files_released=tests/a no_bead_reason=fixture callback_delivery_verified=true"'
out="$(jq -nc --arg cwd "$repo" --arg cmd "$cmd" '{tool_name:"Bash",cwd:$cwd,tool_input:{command:$cmd}}' | bash "$HOOK")"

jq -e '.hookSpecificOutput.permissionDecision == "deny"' <<<"$out" >/dev/null
grep -q 'callback_contract_required' <<<"$out"
grep -q 'indexed_chunks_observed' <<<"$out"
