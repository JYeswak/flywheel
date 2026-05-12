#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
  -h|--help) printf 'usage: test_dispatch_log_carries_mission_fitness.sh\n'; exit 0 ;;
  doctor|health)
    [[ "${2:-}" == "--help" || "${2:-}" == "-h" ]] && { printf 'usage: test_dispatch_log_carries_mission_fitness.sh %s --help\n' "$1"; exit 0; }
    ;;
  completion)
    [[ "${2:-}" == "--help" || "${2:-}" == "-h" || -z "${2:-}" ]] && { printf 'usage: test_dispatch_log_carries_mission_fitness.sh completion <bash|zsh>\n'; exit 0; }
    ;;
esac

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/mission-fitness-callback-validator.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/dispatch-log-mission-fitness.XXXXXX")"
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

mkdir -p "$TMP/repo/.flywheel"
dispatch_log="$TMP/repo/.flywheel/dispatch-log.jsonl"
validation_log="$TMP/repo/.flywheel/callback-validation-log.jsonl"
cat >"$dispatch_log" <<'JSONL'
{"task_id":"round-trip-1","ts":"2026-05-07T00:00:00Z","task_summary":"fixture dispatch","callback_received_at":null}
{"task_id":"other-task","ts":"2026-05-07T00:01:00Z","task_summary":"untouched","callback_received_at":null}
JSONL

bash -n "$SCRIPT" && pass "script_syntax" || fail "script_syntax"

callback="DONE task_id=round-trip-1 mission_fitness=direct mission_fitness_evidence=enforces_mission_anchor_on_every_callback"
"$SCRIPT" \
  --repo "$TMP/repo" \
  --callback "$callback" \
  --dispatch-log "$dispatch_log" \
  --log "$validation_log" \
  --apply \
  --json >"$TMP/out.json"

assert_jq "$TMP/out.json" '.decision == "accept" and .dispatch_log_updated == 1 and .log_written == true' "validator_accepts_and_updates_one_row"
assert_jq "$dispatch_log" 'select(.task_id == "round-trip-1" and .mission_fitness == "direct" and .mission_fitness_evidence == "enforces_mission_anchor_on_every_callback" and .mission_fitness_evidence_class == "sentence" and .mission_fitness_validator_decision == "accept")' "dispatch_log_row_carries_mission_fitness"
assert_jq "$dispatch_log" 'select(.task_id == "other-task" and has("mission_fitness") | not)' "nonmatching_row_untouched"
assert_jq "$validation_log" 'select(.task_id == "round-trip-1" and .decision == "accept")' "validation_log_receipt_written"

printf 'OK_dispatch_log_carries_mission_fitness\n'
printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 && "$pass_count" -ge 5 ]]
