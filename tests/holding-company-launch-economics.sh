#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/holding-company-launch-economics-validate.py"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/holding-company-launch-economics.schema.json"
LEDGER="$ROOT/state/holding-company-launch-economics.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/holding-company-launch-economics.XXXXXX")"
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
assert_jq "$TMP/current.json" '.status == "pass" and .measurement_status == "baseline" and .launch_count == 1' "current baseline ledger passes without N+1 claim"

jq '.measurement_status = "measured_pass"' "$LEDGER" >"$TMP/one-row-measured.json"
if "$SCRIPT" --ledger "$TMP/one-row-measured.json" --json >"$TMP/one-row-measured.out.json" 2>/dev/null; then
  fail "one-row measured pass rejected"
else
  assert_jq "$TMP/one-row-measured.out.json" '.status == "fail" and (.failures[] | select(.code == "measured_status_without_two_launches"))' "one-row measured pass rejected"
fi

jq '.measurement_status = "measured_pass" | .launches[0].peel_hours = 20 | .launches[0].press_build_hours = 80 | .launches += [{
  "launch_id":"fixture-second-launch",
  "company_slug":"fixture-co",
  "sequence":2,
  "status":"launched",
  "peel_interview_count":5,
  "peel_hours":10,
  "press_build_hours":60,
  "reused_package_count":30,
  "new_substrate_contribution_count":2,
  "downstream_propagation_window_days":14,
  "substrate_share_receipt":"fixture://substrate-share",
  "evidence_refs":["fixture://launch-evidence"]
}]' "$LEDGER" >"$TMP/two-row-pass.json"
"$SCRIPT" --ledger "$TMP/two-row-pass.json" --json >"$TMP/two-row-pass.out.json"
assert_jq "$TMP/two-row-pass.out.json" '.status == "pass" and .measurement_status == "measured_pass" and .measured_pairs[0].cheaper == true' "two-row cheaper pass accepted"

jq '.launches[1].press_build_hours = 95 | .launches[1].reused_package_count = 20' "$TMP/two-row-pass.json" >"$TMP/two-row-false-pass.json"
if "$SCRIPT" --ledger "$TMP/two-row-false-pass.json" --json >"$TMP/two-row-false-pass.out.json" 2>/dev/null; then
  fail "false measured pass rejected"
else
  assert_jq "$TMP/two-row-false-pass.out.json" '.status == "fail" and (.failures[] | select(.code == "measured_pass_without_cheaper_pair"))' "false measured pass rejected"
fi

jq 'del(.gate)' "$LEDGER" >"$TMP/schema-invalid.json"
if "$SCRIPT" --ledger "$TMP/schema-invalid.json" --json >"$TMP/schema-invalid.out.json" 2>/dev/null; then
  fail "schema-invalid ledger rejected"
else
  assert_jq "$TMP/schema-invalid.out.json" '.status == "fail" and (.failures[] | select(.code == "schema_invalid"))' "schema-invalid ledger rejected"
fi

jq '.launches[0].sequence = 2' "$LEDGER" >"$TMP/sequence-gap.json"
if "$SCRIPT" --ledger "$TMP/sequence-gap.json" --json >"$TMP/sequence-gap.out.json" 2>/dev/null; then
  fail "sequence gap rejected"
else
  assert_jq "$TMP/sequence-gap.out.json" '.status == "fail" and (.failures[] | select(.code == "sequence_gap_or_duplicate"))' "sequence gap rejected"
fi

jq '.measurement_status = "baseline"' "$TMP/two-row-pass.json" >"$TMP/baseline-multiple.json"
if "$SCRIPT" --ledger "$TMP/baseline-multiple.json" --json >"$TMP/baseline-multiple.out.json" 2>/dev/null; then
  fail "baseline with multiple launches rejected"
else
  assert_jq "$TMP/baseline-multiple.out.json" '.status == "fail" and (.failures[] | select(.code == "baseline_status_with_multiple_launches"))' "baseline with multiple launches rejected"
fi

jq '.measurement_status = "measured_fail"' "$TMP/two-row-pass.json" >"$TMP/measured-fail-cheaper.json"
if "$SCRIPT" --ledger "$TMP/measured-fail-cheaper.json" --json >"$TMP/measured-fail-cheaper.out.json" 2>/dev/null; then
  fail "measured fail with cheaper pair rejected"
else
  assert_jq "$TMP/measured-fail-cheaper.out.json" '.status == "fail" and (.failures[] | select(.code == "measured_fail_but_cheaper_pair_exists"))' "measured fail with cheaper pair rejected"
fi

jq '.launches[0].substrate_share_receipt = "state/does-not-exist-launch-economics.json"' "$LEDGER" >"$TMP/missing-path.json"
if "$SCRIPT" --ledger "$TMP/missing-path.json" --check-paths --json >"$TMP/missing-path.out.json" 2>/dev/null; then
  fail "missing substrate path rejected"
else
  assert_jq "$TMP/missing-path.out.json" '.status == "fail" and (.failures[] | select(.code | startswith("path_missing:")))' "missing substrate path rejected"
fi

jq '.launches[0].evidence_refs = ["state/does-not-exist-launch-evidence.json"]' "$LEDGER" >"$TMP/missing-evidence.json"
if "$SCRIPT" --ledger "$TMP/missing-evidence.json" --check-paths --json >"$TMP/missing-evidence.out.json" 2>/dev/null; then
  fail "missing evidence ref rejected"
else
  assert_jq "$TMP/missing-evidence.out.json" '.status == "fail" and (.failures[] | select(.code == "evidence_ref_missing"))' "missing evidence ref rejected"
fi

printf 'RESULT pass=%d fail=%d\n' "$pass_count" "$fail_count"
exit "$fail_count"
