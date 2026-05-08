#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
ESCALATOR="$ROOT/.flywheel/scripts/two-blocker-ticks-escalator.sh"
SCANNER="$ROOT/.flywheel/scripts/sister-orch-escalation-capsules.sh"
TICK_MD="$HOME/.claude/commands/flywheel/tick.md"
SKILL_MD="$HOME/.claude/skills/flywheel-end-to-end/SKILL.md"
TMP="$(mktemp -d -t jm2b.XXXXXX)"
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
mkdir -p "$repo/.flywheel" "$repo/.beads"
: >"$repo/.beads/issues.jsonl"
jq -nc '{
  ts:"2026-05-08T00:00:00Z",
  event:"manual_dispatch",
  task_id:"skillos-blocker-a",
  bead_id:"skillos-blocker-a",
  callback_expected_by:"2026-05-08T00:05:00Z",
  callback_received_at:null,
  to:"skillos:2-codex"
}' >"$repo/.flywheel/dispatch-log.jsonl"

state="$TMP/state.json"
ledger="$TMP/ledger.jsonl"
coord="$TMP/cross-orch.jsonl"
fuckup="$TMP/fuckup-log.jsonl"

bash -n "$ESCALATOR" && pass "escalator_syntax"
bash -n "$SCANNER" && pass "scanner_syntax"

"$SCANNER" schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" \
  '.subject_prefix == "[ESCALATE]" and (.required_body_fields | index("blocker_id")) and (.required_body_fields | index("tick_count")) and .fuckup_log_class == "sister-orch-2-tick-blocker"' \
  "capsule_schema_codified"

TWO_BLOCKER_TICKS_STATE="$state" \
TWO_BLOCKER_TICKS_LEDGER="$ledger" \
TWO_BLOCKER_TICKS_COORDINATION_LOG="$coord" \
TWO_BLOCKER_TICKS_FUCKUP_LOG="$fuckup" \
TWO_BLOCKER_TICKS_SISTER_SESSION="skillos" \
TWO_BLOCKER_TICKS_NOW="2026-05-08T00:10:00Z" \
  "$ESCALATOR" check --repo "$repo" --json >"$TMP/tick1.json"

TWO_BLOCKER_TICKS_STATE="$state" \
TWO_BLOCKER_TICKS_LEDGER="$ledger" \
TWO_BLOCKER_TICKS_COORDINATION_LOG="$coord" \
TWO_BLOCKER_TICKS_FUCKUP_LOG="$fuckup" \
TWO_BLOCKER_TICKS_SISTER_SESSION="skillos" \
TWO_BLOCKER_TICKS_NOW="2026-05-08T00:15:00Z" \
  "$ESCALATOR" check --repo "$repo" --auto-escalate --json >"$TMP/tick2.json"

assert_jq "$TMP/tick1.json" '.signal == "YELLOW" and .blocked_beads[0].consecutive_tick_count == 1' "first_tick_counts_blocker"
assert_jq "$TMP/tick2.json" '.signal == "RED" and .blocked_beads[0].consecutive_tick_count == 2 and (.auto_escalations_filed | length) == 1' "second_tick_auto_escalates"

coord_row="$TMP/coord-row.json"
tail -n 1 "$coord" >"$coord_row"
assert_jq "$coord_row" \
  '(.agent_mail_subject | startswith("[ESCALATE]")) and .capsule_schema_version == "sister-orch-escalation-capsule/v1" and .tick_count == 2 and .sister_session == "skillos" and .blocker_class == "sister-orch-2-tick-blocker" and (.agent_mail_body_md | contains("blocker_id: skillos-blocker-a") and contains("tick_count: 2") and contains("sister_session: skillos") and contains("evidence_paths:") and contains("/flywheel:plan"))' \
  "fleet_mail_capsule_contract"
assert_jq "$coord_row" '.proposed_action | contains("/flywheel:plan accretive fix for skillos-blocker-a")' "auto_plan_next_action_in_capsule"

assert_jq "$fuckup" 'select(.trauma_class == "sister-orch-2-tick-blocker" and .blocker_id == "skillos-blocker-a" and .tick_count == 2)' "escalator_logs_fuckup_class"

jq -s '[.[0] | {id: 42, subject: .agent_mail_subject, body_md: .agent_mail_body_md}]' "$coord_row" >"$TMP/inbox.json"
SISTER_ORCH_ESCALATION_FUCKUP_LOG="$TMP/inbox-fuckup.jsonl" \
  "$SCANNER" scan --repo "$repo" --inbox-json "$TMP/inbox.json" --json >"$TMP/scan1.json"

assert_jq "$TMP/scan1.json" '.escalations_found == 1 and (.beads_created | length) == 1 and .fuckup_rows_logged == 1' "orch_inbox_scan_wires_plan_bead"
assert_jq "$repo/.beads/issues.jsonl" 'select(.source == "fleet-mail-escalate-capsule" and (.description | contains("/flywheel:plan accretive fix for skillos-blocker-a")))' "plan_bead_cites_flywheel_plan"
assert_jq "$TMP/inbox-fuckup.jsonl" 'select(.trauma_class == "sister-orch-2-tick-blocker" and .source_message_id == 42)' "scanner_logs_fuckup_class"

SISTER_ORCH_ESCALATION_FUCKUP_LOG="$TMP/inbox-fuckup.jsonl" \
  "$SCANNER" scan --repo "$repo" --inbox-json "$TMP/inbox.json" --json >"$TMP/scan2.json"
assert_jq "$TMP/scan2.json" '.escalations_found == 1 and (.beads_created | length) == 0 and (.beads_reused | length) == 1' "orch_inbox_scan_idempotent"

grep -q 'sister-orch-escalation-capsules.sh' "$TICK_MD" \
  && grep -q '\[ESCALATE\]' "$TICK_MD" \
  && grep -q 'sister-orch-2-tick-blocker' "$TICK_MD" \
  && pass "flywheel_tick_scans_escalate_subjects" \
  || fail "flywheel_tick_scans_escalate_subjects"

grep -q '\[ESCALATE\] blocker survived 2 ticks' "$SKILL_MD" \
  && grep -q 'blocker_id:' "$SKILL_MD" \
  && grep -q 'tick_count:' "$SKILL_MD" \
  && grep -q 'sister-orch-2-tick-blocker' "$SKILL_MD" \
  && pass "skill_library_capsule_contract" \
  || fail "skill_library_capsule_contract"

printf 'PASS cases=13 assertions=%s failures=0\n' "$pass_count"
