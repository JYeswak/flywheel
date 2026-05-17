#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/holding-company-recycle-loop-validate.py"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/holding-company-recycle-loop.schema.json"
LEDGER="$ROOT/state/holding-company-recycle-loop.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/holding-company-recycle-loop.XXXXXX")"
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
assert_jq "$TMP/current.json" '.status == "pass" and .clear_count == 0 and .friction_items[0].recycle_gate_status == "blocked"' "current ledger validates and blocks RECYCLE"

jq '
  .clear_count = 1
  | .friction_items[0].status = "propagated"
  | .friction_items[0].friction_receipt_ref = "urn:friction:mobile-eats"
  | .friction_items[0].skillos_capability_ref = "urn:skillos-capability:mobile-eats"
  | .friction_items[0].package_or_substrate_ref = "urn:zeststream-package:mobile-eats"
  | .friction_items[0].portfolio_propagation_ref = "urn:portfolio-propagation:mobile-eats"
  | .friction_items[0].propagation_window_days = 14
' "$LEDGER" >"$TMP/propagated.json"
"$SCRIPT" --ledger "$TMP/propagated.json" --json >"$TMP/propagated.out.json"
assert_jq "$TMP/propagated.out.json" '.status == "pass" and .clear_count == 1 and .friction_items[0].recycle_gate_status == "clear"' "propagated friction with capability and package refs clears"

jq '.friction_items[0].skillos_capability_ref = null | .clear_count = 0' "$TMP/propagated.json" >"$TMP/missing-capability.json"
if "$SCRIPT" --ledger "$TMP/missing-capability.json" --json >"$TMP/missing-capability.out.json" 2>/dev/null; then
  fail "propagated friction missing SkillOS capability rejected"
else
  assert_jq "$TMP/missing-capability.out.json" '.status == "fail" and (.failures[] | select(.code == "propagated_status_missing_refs" and (.missing_refs | index("skillos_capability_ref"))))' "propagated friction missing SkillOS capability rejected"
fi

jq '.friction_items[0].propagation_window_days = 45 | .clear_count = 0' "$TMP/propagated.json" >"$TMP/slow-propagation.json"
if "$SCRIPT" --ledger "$TMP/slow-propagation.json" --json >"$TMP/slow-propagation.out.json" 2>/dev/null; then
  fail "over-max propagation window rejected"
else
  assert_jq "$TMP/slow-propagation.out.json" '.status == "fail" and (.failures[] | select(.code == "propagation_window_missing_or_over_max"))' "over-max propagation window rejected"
fi

jq '.clear_count = 2' "$TMP/propagated.json" >"$TMP/count-mismatch.json"
if "$SCRIPT" --ledger "$TMP/count-mismatch.json" --json >"$TMP/count-mismatch.out.json" 2>/dev/null; then
  fail "RECYCLE clear count mismatch rejected"
else
  assert_jq "$TMP/count-mismatch.out.json" '.status == "fail" and (.failures[] | select(.code == "clear_count_mismatch"))' "RECYCLE clear count mismatch rejected"
fi

printf 'RESULT pass=%d fail=%d\n' "$pass_count" "$fail_count"
exit "$fail_count"
