#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
  -h|--help) printf 'usage: test_mission_fitness_callback_validator.sh\n'; exit 0 ;;
  doctor|health)
    [[ "${2:-}" == "--help" || "${2:-}" == "-h" ]] && { printf 'usage: test_mission_fitness_callback_validator.sh %s --help\n' "$1"; exit 0; }
    ;;
  completion)
    [[ "${2:-}" == "--help" || "${2:-}" == "-h" || -z "${2:-}" ]] && { printf 'usage: test_mission_fitness_callback_validator.sh completion <bash|zsh>\n'; exit 0; }
    ;;
esac

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/mission-fitness-callback-validator.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/mission-fitness-callback-validator.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

run_case() {
  local name="$1" callback="$2" expected_rc="$3" filter="$4"
  local out="$TMP/$name.json" err="$TMP/$name.err" rc=0
  set +e
  "$SCRIPT" \
    --repo "$TMP/repo" \
    --callback "$callback" \
    --log "$TMP/validation-log.jsonl" \
    --dispatch-log "$TMP/dispatch-log.jsonl" \
    --alert-log "$TMP/alerts.jsonl" \
    --apply \
    --json >"$out" 2>"$err"
  rc=$?
  set -e
  if [[ "$rc" == "$expected_rc" ]]; then
    pass "$name/exit_code"
  else
    fail "$name/exit_code rc=$rc expected=$expected_rc"
  fi
  assert_jq "$out" "$filter" "$name/decision_json"
}

mkdir -p "$TMP/repo/.flywheel"
cat >"$TMP/dispatch-log.jsonl" <<'JSONL'
{"task_id":"t-direct","callback_received_at":null}
{"task_id":"t-adjacent","callback_received_at":null}
{"task_id":"t-infra","callback_received_at":null}
{"task_id":"t-drift","callback_received_at":null}
{"task_id":"t-missing","callback_received_at":null}
{"task_id":"t-recursion","callback_received_at":null}
JSONL
: >"$TMP/validation-log.jsonl"

bash -n "$SCRIPT" && pass "script_syntax" || fail "script_syntax"

run_case "valid_direct" \
  "DONE task_id=t-direct mission_fitness=direct mission_fitness_evidence=flywheel-direct" \
  0 \
  '.decision == "accept" and .mission_fitness == "direct" and .evidence_class == "bead_id" and .log_written == true and .dispatch_log_updated == 1'

run_case "valid_adjacent" \
  "DONE task_id=t-adjacent mission_fitness=adjacent mission_fitness_evidence=adjacent_supporting_validator" \
  0 \
  '.decision == "accept" and .mission_fitness == "adjacent" and .evidence_class == "sentence"'
if [[ ! -s "$TMP/valid_adjacent.err" ]]; then
  pass "valid_adjacent/stderr_clean"
else
  fail "valid_adjacent/stderr_clean"
  cat "$TMP/valid_adjacent.err" >&2 || true
fi

run_case "valid_infrastructure" \
  "DONE task_id=t-infra mission_fitness=infrastructure mission_fitness_evidence=/tmp/infra-evidence.md" \
  0 \
  '.decision == "accept" and .mission_fitness == "infrastructure" and .evidence_class == "artifact"'

run_case "valid_drift_rejected" \
  "DONE task_id=t-drift mission_fitness=drift mission_fitness_evidence=off_mission_close" \
  3 \
  '.decision == "reject_drift" and .drift_alert_written == true'
assert_jq "$TMP/alerts.jsonl" '.task_id == "t-drift" and .mission_fitness == "drift"' "drift_alert_jsonl_written"

run_case "missing_field_rejected" \
  "DONE task_id=t-missing mission_fitness=direct" \
  2 \
  '.decision == "reject_malformed" and (.missing_fields | index("mission_fitness_evidence"))'

for n in 1 2 3 4 5; do
  jq -nc --arg id "seed-$n" '{schema_version:"mission-fitness-callback-decision.v1",task_id:$id,mission_fitness:"infrastructure",decision:"accept"}' >>"$TMP/validation-log.jsonl"
done
run_case "infra_recursion_warn" \
  "DONE task_id=t-recursion mission_fitness=infrastructure mission_fitness_evidence=recursion_guard" \
  1 \
  '.decision == "warn_infra_recursion" and .mission_fitness == "infrastructure"'

assert_jq "$TMP/dispatch-log.jsonl" 'select(.task_id == "t-direct" and .mission_fitness == "direct" and .mission_fitness_evidence == "flywheel-direct")' "dispatch_log_updated_with_direct"

printf 'OK_mission_fitness_callback_validator\n'
printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 && "$pass_count" -ge 14 ]]
