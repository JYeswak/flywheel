#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/holding-company-pour-readiness-validate.py"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/holding-company-pour-readiness.schema.json"
LEDGER="$ROOT/state/holding-company-pour-readiness.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/holding-company-pour.XXXXXX")"
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
assert_jq "$TMP/current.json" '.status == "pass" and .clear_count == 0 and .launches[0].pour_gate_status == "blocked"' "current ledger validates and blocks POUR"

jq '
  .clear_count = 1
  | .launches[0].status = "pour_clear"
  | .launches[0].first_paying_customer_receipt = "urn:receipt:first-paying-customer"
  | .launches[0].owner_operator_ref = "urn:receipt:signed-owner-operator"
  | .launches[0].operating_control_handoff_ref = "urn:receipt:operating-control-handoff"
' "$LEDGER" >"$TMP/clear.json"
"$SCRIPT" --ledger "$TMP/clear.json" --json >"$TMP/clear.out.json"
assert_jq "$TMP/clear.out.json" '.status == "pass" and .clear_count == 1 and .launches[0].pour_gate_status == "clear"' "complete POUR refs clear launch"

jq '.launches[0].status = "pour_clear"' "$LEDGER" >"$TMP/clear-missing.json"
if "$SCRIPT" --ledger "$TMP/clear-missing.json" --json >"$TMP/clear-missing.out.json" 2>/dev/null; then
  fail "POUR clear missing receipts rejected"
else
  assert_jq "$TMP/clear-missing.out.json" '.status == "fail" and (.failures[] | select(.code == "clear_status_missing_pour_refs"))' "POUR clear missing receipts rejected"
fi

jq '.clear_count = 2' "$TMP/clear.json" >"$TMP/count-mismatch.json"
if "$SCRIPT" --ledger "$TMP/count-mismatch.json" --json >"$TMP/count-mismatch.out.json" 2>/dev/null; then
  fail "POUR clear count mismatch rejected"
else
  assert_jq "$TMP/count-mismatch.out.json" '.status == "fail" and (.failures[] | select(.code == "clear_count_mismatch"))' "POUR clear count mismatch rejected"
fi

printf 'RESULT pass=%d fail=%d\n' "$pass_count" "$fail_count"
exit "$fail_count"
