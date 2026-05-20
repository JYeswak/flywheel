#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
AUDIT="$ROOT/.flywheel/scripts/supabase-rls-audit.sh"
GATE="$ROOT/.flywheel/scripts/supabase-rls-fleet-gate.sh"
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

mkdir -p "$TMP/catalog" "$TMP/out"
cat >"$TMP/projects.json" <<'JSON'
[
  {"ref":"proj_a","name":"Project A"},
  {"ref":"proj_b","name":"Project B"}
]
JSON
cat >"$TMP/catalog/proj_a.json" <<'JSON'
[
  {"table_schema":"public","table_name":"customers","rls_enabled":false,"row_count_estimate":12,"has_sensitive_column":true,"sensitive_columns":["email"]},
  {"table_schema":"public","table_name":"public_pages","rls_enabled":true,"row_count_estimate":3,"has_sensitive_column":false,"sensitive_columns":[]}
]
JSON
cat >"$TMP/catalog/proj_b.json" <<'JSON'
[
  {"table_schema":"public","table_name":"events","rls_enabled":true,"row_count_estimate":7,"has_sensitive_column":false,"sensitive_columns":[]}
]
JSON

bash -n "$AUDIT" "$GATE" && pass "script syntax"
"$AUDIT" --json --out-dir "$TMP/out" --mock-projects-json "$TMP/projects.json" --mock-catalog-dir "$TMP/catalog" >"$TMP/summary.json"
assert_jq "$TMP/summary.json" '.projects_audited == 2' "projects counted"
assert_jq "$TMP/summary.json" '.tables_audited == 3' "tables counted"
assert_jq "$TMP/summary.json" '.rls_disabled_count == 1 and .severe_count == 1' "rls disabled and severe counted"
assert_jq "$TMP/out/PROJECTS.jsonl" 'select(.table_name=="customers") | .severity == "SEVERE"' "project row marks severe"

set +e
"$GATE" --json --audit-json "$TMP/summary.json" >"$TMP/gate-block.json"
gate_rc=$?
set -e
if [[ "$gate_rc" -eq 1 ]]; then
  pass "gate blocks dirty audit"
else
  fail "gate blocks dirty audit rc=$gate_rc"
fi
assert_jq "$TMP/gate-block.json" '.status == "blocked" and .rls_disabled_count == 1' "gate block json"

jq '.rls_disabled_count = 0 | .severe_count = 0' "$TMP/summary.json" >"$TMP/clean-summary.json"
"$GATE" --json --audit-json "$TMP/clean-summary.json" >"$TMP/gate-pass.json"
assert_jq "$TMP/gate-pass.json" '.status == "pass" and .rls_disabled_count == 0' "gate passes clean audit"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
