#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="$ROOT/.flywheel/scripts/dispatch-log-schema-validator.sh"
CHECKER="$HOME/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh"

case "${1:-}" in
  doctor|health|completion)
    if [[ "${2:-}" == "--help" || "${2:-}" == "-h" ]]; then
      printf 'usage: %s [doctor|health|completion --help] [--help]\n' "$(basename "$0")"
      exit 0
    fi
    ;;
  --help|-h|--info|--examples|quickstart|help)
    printf 'usage: %s\n' "$(basename "$0")"
    exit 0
    ;;
esac

TMP="$(mktemp -d "${TMPDIR:-/tmp}/dispatch-log-schema-v2-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
REPO="$TMP/repo"
mkdir -p "$REPO/.flywheel/validation-schema/v1"
cp "$ROOT/.flywheel/validation-schema/v1/dispatch-log-entry-v2.schema.json" "$REPO/.flywheel/validation-schema/v1/"

cat >"$REPO/.flywheel/dispatch-log.jsonl" <<'JSONL'
{"task_id":"valid-v2","ts":"2026-05-07T00:00:00Z","from":"flywheel:1","to":"flywheel-pane-2","pane":2,"session":"flywheel","task_summary":"valid v2","task_file":"/tmp/valid-v2.md","agent_type":"codex","pane_state_source":"ntm_health","mission_anchor":"continuous-orchestrator-uptime-self-sustaining-fleet","mission_fitness_claim":"Directly enforces the mission anchor at dispatch time.","mission_fitness_class":"direct","idempotency_token":"valid-v2","callback_received_at":null,"topology_resolved_pane":2,"topology_role":"worker","topology_row_effective_at":"2026-05-07T00:00:00Z"}
{"task_id":"valid-v2-callback","ts":"2026-05-07T00:01:00Z","from":"flywheel:1","to":"flywheel-pane-3","pane":3,"session":"flywheel","task_summary":"valid callback","task_file":"/tmp/valid-v2-callback.md","agent_type":"claude","pane_state_source":"ntm_health","mission_anchor":"continuous-orchestrator-uptime-self-sustaining-fleet","mission_fitness_claim":"Directly verifies callback metadata carries through closeout.","mission_fitness_class":"direct","idempotency_token":"valid-v2-callback","callback_received_at":"2026-05-07T00:02:00Z","mission_fitness":"direct","mission_fitness_evidence":"fixture","bead_closed":"yes","validated":"yes"}
{"task_id":"missing-claim","ts":"2026-05-07T00:03:00Z","from":"flywheel:1","to":"flywheel-pane-4","pane":4,"session":"flywheel","task_summary":"missing claim","task_file":"/tmp/missing-claim.md","agent_type":"codex","pane_state_source":"ntm_health","mission_anchor":"continuous-orchestrator-uptime-self-sustaining-fleet","mission_fitness_class":"direct","idempotency_token":"missing-claim","callback_received_at":null}
{"task_id":"drift-class","ts":"2026-05-07T00:04:00Z","from":"flywheel:1","to":"flywheel-pane-4","pane":4,"session":"flywheel","task_summary":"drift class","task_file":"/tmp/drift-class.md","agent_type":"codex","pane_state_source":"ntm_health","mission_anchor":"continuous-orchestrator-uptime-self-sustaining-fleet","mission_fitness_claim":"This fixture intentionally classifies drift for audit counting.","mission_fitness_class":"drift","idempotency_token":"drift-class","callback_received_at":null}
{"task_id":"infrastructure-recursion","ts":"2026-05-07T00:05:00Z","from":"flywheel:1","to":"flywheel-pane-2","pane":2,"session":"flywheel","task_summary":"infra recursion","task_file":"/tmp/infra-recursion.md","agent_type":"other","pane_state_source":"ntm_health","mission_anchor":"continuous-orchestrator-uptime-self-sustaining-fleet","mission_fitness_claim":"Infrastructure work hardens the dispatch substrate without becoming drift.","mission_fitness_class":"infrastructure","idempotency_token":"infrastructure-recursion","callback_received_at":null,"backfilled":false}
{malformed-json
JSONL

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null 2>&1; then pass "$label"; else fail "$label"; jq . "$file" >&2 2>/dev/null || true; fi
}

OUT="$TMP/summary.json"
bash "$BIN" --repo "$REPO" --json >"$OUT"
assert_jq "$OUT" '.total == 6' "summary/total_six_rows"
assert_jq "$OUT" '.valid == 4' "summary/four_valid_v2_rows"
assert_jq "$OUT" '.missing_fitness_claim == 1' "summary/missing_claim_count"
assert_jq "$OUT" '.drift_count == 1' "summary/drift_count"
assert_jq "$OUT" '.by_class.infrastructure == 1' "summary/infrastructure_class_count"
assert_jq "$OUT" '.malformed_count == 1' "summary/malformed_count"

EXPLAIN="$TMP/explain.txt"
bash "$BIN" --repo "$REPO" --explain >"$EXPLAIN"
grep -q 'row=3 .*missing_mission_fitness_claim' "$EXPLAIN" && pass "explain/missing_claim_row" || fail "explain/missing_claim_row"
grep -q 'row=6 .*malformed_json' "$EXPLAIN" && pass "explain/malformed_row" || fail "explain/malformed_row"

bash "$BIN" --repo "$REPO" --apply --json >/dev/null
[[ "$(wc -l <"$REPO/.flywheel/dispatch-log-validation.jsonl" | tr -d ' ')" == "6" ]] && pass "apply/sidecar_six_rows" || fail "apply/sidecar_six_rows"

bash "$BIN" --schema | jq -e '.properties.mission_anchor.const == "continuous-orchestrator-uptime-self-sustaining-fleet"' >/dev/null \
  && pass "schema/mission_anchor_const" || fail "schema/mission_anchor_const"

bash "$BIN" --schema | jq -e '.properties.topology_resolved_pane and .properties.topology_role and .properties.topology_row_effective_at' >/dev/null \
  && pass "schema/topology_fields" || fail "schema/topology_fields"

bash "$BIN" --schema | jq -e '.required | index("pane_state_source")' >/dev/null \
  && bash "$BIN" --schema | jq -e '.properties.pane_state_source.enum == ["ntm_health","ntm_copy","raw_capture","none"]' >/dev/null \
  && pass "schema/pane_state_source" || fail "schema/pane_state_source"

sed -n '1p' "$REPO/.flywheel/dispatch-log.jsonl" \
  | jq -e '.topology_resolved_pane == 2 and .topology_role == "worker" and .topology_row_effective_at == "2026-05-07T00:00:00Z" and .pane_state_source == "ntm_health"' >/dev/null \
  && pass "fixture/topology_and_pane_state_fields" || fail "fixture/topology_and_pane_state_fields"

bash "$CHECKER" "$BIN" >/dev/null && pass "canonical_cli_scoping/validator" || fail "canonical_cli_scoping/validator"

printf '\nResults: %d PASS  %d FAIL\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]] || exit 1
