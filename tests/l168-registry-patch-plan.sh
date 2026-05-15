#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/l168-registry-patch-plan.py"
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

if python3 -m py_compile "$SCRIPT"; then
  pass "script py_compile"
else
  fail "script py_compile"
fi

cat >"$TMP/wave.json" <<'JSON'
{
  "schema_version": "flywheel.l168_wave_registry_input.v1",
  "current_failures": {
    "vrtx": ["registry_row_missing", "repo_declaration_missing"],
    "unknown": ["registry_row_missing"]
  },
  "non_secret_evidence": {
    "vrtx": {
      "infisical_project_id": "f6e31796-9434-486d-94bd-9e23a27d5c44",
      "supabase_project_ref": "hsmyagcerajgjmlljtmx",
      "supabase_project_url": "https://hsmyagcerajgjmlljtmx.supabase.co",
      "candidate_server_keys": ["DATABASE_URL", "SUPABASE_SERVICE_ROLE_KEY"],
      "candidate_client_keys": ["NEXT_PUBLIC_SUPABASE_URL"]
    },
    "unknown": {
      "known_state": "missing canonical ids"
    }
  }
}
JSON

cat >"$TMP/skillos.json" <<'JSON'
{
  "schema_version": "flywheel.l168_skillos_registry_input.v1",
  "rows": [
    {
      "slug": "clutterfreespaces",
      "classification": "tenant_registry_row_and_declaration_adapter_required",
      "known_non_secret_identifiers": {
        "infisical_project_id": "f8a53408-53f2-4213-9bfb-7b5154d032f3",
        "legacy_declaration_schema_version": 1,
        "legacy_tenant_slug": "cfs",
        "supabase_candidate_project_ref": "hsmyagcerajgjmlljtmx",
        "supabase_candidate_project_url": "https://hsmyagcerajgjmlljtmx.supabase.co",
        "candidate_server_keys": ["SUPABASE_URL", "SUPABASE_SERVICE_ROLE_KEY"],
        "candidate_client_keys": ["NEXT_PUBLIC_SUPABASE_URL", "NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY"]
      },
      "evidence_refs": ["fixture://cfs"]
    },
    {
      "slug": "picoz",
      "classification": "skip_with_reason_until_non_supabase_secret_context_adapter_exists",
      "disposition_ref": "fixture://picoz-disposition"
    }
  ]
}
JSON

"$SCRIPT" --input "$TMP/wave.json" --input "$TMP/skillos.json" --generated-at "2026-05-15T00:00:00Z" --json >"$TMP/plan.json"

assert_jq "$TMP/plan.json" '.schema_version == "flywheel.l168_registry_patch_plan.v1" and .action_count == 4 and .ready_action_count == 3 and .decision_required_count == 1' "plan counts ready and decision-required rows"
assert_jq "$TMP/plan.json" '.actions[] | select(.slug == "vrtx" and .action == "apply_registry_row_and_repo_declaration" and .registry_row.canonical_keys.DATABASE_URL.validator == "postgres_url_contains_supabase_ref")' "wave packet renders registry row candidate"
assert_jq "$TMP/plan.json" '.actions[] | select(.slug == "clutterfreespaces" and .repo_declaration_overlay.migration_note and (.repo_declaration_overlay.deploy_targets[0].keys | index("NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY")))' "adapter row preserves migration note and key list"
assert_jq "$TMP/plan.json" '.actions[] | select(.slug == "clutterfreespaces" and .registry_row.canonical_keys.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY.validator == "supabase_publishable_key_format" and .registry_row.canonical_keys.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY.expected_format == "supabase_publishable_key")' "modern publishable key gets format validator"
assert_jq "$TMP/plan.json" '.actions[] | select(.slug == "picoz" and .action == "apply_disposition_receipt" and .disposition_ref == "fixture://picoz-disposition")' "skip classification renders disposition action"
assert_jq "$TMP/plan.json" '.actions[] | select(.slug == "unknown" and .action == "decision_required" and (.missing_fields | index("infisical_project_id")) and (.missing_fields | index("supabase.project_ref")))' "missing ids stay explicit decisions"

printf 'RESULT pass=%d fail=%d\n' "$pass_count" "$fail_count"
exit "$fail_count"
