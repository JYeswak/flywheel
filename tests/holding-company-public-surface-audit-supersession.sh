#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
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
python3 - "$SCHEMA" "$RECEIPT" <<'PY' && pass "receipt validates against schema" || fail "receipt validates against schema"
import json
import sys

from jsonschema import Draft202012Validator, FormatChecker

schema_path, receipt_path = sys.argv[1], sys.argv[2]
with open(schema_path, encoding="utf-8") as handle:
    schema = json.load(handle)
with open(receipt_path, encoding="utf-8") as handle:
    receipt = json.load(handle)

Draft202012Validator.check_schema(schema)
Draft202012Validator(schema, format_checker=FormatChecker()).validate(receipt)
PY

assert_jq "$RECEIPT" '.schema_version == "zeststream.holding_company_public_surface_audit_supersession.v1" and (.superseded_findings | length == 7)' "receipt declares seven superseded findings"
assert_jq "$RECEIPT" '.current_status.anti_pitch_voice_surface_status == "clear" and .current_status.public_story_surface_status == "clear" and .current_status.objective_coverage_status == "not_complete"' "receipt distinguishes clear surfaces from incomplete objective"

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

if [[ "$fail_count" -ne 0 ]]; then
  printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
