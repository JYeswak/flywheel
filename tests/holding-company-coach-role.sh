#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/holding-company-coach-role-validate.py"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/holding-company-coach-role.schema.json"
LEDGER="$ROOT/state/holding-company-coach-role.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/holding-company-coach-role.XXXXXX")"
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
assert_jq "$TMP/current.json" '.status == "pass" and .clear_count == 0 and .roles[0].coach_role_gate_status == "blocked"' "current ledger validates and blocks coach role"

jq '
  .clear_count = 1
  | .roles[0].status = "coach_role_clear"
  | .roles[0].owner_operator_ref = "urn:owner:mobile-eats"
  | .roles[0].operating_control_handoff_ref = "urn:control:mobile-eats"
  | .roles[0].coach_role_agreement_ref = "urn:coach-role:mobile-eats"
  | .roles[0].majority_stake_ref = "urn:majority-stake:mobile-eats"
  | .roles[0].holding_stake_percent = 75
  | .roles[0].owner_operating_control_ack_ref = "urn:owner-control-ack:mobile-eats"
' "$LEDGER" >"$TMP/clear.json"
"$SCRIPT" --ledger "$TMP/clear.json" --json >"$TMP/clear.out.json"
assert_jq "$TMP/clear.out.json" '.status == "pass" and .clear_count == 1 and .roles[0].coach_role_gate_status == "clear"' "coach role and majority stake clear"

jq '.roles[0].status = "coach_role_clear" | .roles[0].holding_stake_percent = 75' "$LEDGER" >"$TMP/missing.json"
if "$SCRIPT" --ledger "$TMP/missing.json" --json >"$TMP/missing.out.json" 2>/dev/null; then
  fail "coach role clear missing refs rejected"
else
  assert_jq "$TMP/missing.out.json" '.failures[] | select(.code == "coach_role_clear_missing_refs")' "coach role clear missing refs rejected"
fi

jq '.roles[0].holding_stake_percent = 50' "$TMP/clear.json" >"$TMP/minority.json"
if "$SCRIPT" --ledger "$TMP/minority.json" --json >"$TMP/minority.out.json" 2>/dev/null; then
  fail "minority holding stake rejected"
else
  assert_jq "$TMP/minority.out.json" '.failures[] | select(.code == "holding_stake_below_majority")' "minority holding stake rejected"
fi

jq '.clear_count = 1' "$LEDGER" >"$TMP/bad-count.json"
if "$SCRIPT" --ledger "$TMP/bad-count.json" --json >"$TMP/bad-count.out.json" 2>/dev/null; then
  fail "coach role clear count mismatch rejected"
else
  assert_jq "$TMP/bad-count.out.json" '.failures[] | select(.code == "clear_count_mismatch")' "coach role clear count mismatch rejected"
fi

if [[ "$fail_count" -ne 0 ]]; then
  printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
