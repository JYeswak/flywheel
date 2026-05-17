#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/holding-company-progress-velocity-validate.py"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/holding-company-progress-velocity.schema.json"
LEDGER="$ROOT/state/holding-company-progress-velocity.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/holding-company-progress-velocity.XXXXXX")"
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
assert_jq "$TMP/current.json" '.status == "pass" and .progress_velocity_gate_status == "blocked" and .computed_total_commit_count == 3755 and .surface_count == 9' "current ledger validates and blocks 4000 claim"

jq '
  .status = "proven"
  | .exact_surface_set_established = true
  | .measured_total_commit_count = 4000
  | .surface_counts[7].commit_count = 245
' "$LEDGER" >"$TMP/proven.json"
"$SCRIPT" --ledger "$TMP/proven.json" --json >"$TMP/proven.out.json"
assert_jq "$TMP/proven.out.json" '.status == "pass" and .progress_velocity_gate_status == "proven" and .computed_total_commit_count == 4000' "exact nine-surface 4000 count proves gate"

jq '
  .status = "blocked"
  | .claim_text = "4,000+ commits in 7 days across 9 product surfaces"
  | .measured_total_commit_count = 3755
' "$LEDGER" >"$TMP/blocked-overclaim.json"
if "$SCRIPT" --ledger "$TMP/blocked-overclaim.json" --json >"$TMP/blocked-overclaim.out.json" 2>/dev/null; then
  fail "blocked under-target 4000+ overclaim rejected"
else
  assert_jq "$TMP/blocked-overclaim.out.json" '.failures[] | select(.code == "claim_text_overstates_under_target_velocity")' "blocked under-target 4000+ overclaim rejected"
fi

jq '.status = "proven" | .exact_surface_set_established = false' "$TMP/proven.json" >"$TMP/no-exact.json"
if "$SCRIPT" --ledger "$TMP/no-exact.json" --json >"$TMP/no-exact.out.json" 2>/dev/null; then
  fail "proven without exact surface set rejected"
else
  assert_jq "$TMP/no-exact.out.json" '.failures[] | select(.code == "proven_without_exact_surface_set")' "proven without exact surface set rejected"
fi

jq '.status = "proven" | .exact_surface_set_established = true | .measured_total_commit_count = 3999 | .surface_counts[7].commit_count = 244' "$LEDGER" >"$TMP/below-target.json"
if "$SCRIPT" --ledger "$TMP/below-target.json" --json >"$TMP/below-target.out.json" 2>/dev/null; then
  fail "proven below 4000 rejected"
else
  assert_jq "$TMP/below-target.out.json" '.failures[] | select(.code == "proven_below_target_commits")' "proven below 4000 rejected"
fi

jq '.measured_total_commit_count = 1' "$LEDGER" >"$TMP/bad-total.json"
if "$SCRIPT" --ledger "$TMP/bad-total.json" --json >"$TMP/bad-total.out.json" 2>/dev/null; then
  fail "total mismatch rejected"
else
  assert_jq "$TMP/bad-total.out.json" '.failures[] | select(.code == "commit_total_mismatch")' "total mismatch rejected"
fi

jq 'del(.gate)' "$LEDGER" >"$TMP/schema-invalid.json"
if "$SCRIPT" --ledger "$TMP/schema-invalid.json" --json >"$TMP/schema-invalid.out.json" 2>/dev/null; then
  fail "schema-invalid progress velocity ledger rejected"
else
  assert_jq "$TMP/schema-invalid.out.json" '.failures[] | select(.code == "schema_invalid")' "schema-invalid progress velocity ledger rejected"
fi

jq '.surface_counts += [.surface_counts[0]] | .target_surface_count = 10 | .measured_total_commit_count = (.measured_total_commit_count + .surface_counts[0].commit_count)' "$LEDGER" >"$TMP/duplicate-surface.json"
if "$SCRIPT" --ledger "$TMP/duplicate-surface.json" --json >"$TMP/duplicate-surface.out.json" 2>/dev/null; then
  fail "duplicate progress surface rejected"
else
  assert_jq "$TMP/duplicate-surface.out.json" '.failures[] | select(.code == "duplicate_surface_id")' "duplicate progress surface rejected"
fi

jq '.target_surface_count = 8' "$LEDGER" >"$TMP/surface-count-mismatch.json"
if "$SCRIPT" --ledger "$TMP/surface-count-mismatch.json" --json >"$TMP/surface-count-mismatch.out.json" 2>/dev/null; then
  fail "surface count mismatch rejected"
else
  assert_jq "$TMP/surface-count-mismatch.out.json" '.failures[] | select(.code == "surface_count_mismatch")' "surface count mismatch rejected"
fi

jq '.target_window_days = 8' "$LEDGER" >"$TMP/window-days-mismatch.json"
if "$SCRIPT" --ledger "$TMP/window-days-mismatch.json" --json >"$TMP/window-days-mismatch.out.json" 2>/dev/null; then
  fail "window days mismatch rejected"
else
  assert_jq "$TMP/window-days-mismatch.out.json" '.failures[] | select(.code == "window_days_mismatch")' "window days mismatch rejected"
fi

jq '.window_end = "not-a-timestamp"' "$LEDGER" >"$TMP/window-parse-failed.json"
if "$SCRIPT" --ledger "$TMP/window-parse-failed.json" --json >"$TMP/window-parse-failed.out.json" 2>/dev/null; then
  fail "window parse failure rejected"
else
  assert_jq "$TMP/window-parse-failed.out.json" '.failures[] | select(.code == "window_parse_failed")' "window parse failure rejected"
fi

jq '.status = "proven" | .exact_surface_set_established = true | .measured_total_commit_count = 4000 | .surface_counts[0].commit_count = 0 | .surface_counts[7].commit_count = 1132' "$LEDGER" >"$TMP/zero-surface.json"
if "$SCRIPT" --ledger "$TMP/zero-surface.json" --json >"$TMP/zero-surface.out.json" 2>/dev/null; then
  fail "proven with zero-commit surface rejected"
else
  assert_jq "$TMP/zero-surface.out.json" '.failures[] | select(.code == "proven_surface_zero_commits")' "proven with zero-commit surface rejected"
fi

jq '.surface_counts[0].repo_path = "/no/such/progress-velocity-repo"' "$LEDGER" >"$TMP/missing-surface-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-surface-ref.json" --check-paths --json >"$TMP/missing-surface-ref.out.json" 2>/dev/null; then
  fail "missing progress surface ref rejected"
else
  assert_jq "$TMP/missing-surface-ref.out.json" '.failures[] | select(.code == "ref_missing" and .field == "repo_path")' "missing progress surface ref rejected"
fi

jq '.evidence_refs = ["state/does-not-exist-progress-velocity-evidence.json"]' "$LEDGER" >"$TMP/missing-evidence-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-evidence-ref.json" --check-paths --json >"$TMP/missing-evidence-ref.out.json" 2>/dev/null; then
  fail "missing progress evidence ref rejected"
else
  assert_jq "$TMP/missing-evidence-ref.out.json" '.failures[] | select(.code == "evidence_ref_missing")' "missing progress evidence ref rejected"
fi

jq '.notes += ["fixture sk-TestSecret123 should be rejected"]' "$LEDGER" >"$TMP/secret-shape.json"
if "$SCRIPT" --ledger "$TMP/secret-shape.json" --json >"$TMP/secret-shape.out.json" 2>/dev/null; then
  fail "secret-shaped progress value rejected"
else
  assert_jq "$TMP/secret-shape.out.json" '.failures[] | select(.code == "secret_shape_detected")' "secret-shaped progress value rejected"
fi

if [[ "$fail_count" -ne 0 ]]; then
  printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
