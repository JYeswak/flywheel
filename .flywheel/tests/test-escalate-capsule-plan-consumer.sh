#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/escalate-capsule-plan-consumer.sh"
TICK_MD="$HOME/.claude/commands/flywheel/tick.md"
TMP="$(mktemp -d -t 0dd7.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail() { printf 'FAIL %s\n' "$1" >&2; exit 1; }
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    jq . "$file" >&2 || true
    fail "$label"
  fi
}

repo="$TMP/repo"
reply_ledger="$TMP/replies.jsonl"
action_ledger="$TMP/actions.jsonl"
mkdir -p "$repo/.flywheel/plans"

cat >"$TMP/inbox.json" <<'JSON'
[
  {
    "id": 77,
    "from": "skillos",
    "subject": "ESCALATE blocker survived 2 ticks: skillos-doctor-waiver",
    "body_md": "schema_version: sister-orch-escalation-capsule/v1\nblocker_id: skillos-doctor-waiver\ntick_count: 2\nsister_session: skillos\nblocker_class: sister-orch-2-tick-blocker\naffected_beads: skillos-r11x, skillos-swmw\nhypothesis: worker-tick doctor preflight is blocking orthogonal skillos dispatches after local retry twice\nevidence_paths: /tmp/skillos-r11x.md,/tmp/skillos-doctor.json\nasks: /flywheel:plan accretive-fix-skillos-doctor-waiver\n"
  },
  {
    "id": 78,
    "from": "mobile-eats",
    "subject": "FYI not an escalation",
    "body_md": "blocker_id: ignored"
  }
]
JSON

bash -n "$SCRIPT" && pass "consumer_syntax"

ESCALATE_CAPSULE_REPLY_LEDGER="$reply_ledger" \
ESCALATE_CAPSULE_ACTION_LEDGER="$action_ledger" \
  "$SCRIPT" scan --repo "$repo" --inbox-json "$TMP/inbox.json" --json >"$TMP/scan.json"

slug="accretive-fix-skillos-doctor-waiver"
state="$repo/.flywheel/plans/$slug/STATE.json"
intent="$repo/.flywheel/plans/$slug/00-INTENT.md"

assert_jq "$TMP/scan.json" \
  '.escalate_capsules_seen == 1 and (.plans_opened | index("accretive-fix-skillos-doctor-waiver")) and .results[0].blocker_id == "skillos-doctor-waiver" and (.results[0].affected_beads | index("skillos-r11x")) and (.results[0].hypothesis | contains("doctor preflight")) and .results[0].same_tick_sla_met == true' \
  "capsule_parser_extracts_required_fields"
test -s "$intent" && grep -q 'Command: `/flywheel:plan accretive-fix-skillos-doctor-waiver`' "$intent" && grep -q 'Capsule Body' "$intent" && pass "plan_intent_opened_with_capsule_body" || fail "plan_intent_opened_with_capsule_body"
assert_jq "$state" '.slug == "accretive-fix-skillos-doctor-waiver" and .current_phase == "research" and .round_count == 0 and .sla == "opened_within_same_tick"' "plan_state_opened_same_tick"
assert_jq "$reply_ledger" 'select(.kind == "plan_opened" and .to_session == "skillos" and .plan_slug == "accretive-fix-skillos-doctor-waiver" and (.body_md | contains("plan_opened=accretive-fix-skillos-doctor-waiver")))' "sister_notified_plan_opened"
assert_jq "$action_ledger" 'select(.event == "escalate_capsule_plan_opened" and .same_tick_sla_met == true and .command == "/flywheel:plan accretive-fix-skillos-doctor-waiver")' "plan_auto_trigger_logged"

jq '.current_phase="refine" | .round_count=2' "$state" >"$TMP/state.next"
mv "$TMP/state.next" "$state"
ESCALATE_CAPSULE_REPLY_LEDGER="$reply_ledger" \
ESCALATE_CAPSULE_ACTION_LEDGER="$action_ledger" \
  "$SCRIPT" report-progress --repo "$repo" --slug "$slug" --sister-session skillos --message-id 77 --json >"$TMP/progress1.json"
ESCALATE_CAPSULE_REPLY_LEDGER="$reply_ledger" \
ESCALATE_CAPSULE_ACTION_LEDGER="$action_ledger" \
  "$SCRIPT" report-progress --repo "$repo" --slug "$slug" --sister-session skillos --message-id 77 --json >"$TMP/progress2.json"

assert_jq "$TMP/progress1.json" '.phase == "refine" and .round_count == 2 and .progress_reply == "created"' "progress_report_created"
assert_jq "$TMP/progress2.json" '.phase == "refine" and .round_count == 2 and .progress_reply == "reused"' "progress_report_idempotent_per_round"
test "$(jq -c 'select(.kind == "plan_progress" and .plan_slug == "accretive-fix-skillos-doctor-waiver" and .phase == "refine" and .round_count == 2)' "$reply_ledger" | wc -l | tr -d ' ')" = "1" \
  && pass "progress_reported_once_per_round" \
  || fail "progress_reported_once_per_round"

grep -q 'escalate-capsule-plan-consumer.sh' "$TICK_MD" \
  && grep -q 'affected_beads:' "$TICK_MD" \
  && grep -q 'hypothesis:' "$TICK_MD" \
  && grep -q 'plan_opened=<slug>' "$TICK_MD" \
  && pass "tick_step_documents_consumer" \
  || fail "tick_step_documents_consumer"

printf 'PASS cases=10 assertions=%s failures=0\n' "$pass_count"
