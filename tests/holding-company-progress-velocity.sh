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

if [[ "$fail_count" -ne 0 ]]; then
  printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
