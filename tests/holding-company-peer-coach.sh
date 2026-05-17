#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/holding-company-peer-coach-validate.py"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/holding-company-peer-coach.schema.json"
LEDGER="$ROOT/state/holding-company-peer-coach.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/holding-company-peer-coach.XXXXXX")"
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
assert_jq "$TMP/current.json" '.status == "pass" and .clear_count == 0 and .peer_coaches[0].peer_coach_gate_status == "blocked"' "current ledger validates and blocks peer coach"

jq '
  .clear_count = 1
  | .peer_coaches[0].status = "eligible"
  | .peer_coaches[0].owner_tier = 2
  | .peer_coaches[0].sustainable_cash_position_ref = "urn:sustainable-cash:mobile-eats"
  | .peer_coaches[0].operating_control_ref = "urn:operating-control:mobile-eats"
  | .peer_coaches[0].peer_coach_agreement_ref = "urn:peer-coach-agreement:mobile-eats"
  | .peer_coaches[0].equity_grant_percent = 5
  | .peer_coaches[0].equity_grant_ref = "urn:equity-grant:future-sub:5pct"
' "$LEDGER" >"$TMP/eligible.json"
"$SCRIPT" --ledger "$TMP/eligible.json" --json >"$TMP/eligible.out.json"
assert_jq "$TMP/eligible.out.json" '.status == "pass" and .clear_count == 1 and .peer_coaches[0].peer_coach_gate_status == "clear"' "Tier 2 owner with 5 percent grant clears peer coach"

jq '.peer_coaches[0].status = "eligible" | .peer_coaches[0].owner_tier = 1 | .peer_coaches[0].equity_grant_percent = 5' "$LEDGER" >"$TMP/tier1.json"
if "$SCRIPT" --ledger "$TMP/tier1.json" --json >"$TMP/tier1.out.json" 2>/dev/null; then
  fail "Tier 1 peer coach rejected"
else
  assert_jq "$TMP/tier1.out.json" '.status == "fail" and (.failures[] | select(.code == "peer_coach_status_without_tier_2_owner"))' "Tier 1 peer coach rejected"
fi

jq '.peer_coaches[0].equity_grant_percent = 7' "$TMP/eligible.json" >"$TMP/equity-mismatch.json"
if "$SCRIPT" --ledger "$TMP/equity-mismatch.json" --json >"$TMP/equity-mismatch.out.json" 2>/dev/null; then
  fail "wrong peer coach equity percent rejected"
else
  assert_jq "$TMP/equity-mismatch.out.json" '.status == "fail" and (.failures[] | select(.code == "peer_coach_equity_percent_mismatch"))' "wrong peer coach equity percent rejected"
fi

jq '.clear_count = 2' "$TMP/eligible.json" >"$TMP/count-mismatch.json"
if "$SCRIPT" --ledger "$TMP/count-mismatch.json" --json >"$TMP/count-mismatch.out.json" 2>/dev/null; then
  fail "peer coach clear count mismatch rejected"
else
  assert_jq "$TMP/count-mismatch.out.json" '.status == "fail" and (.failures[] | select(.code == "clear_count_mismatch"))' "peer coach clear count mismatch rejected"
fi

printf 'RESULT pass=%d fail=%d\n' "$pass_count" "$fail_count"
exit "$fail_count"
