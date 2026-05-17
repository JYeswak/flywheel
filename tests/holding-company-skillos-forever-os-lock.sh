#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/holding-company-skillos-forever-os-lock-validate.py"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/holding-company-skillos-forever-os-lock.schema.json"
LEDGER="$ROOT/state/holding-company-skillos-forever-os-lock.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/holding-company-forever-os-lock.XXXXXX")"
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
assert_jq "$TMP/current.json" '.status == "pass" and .forever_os_lock_gate_status == "partial" and .ratification_receipt_count == 3 and .structure_locked_20260517 == false' "current ledger validates as partial lock proof"

jq '
  .status = "proven"
  | .structure_locked_20260517 = true
  | .structure_lock_receipt_ref = "urn:skillos-structure-lock:20260517"
  | .structure_lock_receipt_sha256 = "sha256:owner-receipt-recorded-outside-this-fixture"
' "$LEDGER" >"$TMP/proven.json"
"$SCRIPT" --ledger "$TMP/proven.json" --json >"$TMP/proven.out.json"
assert_jq "$TMP/proven.out.json" '.status == "pass" and .forever_os_lock_gate_status == "proven"' "proven fixture clears with structure lock receipt"

jq '
  .status = "partial"
  | .claim_text = "SkillOS Forever-OS v3 ratified 2026-05-16; structure locked 2026-05-17."
  | .structure_locked_20260517 = false
  | .structure_lock_receipt_ref = null
  | .structure_lock_receipt_sha256 = null
' "$LEDGER" >"$TMP/partial-overclaim.json"
if "$SCRIPT" --ledger "$TMP/partial-overclaim.json" --json >"$TMP/partial-overclaim.out.json" 2>/dev/null; then
  fail "partial structure-lock overclaim rejected"
else
  assert_jq "$TMP/partial-overclaim.out.json" '.failures[] | select(.code == "claim_text_overstates_missing_structure_lock")' "partial structure-lock overclaim rejected"
fi

jq '.status = "proven"' "$LEDGER" >"$TMP/proven-no-lock.json"
if "$SCRIPT" --ledger "$TMP/proven-no-lock.json" --json >"$TMP/proven-no-lock.out.json" 2>/dev/null; then
  fail "proven without structure lock receipt rejected"
else
  assert_jq "$TMP/proven-no-lock.out.json" '.failures[] | select(.code == "proven_without_structure_lock_receipt")' "proven without structure lock receipt rejected"
fi

jq '.status = "proven" | .ratification_receipts = [] | .ratification_receipts_present = false' "$TMP/proven.json" >"$TMP/proven-no-ratification.json"
if "$SCRIPT" --ledger "$TMP/proven-no-ratification.json" --json >"$TMP/proven-no-ratification.out.json" 2>/dev/null; then
  fail "proven without ratification receipts rejected"
else
  assert_jq "$TMP/proven-no-ratification.out.json" '.failures[] | select(.code == "proven_without_ratification_receipts")' "proven without ratification receipts rejected"
fi

jq '.status = "proven" | .anti_punt_forbid_list_present = false' "$TMP/proven.json" >"$TMP/proven-no-anti-punt.json"
if "$SCRIPT" --ledger "$TMP/proven-no-anti-punt.json" --json >"$TMP/proven-no-anti-punt.out.json" 2>/dev/null; then
  fail "proven without anti-punt forbid list rejected"
else
  assert_jq "$TMP/proven-no-anti-punt.out.json" '.failures[] | select(.code == "proven_without_anti_punt_forbid_list")' "proven without anti-punt forbid list rejected"
fi

jq '.goal_sha256 = "0000000000000000000000000000000000000000000000000000000000000000"' "$LEDGER" >"$TMP/bad-goal-sha.json"
if "$SCRIPT" --ledger "$TMP/bad-goal-sha.json" --check-paths --json >"$TMP/bad-goal-sha.out.json" 2>/dev/null; then
  fail "goal sha mismatch rejected"
else
  assert_jq "$TMP/bad-goal-sha.out.json" '.failures[] | select(.code == "goal_sha256_mismatch")' "goal sha mismatch rejected"
fi

jq '.evidence_refs += ["/no/such/skillos-lock-evidence.json"]' "$LEDGER" >"$TMP/missing-evidence.json"
if "$SCRIPT" --ledger "$TMP/missing-evidence.json" --check-paths --json >"$TMP/missing-evidence.out.json" 2>/dev/null; then
  fail "missing evidence path rejected"
else
  assert_jq "$TMP/missing-evidence.out.json" '.failures[] | select(.code == "evidence_ref_missing")' "missing evidence path rejected"
fi

jq 'del(.gate)' "$LEDGER" >"$TMP/schema-invalid.json"
if "$SCRIPT" --ledger "$TMP/schema-invalid.json" --json >"$TMP/schema-invalid.out.json" 2>/dev/null; then
  fail "schema-invalid forever-os lock ledger rejected"
else
  assert_jq "$TMP/schema-invalid.out.json" '.failures[] | select(.code == "schema_invalid")' "schema-invalid forever-os lock ledger rejected"
fi

jq '.status = "proven" | .v3_goal_present = false' "$TMP/proven.json" >"$TMP/proven-no-v3-goal.json"
if "$SCRIPT" --ledger "$TMP/proven-no-v3-goal.json" --json >"$TMP/proven-no-v3-goal.out.json" 2>/dev/null; then
  fail "proven without v3 goal rejected"
else
  assert_jq "$TMP/proven-no-v3-goal.out.json" '.failures[] | select(.code == "proven_without_v3_goal")' "proven without v3 goal rejected"
fi

jq '.status = "proven" | .v3_scope_clarifier_present = false' "$TMP/proven.json" >"$TMP/proven-no-scope.json"
if "$SCRIPT" --ledger "$TMP/proven-no-scope.json" --json >"$TMP/proven-no-scope.out.json" 2>/dev/null; then
  fail "proven without v3 scope clarifier rejected"
else
  assert_jq "$TMP/proven-no-scope.out.json" '.failures[] | select(.code == "proven_without_scope_clarifier")' "proven without v3 scope clarifier rejected"
fi

jq '.ratification_receipts_present = false' "$LEDGER" >"$TMP/receipt-mismatch.json"
if "$SCRIPT" --ledger "$TMP/receipt-mismatch.json" --json >"$TMP/receipt-mismatch.out.json" 2>/dev/null; then
  fail "ratification receipts present mismatch rejected"
else
  assert_jq "$TMP/receipt-mismatch.out.json" '.failures[] | select(.code == "ratification_receipts_present_mismatch")' "ratification receipts present mismatch rejected"
fi

jq '.inspected_paths += ["/no/such/skillos-inspected-path"]' "$LEDGER" >"$TMP/missing-inspected-path.json"
if "$SCRIPT" --ledger "$TMP/missing-inspected-path.json" --check-paths --json >"$TMP/missing-inspected-path.out.json" 2>/dev/null; then
  fail "missing inspected path rejected"
else
  assert_jq "$TMP/missing-inspected-path.out.json" '.failures[] | select(.code == "inspected_path_missing")' "missing inspected path rejected"
fi

jq '.notes += ["fixture sk-TestSecret123 should be rejected"]' "$LEDGER" >"$TMP/secret-shape.json"
if "$SCRIPT" --ledger "$TMP/secret-shape.json" --json >"$TMP/secret-shape.out.json" 2>/dev/null; then
  fail "secret-shaped forever-os lock value rejected"
else
  assert_jq "$TMP/secret-shape.out.json" '.failures[] | select(.code == "secret_or_raw_value_shape_detected")' "secret-shaped forever-os lock value rejected"
fi

if [[ "$fail_count" -ne 0 ]]; then
  printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
