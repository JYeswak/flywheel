#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/holding-company-public-surface-audit-supersession-validate.py"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/holding-company-public-surface-audit-supersession.schema.json"
RECEIPT="$ROOT/state/holding-company-public-surface-audit-supersession-20260517T1004Z.json"
COVERAGE="$ROOT/state/holding-company-objective-coverage.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/holding-company-public-surface.XXXXXX")"
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

assert_eq() {
  local actual="$1" expected="$2" label="$3"
  if [[ "$actual" == "$expected" ]]; then
    pass "$label"
  else
    fail "$label"
    printf 'actual: %s\nexpected: %s\n' "$actual" "$expected" >&2
  fi
}

jq empty "$RECEIPT" && pass "receipt json valid" || fail "receipt json valid"
jq empty "$SCHEMA" && pass "schema json valid" || fail "schema json valid"
if python3 -m py_compile "$SCRIPT"; then
  pass "validator py_compile"
else
  fail "validator py_compile"
fi

"$SCRIPT" --receipt "$RECEIPT" --coverage "$COVERAGE" --check-paths --json >"$TMP/current.json"
assert_jq "$TMP/current.json" '.status == "pass" and .public_surface_supersession_status == "clear_surfaces_objective_incomplete" and .superseded_findings_count == 7' "validator accepts current supersession receipt"
assert_jq "$TMP/current.json" '.anti_pitch_receipt_ref_count == 3 and .public_story_receipt_ref_count == 3' "validator exposes supersession evidence ref counts"

assert_jq "$RECEIPT" '.schema_version == "zeststream.holding_company_public_surface_audit_supersession.v1" and (.superseded_findings | length == 7)' "receipt declares seven superseded findings"
assert_jq "$RECEIPT" '.current_status.anti_pitch_voice_surface_status == "clear" and .current_status.public_story_surface_status == "clear" and .current_status.objective_coverage_status == "not_complete"' "receipt distinguishes clear surfaces from incomplete objective"

jq 'del(.source_goal)' "$RECEIPT" >"$TMP/schema-invalid.json"
if "$SCRIPT" --receipt "$TMP/schema-invalid.json" --coverage "$COVERAGE" --json >"$TMP/schema-invalid.out.json" 2>/dev/null; then
  fail "schema-invalid supersession receipt rejected"
else
  assert_jq "$TMP/schema-invalid.out.json" '.failures[] | select(.code == "schema_invalid")' "schema-invalid supersession receipt rejected"
fi

jq '.schema_version = "zeststream.holding_company_public_surface_audit_supersession.v0"' "$RECEIPT" >"$TMP/unexpected-schema-version.json"
if "$SCRIPT" --receipt "$TMP/unexpected-schema-version.json" --coverage "$COVERAGE" --json >"$TMP/unexpected-schema-version.out.json" 2>/dev/null; then
  fail "unexpected supersession schema version rejected"
else
  assert_jq "$TMP/unexpected-schema-version.out.json" '.failures[] | select(.code == "unexpected_schema_version")' "unexpected supersession schema version rejected"
fi

jq '.source_goal = "temporary public surface cleanup"' "$RECEIPT" >"$TMP/unexpected-source-goal.json"
if "$SCRIPT" --receipt "$TMP/unexpected-source-goal.json" --coverage "$COVERAGE" --json >"$TMP/unexpected-source-goal.out.json" 2>/dev/null; then
  fail "unexpected supersession source goal rejected"
else
  assert_jq "$TMP/unexpected-source-goal.out.json" '.failures[] | select(.code == "unexpected_source_goal")' "unexpected supersession source goal rejected"
fi

jq '.notes += [("sk-" + "NOTAREALSECRET")]' "$RECEIPT" >"$TMP/secret-shaped-value.json"
if "$SCRIPT" --receipt "$TMP/secret-shaped-value.json" --coverage "$COVERAGE" --json >"$TMP/secret-shaped-value.out.json" 2>/dev/null; then
  fail "secret-shaped supersession value rejected"
else
  assert_jq "$TMP/secret-shaped-value.out.json" '.failures[] | select(.code == "secret_or_raw_value_shape_detected")' "secret-shaped supersession value rejected"
fi

jq '.superseded_findings |= .[0:6]' "$RECEIPT" >"$TMP/superseded-count-mismatch.json"
if "$SCRIPT" --receipt "$TMP/superseded-count-mismatch.json" --coverage "$COVERAGE" --json >"$TMP/superseded-count-mismatch.out.json" 2>/dev/null; then
  fail "superseded finding count mismatch rejected"
else
  assert_jq "$TMP/superseded-count-mismatch.out.json" '.failures[] | select(.code == "superseded_findings_count_mismatch")' "superseded finding count mismatch rejected"
fi

jq '.current_status.anti_pitch_voice_surface_status = "blocked"' "$RECEIPT" >"$TMP/anti-pitch-not-clear.json"
if "$SCRIPT" --receipt "$TMP/anti-pitch-not-clear.json" --coverage "$COVERAGE" --json >"$TMP/anti-pitch-not-clear.out.json" 2>/dev/null; then
  fail "anti-pitch surface not-clear status rejected"
else
  assert_jq "$TMP/anti-pitch-not-clear.out.json" '.failures[] | select(.code == "anti_pitch_voice_surface_not_clear")' "anti-pitch surface not-clear status rejected"
fi

jq '.current_status.public_story_surface_status = "blocked"' "$RECEIPT" >"$TMP/public-story-not-clear.json"
if "$SCRIPT" --receipt "$TMP/public-story-not-clear.json" --coverage "$COVERAGE" --json >"$TMP/public-story-not-clear.out.json" 2>/dev/null; then
  fail "public-story surface not-clear status rejected"
else
  assert_jq "$TMP/public-story-not-clear.out.json" '.failures[] | select(.code == "public_story_surface_not_clear")' "public-story surface not-clear status rejected"
fi

jq '.current_status.objective_coverage_status = "complete"' "$RECEIPT" >"$TMP/objective-marked-complete.json"
if "$SCRIPT" --receipt "$TMP/objective-marked-complete.json" --coverage "$COVERAGE" --json >"$TMP/objective-marked-complete.out.json" 2>/dev/null; then
  fail "objective coverage complete overclaim rejected"
else
  assert_jq "$TMP/objective-marked-complete.out.json" '.failures[] | select(.code == "objective_coverage_not_marked_incomplete")' "objective coverage complete overclaim rejected"
fi

jq '.notes = []' "$RECEIPT" >"$TMP/missing-preservation-note.json"
if "$SCRIPT" --receipt "$TMP/missing-preservation-note.json" --coverage "$COVERAGE" --json >"$TMP/missing-preservation-note.out.json" 2>/dev/null; then
  fail "missing historical audit preservation note rejected"
else
  assert_jq "$TMP/missing-preservation-note.out.json" '.failures[] | select(.code == "historical_audit_preservation_note_missing")' "missing historical audit preservation note rejected"
fi

while IFS= read -r relpath; do
  if [[ -f "$ROOT/$relpath" ]]; then
    pass "referenced path exists: $relpath"
  else
    fail "referenced path exists: $relpath"
  fi
done < <(jq -r '.supersedes_audit_ref, .current_receipts[]' "$RECEIPT")

jq -S '.current_status.objective_counts_unchanged' "$RECEIPT" >"$TMP/receipt-counts.json"
jq -S '.summary_counts' "$COVERAGE" >"$TMP/coverage-counts.json"
if cmp -s "$TMP/receipt-counts.json" "$TMP/coverage-counts.json"; then
  pass "objective counts snapshot matches coverage matrix"
else
  fail "objective counts snapshot matches coverage matrix"
  diff -u "$TMP/coverage-counts.json" "$TMP/receipt-counts.json" >&2 || true
fi

anti_pitch_refs="$(jq '[.current_receipts[] | select(test("anti-pitch|historical-builder"))] | length' "$RECEIPT")"
public_story_refs="$(jq '[.current_receipts[] | select(test("public-story|objective-coverage"))] | length' "$RECEIPT")"
assert_eq "$anti_pitch_refs" "3" "anti-pitch supersession evidence refs present"
assert_eq "$public_story_refs" "3" "public-story supersession evidence refs present"

if jq -e 'any(.notes[]; contains("does not rewrite the 06:46 audit"))' "$RECEIPT" >/dev/null; then
  pass "receipt preserves historical audit rather than rewriting it"
else
  fail "receipt preserves historical audit rather than rewriting it"
fi

jq '.current_status.objective_counts_unchanged.blocked = 0' "$RECEIPT" >"$TMP/bad-counts.json"
if "$SCRIPT" --receipt "$TMP/bad-counts.json" --coverage "$COVERAGE" --json >"$TMP/bad-counts.out.json" 2>/dev/null; then
  fail "objective count snapshot mismatch rejected"
else
  assert_jq "$TMP/bad-counts.out.json" '.failures[] | select(.code == "objective_counts_snapshot_mismatch")' "objective count snapshot mismatch rejected"
fi

jq '.current_receipts -= ["state/holding-company-anti-pitch-voice.json"]' "$RECEIPT" >"$TMP/missing-anti-pitch-ref.json"
if "$SCRIPT" --receipt "$TMP/missing-anti-pitch-ref.json" --coverage "$COVERAGE" --json >"$TMP/missing-anti-pitch-ref.out.json" 2>/dev/null; then
  fail "missing anti-pitch supersession ref rejected"
else
  assert_jq "$TMP/missing-anti-pitch-ref.out.json" '.failures[] | select(.code == "anti_pitch_supersession_evidence_ref_count_mismatch")' "missing anti-pitch supersession ref rejected"
fi

jq '.current_receipts -= ["state/holding-company-public-story.json"]' "$RECEIPT" >"$TMP/missing-public-story-ref.json"
if "$SCRIPT" --receipt "$TMP/missing-public-story-ref.json" --coverage "$COVERAGE" --json >"$TMP/missing-public-story-ref.out.json" 2>/dev/null; then
  fail "missing public-story supersession ref rejected"
else
  assert_jq "$TMP/missing-public-story-ref.out.json" '.failures[] | select(.code == "public_story_supersession_evidence_ref_count_mismatch")' "missing public-story supersession ref rejected"
fi

jq '.supersedes_audit_ref = "state/no-such-holding-company-audit.json"' "$RECEIPT" >"$TMP/missing-supersedes-audit-ref.json"
if "$SCRIPT" --receipt "$TMP/missing-supersedes-audit-ref.json" --coverage "$COVERAGE" --check-paths --json >"$TMP/missing-supersedes-audit-ref.out.json" 2>/dev/null; then
  fail "missing superseded audit ref rejected"
else
  assert_jq "$TMP/missing-supersedes-audit-ref.out.json" '.failures[] | select(.code == "supersedes_audit_ref_missing")' "missing superseded audit ref rejected"
fi

jq '.current_receipts += ["state/no-such-public-surface-receipt.json"]' "$RECEIPT" >"$TMP/missing-ref.json"
if "$SCRIPT" --receipt "$TMP/missing-ref.json" --coverage "$COVERAGE" --check-paths --json >"$TMP/missing-ref.out.json" 2>/dev/null; then
  fail "missing current receipt ref rejected"
else
  assert_jq "$TMP/missing-ref.out.json" '.failures[] | select(.code == "current_receipt_ref_missing")' "missing current receipt ref rejected"
fi

if [[ "$fail_count" -ne 0 ]]; then
  printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
