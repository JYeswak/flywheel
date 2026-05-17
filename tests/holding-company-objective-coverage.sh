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
  assert_jq "$TMP/recent-progress-overclaim.out.json" '.failures[] | select(.code == "requirement_status_mismatch_with_claim_honesty" and .requirement_id == "recent_progress_velocity_claim" and .evidence_status == "blocked")' "recent-progress requirement status overclaim rejected"
fi

jq '(.requirements[] | select(.requirement_id == "recent_mobile_eats_shipping_claim") | .evidence_refs) -= ["state/holding-company-recent-progress-claim-honesty-20260517T1017Z.json"]' "$LEDGER" >"$TMP/missing-claim-honesty-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-claim-honesty-ref.json" --json >"$TMP/missing-claim-honesty-ref.out.json" 2>/dev/null; then
  fail "recent-progress missing claim-honesty ref rejected"
else
  assert_jq "$TMP/missing-claim-honesty-ref.out.json" '.failures[] | select(.code == "recent_progress_requirement_missing_claim_honesty_ref" and .requirement_id == "recent_mobile_eats_shipping_claim")' "recent-progress missing claim-honesty ref rejected"
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

jq '(.requirements[] | select(.requirement_id == "one_year_small_portfolio_making_money") | .evidence_refs) -= ["state/zeststream-portfolio-company-registry.json"]' "$LEDGER" >"$TMP/missing-registry-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-registry-ref.json" --json >"$TMP/missing-registry-ref.out.json" 2>/dev/null; then
  fail "portfolio requirement missing registry ref rejected"
else
  assert_jq "$TMP/missing-registry-ref.out.json" '.failures[] | select(.code == "portfolio_requirement_missing_registry_ref" and .requirement_id == "one_year_small_portfolio_making_money")' "portfolio requirement missing registry ref rejected"
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
