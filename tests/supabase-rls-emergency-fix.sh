#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
FIX="$ROOT/.flywheel/scripts/supabase-rls-emergency-fix.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'ok %d - %s\n' "$pass_count" "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'not ok %d - %s\n' "$((pass_count + fail_count))" "$1" >&2; }
assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then pass "$label"; else fail "$label"; cat "$file" >&2; fi
}

cat >"$TMP/audit.jsonl" <<'JSONL'
{"project_id":"proj_a","project_name":"Project A","table_schema":"public","table_name":"customers","rls_enabled":false,"row_count_estimate":12,"has_sensitive_column":true,"sensitive_columns":["email"],"severity":"SEVERE"}
{"project_id":"proj_a","project_name":"Project A","table_schema":"public","table_name":"public_pages","rls_enabled":true,"row_count_estimate":3,"has_sensitive_column":false,"sensitive_columns":[],"severity":"OK"}
{"project_id":"proj_b","project_name":"Project B","table_schema":"public","table_name":"events","rls_enabled":false,"row_count_estimate":7,"has_sensitive_column":false,"sensitive_columns":[],"severity":"CRITICAL"}
JSONL

bash -n "$FIX" && pass "script syntax"
"$FIX" --json --audit-file "$TMP/audit.jsonl" --out-dir "$TMP/out" >"$TMP/dry.json"
assert_jq "$TMP/dry.json" '.mode == "dry_run" and .project_count == 2 and .tables_fixed == 2' "dry-run summary"
if grep -q 'ENABLE ROW LEVEL SECURITY' "$TMP/out/fix-sql/proj_a.sql"; then
  pass "dry-run emits enable rls sql"
else
  fail "dry-run emits enable rls sql"
fi
if grep -q 'REVOKE ALL PRIVILEGES' "$TMP/out/fix-sql/proj_a.sql"; then
  pass "dry-run emits revoke sql"
else
  fail "dry-run emits revoke sql"
fi
if grep -q 'TO service_role' "$TMP/out/fix-sql/proj_a.sql"; then
  pass "dry-run emits service_role policy"
else
  fail "dry-run emits service_role policy"
fi

"$FIX" --apply --json --audit-file "$TMP/audit.jsonl" --out-dir "$TMP/apply" --mock-apply-log "$TMP/apply-log.jsonl" >"$TMP/apply.json"
assert_jq "$TMP/apply.json" '.mode == "apply" and .tables_fixed == 2' "mock apply summary"
assert_jq "$TMP/apply-log.jsonl" 'select(.project_id=="proj_a") | .applied == true and .tables_fixed == 1' "mock apply project a"
assert_jq "$TMP/apply/receipts/Project-A-receipt.json" '.tables_fixed == 1 and .policies_added == 1 and .anon_authenticated_grants_revoked == 1' "receipt emitted"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
