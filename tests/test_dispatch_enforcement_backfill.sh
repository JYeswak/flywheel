#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/dispatch-log-backfill-v2.sh"
TMP="$(mktemp -d -t u1x3.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

repo="$TMP/repo"
mkdir -p "$repo/.flywheel"
git -C "$repo" init -q

cat >"$repo/.flywheel/dispatch-log.jsonl" <<'JSONL'
{"task_id":"legacy-1","ts":"2026-05-07T00:00:00Z","target_session":"flywheel","target_pane":2,"task_summary":"legacy row","task_file":"/tmp/dispatch_legacy.md"}
{"schema_version":2,"task_id":"v2-ok","ts":"2026-05-07T00:01:00Z","from":"flywheel:1","to":"flywheel:2","pane":2,"session":"flywheel","task_summary":"v2 row","task_file":"/tmp/dispatch_v2.md","agent_type":"codex","pane_state_source":"ntm_health","mission_anchor":"continuous-orchestrator-uptime-self-sustaining-fleet","mission_fitness_claim":"fixture","mission_fitness_class":"infrastructure","idempotency_token":"v2-ok","callback_received_at":null}
{"schema_version":2,"event":"dispatch_sent","task_id":"v2-attributed","ts":"2026-05-07T00:02:00Z","mode":"manual","origin_task_id":"v2-attributed","goal_id":null,"sprint_id":null,"tick_id":null}
JSONL

before="$(shasum -a 256 "$repo/.flywheel/dispatch-log.jsonl" | awk '{print $1}')"
"$SCRIPT" --repo "$repo" --dry-run --json >"$TMP/dry-run.json"
after="$(shasum -a 256 "$repo/.flywheel/dispatch-log.jsonl" | awk '{print $1}')"
[ "$before" = "$after" ] || fail "dry-run mutated dispatch-log"
jq -e '.mode == "dry-run" and .mutated == false and .planned_annotations_count == 2 and .planned_annotations[0].session == "flywheel" and .planned_annotations[0].pane == 2 and .planned_annotations[0].mode == "unknown" and .planned_annotations[1].task_id == "v2-ok"' "$TMP/dry-run.json" >/dev/null || fail "dry-run summary mismatch"

set +e
"$SCRIPT" --repo "$repo" --apply --json >"$TMP/apply-no-key.json"
rc=$?
set -e
[ "$rc" -ne 0 ] || fail "apply without idempotency key should fail"
jq -e '.reason == "idempotency_key_required"' "$TMP/apply-no-key.json" >/dev/null || fail "missing idempotency refusal reason"

"$SCRIPT" --repo "$repo" --apply --idempotency-key u1x3-fixture --json >"$TMP/apply.json"
jq -e '.mode == "apply" and .mutated == true and .idempotency_key == "u1x3-fixture" and (.audit_receipt_path | length > 0)' "$TMP/apply.json" >/dev/null || fail "apply summary mismatch"
receipt="$(jq -r '.audit_receipt_path' "$TMP/apply.json")"
[ -f "$receipt" ] || fail "audit receipt missing"
jq -e 'select(.schema_version == 2 and .backfilled == true and .backfill_idempotency_key == "u1x3-fixture")' "$repo/.flywheel/dispatch-log.jsonl" >/dev/null || fail "backfilled row missing"
jq -s 'all(.[]; has("mode") and has("origin_task_id") and has("goal_id") and has("sprint_id") and has("tick_id"))' "$repo/.flywheel/dispatch-log.jsonl" >/dev/null || fail "mode attribution fields missing after apply"

"$SCRIPT" --repo "$repo" --apply --idempotency-key u1x3-fixture --json >"$TMP/apply-again.json"
jq -e '.mode == "apply" and .planned_annotations_count == 0' "$TMP/apply-again.json" >/dev/null || fail "second apply should be idempotent"

printf 'OK dispatch enforcement backfill dry-run/apply\n'
