#!/usr/bin/env bash
set -euo pipefail
mp_id="MP-33"; slug="schema-envelope-const-ratchet"; json=0
[[ "${1:-}" == "--json" ]] && { json=1; shift; }
target="${1:-}"
emit(){ local status="$1" reason="$2" rc="$3"; if [[ "$json" -eq 1 ]]; then jq -nc --arg mp "$mp_id" --arg slug "$slug" --arg target "$target" --arg status "$status" --arg reason "$reason" '{schema_version:"mp-validator.row/v1",mp_id:$mp,slug:$slug,validator:"MP-33-schema-envelope-const-ratchet-validator.sh",target:$target,status:$status,reason:$reason}'; else printf '%s %s: %s\n' "$status" "$mp_id" "$reason"; fi; exit "$rc"; }
[[ -e "$target" ]] || emit FAIL "target missing" 1
if [[ -f "$target" && "$target" =~ \.schema\.json$ ]]; then
  jq -e '(.properties.schema_version.const // .properties.schema_version.enum // empty) and (.required | index("schema_version"))' "$target" >/dev/null 2>&1 && emit PASS "JSON schema const-ratchets schema_version" 0 || emit FAIL "schema lacks required const schema_version" 1
fi
if [[ -f "$target" && "$target" =~ \.json$ ]]; then
  jq -e '.schema_version // .schemaVersion // empty' "$target" >/dev/null 2>&1 && emit PASS "durable JSON has schema_version envelope" 0 || emit FAIL "durable JSON lacks schema_version envelope" 1
fi
rg -qi "schema_version|JSON Schema|Zod|additionalProperties|required fields|const" "$target" 2>/dev/null && emit PASS "schema envelope marker present" 0
rg -qi "receipt|handoff|dispatch|callback|artifact|schema" "$target" 2>/dev/null && emit FAIL "durable artifact/schema surface lacks explicit schema envelope marker" 1
emit SKIP "target is not a durable artifact/schema surface" 2
