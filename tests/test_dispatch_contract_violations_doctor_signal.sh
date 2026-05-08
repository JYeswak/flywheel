#!/usr/bin/env bash
set -euo pipefail

LOOP="${LOOP:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/dispatch-contract-doctor.XXXXXX")"

repo="$TMP/repo"
mkdir -p "$repo/.flywheel"
git -C "$repo" init -q
printf '# Mission\n' > "$repo/.flywheel/MISSION.md"
printf '# Goal\n' > "$repo/.flywheel/GOAL.md"
printf '# State\n' > "$repo/.flywheel/STATE.md"

{
    jq -nc '{schema_version:2,event:"worker_callback",task_id:"bad1",callback_status:"DONE",socraticode_required:true,file_reservation_required:true,socraticode_queries:"nope",indexed_chunks_observed:"unknown",files_reserved:"tests/a",files_released:"tests/a",no_bead_reason:"fixture",did:"1/1",didnt:"none",gaps:"none",ts:"2026-05-07T00:00:00Z"}'
    jq -nc '{schema_version:2,event:"worker_callback",task_id:"bad2",callback_status:"BLOCKED",socraticode_required:true,file_reservation_required:true,socraticode_queries:3,indexed_chunks_observed:10,ts:"2026-05-07T00:01:00Z"}'
    jq -nc '{schema_version:1,event:"worker_callback",task_id:"legacy",callback_status:"DONE",ts:"2026-05-07T00:02:00Z"}'
} > "$repo/.flywheel/dispatch-log.jsonl"

out="$("$LOOP" doctor --repo "$repo" --json 2>/dev/null || true)"

jq -e '
  .dispatch_contract_violations == 2
  and .dispatch_contract.status == "fail"
  and .dispatch_contract.legacy_warn_only_count == 1
  and .dispatch_contract.dispatch_enforcement.legacy_policy == "warn_only"
  and .dispatch_contract.dispatch_enforcement.v2_policy == "fail_on_contract_violation"
' <<<"$out" >/dev/null

legacy_repo="$TMP/legacy-repo"
mkdir -p "$legacy_repo/.flywheel"
git -C "$legacy_repo" init -q
printf '# Mission\n' > "$legacy_repo/.flywheel/MISSION.md"
printf '# Goal\n' > "$legacy_repo/.flywheel/GOAL.md"
printf '# State\n' > "$legacy_repo/.flywheel/STATE.md"
jq -nc '{schema_version:1,event:"worker_callback",callback_status:"DONE",task_id:"legacy-only",ts:"2026-05-07T00:02:00Z"}' > "$legacy_repo/.flywheel/dispatch-log.jsonl"

legacy_out="$("$LOOP" doctor --repo "$legacy_repo" --json 2>/dev/null || true)"
jq -e '
  .dispatch_contract_violations == 0
  and .dispatch_contract.status == "warn"
  and .dispatch_contract.legacy_warn_only_count == 1
' <<<"$legacy_out" >/dev/null
