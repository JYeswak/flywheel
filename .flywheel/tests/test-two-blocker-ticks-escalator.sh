#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/two-blocker-ticks-escalator.sh"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/two-blocker-ticks-decision.schema.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/two-blocker-ticks-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail() { printf 'FAIL %s\n' "$1" >&2; exit 1; }
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then pass "$label"; else jq . "$file" >&2 || true; fail "$label"; fi
}

repo() { local d="$TMP/$1"; mkdir -p "$d/.flywheel" "$d/.beads"; : >"$d/.flywheel/dispatch-log.jsonl"; : >"$d/.beads/issues.jsonl"; printf '%s\n' "$d"; }

dispatch_row() {
  local repo="$1" task="$2" expected="$3" received="${4:-null}"
  jq -nc --arg task "$task" --arg expected "$expected" --argjson received "$received" \
    '{ts:"2026-05-06T00:00:00Z",event:"dispatched",task_id:$task,bead_id:$task,callback_expected_by:$expected,callback_received_at:$received,to:"flywheel:4"}' >>"$repo/.flywheel/dispatch-log.jsonl"
}

callback_row() {
  local repo="$1" task="$2"
  jq -nc --arg task "$task" '{ts:"2026-05-06T00:10:00Z",event:"callback_received",task_id:$task,bead_id:$task,callback_received_at:"2026-05-06T00:10:00Z"}' >>"$repo/.flywheel/dispatch-log.jsonl"
}

closed_issue_row() {
  local repo="$1" id="$2" title="$3" task="${4:-}"
  if [[ -n "$task" ]]; then
    jq -nc --arg id "$id" --arg title "$title" --arg task "$task" \
      '{id:$id,title:$title,status:"closed",priority:0,created_at:"2026-05-06T00:10:00Z",updated_at:"2026-05-06T00:10:00Z",closed_at:"2026-05-06T00:10:00Z",original_blocker_task_id:$task}' >>"$repo/.beads/issues.jsonl"
  else
    jq -nc --arg id "$id" --arg title "$title" \
      '{id:$id,title:$title,status:"closed",priority:0,created_at:"2026-05-06T00:10:00Z",updated_at:"2026-05-06T00:10:00Z",closed_at:"2026-05-06T00:10:00Z"}' >>"$repo/.beads/issues.jsonl"
  fi
}

run_case() {
  local label="$1" repo="$2" now="$3"; shift 3
  TWO_BLOCKER_TICKS_STATE="$TMP/$label-state.json" \
  TWO_BLOCKER_TICKS_LEDGER="$TMP/$label-ledger.jsonl" \
  TWO_BLOCKER_TICKS_COORDINATION_LOG="$TMP/$label-coord.jsonl" \
  TWO_BLOCKER_TICKS_NOW="$now" \
    "$SCRIPT" check --repo "$repo" --json "$@" >"$TMP/$label.json"
}

run_case_shared() {
  local label="$1" repo="$2" now="$3" state="$4" ledger="$5" coord="$6"; shift 6
  TWO_BLOCKER_TICKS_STATE="$state" \
  TWO_BLOCKER_TICKS_LEDGER="$ledger" \
  TWO_BLOCKER_TICKS_COORDINATION_LOG="$coord" \
  TWO_BLOCKER_TICKS_NOW="$now" \
    "$SCRIPT" check --repo "$repo" --json "$@" >"$TMP/$label.json"
}

validate_payload() {
  python3 - "$SCHEMA" "$1" <<'PY'
import json, sys
from jsonschema import Draft202012Validator
schema = json.load(open(sys.argv[1], encoding="utf-8"))
payload = json.load(open(sys.argv[2], encoding="utf-8"))
Draft202012Validator.check_schema(schema)
Draft202012Validator(schema).validate(payload)
PY
}

bash -n "$SCRIPT" && pass "script_syntax"
"$SCRIPT" --help >/dev/null && pass "help_passes"
"$SCRIPT" --examples >/dev/null && pass "examples_passes"
jq empty "$SCHEMA" && pass "schema_json_parses"

r="$(repo green)"
run_case green "$r" "2026-05-06T00:20:00Z"
assert_jq "$TMP/green.json" '.signal == "GREEN" and .blocked_count == 0' "zero_blocked_green"
validate_payload "$TMP/green.json" && pass "green_schema_valid"

r="$(repo yellow)"; dispatch_row "$r" "flywheel-blocked-one" "2026-05-06T00:05:00Z"
run_case yellow "$r" "2026-05-06T00:20:00Z"
assert_jq "$TMP/yellow.json" '.signal == "YELLOW" and .blocked_beads[0].consecutive_tick_count == 1' "one_blocked_first_tick_yellow"

r="$(repo red)"; dispatch_row "$r" "flywheel-blocked-red" "2026-05-06T00:05:00Z"
state="$TMP/red-state.json"; ledger="$TMP/red-ledger.jsonl"; coord="$TMP/red-coord.jsonl"
red_coord="$coord"
run_case_shared red1 "$r" "2026-05-06T00:20:00Z" "$state" "$ledger" "$coord"
run_case_shared red2 "$r" "2026-05-06T00:25:00Z" "$state" "$ledger" "$coord" --auto-escalate
assert_jq "$TMP/red2.json" '.signal == "RED" and (.auto_escalations_filed | length) == 1' "second_tick_red_files_escalation"
grep -q '"kind":"blocker_escalation"' "$coord" && pass "fleet_mail_capsule_written" || fail "fleet_mail_capsule_written"

r="$(repo idempotent)"; dispatch_row "$r" "flywheel-idem" "2026-05-06T00:05:00Z"
jq -nc '{id:"flywheel-escalate-existing",title:"escalate-blocker-flywheel-idem-via-flywheel-plan",status:"open",priority:0,created_by:"two-blocker-ticks-escalator"}' >"$r/.beads/issues.jsonl"
state="$TMP/idem-state.json"; ledger="$TMP/idem-ledger.jsonl"; coord="$TMP/idem-coord.jsonl"
run_case_shared idem1 "$r" "2026-05-06T00:20:00Z" "$state" "$ledger" "$coord"
run_case_shared idem2 "$r" "2026-05-06T00:25:00Z" "$state" "$ledger" "$coord" --auto-escalate
run_case_shared idem3 "$r" "2026-05-06T00:30:00Z" "$state" "$ledger" "$coord" --auto-escalate
assert_jq "$TMP/idem2.json" '.auto_escalations[0].action == "reused" and (.auto_escalations_filed | length) == 0' "existing_open_escalation_reused"
[[ "$(grep -c 'escalate-blocker-flywheel-idem-via-flywheel-plan' "$r/.beads/issues.jsonl")" == "1" ]] && pass "no_duplicate_escalation_bead" || fail "no_duplicate_escalation_bead"
[[ "$(grep -c 'two-blocker-ticks:flywheel-idem' "$coord")" == "1" ]] && pass "no_duplicate_capsule" || fail "no_duplicate_capsule"

r="$(repo reset)"; dispatch_row "$r" "flywheel-reset" "2026-05-06T00:05:00Z"
state="$TMP/reset-state.json"; ledger="$TMP/reset-ledger.jsonl"; coord="$TMP/reset-coord.jsonl"
run_case_shared reset1 "$r" "2026-05-06T00:20:00Z" "$state" "$ledger" "$coord"
callback_row "$r" "flywheel-reset"
run_case_shared reset2 "$r" "2026-05-06T00:25:00Z" "$state" "$ledger" "$coord"
assert_jq "$TMP/reset2.json" '.signal == "GREEN" and .blocked_count == 0' "callback_resets_state"

r="$(repo jsonlclose)"; dispatch_row "$r" "flywheel-jsonl-close-2026-05-06" "2026-05-06T00:05:00Z"
state="$TMP/jsonlclose-state.json"; ledger="$TMP/jsonlclose-ledger.jsonl"; coord="$TMP/jsonlclose-coord.jsonl"
run_case_shared jsonlclose1 "$r" "2026-05-06T00:20:00Z" "$state" "$ledger" "$coord"
closed_issue_row "$r" "flywheel-jsonl-close" "flywheel-jsonl-close"
run_case_shared jsonlclose2 "$r" "2026-05-06T00:25:00Z" "$state" "$ledger" "$coord"
assert_jq "$TMP/jsonlclose2.json" '.signal == "GREEN" and .blocked_count == 0 and .closed_via_issues[0].closed_issue_id == "flywheel-jsonl-close"' "jsonl_fallback_close_resets_state"
jq -e '. == {}' "$state" >/dev/null && pass "jsonl_fallback_state_cleared" || fail "jsonl_fallback_state_cleared"

r="$(repo mixed)"; dispatch_row "$r" "flywheel-mixed-callback" "2026-05-06T00:05:00Z"; dispatch_row "$r" "flywheel-mixed-jsonl-2026-05-06" "2026-05-06T00:05:00Z"
callback_row "$r" "flywheel-mixed-callback"
closed_issue_row "$r" "flywheel-escalate-mixed" "escalate-blocker-flywheel-mixed-jsonl-2026-05-06-via-flywheel-plan" "flywheel-mixed-jsonl-2026-05-06"
run_case mixed "$r" "2026-05-06T00:25:00Z"
assert_jq "$TMP/mixed.json" '.signal == "GREEN" and .blocked_count == 0 and (.closed_via_issues | length) == 1' "mixed_callback_and_jsonl_closes_green"

r="$(repo noauto)"; dispatch_row "$r" "flywheel-noauto" "2026-05-06T00:05:00Z"
state="$TMP/noauto-state.json"; ledger="$TMP/noauto-ledger.jsonl"; coord="$TMP/noauto-coord.jsonl"
run_case_shared noauto1 "$r" "2026-05-06T00:20:00Z" "$state" "$ledger" "$coord"
run_case_shared noauto2 "$r" "2026-05-06T00:25:00Z" "$state" "$ledger" "$coord"
assert_jq "$TMP/noauto2.json" '.signal == "RED" and (.auto_escalations_filed | length) == 0 and (.capsules_dispatched | length) == 0' "auto_escalate_flag_respected"

r="$(repo threshold)"; dispatch_row "$r" "flywheel-threshold" "2026-05-06T00:05:00Z"
state="$TMP/threshold-state.json"; ledger="$TMP/threshold-ledger.jsonl"; coord="$TMP/threshold-coord.jsonl"
run_case_shared threshold1 "$r" "2026-05-06T00:20:00Z" "$state" "$ledger" "$coord" --threshold 3
run_case_shared threshold2 "$r" "2026-05-06T00:25:00Z" "$state" "$ledger" "$coord" --threshold 3
assert_jq "$TMP/threshold2.json" '.threshold == 3 and .signal == "YELLOW"' "threshold_configurable"

r="$(repo atomic)"; dispatch_row "$r" "flywheel-atomic" "2026-05-06T00:05:00Z"
state="$TMP/atomic-state.json"; ledger="$TMP/atomic-ledger.jsonl"; coord="$TMP/atomic-coord.jsonl"
run_case_shared atomic1 "$r" "2026-05-06T00:20:00Z" "$state" "$ledger" "$coord"
jq -e . "$state" >/dev/null && pass "state_file_json_valid"
if find "$(dirname "$state")" -name ".two-blocker-ticks-state.json.*.tmp" -print -quit | grep -q .; then fail "state_tmp_leftover"; else pass "state_atomic_no_tmp_leftover"; fi

[[ "$(wc -l <"$ledger" | tr -d ' ')" == "1" ]] && pass "ledger_row_each_invocation" || fail "ledger_row_each_invocation"
assert_jq "$red_coord" '.kind == "blocker_escalation" and .target == "flywheel-orch" and .blocker_type == "flywheel_class" and .requested_owner == "flywheel:1"' "capsule_schema_matches_cross_orch"

printf 'PASS cases=13 assertions=%s failures=0\n' "$pass_count"
