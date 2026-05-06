#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/recovery-escape-then-reprompt.sh"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/recovery-receipt.schema.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/recovery-escape-then-reprompt.XXXXXX")"
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
  local scenario="$1" out="$2"
  RECOVERY_MOCK_SCENARIO="$scenario" \
  RECOVERY_RECEIPT_DIR="$TMP/receipts" \
  RECOVERY_LEDGER="$TMP/ledger.jsonl" \
  RECOVERY_FUCKUP_LOG="$TMP/fuckup.jsonl" \
    "$SCRIPT" --session flywheel --pane 2 --dry-run --json >"$out"
}

bash -n "$SCRIPT" && pass "script_syntax" || fail "script_syntax"
jq -e '.["$schema"] == "https://json-schema.org/draft/2020-12/schema" and .properties.schema_version.const == "recovery-receipt.v1"' "$SCHEMA" >/dev/null \
  && pass "schema_declares_json_schema_2020_12" || fail "schema_declares_json_schema_2020_12"

"$SCRIPT" --schema | jq -e '.title == "Flywheel Recovery Receipt" and .properties.stage_succeeded' >/dev/null \
  && pass "schema_command_returns_schema" || fail "schema_command_returns_schema"

run_case stage1_success "$TMP/stage1.json"
assert_jq "$TMP/stage1.json" '.stage_succeeded == 1 and .recovery_succeeded == true and .dry_run == true and .retries_per_stage.stage1_escape == 1' "stage1_success_path"

run_case stage2_success "$TMP/stage2.json"
assert_jq "$TMP/stage2.json" '.stage_succeeded == 2 and .recovery_succeeded == true and .dry_run == true and .retries_per_stage.stage1_escape == 2 and .retries_per_stage.stage2_reprompt == 1' "stage1_fail_stage2_success_path"

run_case stage3 "$TMP/stage3.json"
assert_jq "$TMP/stage3.json" '.stage_succeeded == 3 and .recovery_succeeded == false and .escalate_to_respawn == true and .dry_run == true' "stage1_stage2_fail_escalates"

for receipt in "$TMP/stage1.json" "$TMP/stage2.json" "$TMP/stage3.json"; do
  assert_jq "$receipt" '.schema_version == "recovery-receipt.v1" and (.stage_succeeded == 1 or .stage_succeeded == 2 or .stage_succeeded == 3 or .stage_succeeded == "none") and (.retries_per_stage | has("stage1_escape") and has("stage2_reprompt")) and (.planned_actions | type == "array") and (.actual_actions | type == "array")' "receipt_shape_$(basename "$receipt" .json)"
done

if [[ ! -e "$TMP/ledger.jsonl" && ! -e "$TMP/fuckup.jsonl" ]]; then
  pass "dry_run_writes_no_state"
else
  fail "dry_run_writes_no_state"
fi

printf 'Summary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
