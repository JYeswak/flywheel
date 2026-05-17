#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/holding-company-anthropic-adoption-validate.py"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/holding-company-anthropic-adoption.schema.json"
LEDGER="$ROOT/state/holding-company-anthropic-adoption.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/holding-company-anthropic-adoption.XXXXXX")"
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
assert_jq "$TMP/current.json" '.status == "pass" and .anthropic_adoption_gate_status == "proven" and .real_consumer_repo_count == 3 and .packages_phantom_fail == 0' "current anthropic adoption validates as proven"

jq '.doctor_status = "WARN"' "$LEDGER" >"$TMP/doctor-warn.json"
if "$SCRIPT" --ledger "$TMP/doctor-warn.json" --json >"$TMP/doctor-warn.out.json" 2>/dev/null; then
  fail "proven without OK doctor rejected"
else
  assert_jq "$TMP/doctor-warn.out.json" '.failures[] | select(.code == "canonical_doctor_status_mismatch" or .code == "proven_without_ok_doctor")' "proven without OK doctor rejected"
fi

jq '.distinct_target_count = 2' "$LEDGER" >"$TMP/below-target.json"
if "$SCRIPT" --ledger "$TMP/below-target.json" --json >"$TMP/below-target.out.json" 2>/dev/null; then
  fail "proven below min target count rejected"
else
  assert_jq "$TMP/below-target.out.json" '.failures[] | select(.code == "canonical_distinct_target_count_mismatch" or .code == "proven_below_min_target_count")' "proven below min target count rejected"
fi

jq '.packages_phantom_fail = 1' "$LEDGER" >"$TMP/phantom.json"
if "$SCRIPT" --ledger "$TMP/phantom.json" --json >"$TMP/phantom.out.json" 2>/dev/null; then
  fail "proven with phantom failures rejected"
else
  assert_jq "$TMP/phantom.out.json" '.failures[] | select(.code == "canonical_phantom_fail_mismatch" or .code == "proven_with_phantom_failures")' "proven with phantom failures rejected"
fi

jq '.adoption_events[0].target_is_synthetic = true' "$LEDGER" >"$TMP/synthetic-declared.json"
if "$SCRIPT" --ledger "$TMP/synthetic-declared.json" --json >"$TMP/synthetic-declared.out.json" 2>/dev/null; then
  fail "declared synthetic target rejected"
else
  assert_jq "$TMP/synthetic-declared.out.json" '.failures[] | select(.code == "declared_event_synthetic_target")' "declared synthetic target rejected"
fi

jq -c 'select(.pack_name == "anthropic-sdk-python" and (.target == "/Users/josh/Developer/agent-bench" or .target == "/Users/josh/Developer/mobile-eats"))' \
  /Users/josh/Developer/skillos/state/skillos-pack-applied-events.jsonl >"$TMP/two-events.jsonl"
jq --arg events "$TMP/two-events.jsonl" '.pack_applied_events_ref = $events' "$LEDGER" >"$TMP/missing-zesttube.json"
if "$SCRIPT" --ledger "$TMP/missing-zesttube.json" --json >"$TMP/missing-zesttube.out.json" 2>/dev/null; then
  fail "missing expected adoption event rejected"
else
  assert_jq "$TMP/missing-zesttube.out.json" '.failures[] | select(.code == "all_expected_events_present_mismatch" or .code == "proven_missing_expected_adoption_events")' "missing expected adoption event rejected"
fi

jq '.evidence_refs += ["/no/such/adoption-evidence.json"]' "$LEDGER" >"$TMP/missing-evidence.json"
if "$SCRIPT" --ledger "$TMP/missing-evidence.json" --check-paths --json >"$TMP/missing-evidence.out.json" 2>/dev/null; then
  fail "missing evidence path rejected"
else
  assert_jq "$TMP/missing-evidence.out.json" '.failures[] | select(.code == "evidence_ref_missing")' "missing evidence path rejected"
fi

if [[ "$fail_count" -ne 0 ]]; then
  printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
