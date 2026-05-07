#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="$ROOT/.flywheel/scripts/dispatch-log-schema-validator.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/dispatch-log-pane-state.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

repo="$TMP/repo"
mkdir -p "$repo/.flywheel/validation-schema/v1"
cp "$ROOT/.flywheel/validation-schema/v1/dispatch-log-entry-v2.schema.json" "$repo/.flywheel/validation-schema/v1/"

cat >"$repo/.flywheel/dispatch-log.jsonl" <<'JSONL'
{"schema_version":2,"event":"dispatch_sent","task_id":"valid-pane-state","ts":"2026-05-07T00:00:00Z","from":"flywheel:1","to":"flywheel-pane-2","pane":2,"session":"flywheel","task_summary":"valid pane state","task_file":"/tmp/valid-pane-state.md","agent_type":"codex","pane_state_source":"ntm_health","mission_anchor":"continuous-orchestrator-uptime-self-sustaining-fleet","mission_fitness_claim":"Directly validates pane-state source contract.","mission_fitness_class":"direct","idempotency_token":"valid-pane-state","callback_received_at":null}
{"schema_version":2,"event":"dispatch_sent","task_id":"raw-pane-state","ts":"2026-05-07T00:01:00Z","from":"flywheel:1","to":"flywheel-pane-3","pane":3,"session":"flywheel","task_summary":"raw pane state","task_file":"/tmp/raw-pane-state.md","agent_type":"codex","pane_state_source":"raw_capture","mission_anchor":"continuous-orchestrator-uptime-self-sustaining-fleet","mission_fitness_claim":"Fixture proves raw capture is rejected for dispatch rows.","mission_fitness_class":"direct","idempotency_token":"raw-pane-state","callback_received_at":null}
{"schema_version":2,"event":"dispatch_sent","task_id":"missing-pane-state","ts":"2026-05-07T00:02:00Z","from":"flywheel:1","to":"flywheel-pane-4","pane":4,"session":"flywheel","task_summary":"missing pane state","task_file":"/tmp/missing-pane-state.md","agent_type":"codex","mission_anchor":"continuous-orchestrator-uptime-self-sustaining-fleet","mission_fitness_claim":"Fixture proves missing pane state source is rejected.","mission_fitness_class":"direct","idempotency_token":"missing-pane-state","callback_received_at":null}
JSONL

bash "$BIN" --schema | jq -e '.required | index("pane_state_source")' >/dev/null
bash "$BIN" --schema | jq -e '.properties.pane_state_source.enum == ["ntm_health","ntm_copy","raw_capture","none"]' >/dev/null
bash "$BIN" --repo "$repo" --json >"$TMP/summary.json"
jq -e '.total == 3 and .valid == 1 and .invalid == 2' "$TMP/summary.json" >/dev/null
set +e
bash "$BIN" validate --repo "$repo" --json >"$TMP/validate.json"
validate_rc=$?
set -e
[[ "$validate_rc" -eq 1 ]]
bash "$BIN" --repo "$repo" --explain >"$TMP/explain.txt"
grep -q 'raw_capture_dispatch_context' "$TMP/explain.txt"
grep -q 'missing_pane_state_source' "$TMP/explain.txt"

printf 'OK pane_state_source schema and dispatch violation checks passed\n'
