#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/holding-company-peel-interviews-validate.py"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/holding-company-peel-interviews.schema.json"
LEDGER="$ROOT/state/holding-company-peel-interviews.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/holding-company-peel.XXXXXX")"
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

write_clear_fixture() {
  local path="$1"
  jq '
    .formation_cash_clear_count = 1
    | .candidates[0].formation_cash_status = "clear"
    | .candidates[0].candidate_source = {
        "source_channel": "client_talk",
        "source_ref": "urn:peel-source:mobile-eats-client-talk",
        "evidence_ref": "urn:peel-source-evidence:mobile-eats-client-talk"
      }
    | .candidates[0].interviews = [
      {
        "interview_id": "mobile-eats-peel-001",
        "interviewed_at": "2026-05-17T07:08:00Z",
        "prospect_ref": "prospect-redacted-001",
        "pain_point": "Scheduling and menu-update drift creates missed orders.",
        "current_alternative": "Manual text threads and spreadsheet notes.",
        "buying_signal": {
          "would_buy": true,
          "price_point": "redacted-price-band-accepted",
          "urgency": "strong",
          "evidence_ref": "urn:prospect-interview:mobile-eats-peel-001"
        }
      },
      {
        "interview_id": "mobile-eats-peel-002",
        "interviewed_at": "2026-05-17T07:09:00Z",
        "prospect_ref": "prospect-redacted-002",
        "pain_point": "Delivery coordination breaks when staff turns over.",
        "current_alternative": "Phone calls plus POS notes.",
        "buying_signal": {
          "would_buy": true,
          "price_point": "redacted-price-band-accepted",
          "urgency": "medium",
          "evidence_ref": "urn:prospect-interview:mobile-eats-peel-002"
        }
      },
      {
        "interview_id": "mobile-eats-peel-003",
        "interviewed_at": "2026-05-17T07:10:00Z",
        "prospect_ref": "prospect-redacted-003",
        "pain_point": "Catering requests are hard to quote consistently.",
        "current_alternative": "Email templates and calendar reminders.",
        "buying_signal": {
          "would_buy": true,
          "price_point": "redacted-price-band-accepted",
          "urgency": "strong",
          "evidence_ref": "urn:prospect-interview:mobile-eats-peel-003"
        }
      },
      {
        "interview_id": "mobile-eats-peel-004",
        "interviewed_at": "2026-05-17T07:11:00Z",
        "prospect_ref": "prospect-redacted-004",
        "pain_point": "Refund and substitution records are fragmented.",
        "current_alternative": "Notebook plus POS comments.",
        "buying_signal": {
          "would_buy": true,
          "price_point": "redacted-price-band-accepted",
          "urgency": "medium",
          "evidence_ref": "urn:prospect-interview:mobile-eats-peel-004"
        }
      },
      {
        "interview_id": "mobile-eats-peel-005",
        "interviewed_at": "2026-05-17T07:12:00Z",
        "prospect_ref": "prospect-redacted-005",
        "pain_point": "Repeat-customer outreach depends on one manager remembering.",
        "current_alternative": "Manual loyalty list.",
        "buying_signal": {
          "would_buy": true,
          "price_point": "redacted-price-band-accepted",
          "urgency": "strong",
          "evidence_ref": "urn:prospect-interview:mobile-eats-peel-005"
        }
      }
    ]
  ' "$LEDGER" >"$path"
}

if python3 -m py_compile "$SCRIPT"; then
  pass "validator py_compile"
else
  fail "validator py_compile"
fi

jq empty "$SCHEMA" && pass "schema json valid" || fail "schema json valid"
jq empty "$LEDGER" && pass "ledger json valid" || fail "ledger json valid"

"$SCRIPT" --ledger "$LEDGER" --check-paths --json >"$TMP/current.json"
assert_jq "$TMP/current.json" '.status == "pass" and .formation_cash_clear_count == 0 and .candidates[0].formation_cash_gate_status == "blocked"' "current ledger validates and blocks formation cash"

jq 'del(.gate)' "$LEDGER" >"$TMP/schema-invalid.json"
if "$SCRIPT" --ledger "$TMP/schema-invalid.json" --json >"$TMP/schema-invalid.out.json" 2>/dev/null; then
  fail "schema-invalid PEEL ledger rejected"
else
  assert_jq "$TMP/schema-invalid.out.json" '.status == "fail" and (.failures[] | select(.code == "schema_invalid"))' "schema-invalid PEEL ledger rejected"
fi

write_clear_fixture "$TMP/clear.json"
"$SCRIPT" --ledger "$TMP/clear.json" --json >"$TMP/clear.out.json"
assert_jq "$TMP/clear.out.json" '.status == "pass" and .formation_cash_clear_count == 1 and .candidates[0].formation_cash_gate_status == "clear"' "five qualified interviews clear formation cash"

jq '.candidates[0].candidate_source.source_channel = "unknown" | .formation_cash_clear_count = 0' "$TMP/clear.json" >"$TMP/unknown-source.json"
if "$SCRIPT" --ledger "$TMP/unknown-source.json" --json >"$TMP/unknown-source.out.json" 2>/dev/null; then
  fail "clear status without PEEL candidate source rejected"
else
  assert_jq "$TMP/unknown-source.out.json" '.status == "fail" and (.failures[] | select(.code == "formation_cash_status_without_candidate_source"))' "clear status without PEEL candidate source rejected"
fi

jq '.candidates[0].interviews = .candidates[0].interviews[0:4] | .formation_cash_clear_count = 0' "$TMP/clear.json" >"$TMP/four.json"
if "$SCRIPT" --ledger "$TMP/four.json" --json >"$TMP/four.out.json" 2>/dev/null; then
  fail "clear status with four interviews rejected"
else
  assert_jq "$TMP/four.out.json" '.status == "fail" and (.failures[] | select(.code == "formation_cash_status_without_five_qualified_interviews"))' "clear status with four interviews rejected"
fi

jq '.candidates[0].formation_cash_status = "committed" | .candidates[0].interviews = [] | .formation_cash_clear_count = 0' "$TMP/clear.json" >"$TMP/committed.json"
if "$SCRIPT" --ledger "$TMP/committed.json" --json >"$TMP/committed.out.json" 2>/dev/null; then
  fail "committed status without interviews rejected"
else
  assert_jq "$TMP/committed.out.json" '.status == "fail" and (.failures[] | select(.code == "formation_cash_committed_without_clear_gate"))' "committed status without interviews rejected"
fi

jq '.formation_cash_clear_count = 2' "$TMP/clear.json" >"$TMP/mismatch.json"
if "$SCRIPT" --ledger "$TMP/mismatch.json" --json >"$TMP/mismatch.out.json" 2>/dev/null; then
  fail "clear count mismatch rejected"
else
  assert_jq "$TMP/mismatch.out.json" '.status == "fail" and (.failures[] | select(.code == "formation_cash_clear_count_mismatch"))' "clear count mismatch rejected"
fi

jq '.candidates[0].evidence_refs = ["state/no-such-peel-evidence.json"]' "$TMP/clear.json" >"$TMP/missing-evidence-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-evidence-ref.json" --check-paths --json >"$TMP/missing-evidence-ref.out.json" 2>/dev/null; then
  fail "missing PEEL evidence ref rejected"
else
  assert_jq "$TMP/missing-evidence-ref.out.json" '.status == "fail" and (.failures[] | select(.code == "evidence_ref_missing"))' "missing PEEL evidence ref rejected"
fi

jq '.candidates[0].candidate_source.evidence_ref = "state/no-such-peel-source-evidence.json"' "$TMP/clear.json" >"$TMP/missing-source-evidence-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-source-evidence-ref.json" --check-paths --json >"$TMP/missing-source-evidence-ref.out.json" 2>/dev/null; then
  fail "missing PEEL candidate source evidence ref rejected"
else
  assert_jq "$TMP/missing-source-evidence-ref.out.json" '.status == "fail" and (.failures[] | select(.code == "candidate_source_evidence_ref_missing"))' "missing PEEL candidate source evidence ref rejected"
fi

jq '.candidates[0].interviews[0].buying_signal.evidence_ref = "state/no-such-peel-interview-evidence.json"' "$TMP/clear.json" >"$TMP/missing-interview-evidence-ref.json"
if "$SCRIPT" --ledger "$TMP/missing-interview-evidence-ref.json" --check-paths --json >"$TMP/missing-interview-evidence-ref.out.json" 2>/dev/null; then
  fail "missing PEEL interview evidence ref rejected"
else
  assert_jq "$TMP/missing-interview-evidence-ref.out.json" '.status == "fail" and (.failures[] | select(.code == "interview_evidence_ref_missing"))' "missing PEEL interview evidence ref rejected"
fi

jq '.candidates[0].interviews[0].buying_signal.price_point = "$1000 pasted raw"' "$TMP/clear.json" >"$TMP/raw-amount.json"
if "$SCRIPT" --ledger "$TMP/raw-amount.json" --json >"$TMP/raw-amount.out.json" 2>/dev/null; then
  fail "raw amount rejected"
else
  assert_jq "$TMP/raw-amount.out.json" '.status == "fail" and (.failures[] | select(.code == "secret_or_raw_amount_shape_detected"))' "raw amount rejected"
fi

printf 'RESULT pass=%d fail=%d\n' "$pass_count" "$fail_count"
exit "$fail_count"
