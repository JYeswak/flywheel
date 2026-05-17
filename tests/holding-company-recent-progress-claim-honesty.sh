#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/holding-company-recent-progress-claim-honesty-validate.py"
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
if python3 -m py_compile "$SCRIPT"; then
  pass "validator py_compile"
else
  fail "validator py_compile"
fi
"$SCRIPT" --receipt "$RECEIPT" --check-paths --json >"$TMP/current.json"
assert_jq "$TMP/current.json" '.status == "pass" and .recent_progress_claim_honesty_status == "mixed_claims_guarded" and .claim_count == 4' "validator accepts current claim-honesty receipt"
assert_jq "$TMP/current.json" '.gate_status_by_claim.anthropic_adoption == "proven" and .gate_status_by_claim.mobile_eats_shipping == "partial" and .gate_status_by_claim.progress_velocity == "blocked" and .gate_status_by_claim.skillos_forever_os_lock == "partial"' "validator surfaces source gate statuses"

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

jq 'del(.claims[] | select(.claim_id == "progress_velocity"))' "$RECEIPT" >"$TMP/missing-claim-id.json"
if "$SCRIPT" --receipt "$TMP/missing-claim-id.json" --json >"$TMP/missing-claim-id.out.json" 2>/dev/null; then
  fail "missing recent-progress claim id rejected"
else
  assert_jq "$TMP/missing-claim-id.out.json" '.failures[] | select(.code == "missing_claim_ids" and (.claim_ids | index("progress_velocity")))' "missing recent-progress claim id rejected"
fi

jq '.claims += [(.claims[0] | .claim_id = "unexpected_claim")]' "$RECEIPT" >"$TMP/unknown-claim-id.json"
if "$SCRIPT" --receipt "$TMP/unknown-claim-id.json" --json >"$TMP/unknown-claim-id.out.json" 2>/dev/null; then
  fail "unknown recent-progress claim id rejected"
else
  assert_jq "$TMP/unknown-claim-id.out.json" '.failures[] | select(.code == "unknown_claim_ids" and (.claim_ids | index("unexpected_claim")))' "unknown recent-progress claim id rejected"
fi

jq '.claims += [.claims[0]]' "$RECEIPT" >"$TMP/duplicate-claim-id.json"
if "$SCRIPT" --receipt "$TMP/duplicate-claim-id.json" --json >"$TMP/duplicate-claim-id.out.json" 2>/dev/null; then
  fail "duplicate recent-progress claim id rejected"
else
  assert_jq "$TMP/duplicate-claim-id.out.json" '.failures[] | select(.code == "duplicate_claim_id" and (.claim_ids | index("anthropic_adoption")))' "duplicate recent-progress claim id rejected"
fi

jq '(.claims[] | select(.claim_id == "mobile_eats_shipping") | .claim_honesty_status) = "safe_to_use"' "$RECEIPT" >"$TMP/wrong-claim-honesty.json"
if "$SCRIPT" --receipt "$TMP/wrong-claim-honesty.json" --json >"$TMP/wrong-claim-honesty.out.json" 2>/dev/null; then
  fail "claim honesty status drift rejected"
else
  assert_jq "$TMP/wrong-claim-honesty.out.json" '.failures[] | select(.code == "claim_honesty_status_mismatch" and .claim_id == "mobile_eats_shipping" and .expected == "formation_claim_blocked_in_text")' "claim honesty status drift rejected"
fi

jq '(.claims[] | select(.claim_id == "progress_velocity") | .current_gate_status) = "proven"' "$RECEIPT" >"$TMP/wrong-current-gate-status.json"
if "$SCRIPT" --receipt "$TMP/wrong-current-gate-status.json" --json >"$TMP/wrong-current-gate-status.out.json" 2>/dev/null; then
  fail "current gate status drift rejected"
else
  assert_jq "$TMP/wrong-current-gate-status.out.json" '.failures[] | select(.code == "current_gate_status_mismatch" and .claim_id == "progress_velocity" and .validator_status == "blocked")' "current gate status drift rejected"
fi

jq '(.claims[] | select(.claim_id == "anthropic_adoption") | .claim_text) = "stale claim text"' "$RECEIPT" >"$TMP/claim-text-mismatch.json"
if "$SCRIPT" --receipt "$TMP/claim-text-mismatch.json" --json >"$TMP/claim-text-mismatch.out.json" 2>/dev/null; then
  fail "claim text mismatch rejected"
else
  assert_jq "$TMP/claim-text-mismatch.out.json" '.failures[] | select(.code == "claim_text_mismatch" and .claim_id == "anthropic_adoption")' "claim text mismatch rejected"
fi

jq 'del(.claims[] | select(.claim_id == "anthropic_adoption") | .ledger_ref)' "$RECEIPT" >"$TMP/missing-ledger-ref.json"
if "$SCRIPT" --receipt "$TMP/missing-ledger-ref.json" --json >"$TMP/missing-ledger-ref.out.json" 2>/dev/null; then
  fail "missing claim ledger ref rejected"
else
  assert_jq "$TMP/missing-ledger-ref.out.json" '.failures[] | select(.code == "claim_missing_validator_or_ledger_ref" and .claim_id == "anthropic_adoption")' "missing claim ledger ref rejected"
fi

jq 'del(.claims[] | select(.claim_id == "anthropic_adoption") | .validator)' "$RECEIPT" >"$TMP/missing-validator-ref.json"
if "$SCRIPT" --receipt "$TMP/missing-validator-ref.json" --json >"$TMP/missing-validator-ref.out.json" 2>/dev/null; then
  fail "missing claim validator ref rejected"
else
  assert_jq "$TMP/missing-validator-ref.out.json" '.failures[] | select(.code == "claim_missing_validator_or_ledger_ref" and .claim_id == "anthropic_adoption")' "missing claim validator ref rejected"
fi

jq '(.claims[] | select(.claim_id == "progress_velocity") | .claim_text) = "4,000+ commits in 7 days across 9 product surfaces."' "$RECEIPT" >"$TMP/progress-overclaim.json"
if "$SCRIPT" --receipt "$TMP/progress-overclaim.json" --json >"$TMP/progress-overclaim.out.json" 2>/dev/null; then
  fail "progress velocity overclaim rejected"
else
  assert_jq "$TMP/progress-overclaim.out.json" '.failures[] | select(.code == "recent_progress_claim_overstates_velocity_target")' "progress velocity overclaim rejected"
fi

jq '(.claims[] | select(.claim_id == "mobile_eats_shipping") | .claim_text) = "mobile-eats shipping; first portfolio company on shared substrate with 9+ @zeststream/* package adoptions."' "$RECEIPT" >"$TMP/mobile-overclaim.json"
if "$SCRIPT" --receipt "$TMP/mobile-overclaim.json" --json >"$TMP/mobile-overclaim.out.json" 2>/dev/null; then
  fail "mobile eats overclaim rejected"
else
  assert_jq "$TMP/mobile-overclaim.out.json" '.failures[] | select(.code == "mobile_eats_first_company_overclaim")' "mobile eats overclaim rejected"
fi

jq '(.claims[] | select(.claim_id == "skillos_forever_os_lock") | .claim_text) = "SkillOS Forever-OS v3 ratified 2026-05-16; structure locked 2026-05-17."' "$RECEIPT" >"$TMP/skillos-overclaim.json"
if "$SCRIPT" --receipt "$TMP/skillos-overclaim.json" --json >"$TMP/skillos-overclaim.out.json" 2>/dev/null; then
  fail "SkillOS structure-lock overclaim rejected"
else
  assert_jq "$TMP/skillos-overclaim.out.json" '.failures[] | select(.code == "skillos_structure_lock_overclaim")' "SkillOS structure-lock overclaim rejected"
fi

if [[ "$fail_count" -ne 0 ]]; then
  printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
