#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
loop-goal-contract-gate.sh validate --decision <ID> --dispatch-log <path> [--contract <path>] [--repo <path>] [--task-id <id>] [--json]

Validates the compact goal contract required before /flywheel:tick dispatches.
Missing or invalid contracts emit NO_DISPATCH: missing_goal_contract and return 0.
EOF
}

json_out=0
repo="$(pwd -P)"
decision=""
dispatch_log=""
contract_path="${FLYWHEEL_GOAL_CONTRACT:-}"
task_id="${FLYWHEEL_TICK_ID:-}"
mode="validate"

[[ "${1:-}" == "validate" ]] && shift
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) repo="$2"; shift 2 ;;
    --decision) decision="$2"; shift 2 ;;
    --dispatch-log) dispatch_log="$2"; shift 2 ;;
    --contract) contract_path="$2"; shift 2 ;;
    --task-id) task_id="$2"; shift 2 ;;
    --json) json_out=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) echo "ERR: unknown arg: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$dispatch_log" ]] || dispatch_log="$repo/.flywheel/dispatch-log.jsonl"
[[ -n "$task_id" ]] || task_id="tick-$(date -u +%Y%m%dT%H%M%SZ)"
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
mkdir -p "$(dirname "$dispatch_log")"

emit_result() {
  local payload="$1"
  if [[ "$json_out" -eq 1 ]]; then
    printf '%s\n' "$payload"
  else
    jq -r '"\(.status): \(.reason // "ok")"' <<<"$payload"
  fi
}

append_no_dispatch() {
  local reason="$1" missing="$2"
  local row
  row="$(jq -nc \
    --arg ts "$ts" \
    --arg task_id "$task_id" \
    --arg decision "$decision" \
    --arg reason "$reason" \
    --argjson missing "$missing" \
    '{
      schema_version:"loop-goal-contract-gate/v1",
      ts:$ts,
      event:"NO_DISPATCH",
      event_key:"NO_DISPATCH:missing-contract",
      status:"missing_goal_contract",
      reason:$reason,
      mode:"loop",
      origin_task_id:$task_id,
      goal_id:null,
      sprint_id:null,
      tick_id:$task_id,
      task_id:$task_id,
      decision:$decision,
      missing_goal_contract:true,
      missing_fields:$missing
    }')"
  printf '%s\n' "$row" >>"$dispatch_log"
}

if [[ ! "$decision" =~ ^(DISPATCH_BEAD|DOCTRINE_HUNT|FLEET_REPAIR|auto_refill_after_reap)$ ]]; then
  emit_result "$(jq -nc --arg decision "$decision" '{schema_version:"loop-goal-contract-gate/v1",status:"not_applicable",decision:$decision}')"
  exit 0
fi

missing='[]'
contract='{}'
if [[ -z "$contract_path" || ! -r "$contract_path" ]]; then
  missing='["contract_path"]'
else
  if ! contract="$(jq -c . "$contract_path" 2>/dev/null)"; then
    missing='["valid_json"]'
  else
    missing="$(jq -c '
      [
        (if ((.goal_id // "") | length) > 0 then empty else "goal_id" end),
        (if (((.hard_bars // []) | type) == "array" and ((.hard_bars // []) | length) > 0) then empty else "hard_bars" end),
        (if (((.forbid_clauses // []) | type) == "array" and ((.forbid_clauses // []) | length) > 0) then empty else "forbid_clauses" end),
        (if (((.target_beads // []) | type) == "array" and ((.target_beads // []) | length) > 0) then empty else "target_beads" end),
        (if (((.out_of_scope_lanes // []) | type) == "array" and ((.out_of_scope_lanes // []) | length) > 0) then empty else "out_of_scope_lanes" end),
        (if (.callback_envelope // null) != null then empty else "callback_envelope" end),
        (if (((.stop_conditions // []) | type) == "array" and ((.stop_conditions // []) | length) > 0) then empty else "stop_conditions" end)
      ]' <<<"$contract")"
  fi
fi

if [[ "$(jq -r 'length' <<<"$missing")" -gt 0 ]]; then
  append_no_dispatch "missing_goal_contract" "$missing"
  emit_result "$(jq -nc --arg ts "$ts" --arg task_id "$task_id" --arg decision "$decision" --argjson missing "$missing" '{schema_version:"loop-goal-contract-gate/v1",ts:$ts,status:"no_dispatch",reason:"missing_goal_contract",task_id:$task_id,mode:"loop",tick_id:$task_id,decision:$decision,missing_fields:$missing}')"
  exit 0
fi

emit_result "$(jq -nc --arg ts "$ts" --arg task_id "$task_id" --arg decision "$decision" --arg contract_path "$contract_path" --argjson contract "$contract" '{schema_version:"loop-goal-contract-gate/v1",ts:$ts,status:"dispatch_allowed",task_id:$task_id,mode:"loop",tick_id:$task_id,decision:$decision,contract_path:$contract_path,contract:$contract}')"
