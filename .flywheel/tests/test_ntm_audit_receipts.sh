#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/ntm-audit-receipts.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/ntm-audit-receipts.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

run_case() {
  local name="$1"
  shift
  local out="$TMP/$name.json"
  local rc=0
  set +e
  "$SCRIPT" "$@" --json >"$out"
  rc=$?
  set -e
  printf '%s\n' "$rc" >"$TMP/$name.rc"
  printf '%s\n' "$out"
}

row_hash() {
  local canonical
  canonical="$(jq -cS 'del(.sha256,.row_sha256,.hash,.receipt_sha256,.prev_sha256,.previous_sha256,.prev_hash,.hash_chain)')"
  printf '%s' "$canonical" | shasum -a 256 | awk '{print $1}'
}

append_chained_row() {
  local ledger="$1" body="$2" prev="$3" hash
  hash="$(printf '%s\n' "$body" | row_hash)"
  jq -c --arg prev "$prev" --arg hash "$hash" '. + {prev_sha256:$prev, sha256:$hash}' <<<"$body" >>"$ledger"
  printf '%s\n' "$hash"
}

valid_ledger="$TMP/valid.jsonl"
row1="$(jq -cn '{schema_version:"fixture/v1",canonical_writer:"ntm-receipt-writer",event:"started",sequence:1}')"
hash1="$(append_chained_row "$valid_ledger" "$row1" "GENESIS")"
row2="$(jq -cn '{schema_version:"fixture/v1",canonical_writer:"ntm-receipt-writer",event:"closed",sequence:2}')"
append_chained_row "$valid_ledger" "$row2" "$hash1" >/dev/null

multi_writer="$TMP/multi-writer.jsonl"
append_chained_row "$multi_writer" "$(jq -cn '{canonical_writer:"writer-a",event:"one"}')" "GENESIS" >/dev/null
append_chained_row "$multi_writer" "$(jq -cn '{canonical_writer:"writer-b",event:"two"}')" "$(tail -1 "$multi_writer" | jq -r '.sha256')" >/dev/null

broken_chain="$TMP/broken-chain.jsonl"
append_chained_row "$broken_chain" "$(jq -cn '{canonical_writer:"ntm-receipt-writer",event:"one"}')" "GENESIS" >/dev/null
jq -c '.prev_sha256="not-the-prior-hash"' <<<"$(jq -cn '{canonical_writer:"ntm-receipt-writer",event:"two",prev_sha256:"x",sha256:"x"}')" >>"$broken_chain"

no_hash="$TMP/no-hash.jsonl"
jq -cn '{canonical_writer:"ntm-receipt-writer",event:"one"}' >"$no_hash"

invalid_json="$TMP/invalid.jsonl"
printf '{"canonical_writer":"ntm-receipt-writer"}\n{bad json\n' >"$invalid_json"

bash -n "$SCRIPT" && pass "script_syntax" || fail "script_syntax"

info_out="$(run_case info --info)"
assert_jq "$info_out" '.status == "ok" and .name == "ntm-audit-receipts" and .l112_observed == "OK_ntm_migrate_W3bA"' "info_json_contract"

schema_out="$(run_case schema schema)"
assert_jq "$schema_out" '.default_mode == "read_only" and (.apply_requires | index("--idempotency-key")) and .source_ledger_mutation == "forbidden"' "schema_documents_mutation_discipline"

doctor_out="$(run_case doctor doctor)"
assert_jq "$doctor_out" '.status == "pass" and .checks.canonical_cli.audit == true and .checks.canonical_cli.repair == true' "doctor_reports_canonical_cli"

valid_out="$(run_case valid audit --ledger "$valid_ledger" --dry-run)"
[[ "$(cat "$TMP/valid.rc")" == "0" ]] && pass "valid_audit_exit_zero" || fail "valid_audit_exit_zero"
assert_jq "$valid_out" '.status == "pass" and .canonical_writer.status == "pass" and .hash_chain.status == "pass" and .report_written == false' "valid_audit_passes_writer_and_hash_chain"

apply_no_key_out="$(run_case apply-no-key audit --ledger "$valid_ledger" --apply)"
[[ "$(cat "$TMP/apply-no-key.rc")" == "2" ]] && pass "apply_requires_idempotency_key_exit_2" || fail "apply_requires_idempotency_key_exit_2"
assert_jq "$apply_no_key_out" '.status == "fail" and .reason_code == "missing_idempotency_key"' "apply_requires_idempotency_key_json"

report_path="$TMP/report.json"
apply_out="$(run_case apply audit --ledger "$valid_ledger" --apply --idempotency-key fixture-key --report-path "$report_path")"
[[ "$(cat "$TMP/apply.rc")" == "0" ]] && pass "apply_exit_zero" || fail "apply_exit_zero"
test -s "$report_path" && pass "apply_writes_report" || fail "apply_writes_report"
assert_jq "$apply_out" '.report_written == true and .idempotency_key == "fixture-key"' "apply_reports_written_receipt"
assert_jq "$report_path" '.report_written == true and .status == "pass" and .hash_chain.reason_code == "hash_chain_verified"' "written_report_replays_audit_result"

multi_out="$(run_case multi audit --ledger "$multi_writer" --dry-run)"
[[ "$(cat "$TMP/multi.rc")" == "1" ]] && pass "multi_writer_exit_1" || fail "multi_writer_exit_1"
assert_jq "$multi_out" '.status == "fail" and .canonical_writer.reason_code == "multiple_canonical_writers"' "multiple_writer_fails"

broken_out="$(run_case broken audit --ledger "$broken_chain" --dry-run)"
[[ "$(cat "$TMP/broken.rc")" == "1" ]] && pass "broken_chain_exit_1" || fail "broken_chain_exit_1"
assert_jq "$broken_out" '.status == "fail" and .hash_chain.reason_code == "hash_chain_failed"' "broken_hash_chain_fails"

no_hash_out="$(run_case no-hash audit --ledger "$no_hash" --dry-run)"
[[ "$(cat "$TMP/no-hash.rc")" == "0" ]] && pass "missing_hash_chain_warn_exit_zero" || fail "missing_hash_chain_warn_exit_zero"
assert_jq "$no_hash_out" '.status == "warn" and .hash_chain.reason_code == "hash_chain_not_present"' "missing_hash_chain_warns"

invalid_out="$(run_case invalid audit --ledger "$invalid_json" --dry-run)"
[[ "$(cat "$TMP/invalid.rc")" == "1" ]] && pass "invalid_json_exit_1" || fail "invalid_json_exit_1"
assert_jq "$invalid_out" '.status == "fail" and .ledger.invalid_json_rows == 1 and (.failure_reasons | index("invalid_json"))' "invalid_json_fails"

repair_out="$(run_case repair repair --dry-run)"
assert_jq "$repair_out" '.status == "pass" and .source_ledger_mutated == false and (.cannot_repair | index("hash backfill into historical rows"))' "repair_refuses_source_mutation"

why_out="$(run_case why why hash-chain)"
assert_jq "$why_out" '.status == "ok" and .explanations["hash-chain"]' "why_explains_hash_chain"

completion_out="$TMP/completion.bash"
"$SCRIPT" completion bash >"$completion_out"
rg -q 'complete -W' "$completion_out" && pass "completion_bash" || fail "completion_bash"

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
