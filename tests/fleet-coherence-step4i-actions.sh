#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/fleet-coherence-step4i-actions.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

repo="$TMP/repo"
mkdir -p "$repo/.flywheel"
git -C "$repo" init -q
(cd "$repo" && br init --prefix fx >/dev/null)
printf 'mission\n' >"$repo/.flywheel/MISSION.md"
printf 'goal\n' >"$repo/.flywheel/GOAL.md"
printf 'state\n' >"$repo/.flywheel/STATE.md"
touch "$repo/.flywheel/dispatch-log.jsonl"

cat >"$TMP/latest.json" <<'JSON'
{"schema_version":"fleet-coherence-latest/v1","generated_at":"2026-05-08T12:00:00Z","latest_event":{"event_id":"fc-action-create-new","ts":"2026-05-08T12:00:00Z"}}
JSON

: >"$TMP/suppressions.jsonl"

cat >"$TMP/events.jsonl" <<'JSONL'
{"schema_version":"fleet-coherence-event/v2","event_id":"fc-action-create-old","ts":"2026-05-08T11:40:00Z","class":"repair_class","severity":"error","state":"open","session":"flywheel","pane":2,"dedupe_key":"repair_class:flywheel:pane1","l62":{"repair_callback_required":true,"sd_count":2,"sd_ids":["SD-1","SD-2"]},"l63":{"recovery_action_requires_drill":true,"recovery_drill_ids":["drill-1","drill-2","drill-3","drill-4","drill-5"]},"actions":{"receipt_required":true,"would_bead":true,"fleet_repair":true,"repair_action":"restart_worker"}}
{"schema_version":"fleet-coherence-event/v2","event_id":"fc-action-create-new","ts":"2026-05-08T11:50:00Z","class":"repair_class","severity":"error","state":"still_open","session":"flywheel","pane":2,"dedupe_key":"repair_class:flywheel:pane1","l62":{"repair_callback_required":true,"sd_count":2,"sd_ids":["SD-1","SD-2"]},"l63":{"recovery_action_requires_drill":true,"recovery_drill_ids":["drill-1","drill-2","drill-3","drill-4","drill-5"]},"actions":{"receipt_required":true,"would_bead":true,"fleet_repair":true,"repair_action":"restart_worker"}}
{"schema_version":"fleet-coherence-event/v2","event_id":"fc-no-bead","ts":"2026-05-08T11:51:00Z","class":"observation_only","severity":"warn","state":"open","session":"flywheel","pane":3,"dedupe_key":"observation_only:flywheel:pane3","l62":{"repair_callback_required":false,"sd_count":0,"sd_ids":[]},"l63":{"recovery_action_requires_drill":false,"recovery_drill_ids":[]},"actions":{"receipt_required":true,"would_bead":false,"would_no_bead_reason":"operator_pause_no_action"}}
{"schema_version":"fleet-coherence-event/v2","event_id":"fc-l62-missing","ts":"2026-05-08T11:52:00Z","class":"l62_missing","severity":"error","state":"open","session":"flywheel","pane":4,"dedupe_key":"l62_missing:flywheel:pane4","l62":{"repair_callback_required":true,"sd_count":0,"sd_ids":[]},"l63":{"recovery_action_requires_drill":true,"recovery_drill_ids":["drill-1","drill-2","drill-3","drill-4","drill-5"]},"actions":{"receipt_required":true,"would_bead":true,"fleet_repair":true,"repair_action":"restart_worker"}}
{"schema_version":"fleet-coherence-event/v2","event_id":"fc-missing-drills","ts":"2026-05-08T11:53:00Z","class":"missing_drills","severity":"error","state":"open","session":"flywheel","pane":5,"dedupe_key":"missing_drills:flywheel:pane5","l62":{"repair_callback_required":false,"sd_count":0,"sd_ids":[]},"l63":{"recovery_action_requires_drill":true,"recovery_drill_ids":["drill-1"]},"actions":{"receipt_required":true,"would_bead":true,"fleet_repair":true,"repair_action":"restart_worker"}}
{"schema_version":"fleet-coherence-event/v2","event_id":"fc-protected-client","ts":"2026-05-08T11:54:00Z","class":"protected_client","severity":"error","state":"open","session":"alpsinsurance","pane":1,"dedupe_key":"protected_client:alpsinsurance:pane1","l62":{"repair_callback_required":false,"sd_count":0,"sd_ids":[]},"l63":{"recovery_action_requires_drill":true,"recovery_drill_ids":["drill-1","drill-2","drill-3","drill-4","drill-5"]},"actions":{"receipt_required":true,"would_bead":true,"fleet_repair":true,"repair_action":"kill_and_respawn"}}
JSONL

env_base=(
  "FLYWHEEL_AUTO_RESPAWN=0"
  "FLYWHEEL_LOOP_STATE_DIR=$TMP/state"
  "FLYWHEEL_FLEET_COHERENCE_EVENTS=$TMP/events.jsonl"
  "FLYWHEEL_FLEET_COHERENCE_LATEST=$TMP/latest.json"
  "FLYWHEEL_FLEET_COHERENCE_SUPPRESSIONS=$TMP/suppressions.jsonl"
  "FLYWHEEL_FLEET_COHERENCE_ACTION_LEDGER=$repo/.flywheel/dispatch-log.jsonl"
  "FLYWHEEL_FLEET_COHERENCE_STEP4I_MODE=actions"
  "FLYWHEEL_FLEET_COHERENCE_ACTION_APPLY=1"
  "FLYWHEEL_FLEET_COHERENCE_NOW_EPOCH=1778245201"
)

bash -n "$BIN" && pass "flywheel_loop_syntax" || fail "flywheel_loop_syntax"

env "${env_base[@]}" "$BIN" tick --repo "$repo" --dry-run --json >"$TMP/dry-run.json"
assert_jq "$TMP/dry-run.json" '.fleet_coherence_step4i.mode == "action" and .fleet_coherence_step4i.phase == "3b"' "action_mode_schema"
assert_jq "$TMP/dry-run.json" '.fleet_coherence_step4i.mutation_apply == false and .fleet_coherence_step4i.no_mutations == true' "dry_run_no_mutation"
assert_jq "$TMP/dry-run.json" '.fleet_coherence_step4i.bead_decision_count == 1 and (.fleet_coherence_step4i.action_decisions[] | select(.event_id == "fc-action-create-new" and .bead_status == "planned"))' "dry_run_plans_bead"

env "${env_base[@]}" "$BIN" tick --repo "$repo" --json >"$TMP/apply.json"
assert_jq "$TMP/apply.json" '.fleet_coherence_step4i.mutation_apply == true and .fleet_coherence_step4i.no_mutations == false' "apply_mutation_mode"
assert_jq "$TMP/apply.json" '.fleet_coherence_step4i.dedupe_duplicate_count == 1 and .fleet_coherence_step4i.action_decision_count == 5' "duplicate_suppression_keeps_latest"
assert_jq "$TMP/apply.json" '.fleet_coherence_step4i.bead_decision_count == 1 and .fleet_coherence_step4i.no_bead_reason_count == 4' "bead_or_no_bead_exhaustive"
assert_jq "$TMP/apply.json" '.fleet_coherence_step4i.action_decisions[] | select(.event_id == "fc-no-bead" and .decision == "no_bead_reason" and .no_bead_reason == "operator_pause_no_action")' "no_bead_path"
assert_jq "$TMP/apply.json" '.fleet_coherence_step4i.l62_callback_violation_count == 1 and (.fleet_coherence_step4i.repair_receipts[] | select(.event_id == "fc-l62-missing" and .status == "failed" and .reason == "l62_callback_violation"))' "l62_missing_fields_fail_repair"
assert_jq "$TMP/apply.json" '.fleet_coherence_step4i.missing_drill_ids_count == 1 and (.fleet_coherence_step4i.action_decisions[] | select(.event_id == "fc-missing-drills" and .no_bead_reason == "missing_recovery_drill_ids"))' "missing_drills_block_recovery"
assert_jq "$TMP/apply.json" '.fleet_coherence_step4i.protected_client_guard_count == 1 and (.fleet_coherence_step4i.action_decisions[] | select(.event_id == "fc-protected-client" and .no_bead_reason == "protected_client_guard"))' "protected_client_guard"
assert_jq "$TMP/apply.json" '.fleet_coherence_step4i.fleet_repair_dispatch_count == 1 and (.fleet_coherence_step4i.repair_receipts[] | select(.event == "FLEET_REPAIR" and (.required_callback_fields == ["sd_count","sd_ids"])))' "fleet_repair_requires_l62_fields"
assert_jq "$TMP/apply.json" '.fleet_coherence_step4i.br_create_executed == true and .fleet_coherence_step4i.fleet_repair_dispatched == true and .fleet_coherence_step4i.no_bead_reason_finalized == true' "apply_executes_actions"

jq -s 'map(select(.event == "FLEET_REPAIR")) | length == 1' "$repo/.flywheel/dispatch-log.jsonl" >/dev/null \
  && pass "fleet_repair_ledger_row_written" || fail "fleet_repair_ledger_row_written"

env "${env_base[@]}" "$BIN" tick --repo "$repo" --json >"$TMP/reapply.json"
(cd "$repo" && br list --json) >"$TMP/br-list.json"
assert_jq "$TMP/br-list.json" '[.issues[] | select((.description // "") | contains("fleet-coherence-dedupe:repair_class:flywheel:pane1"))] | length == 1' "reapply_does_not_duplicate_bead"
assert_jq "$TMP/reapply.json" '.fleet_coherence_step4i.action_decisions[] | select(.event_id == "fc-action-create-new" and .bead_status == "existing")' "reapply_reuses_existing_bead"

if [[ "$fail_count" -eq 0 ]]; then
  printf 'PASS tests/fleet-coherence-step4i-actions.sh (%s checks)\n' "$pass_count"
  exit 0
fi

printf 'FAIL tests/fleet-coherence-step4i-actions.sh (%s failures, %s passes)\n' "$fail_count" "$pass_count" >&2
exit 1
