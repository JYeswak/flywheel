#!/usr/bin/env bash
set -euo pipefail

HOOK="${HOOK:-$HOME/.claude/hooks/flywheel-loop-dispatch-transport-gate.sh}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/callback-contract-no-soc.XXXXXX")"

repo="$TMP/repo"
mkdir -p "$repo/.flywheel"
git -C "$repo" init -q

topology="$TMP/session-topology.jsonl"
jq -nc '{session:"flywheel",orchestrator_pane:1,callback_pane:1,human_pane:0,worker_panes:[2],effective_at:"2026-05-07T00:00:00Z"}' > "$topology"
export FLYWHEEL_SESSION_TOPOLOGY="$topology"
export FLYWHEEL_LOOP_HOOK_LOG="$TMP/hook-blocks.jsonl"

jq -nc '{schema_version:2,event:"worker_dispatch",task_id:"fixture-no-soc",socraticode_required:false,file_reservation_required:true,ts:"2026-05-07T00:00:00Z"}' > "$repo/.flywheel/dispatch-log.jsonl"

cmd='ntm send flywheel --pane=1 "DONE fixture task_id=fixture-no-soc did=4/4 didnt=none gaps=none socraticode_queries=0 indexed_chunks_observed=0 socraticode_unavailable_reason=explicit_no_socraticode files_reserved=NONE_NO_EDITS files_released=NONE_NO_EDITS no_bead_reason=fixture callback_delivery_verified=true"'
out="$(jq -nc --arg cwd "$repo" --arg cmd "$cmd" '{tool_name:"Bash",cwd:$cwd,tool_input:{command:$cmd}}' | bash "$HOOK")"

if [[ -n "$out" ]]; then
    printf 'expected pass, got hook output: %s\n' "$out" >&2
    exit 1
fi
