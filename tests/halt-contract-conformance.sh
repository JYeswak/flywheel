#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCHEMA="$ROOT/templates/flywheel-install/halt-contract/v1.schema.json"
FIXTURE_DIR="$ROOT/templates/flywheel-install/halt-contract/fixtures"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/halt-contract-conformance.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" || true
  fi
}

action_filter='all(.blocked_actions[]?, .permitted_actions[]?, .repair_actions[]?; test("^[a-z]+(\\.[a-z_]+)+$"))'
contract_filter='
  .schema_version == "halt-contract/v1"
  and (.severity | IN("green", "yellow", "red"))
  and (.tier | IN("host", "repo", "fleet"))
  and (.mathematically_local | type == "boolean")
  and (.blocked_actions | type == "array")
  and (.permitted_actions | type == "array")
  and (.repair_actions | type == "array")
  and (.owner | IN("repo_orch", "host_orch", "joshua"))
  and (.expires_at | test("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$"))
  and (.reason | type == "string" and length >= 1 and length <= 200)
  and all(.blocked_actions[]?, .permitted_actions[]?, .repair_actions[]?; test("^[a-z]+(\\.[a-z_]+)+$"))
  and (
    if (.severity | IN("yellow", "red")) then
      ((.blocked_actions | length) > 0)
      and (((.permitted_actions | length) > 0) or ((.no_safe_work_reason // "") | length > 0))
    else
      true
    end
  )
'

validate_with_jq() {
  local file="$1"
  jq -e "$contract_filter" "$file" >/dev/null
}

validate_contract() {
  local file="$1"
  validate_with_jq "$file" || return 1
  if command -v ajv >/dev/null 2>&1; then
    ajv validate -s "$SCHEMA" -d "$file" --strict=false >/dev/null
  fi
}

expect_valid() {
  local file="$1" label="$2"
  if validate_contract "$file"; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" || true
  fi
}

expect_invalid() {
  local file="$1" label="$2"
  if validate_contract "$file"; then
    fail "$label"
    jq . "$file" || true
  else
    pass "$label"
  fi
}

bash -n "$0" && pass "script_syntax"
jq empty "$SCHEMA" && pass "schema_json_parses" || fail "schema_json_parses"
assert_jq "$SCHEMA" '.["$schema"] == "https://json-schema.org/draft/2020-12/schema" and .properties.schema_version.const == "halt-contract/v1"' "schema_declares_draft_2020_12_and_version"
assert_jq "$SCHEMA" '.properties.severity.enum == ["green","yellow","red"] and .properties.tier.enum == ["host","repo","fleet"] and .properties.owner.enum == ["repo_orch","host_orch","joshua"]' "schema_enums"
assert_jq "$SCHEMA" '.["$defs"].action_class.pattern == "^[a-z]+(\\.[a-z_]+)+$"' "schema_action_class_pattern"

for fixture in green yellow-disk red-beads-db; do
  file="$FIXTURE_DIR/$fixture.json"
  jq empty "$file" && pass "fixture_${fixture}_json_parses" || fail "fixture_${fixture}_json_parses"
  expect_valid "$file" "fixture_${fixture}_validates"
done

jq -n '{
  schema_version:"halt-contract/v1",
  severity:"yellow",
  tier:"host",
  mathematically_local:false,
  blocked_actions:["corpus.ingest"],
  permitted_actions:[],
  repair_actions:["storage.report"],
  owner:"host_orch",
  expires_at:"2026-05-04T20:55:00Z",
  reason:"bad fixture"
}' >"$TMP/no-permitted.json"
expect_invalid "$TMP/no-permitted.json" "rejects_halt_without_permitted_actions_or_no_safe_work_reason"

jq -n '{
  schema_version:"halt-contract/v1",
  severity:"yellow",
  tier:"host",
  mathematically_local:false,
  blocked_actions:[],
  permitted_actions:["docs.plan"],
  repair_actions:["storage.report"],
  owner:"host_orch",
  expires_at:"2026-05-04T20:55:00Z",
  reason:"bad fixture"
}' >"$TMP/no-blocked.json"
expect_invalid "$TMP/no-blocked.json" "rejects_yellow_with_empty_blocked_actions"

jq -n '{
  schema_version:"halt-contract/v0",
  severity:"green",
  tier:"repo",
  mathematically_local:true,
  blocked_actions:[],
  permitted_actions:["docs.plan"],
  repair_actions:[],
  owner:"repo_orch",
  expires_at:"2026-05-04T20:55:00Z",
  reason:"bad fixture"
}' >"$TMP/schema-mismatch.json"
expect_invalid "$TMP/schema-mismatch.json" "rejects_schema_version_mismatch"

printf '\nvalidator=%s\n' "$(command -v ajv >/dev/null 2>&1 && printf 'ajv+jq' || printf 'jq')"
printf 'Summary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
