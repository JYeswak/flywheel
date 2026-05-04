#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SMOKE="$ROOT/.flywheel/scripts/validation-e2e-smoke.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/validation-e2e.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

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

bash -n "$SMOKE" && pass "B12_AG9 smoke script syntax" || fail "B12_AG9 smoke script syntax"
schema_out="$TMP/schema.json"
"$SMOKE" --schema >"$schema_out"
assert_jq "$schema_out" '.command == "validation-e2e-smoke" and .read_only_default == true and .stable_exit_codes.pass == 0' "B12_AG8 command schema documents dry-run posture"

examples_out="$TMP/examples.json"
"$SMOKE" --examples >"$examples_out"
assert_jq "$examples_out" '(.examples | length) >= 3' "B12_AG8 examples surface"

out="$TMP/smoke.json"
"$SMOKE" --receipt-dir "$TMP/receipts" --json >"$out"
assert_jq "$out" '.status == "pass" and .failed == 0 and .passed >= 10' "B12 final smoke exits pass"

final="$(jq -r '.final_receipt' "$out")"
test -f "$final" && pass "B12_AG9 final receipt exists" || fail "B12_AG9 final receipt exists"

assert_jq "$final" '.schema_version == "validation-e2e/v1" and .owner_bead == "flywheel-yasl" and .status == "pass"' "B12_AG9 final receipt schema"
for gate in B12_AG1 B12_AG2 B12_AG3 B12_AG4 B12_AG5 B12_AG6 B12_AG7 B12_AG8 B12_AG9; do
  assert_jq "$final" "any(.gates[]; .gate == \"$gate\" and .status == \"pass\")" "$gate present and passing"
done

assert_jq "$final" '.component_outputs.synthetic_dispatch | test("synthetic-dispatch.md$")' "B12_AG1 synthetic dispatch artifact recorded"
assert_jq "$final" '.component_outputs.validate_callback | test("validate-callback-missing.json$")' "B12_AG2 validator artifact recorded"
assert_jq "$final" '.component_outputs.fix_bead_dry_run | test("fix-bead-dry-run.json$")' "B12_AG3 fix-bead artifact recorded"
assert_jq "$final" '.component_outputs.doctor | test("doctor.json$")' "B12_AG3 doctor artifact recorded"
assert_jq "$final" '.validation_receipt | test("b12-missing-done-.*\\.json$")' "B12_AG2 failed validation receipt recorded"
assert_jq "$final" '(.changed_surfaces | map(.surface) | sort) == ["command","docs","doctor","learn","skill","template","tests","tick"]' "B12_AG9 changed surfaces complete"
assert_jq "$final" '(.rollout_plan | test("rollout-plan.json$"))' "B12_AG8 rollout plan recorded"

rollout="$(jq -r '.rollout_plan' "$final")"
assert_jq "$rollout" '(.rollout_modes | map(.mode)) == ["schema-only","warn-only-doctor","strict-doctor","mutating-remediation"]' "B12_AG8 staged rollout modes"

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
