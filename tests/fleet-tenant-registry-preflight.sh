#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/fleet-tenant-registry-preflight.py"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then pass "$label"; else fail "$label"; fi
}

mkdir -p "$TMP/good" "$TMP/stale" "$TMP/missing-decl"
cat >"$TMP/registry.yaml" <<'YAML'
schema_version: skillos.tenant_routing_registry.v1
mappings:
  good:
    infisical_project_id: 11111111-1111-4111-8111-111111111111
    description: Good row
    supabase:
      project_ref: abcdefghijklmnopqrst
      project_url: https://abcdefghijklmnopqrst.supabase.co
      pooler_mode: dedicated
    vercel:
      project_id: prj_good
      project_name: good
    canonical_keys:
      DATABASE_URL:
        validator: postgres_url_contains_supabase_ref
        expected_supabase_ref: abcdefghijklmnopqrst
      NEXT_PUBLIC_SUPABASE_URL:
        validator: equals
        expected_value: https://abcdefghijklmnopqrst.supabase.co
      SUPABASE_SERVICE_ROLE_KEY:
        validator: supabase_jwt_ref_claim_equals
        expected_ref_claim: abcdefghijklmnopqrst
      NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY:
        validator: supabase_publishable_key_format
        expected_format: supabase_publishable_key
  todo-row:
    infisical_project_id: TODO_ASK_JOSHUA
    description: TODO
    supabase:
      project_ref: TODO
      project_url: TODO
      pooler_mode: TODO
    canonical_keys: {}
YAML

cat >"$TMP/good/.zs-tenant.yaml" <<'YAML'
schema_version: skillos.tenant_routing_repo_declaration.v1
project_slug: good
infisical_project_id: 11111111-1111-4111-8111-111111111111
expected_supabase_ref: abcdefghijklmnopqrst
expected_vercel_project_id: prj_good
deploy_targets:
  - kind: vercel
    env: production
    keys:
      - DATABASE_URL
YAML

cat >"$TMP/stale/.zs-tenant.yaml" <<'YAML'
schema_version: 1
tenant:
  slug: stale
YAML

if python3 -m py_compile "$SCRIPT"; then
  pass "script py_compile"
else
  fail "script py_compile"
fi
"$SCRIPT" --registry "$TMP/registry.yaml" --require good --repo "good=$TMP/good" --json >"$TMP/good.json"
assert_jq "$TMP/good.json" '.status == "pass" and .fail_count == 0 and .rows[0].declaration_status == "pass"' "valid row and declaration pass"

"$SCRIPT" --registry "$TMP/registry.yaml" --require todo-row --json >"$TMP/todo.json" 2>/dev/null
assert_jq "$TMP/todo.json" '.status == "fail" and (.rows[0].failures | index("registry_field_missing:infisical_project_id")) and (.rows[0].failures | index("registry_field_missing:canonical_keys"))' "TODO registry row fails"

"$SCRIPT" --registry "$TMP/registry.yaml" --require absent --json >"$TMP/absent.json" 2>/dev/null
assert_jq "$TMP/absent.json" '.status == "fail" and (.rows[0].failures | index("registry_row_missing"))' "missing registry row fails"

cat >"$TMP/absent-disposition.json" <<'JSON'
{
  "schema_version": "flywheel.tenant_registry_disposition.v1",
  "slug": "absent",
  "status": "skip_with_reason",
  "reason": "direct_postgres_no_infisical_supabase_surface",
  "registry_row_required": false,
  "repo_declaration_required": false,
  "evidence_refs": ["fixture://direct-postgres"]
}
JSON
"$SCRIPT" --registry "$TMP/registry.yaml" --require absent --disposition "absent=$TMP/absent-disposition.json" --json >"$TMP/absent-disposition.out.json"
assert_jq "$TMP/absent-disposition.out.json" '.status == "pass" and .rows[0].registry_status == "skipped" and .rows[0].declaration_status == "skipped"' "disposition receipt can skip non-applicable registry row"

"$SCRIPT" --registry "$TMP/registry.yaml" --require good --repo "good=$TMP/stale" --json >"$TMP/stale.json" 2>/dev/null
assert_jq "$TMP/stale.json" '.status == "fail" and (.rows[0].failures | index("repo_declaration_schema_mismatch")) and (.rows[0].failures | index("repo_declaration_slug_mismatch"))' "stale declaration schema fails"

"$SCRIPT" --registry "$TMP/registry.yaml" --require good --repo "good=$TMP/missing-decl" --json >"$TMP/missing-decl.json" 2>/dev/null
assert_jq "$TMP/missing-decl.json" '.status == "fail" and (.rows[0].failures | index("repo_declaration_missing"))' "missing declaration fails"

printf 'RESULT pass=%d fail=%d\n' "$pass_count" "$fail_count"
exit "$fail_count"
