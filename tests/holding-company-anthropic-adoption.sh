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

jq 'del(.gate)' "$LEDGER" >"$TMP/schema-invalid.json"
if "$SCRIPT" --ledger "$TMP/schema-invalid.json" --json >"$TMP/schema-invalid.out.json" 2>/dev/null; then
  fail "schema-invalid Anthropic adoption ledger rejected"
else
  assert_jq "$TMP/schema-invalid.out.json" '.failures[] | select(.code == "schema_invalid")' "schema-invalid Anthropic adoption ledger rejected"
fi

jq '.all_expected_repos_present = false' "$LEDGER" >"$TMP/repo-present-mismatch.json"
if "$SCRIPT" --ledger "$TMP/repo-present-mismatch.json" --json >"$TMP/repo-present-mismatch.out.json" 2>/dev/null; then
  fail "all expected repos present mismatch rejected"
else
  assert_jq "$TMP/repo-present-mismatch.out.json" '.failures[] | select(.code == "all_expected_repos_present_mismatch")' "all expected repos present mismatch rejected"
fi

jq '.expected_consumer_repos += ["/no/such/anthropic-adoption-repo"]' "$LEDGER" >"$TMP/missing-repo.json"
if "$SCRIPT" --ledger "$TMP/missing-repo.json" --check-paths --json >"$TMP/missing-repo.out.json" 2>/dev/null; then
  fail "missing expected consumer repo rejected"
else
  assert_jq "$TMP/missing-repo.out.json" '.failures[] | select(.code == "expected_repo_missing")' "missing expected consumer repo rejected"
fi

printf '{"gate_2_consumer_adoption_compression":{"adoption_clause":{"doctor_status":"OK","distinct_target_count":3,"packages_phantom_fail":0,"real_consumer_repos":["/Users/josh/Developer/agent-bench","/Users/josh/Developer/mobile-eats"]}}}\n' >"$TMP/canonical-missing-repo.json"
jq --arg ref "$TMP/canonical-missing-repo.json" '.canonical_gates_status_ref = $ref' "$LEDGER" >"$TMP/canonical-missing-repo-ledger.json"
if "$SCRIPT" --ledger "$TMP/canonical-missing-repo-ledger.json" --json >"$TMP/canonical-missing-repo.out.json" 2>/dev/null; then
  fail "expected repo missing from canonical gate rejected"
else
  assert_jq "$TMP/canonical-missing-repo.out.json" '.failures[] | select(.code == "expected_repo_missing_from_canonical_gate")' "expected repo missing from canonical gate rejected"
fi

printf '{bad jsonl row\n' >"$TMP/bad-events.jsonl"
jq --arg ref "$TMP/bad-events.jsonl" '.pack_applied_events_ref = $ref' "$LEDGER" >"$TMP/bad-events-ledger.json"
if "$SCRIPT" --ledger "$TMP/bad-events-ledger.json" --json >"$TMP/bad-events.out.json" 2>/dev/null; then
  fail "malformed pack applied events rejected"
else
  assert_jq "$TMP/bad-events.out.json" '.failures[] | select(.code == "pack_applied_events_parse_failed")' "malformed pack applied events rejected"
fi

jq 'del(.adoption_events[2])' "$LEDGER" >"$TMP/missing-declared-event.json"
if "$SCRIPT" --ledger "$TMP/missing-declared-event.json" --json >"$TMP/missing-declared-event.out.json" 2>/dev/null; then
  fail "missing declared adoption event rejected"
else
  assert_jq "$TMP/missing-declared-event.out.json" '.failures[] | select(.code == "declared_adoption_event_missing")' "missing declared adoption event rejected"
fi

jq '.adoption_events[0].event_ts = "2026-05-17T00:00:00Z"' "$LEDGER" >"$TMP/event-not-found.json"
if "$SCRIPT" --ledger "$TMP/event-not-found.json" --json >"$TMP/event-not-found.out.json" 2>/dev/null; then
  fail "declared adoption event missing from source rejected"
else
  assert_jq "$TMP/event-not-found.out.json" '.failures[] | select(.code == "declared_event_not_found_in_source")' "declared adoption event missing from source rejected"
fi

jq '.adoption_events[0].target_was_self = true' "$LEDGER" >"$TMP/self-target.json"
if "$SCRIPT" --ledger "$TMP/self-target.json" --json >"$TMP/self-target.out.json" 2>/dev/null; then
  fail "declared self target rejected"
else
  assert_jq "$TMP/self-target.out.json" '.failures[] | select(.code == "declared_event_self_target")' "declared self target rejected"
fi

jq '.target_repos_remaining_to_min_target_count = 1' "$LEDGER" >"$TMP/targets-remaining.json"
if "$SCRIPT" --ledger "$TMP/targets-remaining.json" --json >"$TMP/targets-remaining.out.json" 2>/dev/null; then
  fail "proven with targets remaining rejected"
else
  assert_jq "$TMP/targets-remaining.out.json" '.failures[] | select(.code == "proven_with_targets_remaining")' "proven with targets remaining rejected"
fi

jq '.real_consumer_repo_count = 2' "$LEDGER" >"$TMP/real-count-mismatch.json"
if "$SCRIPT" --ledger "$TMP/real-count-mismatch.json" --json >"$TMP/real-count-mismatch.out.json" 2>/dev/null; then
  fail "real consumer repo count mismatch rejected"
else
  assert_jq "$TMP/real-count-mismatch.out.json" '.failures[] | select(.code == "real_consumer_repo_count_mismatch")' "real consumer repo count mismatch rejected"
fi

printf '%s\n' \
  '{"pack_name":"anthropic-sdk-python","lifecycle_transition":"applied","target":"/Users/josh/Developer/agent-bench","ts":"2026-05-13T14:40:33Z","target_is_synthetic":true}' \
  '{"pack_name":"anthropic-sdk-python","lifecycle_transition":"applied","target":"/Users/josh/Developer/mobile-eats","ts":"2026-05-08T23:12:23Z","target_is_synthetic":true}' \
  '{"pack_name":"anthropic-sdk-python","lifecycle_transition":"applied","target":"/Users/josh/Developer/zesttube","ts":"2026-05-13T14:40:33Z","target_is_synthetic":true}' \
  >"$TMP/synthetic-events.jsonl"
jq --arg ref "$TMP/synthetic-events.jsonl" '.pack_applied_events_ref = $ref' "$LEDGER" >"$TMP/no-real-consumers.json"
if "$SCRIPT" --ledger "$TMP/no-real-consumers.json" --json >"$TMP/no-real-consumers.out.json" 2>/dev/null; then
  fail "proven without real consumer repos rejected"
else
  assert_jq "$TMP/no-real-consumers.out.json" '.failures[] | select(.code == "proven_without_real_consumer_repos")' "proven without real consumer repos rejected"
fi

jq '.notes += ["fixture sk-TestSecret123 should be rejected"]' "$LEDGER" >"$TMP/secret-shape.json"
if "$SCRIPT" --ledger "$TMP/secret-shape.json" --json >"$TMP/secret-shape.out.json" 2>/dev/null; then
  fail "secret-shaped Anthropic adoption value rejected"
else
  assert_jq "$TMP/secret-shape.out.json" '.failures[] | select(.code == "secret_or_raw_value_shape_detected")' "secret-shaped Anthropic adoption value rejected"
fi

if [[ "$fail_count" -ne 0 ]]; then
  printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
