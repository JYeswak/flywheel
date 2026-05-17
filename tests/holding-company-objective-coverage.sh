#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/holding-company-objective-coverage-validate.py"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/holding-company-objective-coverage.schema.json"
LEDGER="$ROOT/state/holding-company-objective-coverage.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/holding-company-objective-coverage.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

if python3 -m py_compile "$SCRIPT"; then
  pass "validator py_compile"
else
  fail "validator py_compile"
fi

jq empty "$SCHEMA" && pass "schema json valid" || fail "schema json valid"
jq empty "$LEDGER" && pass "ledger json valid" || fail "ledger json valid"

"$SCRIPT" --ledger "$LEDGER" --check-paths --json >"$TMP/current.json"
assert_jq "$TMP/current.json" '.status == "pass" and .objective_coverage_gate_status == "not_complete" and .summary_counts.total == 29 and .summary_counts.partial == 8 and .summary_counts.blocked == 17' "current objective coverage validates as not complete"
assert_jq "$TMP/current.json" '.required_validation_command.command == "bash tests/zeststream-holding-company-standing-goal.sh" and (.validation_commands[] | select(.command_id == "standing_goal_aggregate"))' "validator output surfaces aggregate validation command"
assert_jq "$LEDGER" 'any(.notes[]; contains("bash tests/zeststream-holding-company-standing-goal.sh"))' "coverage matrix names aggregate standing-goal validation"
assert_jq "$LEDGER" '.validation_commands[] | select(.command_id == "standing_goal_aggregate" and .command == "bash tests/zeststream-holding-company-standing-goal.sh" and (.covers | index("state/zeststream-portfolio-company-registry.json")))' "coverage matrix structures aggregate validation command"

jq '.objective_status = "one_off_project"' "$LEDGER" >"$TMP/wrong-objective-status.json"
if "$SCRIPT" --ledger "$TMP/wrong-objective-status.json" --json >"$TMP/wrong-objective-status.out.json" 2>/dev/null; then
  fail "non-standing objective status rejected"
else
  assert_jq "$TMP/wrong-objective-status.out.json" '.failures[] | select(.code == "objective_status_not_standing_non_closing")' "non-standing objective status rejected"
fi

jq '(.requirements[] | select(.requirement_id == "standing_non_closing_goal") | .evidence_refs) -= ["/Users/josh/Desktop/zeststream-goals/zeststream/holding-company-portfolio-20260516.txt"]' "$LEDGER" >"$TMP/missing-standing-source-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-standing-source-ref.json" --json >"$TMP/missing-standing-source-ref.out.json" 2>/dev/null; then
  fail "standing requirement missing source goal ref rejected"
else
  assert_jq "$TMP/missing-standing-source-ref.out.json" '.failures[] | select(.code == "standing_requirement_missing_source_goal_ref" and .requirement_id == "standing_non_closing_goal")' "standing requirement missing source goal ref rejected"
fi

jq '(.requirements[] | select(.requirement_id == "standing_non_closing_goal") | .evidence_refs) -= ["state/zeststream-holding-company-gate-audit-20260517T0646Z.json"]' "$LEDGER" >"$TMP/missing-standing-audit-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-standing-audit-ref.json" --json >"$TMP/missing-standing-audit-ref.out.json" 2>/dev/null; then
  fail "standing requirement missing audit ref rejected"
else
  assert_jq "$TMP/missing-standing-audit-ref.out.json" '.failures[] | select(.code == "standing_requirement_missing_audit_ref" and .requirement_id == "standing_non_closing_goal")' "standing requirement missing audit ref rejected"
fi

jq '
  (.requirements[] | select(.requirement_id == "standing_non_closing_goal") | .coverage_status) = "partial"
  | .summary_counts.partial += 1
  | .summary_counts.proven -= 1
' "$LEDGER" >"$TMP/standing-status-underclaim.json"
if "$SCRIPT" --ledger "$TMP/standing-status-underclaim.json" --json >"$TMP/standing-status-underclaim.out.json" 2>/dev/null; then
  fail "standing requirement status underclaim rejected"
else
  assert_jq "$TMP/standing-status-underclaim.out.json" '.failures[] | select(.code == "standing_requirement_status_not_proven" and .requirement_id == "standing_non_closing_goal" and .expected == "proven")' "standing requirement status underclaim rejected"
fi

jq '(.requirements[] | select(.requirement_id == "management_plane_portfolio") | .evidence_refs) -= ["state/zeststream-holding-company-gate-audit-20260517T0646Z.json"]' "$LEDGER" >"$TMP/missing-management-audit-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-management-audit-ref.json" --json >"$TMP/missing-management-audit-ref.out.json" 2>/dev/null; then
  fail "management-plane requirement missing audit ref rejected"
else
  assert_jq "$TMP/missing-management-audit-ref.out.json" '.failures[] | select(.code == "management_plane_requirement_missing_audit_ref" and .requirement_id == "management_plane_portfolio")' "management-plane requirement missing audit ref rejected"
fi

jq '(.requirements[] | select(.requirement_id == "management_plane_portfolio") | .evidence_refs) -= ["state/zeststream-portfolio-company-registry.json"]' "$LEDGER" >"$TMP/missing-management-registry-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-management-registry-ref.json" --json >"$TMP/missing-management-registry-ref.out.json" 2>/dev/null; then
  fail "management-plane requirement missing registry ref rejected"
else
  assert_jq "$TMP/missing-management-registry-ref.out.json" '.failures[] | select(.code == "management_plane_requirement_missing_registry_ref" and .requirement_id == "management_plane_portfolio")' "management-plane requirement missing registry ref rejected"
fi

jq '
  (.requirements[] | select(.requirement_id == "management_plane_portfolio") | .coverage_status) = "proven"
  | .summary_counts.proven += 1
  | .summary_counts.partial -= 1
' "$LEDGER" >"$TMP/management-plane-overclaim.json"
if "$SCRIPT" --ledger "$TMP/management-plane-overclaim.json" --json >"$TMP/management-plane-overclaim.out.json" 2>/dev/null; then
  fail "zero-portfolio registry rejects management-plane overclaim"
else
  assert_jq "$TMP/management-plane-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_zero_portfolio_registry" and .requirement_id == "management_plane_portfolio" and .expected == "partial")' "zero-portfolio registry rejects management-plane overclaim"
fi

jq '
  (.requirements[] | select(.requirement_id == "management_plane_portfolio") | .coverage_status) = "blocked"
  | .summary_counts.blocked += 1
  | .summary_counts.partial -= 1
' "$LEDGER" >"$TMP/management-plane-underclaim.json"
if "$SCRIPT" --ledger "$TMP/management-plane-underclaim.json" --json >"$TMP/management-plane-underclaim.out.json" 2>/dev/null; then
  fail "zero-portfolio registry rejects management-plane underclaim"
else
  assert_jq "$TMP/management-plane-underclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_zero_portfolio_registry" and .requirement_id == "management_plane_portfolio" and .expected == "partial")' "zero-portfolio registry rejects management-plane underclaim"
fi

jq '.objective_status = "one_off_project"' "$ROOT/state/zeststream-holding-company-gate-audit-20260517T0646Z.json" >"$TMP/wrong-audit.json"
jq --arg old "state/zeststream-holding-company-gate-audit-20260517T0646Z.json" --arg audit "$TMP/wrong-audit.json" '
  .audit_ref = $audit
  | (.requirements[] | select(.primary_evidence_ref == $old) | .primary_evidence_ref) = $audit
  | (.requirements[] | .evidence_refs) |= map(if . == $old then $audit else . end)
' "$LEDGER" >"$TMP/wrong-audit-ledger.json"
if "$SCRIPT" --ledger "$TMP/wrong-audit-ledger.json" --json >"$TMP/wrong-audit-ledger.out.json" 2>/dev/null; then
  fail "audit objective status drift rejected"
else
  assert_jq "$TMP/wrong-audit-ledger.out.json" '.failures[] | select(.code == "audit_objective_status_not_standing_non_closing")' "audit objective status drift rejected"
fi

jq 'del(.requirements[] | select(.requirement_id == "runway_gate")) | .summary_counts.total = 28 | .summary_counts.blocked = 20' "$LEDGER" >"$TMP/missing-id.json"
if "$SCRIPT" --ledger "$TMP/missing-id.json" --json >"$TMP/missing-id.out.json" 2>/dev/null; then
  fail "missing required requirement rejected"
else
  assert_jq "$TMP/missing-id.out.json" '.failures[] | select(.code == "missing_required_requirement_ids")' "missing required requirement rejected"
fi

jq '.requirements += [.requirements[0]] | .summary_counts.total = 30 | .summary_counts.proven = 3' "$LEDGER" >"$TMP/duplicate-id.json"
if "$SCRIPT" --ledger "$TMP/duplicate-id.json" --json >"$TMP/duplicate-id.out.json" 2>/dev/null; then
  fail "duplicate requirement id rejected"
else
  assert_jq "$TMP/duplicate-id.out.json" '.failures[] | select(.code == "duplicate_requirement_id")' "duplicate requirement id rejected"
fi

jq 'del(.validation_commands)' "$LEDGER" >"$TMP/missing-validation-commands.json"
if "$SCRIPT" --ledger "$TMP/missing-validation-commands.json" --json >"$TMP/missing-validation-commands.out.json" 2>/dev/null; then
  fail "missing validation commands rejected"
else
  assert_jq "$TMP/missing-validation-commands.out.json" '.failures[] | select(.code == "schema_invalid")' "missing validation commands rejected"
fi

jq '.validation_commands[0].command = "bash tests/holding-company-objective-coverage.sh"' "$LEDGER" >"$TMP/wrong-aggregate-command.json"
if "$SCRIPT" --ledger "$TMP/wrong-aggregate-command.json" --json >"$TMP/wrong-aggregate-command.out.json" 2>/dev/null; then
  fail "wrong aggregate command rejected"
else
  assert_jq "$TMP/wrong-aggregate-command.out.json" '.failures[] | select(.code == "wrong_standing_goal_aggregate_command")' "wrong aggregate command rejected"
fi

jq '.validation_commands[0].covers -= ["state/zeststream-portfolio-company-registry.json"]' "$LEDGER" >"$TMP/missing-registry-coverage.json"
if "$SCRIPT" --ledger "$TMP/missing-registry-coverage.json" --json >"$TMP/missing-registry-coverage.out.json" 2>/dev/null; then
  fail "aggregate command missing registry coverage rejected"
else
  assert_jq "$TMP/missing-registry-coverage.out.json" '.failures[] | select(.code == "standing_goal_aggregate_missing_registry_coverage")' "aggregate command missing registry coverage rejected"
fi

jq '.validation_commands[0].command = "bash tests/no-such-holding-company-standing-goal.sh"' "$LEDGER" >"$TMP/missing-command-script.json"
if "$SCRIPT" --ledger "$TMP/missing-command-script.json" --check-paths --json >"$TMP/missing-command-script.out.json" 2>/dev/null; then
  fail "missing validation command script rejected"
else
  assert_jq "$TMP/missing-command-script.out.json" '.failures[] | select(.code == "wrong_standing_goal_aggregate_command")' "missing validation command still trips semantic command guard"
  assert_jq "$TMP/missing-command-script.out.json" '.failures[] | select(.code == "validation_command_script_missing")' "missing validation command script rejected"
fi

jq '
  (.requirements[] | select(.requirement_id == "recent_progress_velocity_claim") | .coverage_status) = "proven"
  | .summary_counts.proven += 1
  | .summary_counts.blocked -= 1
' "$LEDGER" >"$TMP/recent-progress-overclaim.json"
if "$SCRIPT" --ledger "$TMP/recent-progress-overclaim.json" --json >"$TMP/recent-progress-overclaim.out.json" 2>/dev/null; then
  fail "recent-progress requirement status overclaim rejected"
else
  assert_jq "$TMP/recent-progress-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_progress_velocity_receipt" and .requirement_id == "recent_progress_velocity_claim" and .evidence_status == "blocked")' "recent-progress requirement status overclaim rejected by progress velocity receipt"
  assert_jq "$TMP/recent-progress-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_claim_honesty" and .requirement_id == "recent_progress_velocity_claim" and .evidence_status == "blocked")' "recent-progress requirement status overclaim rejected"
fi

jq '(.requirements[] | select(.requirement_id == "recent_progress_velocity_claim") | .evidence_refs) -= ["state/holding-company-progress-velocity.json"]' "$LEDGER" >"$TMP/missing-progress-velocity-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-progress-velocity-ref.json" --json >"$TMP/missing-progress-velocity-ref.out.json" 2>/dev/null; then
  fail "recent-progress requirement missing progress velocity ref rejected"
else
  assert_jq "$TMP/missing-progress-velocity-ref.out.json" '.failures[] | select(.code == "progress_velocity_requirement_missing_progress_velocity_ref" and .requirement_id == "recent_progress_velocity_claim")' "recent-progress requirement missing progress velocity ref rejected"
fi

jq '
  (.requirements[] | select(.requirement_id == "recent_mobile_eats_shipping_claim") | .coverage_status) = "proven"
  | .summary_counts.proven += 1
  | .summary_counts.partial -= 1
' "$LEDGER" >"$TMP/mobile-eats-overclaim.json"
if "$SCRIPT" --ledger "$TMP/mobile-eats-overclaim.json" --json >"$TMP/mobile-eats-overclaim.out.json" 2>/dev/null; then
  fail "Mobile Eats shipping status overclaim rejected"
else
  assert_jq "$TMP/mobile-eats-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_mobile_eats_shipping_receipt" and .requirement_id == "recent_mobile_eats_shipping_claim" and .evidence_status == "partial")' "Mobile Eats shipping status overclaim rejected by shipping receipt"
  assert_jq "$TMP/mobile-eats-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_claim_honesty" and .requirement_id == "recent_mobile_eats_shipping_claim" and .evidence_status == "partial")' "Mobile Eats shipping status overclaim rejected by claim honesty"
fi

jq '
  (.requirements[] | select(.requirement_id == "recent_mobile_eats_shipping_claim") | .coverage_status) = "blocked"
  | .summary_counts.blocked += 1
  | .summary_counts.partial -= 1
' "$LEDGER" >"$TMP/mobile-eats-underclaim.json"
if "$SCRIPT" --ledger "$TMP/mobile-eats-underclaim.json" --json >"$TMP/mobile-eats-underclaim.out.json" 2>/dev/null; then
  fail "Mobile Eats shipping partial status underclaim rejected"
else
  assert_jq "$TMP/mobile-eats-underclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_mobile_eats_shipping_receipt" and .requirement_id == "recent_mobile_eats_shipping_claim" and .evidence_status == "partial")' "Mobile Eats shipping partial status underclaim rejected by shipping receipt"
  assert_jq "$TMP/mobile-eats-underclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_claim_honesty" and .requirement_id == "recent_mobile_eats_shipping_claim" and .evidence_status == "partial")' "Mobile Eats shipping partial status underclaim rejected by claim honesty"
fi

jq '
  (.requirements[] | select(.requirement_id == "recent_anthropic_adoption_claim") | .coverage_status) = "partial"
  | .summary_counts.proven -= 1
  | .summary_counts.partial += 1
' "$LEDGER" >"$TMP/anthropic-adoption-underclaim.json"
if "$SCRIPT" --ledger "$TMP/anthropic-adoption-underclaim.json" --json >"$TMP/anthropic-adoption-underclaim.out.json" 2>/dev/null; then
  fail "Anthropic adoption receipt status drift rejected"
else
  assert_jq "$TMP/anthropic-adoption-underclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_anthropic_adoption_receipt" and .requirement_id == "recent_anthropic_adoption_claim" and .evidence_status == "proven")' "Anthropic adoption status drift rejected by adoption receipt"
  assert_jq "$TMP/anthropic-adoption-underclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_claim_honesty" and .requirement_id == "recent_anthropic_adoption_claim" and .evidence_status == "proven")' "Anthropic adoption status drift rejected by claim honesty"
fi

jq '(.requirements[] | select(.requirement_id == "recent_anthropic_adoption_claim") | .evidence_refs) -= ["state/holding-company-anthropic-adoption.json"]' "$LEDGER" >"$TMP/missing-anthropic-adoption-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-anthropic-adoption-ref.json" --json >"$TMP/missing-anthropic-adoption-ref.out.json" 2>/dev/null; then
  fail "Anthropic adoption requirement missing adoption receipt ref rejected"
else
  assert_jq "$TMP/missing-anthropic-adoption-ref.out.json" '.failures[] | select(.code == "anthropic_adoption_requirement_missing_adoption_ref" and .requirement_id == "recent_anthropic_adoption_claim")' "Anthropic adoption requirement missing adoption receipt ref rejected"
fi

jq '(.requirements[] | select(.requirement_id == "recent_mobile_eats_shipping_claim") | .evidence_refs) -= ["state/holding-company-mobile-eats-shipping.json"]' "$LEDGER" >"$TMP/missing-mobile-eats-shipping-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-mobile-eats-shipping-ref.json" --json >"$TMP/missing-mobile-eats-shipping-ref.out.json" 2>/dev/null; then
  fail "Mobile Eats requirement missing shipping receipt ref rejected"
else
  assert_jq "$TMP/missing-mobile-eats-shipping-ref.out.json" '.failures[] | select(.code == "mobile_eats_requirement_missing_shipping_ref" and .requirement_id == "recent_mobile_eats_shipping_claim")' "Mobile Eats requirement missing shipping receipt ref rejected"
fi

jq '(.requirements[] | select(.requirement_id == "recent_mobile_eats_shipping_claim") | .evidence_refs) -= ["state/substrate-share/mobile-eats-20260517T0654Z.json"]' "$LEDGER" >"$TMP/missing-mobile-eats-substrate-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-mobile-eats-substrate-ref.json" --json >"$TMP/missing-mobile-eats-substrate-ref.out.json" 2>/dev/null; then
  fail "Mobile Eats requirement missing substrate-share ref rejected"
else
  assert_jq "$TMP/missing-mobile-eats-substrate-ref.out.json" '.failures[] | select(.code == "mobile_eats_requirement_missing_substrate_share_ref" and .requirement_id == "recent_mobile_eats_shipping_claim")' "Mobile Eats requirement missing substrate-share ref rejected"
fi

jq '
  (.requirements[] | select(.requirement_id == "recent_skillos_forever_os_claim") | .coverage_status) = "proven"
  | .summary_counts.proven += 1
  | .summary_counts.partial -= 1
' "$LEDGER" >"$TMP/skillos-forever-overclaim.json"
if "$SCRIPT" --ledger "$TMP/skillos-forever-overclaim.json" --json >"$TMP/skillos-forever-overclaim.out.json" 2>/dev/null; then
  fail "SkillOS Forever-OS structure-lock overclaim rejected"
else
  assert_jq "$TMP/skillos-forever-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_skillos_forever_os_lock_receipt" and .requirement_id == "recent_skillos_forever_os_claim" and .evidence_status == "partial")' "SkillOS Forever-OS overclaim rejected by lock receipt"
  assert_jq "$TMP/skillos-forever-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_claim_honesty" and .requirement_id == "recent_skillos_forever_os_claim" and .evidence_status == "partial")' "SkillOS Forever-OS overclaim rejected by claim honesty"
fi

jq '(.requirements[] | select(.requirement_id == "recent_skillos_forever_os_claim") | .evidence_refs) -= ["state/holding-company-skillos-forever-os-lock.json"]' "$LEDGER" >"$TMP/missing-skillos-forever-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-skillos-forever-ref.json" --json >"$TMP/missing-skillos-forever-ref.out.json" 2>/dev/null; then
  fail "SkillOS Forever-OS requirement missing lock receipt ref rejected"
else
  assert_jq "$TMP/missing-skillos-forever-ref.out.json" '.failures[] | select(.code == "skillos_forever_os_requirement_missing_lock_ref" and .requirement_id == "recent_skillos_forever_os_claim")' "SkillOS Forever-OS requirement missing lock receipt ref rejected"
fi

jq '(.requirements[] | select(.requirement_id == "recent_mobile_eats_shipping_claim") | .evidence_refs) -= ["state/holding-company-recent-progress-claim-honesty-20260517T1017Z.json"]' "$LEDGER" >"$TMP/missing-claim-honesty-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-claim-honesty-ref.json" --json >"$TMP/missing-claim-honesty-ref.out.json" 2>/dev/null; then
  fail "recent-progress missing claim-honesty ref rejected"
else
  assert_jq "$TMP/missing-claim-honesty-ref.out.json" '.failures[] | select(.code == "recent_progress_requirement_missing_claim_honesty_ref" and .requirement_id == "recent_mobile_eats_shipping_claim")' "recent-progress missing claim-honesty ref rejected"
fi

jq '
  (.requirements[] | select(.requirement_id == "anti_pitch_voice_gate") | .coverage_status) = "proven"
  | .summary_counts.proven += 1
  | .summary_counts.partial -= 1
' "$LEDGER" >"$TMP/anti-pitch-overclaim.json"
if "$SCRIPT" --ledger "$TMP/anti-pitch-overclaim.json" --json >"$TMP/anti-pitch-overclaim.out.json" 2>/dev/null; then
  fail "blocked adjacent voice receipts reject anti-pitch proven claim"
else
  assert_jq "$TMP/anti-pitch-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_anti_pitch_voice_receipts" and .requirement_id == "anti_pitch_voice_gate" and .evidence_status == "partial")' "anti-pitch overclaim rejected by combined receipts"
  assert_jq "$TMP/anti-pitch-overclaim.out.json" '.failures[] | select(.code == "proven_requirement_has_blocked_brand_voice_skill_receipt" and .requirement_id == "anti_pitch_voice_gate")' "blocked brand-voice receipt rejects anti-pitch proven claim"
  assert_jq "$TMP/anti-pitch-overclaim.out.json" '.failures[] | select(.code == "proven_requirement_has_blocked_founder_post_voice_receipt" and .requirement_id == "anti_pitch_voice_gate")' "blocked founder-post receipt rejects anti-pitch proven claim"
fi

jq '
  (.requirements[] | select(.requirement_id == "anti_pitch_voice_gate") | .coverage_status) = "blocked"
  | .summary_counts.blocked += 1
  | .summary_counts.partial -= 1
' "$LEDGER" >"$TMP/anti-pitch-underclaim.json"
if "$SCRIPT" --ledger "$TMP/anti-pitch-underclaim.json" --json >"$TMP/anti-pitch-underclaim.out.json" 2>/dev/null; then
  fail "anti-pitch partial status underclaim rejected"
else
  assert_jq "$TMP/anti-pitch-underclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_anti_pitch_voice_receipts" and .requirement_id == "anti_pitch_voice_gate" and .evidence_status == "partial")' "anti-pitch partial status underclaim rejected"
fi

jq '(.requirements[] | select(.requirement_id == "anti_pitch_voice_gate") | .evidence_refs) -= ["state/holding-company-anti-pitch-voice.json"]' "$LEDGER" >"$TMP/missing-anti-pitch-voice-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-anti-pitch-voice-ref.json" --json >"$TMP/missing-anti-pitch-voice-ref.out.json" 2>/dev/null; then
  fail "anti-pitch requirement missing anti-pitch voice ref rejected"
else
  assert_jq "$TMP/missing-anti-pitch-voice-ref.out.json" '.failures[] | select(.code == "anti_pitch_requirement_missing_anti_pitch_voice_ref" and .requirement_id == "anti_pitch_voice_gate")' "anti-pitch requirement missing anti-pitch voice ref rejected"
fi

jq '(.requirements[] | select(.requirement_id == "anti_pitch_voice_gate") | .evidence_refs) -= ["state/holding-company-brand-voice-skill.json"]' "$LEDGER" >"$TMP/missing-anti-pitch-brand-voice-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-anti-pitch-brand-voice-ref.json" --json >"$TMP/missing-anti-pitch-brand-voice-ref.out.json" 2>/dev/null; then
  fail "anti-pitch requirement missing brand-voice ref rejected"
else
  assert_jq "$TMP/missing-anti-pitch-brand-voice-ref.out.json" '.failures[] | select(.code == "anti_pitch_requirement_missing_brand_voice_skill_ref" and .requirement_id == "anti_pitch_voice_gate")' "anti-pitch requirement missing brand-voice ref rejected"
fi

jq '
  (.requirements[] | select(.requirement_id == "recent_brand_voice_claim") | .coverage_status) = "proven"
  | .summary_counts.proven += 1
  | .summary_counts.partial -= 1
' "$LEDGER" >"$TMP/brand-voice-overclaim.json"
if "$SCRIPT" --ledger "$TMP/brand-voice-overclaim.json" --json >"$TMP/brand-voice-overclaim.out.json" 2>/dev/null; then
  fail "blocked brand-voice receipt rejects brand voice proven claim"
else
  assert_jq "$TMP/brand-voice-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_recent_brand_voice_receipts" and .requirement_id == "recent_brand_voice_claim" and .evidence_status == "partial")' "brand voice overclaim rejected by combined receipts"
  assert_jq "$TMP/brand-voice-overclaim.out.json" '.failures[] | select(.code == "proven_requirement_has_blocked_brand_voice_skill_receipt" and .requirement_id == "recent_brand_voice_claim")' "blocked brand-voice receipt rejects brand voice proven claim"
fi

jq '
  (.requirements[] | select(.requirement_id == "recent_brand_voice_claim") | .coverage_status) = "blocked"
  | .summary_counts.blocked += 1
  | .summary_counts.partial -= 1
' "$LEDGER" >"$TMP/brand-voice-underclaim.json"
if "$SCRIPT" --ledger "$TMP/brand-voice-underclaim.json" --json >"$TMP/brand-voice-underclaim.out.json" 2>/dev/null; then
  fail "brand voice partial status underclaim rejected"
else
  assert_jq "$TMP/brand-voice-underclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_recent_brand_voice_receipts" and .requirement_id == "recent_brand_voice_claim" and .evidence_status == "partial")' "brand voice partial status underclaim rejected"
fi

jq '(.requirements[] | select(.requirement_id == "recent_brand_voice_claim") | .evidence_refs) -= ["state/holding-company-anti-pitch-voice.json"]' "$LEDGER" >"$TMP/missing-brand-voice-anti-pitch-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-brand-voice-anti-pitch-ref.json" --json >"$TMP/missing-brand-voice-anti-pitch-ref.out.json" 2>/dev/null; then
  fail "brand voice requirement missing anti-pitch ref rejected"
else
  assert_jq "$TMP/missing-brand-voice-anti-pitch-ref.out.json" '.failures[] | select(.code == "brand_voice_requirement_missing_anti_pitch_voice_ref" and .requirement_id == "recent_brand_voice_claim")' "brand voice requirement missing anti-pitch ref rejected"
fi

jq '(.requirements[] | select(.requirement_id == "no_custom_apps_positioning") | .evidence_refs) -= ["state/holding-company-anti-pitch-voice.json"]' "$LEDGER" >"$TMP/missing-no-custom-anti-pitch-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-no-custom-anti-pitch-ref.json" --json >"$TMP/missing-no-custom-anti-pitch-ref.out.json" 2>/dev/null; then
  fail "no-custom-apps requirement missing anti-pitch ref rejected"
else
  assert_jq "$TMP/missing-no-custom-anti-pitch-ref.out.json" '.failures[] | select(.code == "no_custom_apps_requirement_missing_anti_pitch_voice_ref" and .requirement_id == "no_custom_apps_positioning")' "no-custom-apps requirement missing anti-pitch ref rejected"
fi

jq '
  (.requirements[] | select(.requirement_id == "no_custom_apps_positioning") | .coverage_status) = "proven"
  | .summary_counts.proven += 1
  | .summary_counts.partial -= 1
' "$LEDGER" >"$TMP/no-custom-apps-overclaim.json"
if "$SCRIPT" --ledger "$TMP/no-custom-apps-overclaim.json" --json >"$TMP/no-custom-apps-overclaim.out.json" 2>/dev/null; then
  fail "no-custom-apps partial status overclaim rejected"
else
  assert_jq "$TMP/no-custom-apps-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_no_custom_apps_positioning_receipts" and .requirement_id == "no_custom_apps_positioning" and .evidence_status == "partial")' "no-custom-apps partial status overclaim rejected"
fi

jq '
  (.requirements[] | select(.requirement_id == "no_custom_apps_positioning") | .coverage_status) = "blocked"
  | .summary_counts.blocked += 1
  | .summary_counts.partial -= 1
' "$LEDGER" >"$TMP/no-custom-apps-underclaim.json"
if "$SCRIPT" --ledger "$TMP/no-custom-apps-underclaim.json" --json >"$TMP/no-custom-apps-underclaim.out.json" 2>/dev/null; then
  fail "no-custom-apps partial status underclaim rejected"
else
  assert_jq "$TMP/no-custom-apps-underclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_no_custom_apps_positioning_receipts" and .requirement_id == "no_custom_apps_positioning" and .evidence_status == "partial")' "no-custom-apps partial status underclaim rejected"
fi

jq '(.requirements[] | select(.requirement_id == "no_custom_apps_positioning") | .evidence_refs) -= ["state/holding-company-public-story-route-20260517T0948Z.json"]' "$LEDGER" >"$TMP/missing-no-custom-public-story-route-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-no-custom-public-story-route-ref.json" --json >"$TMP/missing-no-custom-public-story-route-ref.out.json" 2>/dev/null; then
  fail "no-custom-apps requirement missing public-story route ref rejected"
else
  assert_jq "$TMP/missing-no-custom-public-story-route-ref.out.json" '.failures[] | select(.code == "no_custom_apps_requirement_missing_public_story_route_ref" and .requirement_id == "no_custom_apps_positioning")' "no-custom-apps requirement missing public-story route ref rejected"
fi

jq '(.requirements[] | select(.requirement_id == "no_custom_apps_positioning") | .evidence_refs) -= ["state/holding-company-public-surface-audit-supersession-20260517T1004Z.json"]' "$LEDGER" >"$TMP/missing-no-custom-public-surface-supersession-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-no-custom-public-surface-supersession-ref.json" --json >"$TMP/missing-no-custom-public-surface-supersession-ref.out.json" 2>/dev/null; then
  fail "no-custom-apps requirement missing public-surface supersession ref rejected"
else
  assert_jq "$TMP/missing-no-custom-public-surface-supersession-ref.out.json" '.failures[] | select(.code == "no_custom_apps_requirement_missing_public_surface_supersession_ref" and .requirement_id == "no_custom_apps_positioning")' "no-custom-apps requirement missing public-surface supersession ref rejected"
fi

jq '
  (.requirements[] | select(.requirement_id == "public_story_show_receipts") | .coverage_status) = "proven"
  | .summary_counts.proven += 1
  | .summary_counts.partial -= 1
' "$LEDGER" >"$TMP/public-story-overclaim.json"
if "$SCRIPT" --ledger "$TMP/public-story-overclaim.json" --json >"$TMP/public-story-overclaim.out.json" 2>/dev/null; then
  fail "blocked founder-post receipt rejects public story proven claim"
else
  assert_jq "$TMP/public-story-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_public_story_receipts" and .requirement_id == "public_story_show_receipts" and .evidence_status == "partial")' "public-story overclaim rejected by combined receipts"
  assert_jq "$TMP/public-story-overclaim.out.json" '.failures[] | select(.code == "proven_requirement_has_blocked_founder_post_voice_receipt" and .requirement_id == "public_story_show_receipts")' "blocked founder-post receipt rejects public story proven claim"
fi

jq '
  (.requirements[] | select(.requirement_id == "public_story_show_receipts") | .coverage_status) = "blocked"
  | .summary_counts.blocked += 1
  | .summary_counts.partial -= 1
' "$LEDGER" >"$TMP/public-story-underclaim.json"
if "$SCRIPT" --ledger "$TMP/public-story-underclaim.json" --json >"$TMP/public-story-underclaim.out.json" 2>/dev/null; then
  fail "public-story partial status underclaim rejected"
else
  assert_jq "$TMP/public-story-underclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_public_story_receipts" and .requirement_id == "public_story_show_receipts" and .evidence_status == "partial")' "public-story partial status underclaim rejected"
fi

jq '(.requirements[] | select(.requirement_id == "public_story_show_receipts") | .evidence_refs) -= ["state/holding-company-public-story-route-20260517T0948Z.json"]' "$LEDGER" >"$TMP/missing-public-story-route-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-public-story-route-ref.json" --json >"$TMP/missing-public-story-route-ref.out.json" 2>/dev/null; then
  fail "public-story requirement missing route ref rejected"
else
  assert_jq "$TMP/missing-public-story-route-ref.out.json" '.failures[] | select(.code == "public_story_requirement_missing_public_story_route_ref" and .requirement_id == "public_story_show_receipts")' "public-story requirement missing route ref rejected"
fi

jq '(.requirements[] | select(.requirement_id == "public_story_show_receipts") | .evidence_refs) -= ["state/holding-company-public-surface-audit-supersession-20260517T1004Z.json"]' "$LEDGER" >"$TMP/missing-public-story-public-surface-supersession-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-public-story-public-surface-supersession-ref.json" --json >"$TMP/missing-public-story-public-surface-supersession-ref.out.json" 2>/dev/null; then
  fail "public-story requirement missing supersession ref rejected"
else
  assert_jq "$TMP/missing-public-story-public-surface-supersession-ref.out.json" '.failures[] | select(.code == "public_story_requirement_missing_public_surface_supersession_ref" and .requirement_id == "public_story_show_receipts")' "public-story requirement missing supersession ref rejected"
fi

jq '(.requirements[] | select(.requirement_id == "public_story_show_receipts") | .evidence_refs) -= ["state/holding-company-founder-post-voice.json"]' "$LEDGER" >"$TMP/missing-public-story-founder-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-public-story-founder-ref.json" --json >"$TMP/missing-public-story-founder-ref.out.json" 2>/dev/null; then
  fail "public-story requirement missing founder-post ref rejected"
else
  assert_jq "$TMP/missing-public-story-founder-ref.out.json" '.failures[] | select(.code == "public_story_requirement_missing_founder_post_voice_ref" and .requirement_id == "public_story_show_receipts")' "public-story requirement missing founder-post ref rejected"
fi

jq '
  (.requirements[] | select(.requirement_id == "portfolio_company_existence_gate") | .coverage_status) = "partial"
  | .summary_counts.partial += 1
  | .summary_counts.blocked -= 1
' "$LEDGER" >"$TMP/portfolio-overclaim.json"
if "$SCRIPT" --ledger "$TMP/portfolio-overclaim.json" --json >"$TMP/portfolio-overclaim.out.json" 2>/dev/null; then
  fail "zero-portfolio registry overclaim rejected"
else
  assert_jq "$TMP/portfolio-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_zero_portfolio_registry" and .requirement_id == "portfolio_company_existence_gate" and .expected == "blocked")' "zero-portfolio registry overclaim rejected"
fi

jq '(.requirements[] | select(.requirement_id == "portfolio_company_existence_gate") | .evidence_refs) -= ["state/holding-company-mobile-eats-shipping.json"]' "$LEDGER" >"$TMP/missing-portfolio-existence-mobile-eats-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-portfolio-existence-mobile-eats-ref.json" --json >"$TMP/missing-portfolio-existence-mobile-eats-ref.out.json" 2>/dev/null; then
  fail "portfolio existence requirement missing Mobile Eats shipping ref rejected"
else
  assert_jq "$TMP/missing-portfolio-existence-mobile-eats-ref.out.json" '.failures[] | select(.code == "portfolio_existence_requirement_missing_mobile_eats_shipping_ref" and .requirement_id == "portfolio_company_existence_gate")' "portfolio existence requirement missing Mobile Eats shipping ref rejected"
fi

jq '(.requirements[] | select(.requirement_id == "one_year_small_portfolio_making_money") | .evidence_refs) -= ["state/zeststream-portfolio-company-registry.json"]' "$LEDGER" >"$TMP/missing-registry-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-registry-ref.json" --json >"$TMP/missing-registry-ref.out.json" 2>/dev/null; then
  fail "portfolio requirement missing registry ref rejected"
else
  assert_jq "$TMP/missing-registry-ref.out.json" '.failures[] | select(.code == "portfolio_requirement_missing_registry_ref" and .requirement_id == "one_year_small_portfolio_making_money")' "portfolio requirement missing registry ref rejected"
  assert_jq "$TMP/missing-registry-ref.out.json" '.failures[] | select(.code == "one_year_requirement_missing_registry_ref" and .requirement_id == "one_year_small_portfolio_making_money")' "one-year requirement missing registry ref rejected"
fi

jq '
  (.requirements[] | select(.requirement_id == "one_year_small_portfolio_making_money") | .coverage_status) = "partial"
  | .summary_counts.partial += 1
  | .summary_counts.blocked -= 1
' "$LEDGER" >"$TMP/one-year-overclaim.json"
if "$SCRIPT" --ledger "$TMP/one-year-overclaim.json" --json >"$TMP/one-year-overclaim.out.json" 2>/dev/null; then
  fail "blocked one-year receipts reject success status promotion"
else
  assert_jq "$TMP/one-year-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_zero_portfolio_registry" and .requirement_id == "one_year_small_portfolio_making_money" and .expected == "blocked")' "zero-portfolio registry rejects one-year status promotion"
  assert_jq "$TMP/one-year-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_owner_economics_receipt" and .requirement_id == "one_year_small_portfolio_making_money" and .evidence_status == "blocked")' "blocked owner-economics receipt rejects one-year status promotion"
  assert_jq "$TMP/one-year-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_operating_health_receipt" and .requirement_id == "one_year_small_portfolio_making_money" and .evidence_status == "blocked")' "blocked operating-health receipt rejects one-year status promotion"
  assert_jq "$TMP/one-year-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_shared_stack_receipt" and .requirement_id == "one_year_small_portfolio_making_money" and .evidence_status == "blocked")' "blocked shared-stack receipt rejects one-year status promotion"
fi

jq '(.requirements[] | select(.requirement_id == "one_year_small_portfolio_making_money") | .evidence_refs) -= ["state/holding-company-owner-economics.json"]' "$LEDGER" >"$TMP/missing-one-year-owner-economics-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-one-year-owner-economics-ref.json" --json >"$TMP/missing-one-year-owner-economics-ref.out.json" 2>/dev/null; then
  fail "one-year requirement missing owner-economics ref rejected"
else
  assert_jq "$TMP/missing-one-year-owner-economics-ref.out.json" '.failures[] | select(.code == "one_year_requirement_missing_owner_economics_ref" and .requirement_id == "one_year_small_portfolio_making_money")' "one-year requirement missing owner-economics ref rejected"
fi

jq '(.requirements[] | select(.requirement_id == "one_year_small_portfolio_making_money") | .evidence_refs) -= ["state/holding-company-operating-health.json"]' "$LEDGER" >"$TMP/missing-one-year-operating-health-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-one-year-operating-health-ref.json" --json >"$TMP/missing-one-year-operating-health-ref.out.json" 2>/dev/null; then
  fail "one-year requirement missing operating-health ref rejected"
else
  assert_jq "$TMP/missing-one-year-operating-health-ref.out.json" '.failures[] | select(.code == "one_year_requirement_missing_operating_health_ref" and .requirement_id == "one_year_small_portfolio_making_money")' "one-year requirement missing operating-health ref rejected"
fi

jq '(.requirements[] | select(.requirement_id == "one_year_small_portfolio_making_money") | .evidence_refs) -= ["state/holding-company-shared-stack.json"]' "$LEDGER" >"$TMP/missing-one-year-shared-stack-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-one-year-shared-stack-ref.json" --json >"$TMP/missing-one-year-shared-stack-ref.out.json" 2>/dev/null; then
  fail "one-year requirement missing shared-stack ref rejected"
else
  assert_jq "$TMP/missing-one-year-shared-stack-ref.out.json" '.failures[] | select(.code == "one_year_requirement_missing_shared_stack_ref" and .requirement_id == "one_year_small_portfolio_making_money")' "one-year requirement missing shared-stack ref rejected"
fi

jq '
  (.requirements[] | select(.requirement_id == "each_business_own_brand_owner_customers") | .coverage_status) = "partial"
  | .summary_counts.partial += 1
  | .summary_counts.blocked -= 1
' "$LEDGER" >"$TMP/own-brand-overclaim.json"
if "$SCRIPT" --ledger "$TMP/own-brand-overclaim.json" --json >"$TMP/own-brand-overclaim.out.json" 2>/dev/null; then
  fail "blocked brand-naming and POUR receipts reject own-brand status promotion"
else
  assert_jq "$TMP/own-brand-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_brand_naming_receipt" and .requirement_id == "each_business_own_brand_owner_customers" and .evidence_status == "blocked")' "blocked brand-naming receipt rejects own-brand status promotion"
  assert_jq "$TMP/own-brand-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_pour_readiness_receipt" and .requirement_id == "each_business_own_brand_owner_customers" and .evidence_status == "blocked")' "blocked POUR receipt rejects own-brand status promotion"
fi

jq '(.requirements[] | select(.requirement_id == "each_business_own_brand_owner_customers") | .evidence_refs) -= ["state/holding-company-brand-naming.json"]' "$LEDGER" >"$TMP/missing-own-brand-naming-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-own-brand-naming-ref.json" --json >"$TMP/missing-own-brand-naming-ref.out.json" 2>/dev/null; then
  fail "own-brand requirement missing brand-naming receipt ref rejected"
else
  assert_jq "$TMP/missing-own-brand-naming-ref.out.json" '.failures[] | select(.code == "own_brand_requirement_missing_brand_naming_ref" and .requirement_id == "each_business_own_brand_owner_customers")' "own-brand requirement missing brand-naming receipt ref rejected"
fi

jq '(.requirements[] | select(.requirement_id == "each_business_own_brand_owner_customers") | .evidence_refs) -= ["state/holding-company-pour-readiness.json"]' "$LEDGER" >"$TMP/missing-own-brand-pour-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-own-brand-pour-ref.json" --json >"$TMP/missing-own-brand-pour-ref.out.json" 2>/dev/null; then
  fail "own-brand requirement missing POUR receipt ref rejected"
else
  assert_jq "$TMP/missing-own-brand-pour-ref.out.json" '.failures[] | select(.code == "own_brand_requirement_missing_pour_readiness_ref" and .requirement_id == "each_business_own_brand_owner_customers")' "own-brand requirement missing POUR receipt ref rejected"
fi

jq '(.requirements[] | select(.requirement_id == "runway_gate") | .evidence_refs) = []' "$LEDGER" >"$TMP/missing-primary-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-primary-ref.json" --json >"$TMP/missing-primary-ref.out.json" 2>/dev/null; then
  fail "primary evidence ref must appear in evidence refs"
else
  assert_jq "$TMP/missing-primary-ref.out.json" '.failures[] | select(.code == "schema_invalid")' "empty evidence refs still trips schema"
  assert_jq "$TMP/missing-primary-ref.out.json" '.failures[] | select(.code == "primary_evidence_ref_missing_from_evidence_refs" and .requirement_id == "runway_gate")' "primary evidence ref must appear in evidence refs"
fi

jq '
  (.requirements[] | select(.requirement_id == "runway_gate") | .coverage_status) = "partial"
  | .summary_counts.partial += 1
  | .summary_counts.blocked -= 1
' "$LEDGER" >"$TMP/runway-overclaim.json"
if "$SCRIPT" --ledger "$TMP/runway-overclaim.json" --json >"$TMP/runway-overclaim.out.json" 2>/dev/null; then
  fail "blocked runway receipt rejects runway status promotion"
else
  assert_jq "$TMP/runway-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_runway_receipt" and .requirement_id == "runway_gate" and .evidence_status == "blocked")' "blocked runway receipt rejects runway status promotion"
fi

jq '(.requirements[] | select(.requirement_id == "runway_gate") | .evidence_refs) -= ["state/holding-company-runway-current.json"]' "$LEDGER" >"$TMP/missing-runway-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-runway-ref.json" --json >"$TMP/missing-runway-ref.out.json" 2>/dev/null; then
  fail "runway requirement missing runway receipt ref rejected"
else
  assert_jq "$TMP/missing-runway-ref.out.json" '.failures[] | select(.code == "runway_requirement_missing_runway_receipt_ref" and .requirement_id == "runway_gate")' "runway requirement missing runway receipt ref rejected"
fi

jq '
  (.requirements[] | select(.requirement_id == "legal_structure_gate") | .coverage_status) = "partial"
  | .summary_counts.partial += 1
  | .summary_counts.blocked -= 1
' "$LEDGER" >"$TMP/legal-overclaim.json"
if "$SCRIPT" --ledger "$TMP/legal-overclaim.json" --json >"$TMP/legal-overclaim.out.json" 2>/dev/null; then
  fail "blocked legal receipt rejects legal status promotion"
else
  assert_jq "$TMP/legal-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_legal_structure_receipt" and .requirement_id == "legal_structure_gate" and .evidence_status == "blocked")' "blocked legal receipt rejects legal status promotion"
fi

jq '(.requirements[] | select(.requirement_id == "legal_structure_gate") | .evidence_refs) -= ["state/holding-company-legal-structure.json"]' "$LEDGER" >"$TMP/missing-legal-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-legal-ref.json" --json >"$TMP/missing-legal-ref.out.json" 2>/dev/null; then
  fail "legal requirement missing legal-structure receipt ref rejected"
else
  assert_jq "$TMP/missing-legal-ref.out.json" '.failures[] | select(.code == "legal_requirement_missing_legal_structure_ref" and .requirement_id == "legal_structure_gate")' "legal requirement missing legal-structure receipt ref rejected"
fi

jq '
  (.requirements[] | select(.requirement_id == "sustainable_pace_gate") | .coverage_status) = "partial"
  | .summary_counts.partial += 1
  | .summary_counts.blocked -= 1
' "$LEDGER" >"$TMP/pace-overclaim.json"
if "$SCRIPT" --ledger "$TMP/pace-overclaim.json" --json >"$TMP/pace-overclaim.out.json" 2>/dev/null; then
  fail "blocked sustainable-pace receipt rejects pace status promotion"
else
  assert_jq "$TMP/pace-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_sustainable_pace_receipt" and .requirement_id == "sustainable_pace_gate" and .evidence_status == "blocked")' "blocked sustainable-pace receipt rejects pace status promotion"
fi

jq '(.requirements[] | select(.requirement_id == "sustainable_pace_gate") | .evidence_refs) -= ["state/holding-company-sustainable-pace.json"]' "$LEDGER" >"$TMP/missing-pace-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-pace-ref.json" --json >"$TMP/missing-pace-ref.out.json" 2>/dev/null; then
  fail "sustainable-pace requirement missing pace receipt ref rejected"
else
  assert_jq "$TMP/missing-pace-ref.out.json" '.failures[] | select(.code == "sustainable_pace_requirement_missing_pace_ref" and .requirement_id == "sustainable_pace_gate")' "sustainable-pace requirement missing pace receipt ref rejected"
fi

jq '
  (.requirements[] | select(.requirement_id == "joshua_coach_sustainable_pace") | .coverage_status) = "partial"
  | .summary_counts.partial += 1
  | .summary_counts.blocked -= 1
' "$LEDGER" >"$TMP/coach-overclaim.json"
if "$SCRIPT" --ledger "$TMP/coach-overclaim.json" --json >"$TMP/coach-overclaim.out.json" 2>/dev/null; then
  fail "blocked coach-role and pace receipts reject coach status promotion"
else
  assert_jq "$TMP/coach-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_coach_role_receipt" and .requirement_id == "joshua_coach_sustainable_pace" and .evidence_status == "blocked")' "blocked coach-role receipt rejects coach status promotion"
  assert_jq "$TMP/coach-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_sustainable_pace_receipt" and .requirement_id == "joshua_coach_sustainable_pace" and .evidence_status == "blocked")' "blocked pace receipt rejects coach status promotion"
fi

jq '(.requirements[] | select(.requirement_id == "joshua_coach_sustainable_pace") | .evidence_refs) -= ["state/holding-company-coach-role.json"]' "$LEDGER" >"$TMP/missing-coach-role-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-coach-role-ref.json" --json >"$TMP/missing-coach-role-ref.out.json" 2>/dev/null; then
  fail "coach requirement missing coach-role receipt ref rejected"
else
  assert_jq "$TMP/missing-coach-role-ref.out.json" '.failures[] | select(.code == "coach_requirement_missing_coach_role_ref" and .requirement_id == "joshua_coach_sustainable_pace")' "coach requirement missing coach-role receipt ref rejected"
fi

jq '(.requirements[] | select(.requirement_id == "joshua_coach_sustainable_pace") | .evidence_refs) -= ["state/holding-company-sustainable-pace.json"]' "$LEDGER" >"$TMP/missing-coach-pace-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-coach-pace-ref.json" --json >"$TMP/missing-coach-pace-ref.out.json" 2>/dev/null; then
  fail "coach requirement missing sustainable-pace receipt ref rejected"
else
  assert_jq "$TMP/missing-coach-pace-ref.out.json" '.failures[] | select(.code == "coach_requirement_missing_sustainable_pace_ref" and .requirement_id == "joshua_coach_sustainable_pace")' "coach requirement missing sustainable-pace receipt ref rejected"
fi

jq '
  (.requirements[] | select(.requirement_id == "owner_search_phasing_gate") | .coverage_status) = "partial"
  | .summary_counts.partial += 1
  | .summary_counts.blocked -= 1
' "$LEDGER" >"$TMP/owner-search-overclaim.json"
if "$SCRIPT" --ledger "$TMP/owner-search-overclaim.json" --json >"$TMP/owner-search-overclaim.out.json" 2>/dev/null; then
  fail "blocked owner-search receipt rejects owner-search status promotion"
else
  assert_jq "$TMP/owner-search-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_owner_search_phasing_receipt" and .requirement_id == "owner_search_phasing_gate" and .evidence_status == "blocked")' "blocked owner-search receipt rejects owner-search status promotion"
fi

jq '(.requirements[] | select(.requirement_id == "owner_search_phasing_gate") | .evidence_refs) -= ["state/holding-company-owner-search-phasing.json"]' "$LEDGER" >"$TMP/missing-owner-search-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-owner-search-ref.json" --json >"$TMP/missing-owner-search-ref.out.json" 2>/dev/null; then
  fail "owner-search requirement missing phasing receipt ref rejected"
else
  assert_jq "$TMP/missing-owner-search-ref.out.json" '.failures[] | select(.code == "owner_search_requirement_missing_phasing_ref" and .requirement_id == "owner_search_phasing_gate")' "owner-search requirement missing phasing receipt ref rejected"
fi

jq '
  (.requirements[] | select(.requirement_id == "owner_equity_distribution_terms") | .coverage_status) = "partial"
  | .summary_counts.partial += 1
  | .summary_counts.blocked -= 1
' "$LEDGER" >"$TMP/owner-economics-overclaim.json"
if "$SCRIPT" --ledger "$TMP/owner-economics-overclaim.json" --json >"$TMP/owner-economics-overclaim.out.json" 2>/dev/null; then
  fail "blocked owner-economics receipt rejects equity terms promotion"
else
  assert_jq "$TMP/owner-economics-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_owner_economics_receipt" and .requirement_id == "owner_equity_distribution_terms" and .evidence_status == "blocked")' "blocked owner-economics receipt rejects equity terms promotion"
fi

jq '(.requirements[] | select(.requirement_id == "owner_equity_distribution_terms") | .evidence_refs) -= ["state/holding-company-owner-economics.json"]' "$LEDGER" >"$TMP/missing-owner-economics-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-owner-economics-ref.json" --json >"$TMP/missing-owner-economics-ref.out.json" 2>/dev/null; then
  fail "owner-economics requirement missing owner-economics receipt ref rejected"
else
  assert_jq "$TMP/missing-owner-economics-ref.out.json" '.failures[] | select(.code == "owner_economics_requirement_missing_owner_economics_ref" and .requirement_id == "owner_equity_distribution_terms")' "owner-economics requirement missing owner-economics receipt ref rejected"
fi

jq '
  (.requirements[] | select(.requirement_id == "customer_smb_owner_operator") | .coverage_status) = "partial"
  | .summary_counts.partial += 1
  | .summary_counts.blocked -= 1
' "$LEDGER" >"$TMP/customer-overclaim.json"
if "$SCRIPT" --ledger "$TMP/customer-overclaim.json" --json >"$TMP/customer-overclaim.out.json" 2>/dev/null; then
  fail "blocked customer evidence rejects customer status promotion"
else
  assert_jq "$TMP/customer-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_candidate_fit_receipt" and .requirement_id == "customer_smb_owner_operator" and .evidence_status == "blocked")' "blocked candidate-fit receipt rejects customer status promotion"
  assert_jq "$TMP/customer-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_owner_voice_receipt" and .requirement_id == "customer_smb_owner_operator" and .evidence_status == "blocked")' "blocked owner-voice receipt rejects customer status promotion"
fi

jq '(.requirements[] | select(.requirement_id == "customer_smb_owner_operator") | .evidence_refs) -= ["state/holding-company-candidate-fit.json"]' "$LEDGER" >"$TMP/missing-customer-candidate-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-customer-candidate-ref.json" --json >"$TMP/missing-customer-candidate-ref.out.json" 2>/dev/null; then
  fail "customer requirement missing candidate-fit receipt ref rejected"
else
  assert_jq "$TMP/missing-customer-candidate-ref.out.json" '.failures[] | select(.code == "customer_requirement_missing_candidate_fit_ref" and .requirement_id == "customer_smb_owner_operator")' "customer requirement missing candidate-fit receipt ref rejected"
fi

jq '(.requirements[] | select(.requirement_id == "customer_smb_owner_operator") | .evidence_refs) -= ["state/holding-company-owner-voice.json"]' "$LEDGER" >"$TMP/missing-customer-owner-voice-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-customer-owner-voice-ref.json" --json >"$TMP/missing-customer-owner-voice-ref.out.json" 2>/dev/null; then
  fail "customer requirement missing owner-voice receipt ref rejected"
else
  assert_jq "$TMP/missing-customer-owner-voice-ref.out.json" '.failures[] | select(.code == "customer_requirement_missing_owner_voice_ref" and .requirement_id == "customer_smb_owner_operator")' "customer requirement missing owner-voice receipt ref rejected"
fi

jq '
  (.requirements[] | select(.requirement_id == "peel_loop") | .coverage_status) = "partial"
  | .summary_counts.partial += 1
  | .summary_counts.blocked -= 1
' "$LEDGER" >"$TMP/peel-overclaim.json"
if "$SCRIPT" --ledger "$TMP/peel-overclaim.json" --json >"$TMP/peel-overclaim.out.json" 2>/dev/null; then
  fail "blocked PEEL receipt rejects PEEL status promotion"
else
  assert_jq "$TMP/peel-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_peel_interviews_receipt" and .requirement_id == "peel_loop" and .evidence_status == "blocked")' "blocked PEEL receipt rejects PEEL status promotion"
fi

jq '(.requirements[] | select(.requirement_id == "peel_loop") | .evidence_refs) -= ["state/holding-company-peel-interviews.json"]' "$LEDGER" >"$TMP/missing-peel-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-peel-ref.json" --json >"$TMP/missing-peel-ref.out.json" 2>/dev/null; then
  fail "PEEL requirement missing interview receipt ref rejected"
else
  assert_jq "$TMP/missing-peel-ref.out.json" '.failures[] | select(.code == "peel_requirement_missing_interviews_ref" and .requirement_id == "peel_loop")' "PEEL requirement missing interview receipt ref rejected"
fi

jq '(.requirements[] | select(.requirement_id == "peel_loop") | .evidence_refs) -= ["state/holding-company-candidate-fit.json"]' "$LEDGER" >"$TMP/missing-peel-candidate-fit-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-peel-candidate-fit-ref.json" --json >"$TMP/missing-peel-candidate-fit-ref.out.json" 2>/dev/null; then
  fail "PEEL requirement missing candidate-fit receipt ref rejected"
else
  assert_jq "$TMP/missing-peel-candidate-fit-ref.out.json" '.failures[] | select(.code == "peel_requirement_missing_candidate_fit_ref" and .requirement_id == "peel_loop")' "PEEL requirement missing candidate-fit receipt ref rejected"
fi

jq '
  (.requirements[] | select(.requirement_id == "press_loop") | .coverage_status) = "partial"
  | .summary_counts.partial += 1
  | .summary_counts.blocked -= 1
' "$LEDGER" >"$TMP/press-overclaim.json"
if "$SCRIPT" --ledger "$TMP/press-overclaim.json" --json >"$TMP/press-overclaim.out.json" 2>/dev/null; then
  fail "blocked PRESS receipt rejects PRESS status promotion"
else
  assert_jq "$TMP/press-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_press_readiness_receipt" and .requirement_id == "press_loop" and .evidence_status == "blocked")' "blocked PRESS receipt rejects PRESS status promotion"
fi

jq '(.requirements[] | select(.requirement_id == "press_loop") | .evidence_refs) -= ["state/holding-company-press-readiness.json"]' "$LEDGER" >"$TMP/missing-press-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-press-ref.json" --json >"$TMP/missing-press-ref.out.json" 2>/dev/null; then
  fail "PRESS requirement missing readiness receipt ref rejected"
else
  assert_jq "$TMP/missing-press-ref.out.json" '.failures[] | select(.code == "press_requirement_missing_press_readiness_ref" and .requirement_id == "press_loop")' "PRESS requirement missing readiness receipt ref rejected"
fi

jq '(.requirements[] | select(.requirement_id == "press_loop") | .evidence_refs) -= ["state/holding-company-owner-economics.json"]' "$LEDGER" >"$TMP/missing-press-owner-economics-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-press-owner-economics-ref.json" --json >"$TMP/missing-press-owner-economics-ref.out.json" 2>/dev/null; then
  fail "PRESS requirement missing owner-economics receipt ref rejected"
else
  assert_jq "$TMP/missing-press-owner-economics-ref.out.json" '.failures[] | select(.code == "press_requirement_missing_owner_economics_ref" and .requirement_id == "press_loop")' "PRESS requirement missing owner-economics receipt ref rejected"
fi

jq '
  (.requirements[] | select(.requirement_id == "pour_loop") | .coverage_status) = "partial"
  | .summary_counts.partial += 1
  | .summary_counts.blocked -= 1
' "$LEDGER" >"$TMP/pour-overclaim.json"
if "$SCRIPT" --ledger "$TMP/pour-overclaim.json" --json >"$TMP/pour-overclaim.out.json" 2>/dev/null; then
  fail "blocked POUR receipt rejects POUR status promotion"
else
  assert_jq "$TMP/pour-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_pour_readiness_receipt" and .requirement_id == "pour_loop" and .evidence_status == "blocked")' "blocked POUR receipt rejects POUR status promotion"
fi

jq '(.requirements[] | select(.requirement_id == "pour_loop") | .evidence_refs) -= ["state/holding-company-pour-readiness.json"]' "$LEDGER" >"$TMP/missing-pour-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-pour-ref.json" --json >"$TMP/missing-pour-ref.out.json" 2>/dev/null; then
  fail "POUR requirement missing readiness receipt ref rejected"
else
  assert_jq "$TMP/missing-pour-ref.out.json" '.failures[] | select(.code == "pour_requirement_missing_pour_readiness_ref" and .requirement_id == "pour_loop")' "POUR requirement missing readiness receipt ref rejected"
fi

jq '
  (.requirements[] | select(.requirement_id == "n_plus_one_cheaper_than_n") | .coverage_status) = "partial"
  | .summary_counts.partial += 1
  | .summary_counts.blocked -= 1
' "$LEDGER" >"$TMP/n-plus-one-overclaim.json"
if "$SCRIPT" --ledger "$TMP/n-plus-one-overclaim.json" --json >"$TMP/n-plus-one-overclaim.out.json" 2>/dev/null; then
  fail "blocked launch-economics receipt rejects N+1 status promotion"
else
  assert_jq "$TMP/n-plus-one-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_launch_economics_receipt" and .requirement_id == "n_plus_one_cheaper_than_n" and .evidence_status == "blocked")' "blocked launch-economics receipt rejects N+1 status promotion"
fi

jq '(.requirements[] | select(.requirement_id == "n_plus_one_cheaper_than_n") | .evidence_refs) -= ["state/holding-company-launch-economics.json"]' "$LEDGER" >"$TMP/missing-n-plus-one-launch-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-n-plus-one-launch-ref.json" --json >"$TMP/missing-n-plus-one-launch-ref.out.json" 2>/dev/null; then
  fail "N+1 requirement missing launch-economics receipt ref rejected"
else
  assert_jq "$TMP/missing-n-plus-one-launch-ref.out.json" '.failures[] | select(.code == "n_plus_one_requirement_missing_launch_economics_ref" and .requirement_id == "n_plus_one_cheaper_than_n")' "N+1 requirement missing launch-economics receipt ref rejected"
fi

jq '
  (.requirements[] | select(.requirement_id == "recycle_loop") | .coverage_status) = "partial"
  | .summary_counts.partial += 1
  | .summary_counts.blocked -= 1
' "$LEDGER" >"$TMP/recycle-overclaim.json"
if "$SCRIPT" --ledger "$TMP/recycle-overclaim.json" --json >"$TMP/recycle-overclaim.out.json" 2>/dev/null; then
  fail "blocked RECYCLE receipt rejects RECYCLE status promotion"
else
  assert_jq "$TMP/recycle-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_recycle_loop_receipt" and .requirement_id == "recycle_loop" and .evidence_status == "blocked")' "blocked RECYCLE receipt rejects RECYCLE status promotion"
fi

jq '(.requirements[] | select(.requirement_id == "recycle_loop") | .evidence_refs) -= ["state/holding-company-recycle-loop.json"]' "$LEDGER" >"$TMP/missing-recycle-loop-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-recycle-loop-ref.json" --json >"$TMP/missing-recycle-loop-ref.out.json" 2>/dev/null; then
  fail "RECYCLE requirement missing recycle-loop receipt ref rejected"
else
  assert_jq "$TMP/missing-recycle-loop-ref.out.json" '.failures[] | select(.code == "recycle_requirement_missing_recycle_loop_ref" and .requirement_id == "recycle_loop")' "RECYCLE requirement missing recycle-loop receipt ref rejected"
fi

jq '(.requirements[] | select(.requirement_id == "recycle_loop") | .evidence_refs) -= ["state/holding-company-launch-economics.json"]' "$LEDGER" >"$TMP/missing-recycle-launch-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-recycle-launch-ref.json" --json >"$TMP/missing-recycle-launch-ref.out.json" 2>/dev/null; then
  fail "RECYCLE requirement missing launch-economics receipt ref rejected"
else
  assert_jq "$TMP/missing-recycle-launch-ref.out.json" '.failures[] | select(.code == "recycle_requirement_missing_launch_economics_ref" and .requirement_id == "recycle_loop")' "RECYCLE requirement missing launch-economics receipt ref rejected"
fi

jq '
  (.requirements[] | select(.requirement_id == "shared_substrate_stack") | .coverage_status) = "proven"
  | .summary_counts.proven += 1
  | .summary_counts.partial -= 1
' "$LEDGER" >"$TMP/shared-substrate-overclaim.json"
if "$SCRIPT" --ledger "$TMP/shared-substrate-overclaim.json" --json >"$TMP/shared-substrate-overclaim.out.json" 2>/dev/null; then
  fail "blocked shared-stack receipt rejects shared-substrate proven claim"
else
  assert_jq "$TMP/shared-substrate-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_shared_substrate_receipts" and .requirement_id == "shared_substrate_stack" and .evidence_status == "partial")' "shared-substrate overclaim rejected by combined receipts"
  assert_jq "$TMP/shared-substrate-overclaim.out.json" '.failures[] | select(.code == "proven_requirement_has_zero_clear_primary_evidence" and .requirement_id == "shared_substrate_stack")' "zero-clear shared-stack receipt rejects shared-substrate proven claim"
  assert_jq "$TMP/shared-substrate-overclaim.out.json" '.failures[] | select(.code == "proven_requirement_has_blocked_shared_stack_receipt" and .requirement_id == "shared_substrate_stack" and .evidence_status == "blocked")' "blocked shared-stack receipt rejects shared-substrate proven claim"
fi

jq '
  (.requirements[] | select(.requirement_id == "shared_substrate_stack") | .coverage_status) = "blocked"
  | .summary_counts.blocked += 1
  | .summary_counts.partial -= 1
' "$LEDGER" >"$TMP/shared-substrate-underclaim.json"
if "$SCRIPT" --ledger "$TMP/shared-substrate-underclaim.json" --json >"$TMP/shared-substrate-underclaim.out.json" 2>/dev/null; then
  fail "shared-substrate partial status underclaim rejected"
else
  assert_jq "$TMP/shared-substrate-underclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_shared_substrate_receipts" and .requirement_id == "shared_substrate_stack" and .evidence_status == "partial")' "shared-substrate partial status underclaim rejected"
fi

jq '(.requirements[] | select(.requirement_id == "shared_substrate_stack") | .evidence_refs) -= ["state/holding-company-shared-stack.json"]' "$LEDGER" >"$TMP/missing-shared-substrate-stack-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-shared-substrate-stack-ref.json" --json >"$TMP/missing-shared-substrate-stack-ref.out.json" 2>/dev/null; then
  fail "shared-substrate requirement missing shared-stack ref rejected"
else
  assert_jq "$TMP/missing-shared-substrate-stack-ref.out.json" '.failures[] | select(.code == "shared_substrate_requirement_missing_shared_stack_ref" and .requirement_id == "shared_substrate_stack")' "shared-substrate requirement missing shared-stack ref rejected"
fi

jq '(.requirements[] | select(.requirement_id == "shared_substrate_stack") | .evidence_refs) -= ["state/substrate-share/mobile-eats-20260517T0654Z.json"]' "$LEDGER" >"$TMP/missing-shared-substrate-share-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-shared-substrate-share-ref.json" --json >"$TMP/missing-shared-substrate-share-ref.out.json" 2>/dev/null; then
  fail "shared-substrate requirement missing substrate-share ref rejected"
else
  assert_jq "$TMP/missing-shared-substrate-share-ref.out.json" '.failures[] | select(.code == "shared_substrate_requirement_missing_substrate_share_ref" and .requirement_id == "shared_substrate_stack")' "shared-substrate requirement missing substrate-share ref rejected"
fi

jq '(.requirements[] | select(.requirement_id == "shared_substrate_stack") | .evidence_refs) -= ["state/holding-company-anthropic-adoption.json"]' "$LEDGER" >"$TMP/missing-shared-substrate-anthropic-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-shared-substrate-anthropic-ref.json" --json >"$TMP/missing-shared-substrate-anthropic-ref.out.json" 2>/dev/null; then
  fail "shared-substrate requirement missing Anthropic adoption ref rejected"
else
  assert_jq "$TMP/missing-shared-substrate-anthropic-ref.out.json" '.failures[] | select(.code == "shared_substrate_requirement_missing_anthropic_adoption_ref" and .requirement_id == "shared_substrate_stack")' "shared-substrate requirement missing Anthropic adoption ref rejected"
fi

jq '
  (.requirements[] | select(.requirement_id == "nurture_loop") | .coverage_status) = "partial"
  | .summary_counts.partial += 1
  | .summary_counts.blocked -= 1
' "$LEDGER" >"$TMP/nurture-overclaim.json"
if "$SCRIPT" --ledger "$TMP/nurture-overclaim.json" --json >"$TMP/nurture-overclaim.out.json" 2>/dev/null; then
  fail "blocked NURTURE receipts reject NURTURE status promotion"
else
  assert_jq "$TMP/nurture-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_shared_stack_receipt" and .requirement_id == "nurture_loop" and .evidence_status == "blocked")' "blocked shared-stack receipt rejects NURTURE status promotion"
  assert_jq "$TMP/nurture-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_peer_coach_receipt" and .requirement_id == "nurture_loop" and .evidence_status == "blocked")' "blocked peer-coach receipt rejects NURTURE status promotion"
fi

jq '(.requirements[] | select(.requirement_id == "nurture_loop") | .evidence_refs) -= ["state/holding-company-shared-stack.json"]' "$LEDGER" >"$TMP/missing-nurture-shared-stack-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-nurture-shared-stack-ref.json" --json >"$TMP/missing-nurture-shared-stack-ref.out.json" 2>/dev/null; then
  fail "NURTURE requirement missing shared-stack receipt ref rejected"
else
  assert_jq "$TMP/missing-nurture-shared-stack-ref.out.json" '.failures[] | select(.code == "nurture_requirement_missing_shared_stack_ref" and .requirement_id == "nurture_loop")' "NURTURE requirement missing shared-stack receipt ref rejected"
fi

jq '(.requirements[] | select(.requirement_id == "nurture_loop") | .evidence_refs) -= ["state/holding-company-peer-coach.json"]' "$LEDGER" >"$TMP/missing-nurture-peer-coach-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-nurture-peer-coach-ref.json" --json >"$TMP/missing-nurture-peer-coach-ref.out.json" 2>/dev/null; then
  fail "NURTURE requirement missing peer-coach receipt ref rejected"
else
  assert_jq "$TMP/missing-nurture-peer-coach-ref.out.json" '.failures[] | select(.code == "nurture_requirement_missing_peer_coach_ref" and .requirement_id == "nurture_loop")' "NURTURE requirement missing peer-coach receipt ref rejected"
fi

jq '
  (.requirements[] | select(.requirement_id == "future_nonprofit_extension") | .coverage_status) = "partial"
  | .summary_counts.partial += 1
  | .summary_counts.deferred -= 1
' "$LEDGER" >"$TMP/nonprofit-overclaim.json"
if "$SCRIPT" --ledger "$TMP/nonprofit-overclaim.json" --json >"$TMP/nonprofit-overclaim.out.json" 2>/dev/null; then
  fail "blocked nonprofit receipt rejects future nonprofit status promotion"
else
  assert_jq "$TMP/nonprofit-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_nonprofit_extension_receipt" and .requirement_id == "future_nonprofit_extension" and .expected == "deferred" and .evidence_status == "blocked")' "blocked nonprofit receipt rejects future nonprofit status promotion"
fi

jq '
  (.requirements[] | select(.requirement_id == "future_nonprofit_extension") | .coverage_status) = "proven"
  | .summary_counts.proven += 1
  | .summary_counts.deferred -= 1
' "$LEDGER" >"$TMP/nonprofit-proven-overclaim.json"
if "$SCRIPT" --ledger "$TMP/nonprofit-proven-overclaim.json" --json >"$TMP/nonprofit-proven-overclaim.out.json" 2>/dev/null; then
  fail "blocked nonprofit receipt rejects future nonprofit proven claim"
else
  assert_jq "$TMP/nonprofit-proven-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_nonprofit_extension_receipt" and .requirement_id == "future_nonprofit_extension" and .expected == "deferred" and .evidence_status == "blocked")' "blocked nonprofit receipt rejects future nonprofit proven claim"
fi

jq '
  (.requirements[] | select(.requirement_id == "future_nonprofit_extension") | .coverage_status) = "blocked"
  | .summary_counts.blocked += 1
  | .summary_counts.deferred -= 1
' "$LEDGER" >"$TMP/nonprofit-underclaim.json"
if "$SCRIPT" --ledger "$TMP/nonprofit-underclaim.json" --json >"$TMP/nonprofit-underclaim.out.json" 2>/dev/null; then
  fail "blocked nonprofit receipt preserves future nonprofit deferred status"
else
  assert_jq "$TMP/nonprofit-underclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_nonprofit_extension_receipt" and .requirement_id == "future_nonprofit_extension" and .expected == "deferred" and .evidence_status == "blocked")' "blocked nonprofit receipt preserves future nonprofit deferred status"
fi

jq '(.requirements[] | select(.requirement_id == "future_nonprofit_extension") | .evidence_refs) -= ["state/holding-company-nonprofit-extension.json"]' "$LEDGER" >"$TMP/missing-nonprofit-extension-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-nonprofit-extension-ref.json" --json >"$TMP/missing-nonprofit-extension-ref.out.json" 2>/dev/null; then
  fail "future nonprofit requirement missing nonprofit-extension ref rejected"
else
  assert_jq "$TMP/missing-nonprofit-extension-ref.out.json" '.failures[] | select(.code == "future_nonprofit_requirement_missing_nonprofit_extension_ref" and .requirement_id == "future_nonprofit_extension")' "future nonprofit requirement missing nonprofit-extension ref rejected"
fi

jq '
  (.requirements[] | select(.requirement_id == "company_close_pivot_graduate") | .coverage_status) = "partial"
  | .summary_counts.partial += 1
  | .summary_counts.deferred -= 1
' "$LEDGER" >"$TMP/lifecycle-overclaim.json"
if "$SCRIPT" --ledger "$TMP/lifecycle-overclaim.json" --json >"$TMP/lifecycle-overclaim.out.json" 2>/dev/null; then
  fail "blocked lifecycle receipt rejects lifecycle status promotion"
else
  assert_jq "$TMP/lifecycle-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_lifecycle_disposition_receipt" and .requirement_id == "company_close_pivot_graduate" and .expected == "deferred" and .evidence_status == "blocked")' "blocked lifecycle receipt rejects lifecycle status promotion"
fi

jq '
  (.requirements[] | select(.requirement_id == "company_close_pivot_graduate") | .coverage_status) = "proven"
  | .summary_counts.proven += 1
  | .summary_counts.deferred -= 1
' "$LEDGER" >"$TMP/lifecycle-proven-overclaim.json"
if "$SCRIPT" --ledger "$TMP/lifecycle-proven-overclaim.json" --json >"$TMP/lifecycle-proven-overclaim.out.json" 2>/dev/null; then
  fail "blocked lifecycle receipt rejects lifecycle proven claim"
else
  assert_jq "$TMP/lifecycle-proven-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_lifecycle_disposition_receipt" and .requirement_id == "company_close_pivot_graduate" and .expected == "deferred" and .evidence_status == "blocked")' "blocked lifecycle receipt rejects lifecycle proven claim"
fi

jq '
  (.requirements[] | select(.requirement_id == "company_close_pivot_graduate") | .coverage_status) = "blocked"
  | .summary_counts.blocked += 1
  | .summary_counts.deferred -= 1
' "$LEDGER" >"$TMP/lifecycle-underclaim.json"
if "$SCRIPT" --ledger "$TMP/lifecycle-underclaim.json" --json >"$TMP/lifecycle-underclaim.out.json" 2>/dev/null; then
  fail "blocked lifecycle receipt preserves lifecycle deferred status"
else
  assert_jq "$TMP/lifecycle-underclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_lifecycle_disposition_receipt" and .requirement_id == "company_close_pivot_graduate" and .expected == "deferred" and .evidence_status == "blocked")' "blocked lifecycle receipt preserves lifecycle deferred status"
fi

jq '(.requirements[] | select(.requirement_id == "company_close_pivot_graduate") | .evidence_refs) -= ["state/holding-company-lifecycle-disposition.json"]' "$LEDGER" >"$TMP/missing-lifecycle-disposition-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-lifecycle-disposition-ref.json" --json >"$TMP/missing-lifecycle-disposition-ref.out.json" 2>/dev/null; then
  fail "lifecycle requirement missing lifecycle-disposition ref rejected"
else
  assert_jq "$TMP/missing-lifecycle-disposition-ref.out.json" '.failures[] | select(.code == "lifecycle_requirement_missing_lifecycle_disposition_ref" and .requirement_id == "company_close_pivot_graduate")' "lifecycle requirement missing lifecycle-disposition ref rejected"
fi

jq '
  (.requirements[] | select(.requirement_id == "peel_loop") | .coverage_status) = "proven"
  | .summary_counts.proven += 1
  | .summary_counts.blocked -= 1
' "$LEDGER" >"$TMP/zero-clear-proven.json"
if "$SCRIPT" --ledger "$TMP/zero-clear-proven.json" --json >"$TMP/zero-clear-proven.out.json" 2>/dev/null; then
  fail "zero-clear primary evidence cannot support proven coverage"
else
  assert_jq "$TMP/zero-clear-proven.out.json" '.failures[] | select(.code == "proven_requirement_has_zero_clear_primary_evidence" and .requirement_id == "peel_loop")' "zero-clear primary evidence cannot support proven coverage"
fi

jq '.coverage_status = "complete"' "$LEDGER" >"$TMP/complete.json"
if "$SCRIPT" --ledger "$TMP/complete.json" --json >"$TMP/complete.out.json" 2>/dev/null; then
  fail "standing goal completion claim rejected"
else
  assert_jq "$TMP/complete.out.json" '.failures[] | select(.code == "standing_goal_cannot_be_complete")' "standing goal completion claim rejected"
fi

jq '.summary_counts.blocked = 0' "$LEDGER" >"$TMP/bad-counts.json"
if "$SCRIPT" --ledger "$TMP/bad-counts.json" --json >"$TMP/bad-counts.out.json" 2>/dev/null; then
  fail "summary count mismatch rejected"
else
  assert_jq "$TMP/bad-counts.out.json" '.failures[] | select(.code == "summary_counts_mismatch")' "summary count mismatch rejected"
fi

jq '.requirements[0].evidence_refs += ["/no/such/holding-company-evidence.json"]' "$LEDGER" >"$TMP/missing-evidence.json"
if "$SCRIPT" --ledger "$TMP/missing-evidence.json" --check-paths --json >"$TMP/missing-evidence.out.json" 2>/dev/null; then
  fail "missing evidence path rejected"
else
  assert_jq "$TMP/missing-evidence.out.json" '.failures[] | select(.code == "evidence_ref_missing")' "missing evidence path rejected"
fi

if [[ "$fail_count" -ne 0 ]]; then
  printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
