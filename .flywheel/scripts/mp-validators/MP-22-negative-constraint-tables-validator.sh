#!/usr/bin/env bash
set -euo pipefail
mp_id="MP-22"; slug="negative-constraint-tables"; json=0
[[ "${1:-}" == "--json" ]] && { json=1; shift; }
target="${1:-}"
emit(){ local status="$1" reason="$2" rc="$3"; if [[ "$json" -eq 1 ]]; then jq -nc --arg mp "$mp_id" --arg slug "$slug" --arg target "$target" --arg status "$status" --arg reason "$reason" '{schema_version:"mp-validator.row/v1",mp_id:$mp,slug:$slug,validator:"MP-22-negative-constraint-tables-validator.sh",target:$target,status:$status,reason:$reason}'; else printf '%s %s: %s\n' "$status" "$mp_id" "$reason"; fi; exit "$rc"; }
[[ -e "$target" ]] || emit FAIL "target missing" 1
rg -qi "Anti-Patterns|Hard Constraints|Gotchas|Never[[:space:]]*\\|[[:space:]]*Why[[:space:]]*\\|[[:space:]]*Fix|must_not|non-negotiable|Failure branches" "$target" 2>/dev/null && emit PASS "negative constraint section/table present" 0
if [[ -f "$target" && "$target" =~ \.(md|mdx)$ ]]; then emit FAIL "markdown method surface lacks negative constraints" 1; fi
emit SKIP "target is not a documentation/method surface" 2
