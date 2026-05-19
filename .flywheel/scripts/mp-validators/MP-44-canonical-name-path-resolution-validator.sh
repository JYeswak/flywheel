#!/usr/bin/env bash
set -euo pipefail
mp_id="MP-44"; slug="canonical-name-path-resolution"; json=0
[[ "${1:-}" == "--json" ]] && { json=1; shift; }
target="${1:-}"
emit(){ local status="$1" reason="$2" rc="$3"; if [[ "$json" -eq 1 ]]; then jq -nc --arg mp "$mp_id" --arg slug "$slug" --arg target "$target" --arg status "$status" --arg reason "$reason" '{schema_version:"mp-validator.row/v1",mp_id:$mp,slug:$slug,validator:"MP-44-canonical-name-path-resolution-validator.sh",target:$target,status:$status,reason:$reason}'; else printf '%s %s: %s\n' "$status" "$mp_id" "$reason"; fi; exit "$rc"; }
[[ -e "$target" ]] || emit FAIL "target missing" 1
rg -qi "canonical_source|resolved_value|resolution_command|canonical.*path|resolved path|realpath|pwd -P|PATH|package.json|canonical branch|alias_for|stale.*alias|stale.*cop" "$target" 2>/dev/null && emit PASS "canonical name/path resolution marker present" 0
rg -qi "install|rename|alias|PATH|branch|package|repo_path|source_repo|canonical" "$target" 2>/dev/null && emit FAIL "name/path-sensitive surface lacks resolution contract" 1
emit SKIP "target is not a name/path-sensitive surface" 2
