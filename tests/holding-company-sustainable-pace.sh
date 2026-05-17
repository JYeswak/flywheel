#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/holding-company-sustainable-pace-validate.py"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/holding-company-sustainable-pace.schema.json"
LEDGER="$ROOT/state/holding-company-sustainable-pace.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/holding-company-sustainable-pace.XXXXXX")"
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
assert_jq "$TMP/current.json" '.status == "pass" and .pace_clear_count == 0 and .periods[0].pace_gate_status == "blocked"' "current ledger validates and blocks sustainable pace claim"

jq '.pace_clear_count = 1 | .periods[0].lifecycle_year = 2 | .periods[0].measurement_status = "measured_clear" | .periods[0].weekly_hours_total = 55 | .periods[0].coaching_hours_manual = 20 | .periods[0].coaching_hours_offset_by_substrate = 25 | .periods[0].substrate_offset_ratio = 0.5555555556' "$LEDGER" >"$TMP/clear.json"
"$SCRIPT" --ledger "$TMP/clear.json" --json >"$TMP/clear.out.json"
assert_jq "$TMP/clear.out.json" '.status == "pass" and .pace_clear_count == 1 and .periods[0].pace_gate_status == "clear"' "year 2 hours and offset clear gate"

jq '.periods[0].weekly_hours_total = 61 | .pace_clear_count = 0' "$TMP/clear.json" >"$TMP/over-hours.json"
if "$SCRIPT" --ledger "$TMP/over-hours.json" --json >"$TMP/over-hours.out.json" 2>/dev/null; then
  fail "year 2 hours over cap rejected"
else
  assert_jq "$TMP/over-hours.out.json" '.status == "fail" and (.failures[] | select(.code == "year2_weekly_hours_over_cap"))' "year 2 hours over cap rejected"
fi

jq '.periods[0].coaching_hours_manual = 30 | .periods[0].coaching_hours_offset_by_substrate = 20 | .periods[0].substrate_offset_ratio = 0.4 | .pace_clear_count = 0' "$TMP/clear.json" >"$TMP/low-offset.json"
if "$SCRIPT" --ledger "$TMP/low-offset.json" --json >"$TMP/low-offset.out.json" 2>/dev/null; then
  fail "year 2 offset below 50 percent rejected"
else
  assert_jq "$TMP/low-offset.out.json" '.status == "fail" and (.failures[] | select(.code == "year2_substrate_offset_below_required"))' "year 2 offset below 50 percent rejected"
fi

jq '.periods[0].substrate_offset_ratio = 0.9 | .pace_clear_count = 0' "$TMP/clear.json" >"$TMP/ratio-mismatch.json"
if "$SCRIPT" --ledger "$TMP/ratio-mismatch.json" --json >"$TMP/ratio-mismatch.out.json" 2>/dev/null; then
  fail "ratio mismatch rejected"
else
  assert_jq "$TMP/ratio-mismatch.out.json" '.status == "fail" and (.failures[] | select(.code == "substrate_offset_ratio_mismatch"))' "ratio mismatch rejected"
fi

jq '.pace_clear_count = 2' "$TMP/clear.json" >"$TMP/count-mismatch.json"
if "$SCRIPT" --ledger "$TMP/count-mismatch.json" --json >"$TMP/count-mismatch.out.json" 2>/dev/null; then
  fail "pace clear count mismatch rejected"
else
  assert_jq "$TMP/count-mismatch.out.json" '.status == "fail" and (.failures[] | select(.code == "pace_clear_count_mismatch"))' "pace clear count mismatch rejected"
fi

jq 'del(.gate)' "$LEDGER" >"$TMP/schema-invalid.json"
if "$SCRIPT" --ledger "$TMP/schema-invalid.json" --json >"$TMP/schema-invalid.out.json" 2>/dev/null; then
  fail "schema-invalid sustainable pace ledger rejected"
else
  assert_jq "$TMP/schema-invalid.out.json" '.status == "fail" and (.failures[] | select(.code == "schema_invalid"))' "schema-invalid sustainable pace ledger rejected"
fi

jq '.periods[0].measurement_status = "measured_fail" | .periods[0].weekly_hours_total = null | .pace_clear_count = 0' "$TMP/clear.json" >"$TMP/incomplete-metrics.json"
if "$SCRIPT" --ledger "$TMP/incomplete-metrics.json" --json >"$TMP/incomplete-metrics.out.json" 2>/dev/null; then
  fail "measured status without complete metrics rejected"
else
  assert_jq "$TMP/incomplete-metrics.out.json" '.status == "fail" and (.failures[] | select(.code == "measured_status_without_complete_metrics"))' "measured status without complete metrics rejected"
fi

jq '
  .periods[0].coaching_hours_manual = 0
  | .periods[0].coaching_hours_offset_by_substrate = 0
  | .periods[0].substrate_offset_ratio = 0
  | .periods[0].measurement_status = "baseline"
  | .pace_clear_count = 0
' "$TMP/clear.json" >"$TMP/ratio-not-computable.json"
if "$SCRIPT" --ledger "$TMP/ratio-not-computable.json" --json >"$TMP/ratio-not-computable.out.json" 2>/dev/null; then
  fail "non-computable substrate offset ratio rejected"
else
  assert_jq "$TMP/ratio-not-computable.out.json" '.status == "fail" and (.failures[] | select(.code == "substrate_offset_ratio_not_computable"))' "non-computable substrate offset ratio rejected"
fi

jq '.periods[0].lifecycle_year = 1 | .pace_clear_count = 0' "$TMP/clear.json" >"$TMP/year1-clear.json"
if "$SCRIPT" --ledger "$TMP/year1-clear.json" --json >"$TMP/year1-clear.out.json" 2>/dev/null; then
  fail "measured clear before sustainable pace rejected"
else
  assert_jq "$TMP/year1-clear.out.json" '.status == "fail" and (.failures[] | select(.code == "measured_clear_without_sustainable_pace"))' "measured clear before sustainable pace rejected"
fi

jq '.periods[0].evidence_refs = ["state/does-not-exist-sustainable-pace-evidence.json"] | .pace_clear_count = 0' "$TMP/clear.json" >"$TMP/missing-evidence-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-evidence-ref.json" --check-paths --json >"$TMP/missing-evidence-ref.out.json" 2>/dev/null; then
  fail "missing sustainable pace evidence ref rejected"
else
  assert_jq "$TMP/missing-evidence-ref.out.json" '.status == "fail" and (.failures[] | select(.code == "evidence_ref_missing"))' "missing sustainable pace evidence ref rejected"
fi

jq '.periods[0].notes = "fixture sk-TestSecret123 should be rejected" | .pace_clear_count = 0' "$TMP/clear.json" >"$TMP/secret-shape.json"
if "$SCRIPT" --ledger "$TMP/secret-shape.json" --json >"$TMP/secret-shape.out.json" 2>/dev/null; then
  fail "secret-shaped sustainable pace value rejected"
else
  assert_jq "$TMP/secret-shape.out.json" '.status == "fail" and (.failures[] | select(.code == "secret_or_raw_amount_shape_detected"))' "secret-shaped sustainable pace value rejected"
fi

printf 'RESULT pass=%d fail=%d\n' "$pass_count" "$fail_count"
exit "$fail_count"
