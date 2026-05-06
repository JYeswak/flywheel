#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/recovery-doctor-probe.sh"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/recovery-ledger.schema.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/recovery-doctor-probe.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
NOW="2026-05-06T13:00:00Z"
OLD="2026-05-05T12:00:00Z"

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" || true
  fi
}

run_probe() {
  local ledger="$1" out="$2" err="${3:-$TMP/probe.err}"
  RECOVERY_DOCTOR_NOW="$NOW" "$SCRIPT" --ledger "$ledger" --json >"$out" 2>"$err"
}

row() {
  local ts="$1" pane="$2" trauma="$3" verdict="$4" rc="$5" authorized="$6" failure="${7:-null}"
  jq -nc --arg ts "$ts" --arg trauma "$trauma" --arg verdict "$verdict" \
    --argjson pane "$pane" --argjson rc "$rc" --argjson authorized "$authorized" \
    --argjson failure "$failure" '{
      ts:$ts,actor:"watchdog",target_session:"fixture",target_pane:$pane,
      pane_role:"worker_pane",trauma_class:$trauma,signal_text:"fixture signal",
      decision_reason:"fixture decision",
      budget_state:{per_pane_count_window:0,fleet_count_window:0,authorized:$authorized},
      transport:{rc:$rc,duration_ms:12,send_command:"fixture"},
      post_check:{verdict:$verdict,evidence:"fixture evidence"},
      failure_class:$failure,primitive_invoked:"fixture-primitive.sh"
    }'
}

bash -n "$SCRIPT" && pass "script_syntax" || fail "script_syntax"
jq empty "$SCHEMA" && pass "schema_json_parses" || fail "schema_json_parses"
python3 - "$SCHEMA" <<'PY' && pass "schema_check_schema" || fail "schema_check_schema"
import json, sys
from jsonschema import Draft7Validator
with open(sys.argv[1], encoding="utf-8") as handle:
    Draft7Validator.check_schema(json.load(handle))
PY
"$SCRIPT" --info >"$TMP/info.out" && pass "info_exits" || fail "info_exits"
"$SCRIPT" --help >/dev/null && pass "help_exits" || fail "help_exits"
"$SCRIPT" --examples >/dev/null && pass "examples_exits" || fail "examples_exits"

empty="$TMP/empty.jsonl"; : >"$empty"
run_probe "$empty" "$TMP/empty.out"
assert_jq "$TMP/empty.out" '.recovery_count_24h==0 and .recovery_success_pct_24h==0 and .recovery_protected_refusals_24h==0 and .recovery_budget_exhausted_24h==0 and .recovery_transport_failure_pct_24h==0 and (.top_failing_panes_24h|length)==0' "empty_ledger_zeroes"

all_success="$TMP/all-success.jsonl"
for pane in 1 2 3 4 5; do row "$NOW" "$pane" model_at_capacity_halt success 0 true null >>"$all_success"; done
run_probe "$all_success" "$TMP/all-success.out"
assert_jq "$TMP/all-success.out" '.recovery_count_24h==5 and .recovery_success_pct_24h==100 and .recovery_attempted_24h_by_class.model_at_capacity_halt==5' "five_success_100pct"

mixed="$TMP/mixed.jsonl"
for pane in 1 2 3; do row "$NOW" "$pane" model_at_capacity_halt success 0 true null >>"$mixed"; done
row "$NOW" 4 model_at_capacity_halt failure 0 true '"post_check_failed"' >>"$mixed"
row "$NOW" 4 model_at_capacity_halt failure 1 true '"transport_failed"' >>"$mixed"
run_probe "$mixed" "$TMP/mixed.out"
assert_jq "$TMP/mixed.out" '.recovery_count_24h==5 and .recovery_success_pct_24h==60 and .recovery_transport_failure_pct_24h==20 and .top_failing_panes_24h[0].pane=="fixture:4" and .top_failing_panes_24h[0].failure_count==2' "three_success_two_failures"

protected="$TMP/protected.jsonl"
row "$NOW" 2 model_at_capacity_halt failure 0 false '"authorization_refused"' >>"$protected"
run_probe "$protected" "$TMP/protected.out"
assert_jq "$TMP/protected.out" '.recovery_protected_refusals_24h==1' "protected_refusal_counted"

budget="$TMP/budget.jsonl"
row "$NOW" 2 model_at_capacity_halt failure 0 false '"auto_continue_budget_exhausted"' >>"$budget"
run_probe "$budget" "$TMP/budget.out"
assert_jq "$TMP/budget.out" '.recovery_budget_exhausted_24h==1' "budget_exhausted_counted"

old_window="$TMP/old-window.jsonl"
row "$OLD" 2 model_at_capacity_halt success 0 true null >>"$old_window"
row "$NOW" 3 model_at_capacity_halt success 0 true null >>"$old_window"
run_probe "$old_window" "$TMP/old-window.out"
assert_jq "$TMP/old-window.out" '.recovery_count_24h==1 and .recovery_attempted_24h_by_class.model_at_capacity_halt==1' "old_rows_excluded"

malformed="$TMP/malformed.jsonl"
printf '{not-json}\n' >"$malformed"
row "$NOW" 2 frozen_pane success 0 true null >>"$malformed"
run_probe "$malformed" "$TMP/malformed.out" "$TMP/malformed.err"
assert_jq "$TMP/malformed.out" '.recovery_count_24h==1 and .malformed_rows_skipped==1' "malformed_skipped"
grep -q 'WARN malformed_jsonl_line_1' "$TMP/malformed.err" && pass "malformed_warning" || fail "malformed_warning"

legacy="$TMP/legacy.jsonl"
jq -nc --arg ts "$NOW" '{ts:$ts,epoch:1778072400,action:"auto_continue_attempt",session:"fixture",pane:2,recovery_attempted:"auto_continue",attempted:true,sent:true,recovered:true,reason:"legacy success"}' >>"$legacy"
jq -nc --arg ts "$NOW" '{ts:$ts,epoch:1778072400,action:"auto_continue_budget_exhausted",session:"fixture",pane:3,recovery_attempted:"auto_continue",sent:false,recovered:false,budget_outcome:"fleet_exhausted",reason:"legacy budget"}' >>"$legacy"
run_probe "$legacy" "$TMP/legacy.out"
assert_jq "$TMP/legacy.out" '.recovery_count_24h==2 and .legacy_rows_counted_24h==2 and .recovery_success_pct_24h==50 and .recovery_attempted_24h_by_class.model_at_capacity_halt==2 and .recovery_budget_exhausted_24h==1' "mixed_old_schema_counted"

schema_fixture="$TMP/schema-fixture.jsonl"
row "$NOW" 2 model_at_capacity_halt success 0 true null >>"$schema_fixture"
row "$NOW" 3 codex_queued_not_submitted failure 1 true '"transport_failed"' >>"$schema_fixture"
python3 - "$SCHEMA" "$schema_fixture" <<'PY' && pass "schema_fixture_rows_validate" || fail "schema_fixture_rows_validate"
import json, sys
from jsonschema import Draft7Validator, FormatChecker
with open(sys.argv[1], encoding="utf-8") as handle:
    schema = json.load(handle)
validator = Draft7Validator(schema, format_checker=FormatChecker())
with open(sys.argv[2], encoding="utf-8") as handle:
    for line in handle:
        if line.strip():
            validator.validate(json.loads(line))
PY

printf 'Summary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
