#!/usr/bin/env bash
set -euo pipefail
mp_id="MP-99"; slug="authorized-sandbox-envelope"; json=0
[[ "${1:-}" == "--json" ]] && { json=1; shift; }
target="${1:-}"
emit(){ local status="$1" reason="$2" rc="$3"; if [[ "$json" -eq 1 ]]; then jq -nc --arg mp "$mp_id" --arg slug "$slug" --arg target "$target" --arg status "$status" --arg reason "$reason" '{schema_version:"mp-validator.row/v1",mp_id:$mp,slug:$slug,validator:"MP-99-authorized-sandbox-envelope-validator.sh",target:$target,status:$status,reason:$reason}'; else printf '%s %s: %s\n' "$status" "$mp_id" "$reason"; fi; exit "$rc"; }
hay(){ rg -qi "$1" "$target" 2>/dev/null; }
[[ -e "$target" ]] || emit FAIL "target missing" 1
hay 'written scope|scope' && hay 'execution-layer authorization|authorized sandbox|sandbox envelope|authorization envelope' && hay 'least-privilege|least privilege' && hay 'deny-by-default egress|deny by default egress|egress' && hay 'output scanning|audit trail|audit trails' && hay 'human approval|boundary expansion' && emit PASS "sandbox envelope has scope, execution authorization, least privilege, egress deny, scanning, audit, approval" 0
hay 'sandbox|penetration test|secret scan|destructive command|customer data|multi-tenant|webhook|untrusted tool' && emit FAIL "sandbox/tool surface lacks authorized sandbox envelope evidence" 1
emit SKIP "not a detected authorized sandbox surface" 2
