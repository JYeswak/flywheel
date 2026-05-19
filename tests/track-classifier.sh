#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/track-classifier.sh"
DISPATCH_MD="${DISPATCH_MD:-$HOME/.claude/commands/flywheel/dispatch.md}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/track-classifier.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

assert_class() {
  local label="$1" expected="$2" surface="$3" out
  out="$(bash "$SCRIPT" classify --surface "$surface" --json)"
  if jq -e --arg expected "$expected" '.classification == $expected' <<<"$out" >/dev/null; then
    pass "$label"
  else
    fail "$label expected=$expected got=$(jq -r '.classification' <<<"$out")"
    printf '%s\n' "$out" >&2
  fi
}

assert_grep() {
  local pattern="$1" file="$2" label="$3"
  if rg -q -- "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label"
  fi
}

bash -n "$SCRIPT" && pass "script_syntax" || fail "script_syntax"
bash "$SCRIPT" --info | jq -e '.trauma_class == "cross_track_dispatch_collision"' >/dev/null \
  && pass "info_names_trauma_class" || fail "info_names_trauma_class"

assert_class "classify_track1_mission" "track1" ".flywheel/MISSION.md update mission strategy"
assert_class "classify_track2_legal" "track2" "Review legal agreement and DPA"
assert_class "classify_track3_substrate" "track3" ".flywheel/scripts/dispatch-gate.sh validator fixture"
assert_class "classify_track3_with_loop_contract_boilerplate" "track3" "LOOP CONTRACT: Track 3 only. Track 1 mission and Track 2 legal refuse. Add .flywheel/scripts/x.sh"
assert_class "classify_cross_orch_relay" "cross_orch_relay" "ntm send skillos --pane=1 handoff"
assert_class "classify_unknown" "unknown" "summarize customer feedback tone"

mission_file="$TMP/mission-task.md"
printf 'Edit .flywheel/GOAL.md locked goal text\n' >"$mission_file"
override_log="$TMP/track-override-log.jsonl"
fuckup_log="$TMP/fuckup-log.jsonl"

set +e
TRACK_CLASSIFIER_FUCKUP_LOG="$fuckup_log" TRACK_CLASSIFIER_OVERRIDE_LOG="$override_log" \
  bash "$SCRIPT" gate --file "$mission_file" --task-id fixture-track1 --json >"$TMP/refuse.json"
refuse_rc=$?
set -e
[[ "$refuse_rc" -eq 5 ]] && pass "gate_refuses_track1" || fail "gate_refuses_track1 rc=$refuse_rc"
jq -e '.decision == "refuse" and .classification == "track1"' "$TMP/refuse.json" >/dev/null \
  && pass "gate_refusal_json" || fail "gate_refusal_json"
jq -e 'select(.class == "cross_track_dispatch_collision" and .task_id == "fixture-track1")' "$fuckup_log" >/dev/null \
  && pass "gate_refusal_logs_trauma" || fail "gate_refusal_logs_trauma"

set +e
TRACK_CLASSIFIER_FUCKUP_LOG="$fuckup_log" TRACK_CLASSIFIER_OVERRIDE_LOG="$override_log" \
  bash "$SCRIPT" gate --file "$mission_file" --task-id fixture-no-approval --override-track-separation --json >"$TMP/no-approval.json"
no_approval_rc=$?
set -e
[[ "$no_approval_rc" -eq 5 ]] && pass "gate_refuses_bare_override" || fail "gate_refuses_bare_override rc=$no_approval_rc"
jq -e '.reason == "joshua_approval_required"' "$TMP/no-approval.json" >/dev/null \
  && pass "gate_bare_override_reason" || fail "gate_bare_override_reason"

TRACK_CLASSIFIER_FUCKUP_LOG="$fuckup_log" TRACK_CLASSIFIER_OVERRIDE_LOG="$override_log" \
  bash "$SCRIPT" gate --file "$mission_file" --task-id fixture-approved --override-track-separation --joshua-approval "Joshua approved 2026-05-19T04:20Z" --json >"$TMP/approved.json"
jq -e '.decision == "override" and .classification == "track1"' "$TMP/approved.json" >/dev/null \
  && pass "gate_allows_approved_override" || fail "gate_allows_approved_override"
jq -e 'select(.schema_version == "track-separation-override/v1" and .task_id == "fixture-approved" and .decision == "override")' "$override_log" >/dev/null \
  && pass "gate_override_logs_receipt" || fail "gate_override_logs_receipt"

substrate_file="$TMP/substrate-task.md"
printf 'Add .flywheel/scripts/new-validator.sh and tests/new-validator.sh\n' >"$substrate_file"
bash "$SCRIPT" gate --file "$substrate_file" --task-id fixture-track3 --json >"$TMP/track3.json" \
  && pass "gate_allows_track3" || fail "gate_allows_track3"
jq -e '.decision == "allow" and .classification == "track3"' "$TMP/track3.json" >/dev/null \
  && pass "gate_track3_json" || fail "gate_track3_json"

assert_grep 'track-classifier\.sh' "$DISPATCH_MD" "dispatch_invokes_classifier"
assert_grep '--override-track-separation' "$DISPATCH_MD" "dispatch_documents_override_flag"
assert_grep 'TRACK_JOSHUA_APPROVAL' "$DISPATCH_MD" "dispatch_requires_joshua_approval"
assert_grep 'track-override-log\.jsonl' "$DISPATCH_MD" "dispatch_documents_override_log"
assert_grep 'cross_track_dispatch_collision' "$DISPATCH_MD" "dispatch_documents_trauma_class"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
