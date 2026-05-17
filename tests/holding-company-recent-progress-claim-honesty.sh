#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/holding-company-recent-progress-claim-honesty.schema.json"
RECEIPT="$ROOT/state/holding-company-recent-progress-claim-honesty-20260517T1017Z.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/holding-company-claim-honesty.XXXXXX")"
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
assert_jq "$RECEIPT" '.schema_version == "zeststream.holding_company_recent_progress_claim_honesty.v1" and (.claims | length == 4)' "receipt declares four active recent-progress claims"

for id in anthropic_adoption mobile_eats_shipping progress_velocity skillos_forever_os_lock; do
  ledger="$(jq -r --arg id "$id" '.claims[] | select(.claim_id == $id) | .ledger_ref' "$RECEIPT")"
  validator="$(jq -r --arg id "$id" '.claims[] | select(.claim_id == $id) | .validator' "$RECEIPT")"
  receipt_claim="$(jq -r --arg id "$id" '.claims[] | select(.claim_id == $id) | .claim_text' "$RECEIPT")"
  ledger_claim="$(jq -r '.claim_text' "$ROOT/$ledger")"
  assert_eq "$receipt_claim" "$ledger_claim" "$id receipt claim text matches ledger"
  python3 "$ROOT/$validator" --ledger "$ROOT/$ledger" --check-paths --json >"$TMP/$id.json"
  assert_jq "$TMP/$id.json" '.status == "pass" and (.failures | length == 0)' "$id validator passes without failures"
done

assert_jq "$TMP/anthropic_adoption.json" '.anthropic_adoption_gate_status == "proven"' "anthropic adoption is proven"
assert_jq "$TMP/mobile_eats_shipping.json" '.mobile_eats_shipping_gate_status == "partial" and .counted_as_portfolio_company == false and .first_portfolio_company_claim_clear == false' "mobile eats first-company claim remains blocked"
assert_jq "$TMP/progress_velocity.json" '.progress_velocity_gate_status == "blocked" and .computed_total_commit_count == 3755 and .target_min_commits == 4000' "progress velocity public target remains blocked"
assert_jq "$TMP/skillos_forever_os_lock.json" '.forever_os_lock_gate_status == "partial" and .structure_locked_20260517 == false' "SkillOS structure lock receipt remains pending"

if jq -e '.claims[] | select(.claim_id == "progress_velocity") | .claim_text | test("4,?000\\+")' "$RECEIPT" >/dev/null; then
  fail "progress velocity active text avoids 4000+ overclaim"
else
  pass "progress velocity active text avoids 4000+ overclaim"
fi

if jq -e '.claims[] | select(.claim_id == "mobile_eats_shipping") | .claim_text | test("first portfolio company on shared substrate"; "i")' "$RECEIPT" >/dev/null; then
  fail "mobile eats active text avoids first-company overclaim"
else
  pass "mobile eats active text avoids first-company overclaim"
fi

if jq -e '.claims[] | select(.claim_id == "skillos_forever_os_lock") | .claim_text | test("structure locked|locked 2026-05-17"; "i")' "$RECEIPT" >/dev/null; then
  fail "SkillOS active text avoids structure-lock overclaim"
else
  pass "SkillOS active text avoids structure-lock overclaim"
fi

if [[ "$fail_count" -ne 0 ]]; then
  printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
