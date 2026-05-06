#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/two-blocker-ticks-escalator.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/two-blocker-close-shapes.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail() { printf 'FAIL %s\n' "$1" >&2; exit 1; }
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }

repo() {
  local d="$TMP/$1"
  mkdir -p "$d/.flywheel" "$d/.beads"
  : >"$d/.flywheel/dispatch-log.jsonl"
  : >"$d/.beads/issues.jsonl"
  printf '%s\n' "$d"
}

append_row() {
  local path="$1" row="$2"
  printf '%s\n' "$row" >>"$path"
}

dispatch_row() {
  local repo="$1" task="$2" expected="$3" from="${4:-flywheel:1}" to="${5:-flywheel:3-codex}"
  jq -nc --arg task "$task" --arg expected "$expected" --arg from "$from" --arg to "$to" \
    '{task_id:$task,ts:"2026-05-06T11:35:00Z",from:$from,to:$to,pane:3,session:"flywheel",task_summary:"close-row-shape fixture",agent_type:"codex",callback_expected_by:$expected,callback_received_at:null}' >>"$repo/.flywheel/dispatch-log.jsonl"
}

run_probe() {
  local label="$1" repo="$2" now="$3"; shift 3
  TWO_BLOCKER_TICKS_STATE="$TMP/$label-state.json" \
  TWO_BLOCKER_TICKS_LEDGER="$TMP/$label-ledger.jsonl" \
  TWO_BLOCKER_TICKS_COORDINATION_LOG="$TMP/$label-coord.jsonl" \
  TWO_BLOCKER_TICKS_NOW="$now" \
    "$SCRIPT" check --repo "$repo" --json "$@" >"$TMP/$label.json"
}

run_probe_shared() {
  local label="$1" repo="$2" now="$3" state="$4" ledger="$5" coord="$6"; shift 6
  TWO_BLOCKER_TICKS_STATE="$state" \
  TWO_BLOCKER_TICKS_LEDGER="$ledger" \
  TWO_BLOCKER_TICKS_COORDINATION_LOG="$coord" \
  TWO_BLOCKER_TICKS_NOW="$now" \
    "$SCRIPT" check --repo "$repo" --json "$@" >"$TMP/$label.json"
}

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    jq . "$file" >&2 || true
    fail "$label"
  fi
}

r="$(repo worker_self_close)"
dispatch_row "$r" "worker-self-close-2026-05-06" "2026-05-06T12:00:00Z"
append_row "$r/.beads/issues.jsonl" '{"event":"close","ref_id":"flywheel-worker-self-close-f57a","status":"closed","ts":"2026-05-06T12:05:00Z","closed_by":"MagentaPond","close_reason":"worker self close row fixture"}'
run_probe worker_self_close "$r" "2026-05-06T13:10:00Z" --auto-escalate
assert_jq "$TMP/worker_self_close.json" '.signal == "GREEN" and .blocked_count == 0 and (.auto_escalations_filed | length) == 0 and .closed_via_issues[0].closed_issue_id == "flywheel-worker-self-close-f57a"' "worker_self_close_event_ref_id_no_fire"

r="$(repo orch_on_behalf_cloudymill)"
append_row "$r/.flywheel/dispatch-log.jsonl" '{"task_id":"wire-calling-in-sick-policy-2026-05-06","ts":"2026-05-06T11:35:00Z","from":"flywheel:1","to":"flywheel:2-codex","pane":2,"session":"flywheel","task_summary":"Wave 3a P0 wire: calling-in-sick-policy advisory hook (last unstarted Wave 3a P0)","task_file":"/tmp/dispatch_wire-calling-in-sick-policy.md","agent_type":"codex","pane_state_source":"robot_activity","pane_state":"WAITING","capture_provenance":"live","l61_callback_fields_required":false,"callback_expected_by":"2026-05-06T12:20:00Z","callback_received_at":null}'
append_row "$r/.beads/issues.jsonl" '{"event":"close","ref_id":"flywheel-wire-calling-in-sick-policy-flywheel-ow-a04ca90e","status":"closed","ts":"2026-05-06T11:48:00Z","closed_by":"flywheel-orch-on-behalf-of-CloudyMill","close_reason":"DONE callback received as BLOCKED on shared_append_reservation_conflict; orch executed canonical scoped-commit-by-pathspec recipe per feedback_canonical_recipe_scoped_commit_by_pathspec.md to land final 2 append-only deliverables (INCIDENTS entry + this JSONL closure). Worker delivered: hook 64L, test 79L 8/8 pass, settings.json wired. Last unstarted Wave 3a P0; sweep COMPLETE.","worker_self_grade":"Y","wave":"3a","leverage_class":"#4_self_organization","sibling_shape_count":7,"escalation_ladder":"detector->flywheel:1->peer_mesh->joshua"}'
run_probe orch_on_behalf_cloudymill "$r" "2026-05-06T13:10:00Z" --auto-escalate
assert_jq "$TMP/orch_on_behalf_cloudymill.json" '.signal == "GREEN" and .blocked_count == 0 and (.auto_escalations_filed | length) == 0 and .closed_via_issues[0].closed_issue_id == "flywheel-wire-calling-in-sick-policy-flywheel-ow-a04ca90e"' "cloudymill_orch_on_behalf_actual_row_no_fire"

r="$(repo alps_cross_orch)"
dispatch_row "$r" "alps-cross-orch-capacity-halt-2026-05-06" "2026-05-06T12:00:00Z" "alps:1" "flywheel:3-codex"
append_row "$r/.beads/issues.jsonl" '{"event":"close","ref_id":"flywheel-alps-cross-orch-capacity-halt-a1b2","status":"closed","ts":"2026-05-06T12:08:00Z","closed_by":"flywheel-orch-on-behalf-of-BlueCanyon","close_reason":"synthetic alps:1 cross-orch close row because local issues.jsonl has no alps-specific close row; shape matches live orch-on-behalf rows"}'
run_probe alps_cross_orch "$r" "2026-05-06T13:10:00Z" --auto-escalate
assert_jq "$TMP/alps_cross_orch.json" '.signal == "GREEN" and .blocked_count == 0 and (.auto_escalations_filed | length) == 0 and .closed_via_issues[0].closed_issue_id == "flywheel-alps-cross-orch-capacity-halt-a1b2"' "alps_cross_orch_shape_no_fire"

r="$(repo false_positive_autoclose)"
dispatch_row "$r" "flywheel-escalate-8eaf3683-2026-05-06" "2026-05-06T12:50:00Z"
dispatch_row "$r" "flywheel-escalate-8b336af1-2026-05-06" "2026-05-06T12:50:00Z"
append_row "$r/.beads/issues.jsonl" '{"event":"close","ref_id":"flywheel-escalate-8eaf3683","status":"closed","ts":"2026-05-06T13:04:00Z","closed_by":"flywheel-orch","close_reason":"FALSE-POSITIVE: parent bead flywheel-wire-calling-in-sick-policy-flywheel-ow-a04ca90e was closed at 11:48Z (orch-on-behalf-of-CloudyMill, 4/6 worker + scoped-commit-by-pathspec). two-blocker-ticks-escalator fired at 12:43Z claiming 2 consecutive ticks of blocker, but work was already shipped 55min before escalation. Same regression class as feedback_two_blocker_ticks_jsonl_fallback_aware: escalator missed JSONL fallback close row. Filing escalator-regression-class fuckup row.","auto_close_reason":"escalation_target_already_closed_via_jsonl_fallback","escalator_regression_class":"two-blocker-ticks-jsonl-fallback-blind-2"}'
append_row "$r/.beads/issues.jsonl" '{"event":"close","ref_id":"flywheel-escalate-8b336af1","status":"closed","ts":"2026-05-06T13:04:00Z","closed_by":"flywheel-orch","close_reason":"FALSE-POSITIVE: parent bead flywheel-wire-flywheel-owns-orch-pane-recovery-1f097583 was closed at 11:31Z (pane 4, 69L hook + 7/7 tests). two-blocker-ticks-escalator fired at 12:43Z claiming 2 consecutive ticks of blocker, but work was already shipped 1h12min before escalation. Same regression class as feedback_two_blocker_ticks_jsonl_fallback_aware: escalator missed JSONL fallback close row.","auto_close_reason":"escalation_target_already_closed_via_jsonl_fallback","escalator_regression_class":"two-blocker-ticks-jsonl-fallback-blind-2"}'
run_probe false_positive_autoclose "$r" "2026-05-06T13:10:00Z" --auto-escalate
assert_jq "$TMP/false_positive_autoclose.json" '.signal == "GREEN" and .blocked_count == 0 and (.auto_escalations_filed | length) == 0 and (.closed_via_issues | length) == 2' "false_positive_autoclose_rows_no_fire"

r="$(repo genuinely_stuck)"
dispatch_row "$r" "still-stuck-blocker-2026-05-06" "2026-05-06T12:00:00Z"
state="$TMP/genuinely-stuck-state.json"; ledger="$TMP/genuinely-stuck-ledger.jsonl"; coord="$TMP/genuinely-stuck-coord.jsonl"
run_probe_shared genuinely_stuck_1 "$r" "2026-05-06T13:10:00Z" "$state" "$ledger" "$coord"
run_probe_shared genuinely_stuck_2 "$r" "2026-05-06T13:15:00Z" "$state" "$ledger" "$coord" --auto-escalate
assert_jq "$TMP/genuinely_stuck_2.json" '.signal == "RED" and .blocked_count == 1 and .blocked_beads[0].consecutive_tick_count == 2 and (.auto_escalations_filed | length) == 1' "genuinely_stuck_second_tick_fires"

r="$(repo reopen_close)"
dispatch_row "$r" "resurrected-close-2026-05-06" "2026-05-06T12:00:00Z"
append_row "$r/.beads/issues.jsonl" '{"event":"close","ref_id":"flywheel-resurrected-close-abc123","status":"closed","ts":"2026-05-06T11:50:00Z","closed_by":"worker-self","close_reason":"first close"}'
append_row "$r/.beads/issues.jsonl" '{"event":"reopen","ref_id":"flywheel-resurrected-close-abc123","status":"open","ts":"2026-05-06T12:05:00Z","closed_by":"flywheel-orch","close_reason":"reopened for follow-up"}'
state="$TMP/reopen-close-state.json"; ledger="$TMP/reopen-close-ledger.jsonl"; coord="$TMP/reopen-close-coord.jsonl"
run_probe_shared reopen_close_open "$r" "2026-05-06T13:10:00Z" "$state" "$ledger" "$coord"
append_row "$r/.beads/issues.jsonl" '{"event":"close","ref_id":"flywheel-resurrected-close-abc123","status":"closed","ts":"2026-05-06T12:40:00Z","closed_by":"flywheel-orch","close_reason":"final close after reopen"}'
run_probe_shared reopen_close_final "$r" "2026-05-06T13:15:00Z" "$state" "$ledger" "$coord" --auto-escalate
assert_jq "$TMP/reopen_close_open.json" '.signal == "YELLOW" and .blocked_count == 1' "reopen_row_keeps_blocker_live"
assert_jq "$TMP/reopen_close_final.json" '.signal == "GREEN" and .blocked_count == 0 and (.auto_escalations_filed | length) == 0 and .closed_via_issues[0].closed_issue_id == "flywheel-resurrected-close-abc123"' "latest_close_after_reopen_no_fire"

printf 'PASS cases=6 assertions=%s failures=0\n' "$pass_count"
