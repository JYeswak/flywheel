#!/usr/bin/env bash
set -euo pipefail
mp_id="MP-80"; slug="scope-token-operation-matrix"; json=0
[[ "${1:-}" == "--json" ]] && { json=1; shift; }
target="${1:-}"
emit(){ local status="$1" reason="$2" rc="$3"; if [[ "$json" -eq 1 ]]; then jq -nc --arg mp "$mp_id" --arg slug "$slug" --arg target "$target" --arg status "$status" --arg reason "$reason" '{schema_version:"mp-validator.row/v1",mp_id:$mp,slug:$slug,validator:"MP-80-scope-token-operation-matrix-validator.sh",target:$target,status:$status,reason:$reason}'; else printf '%s %s: %s\n' "$status" "$mp_id" "$reason"; fi; exit "$rc"; }
hay(){ rg -qi "$1" "$target" 2>/dev/null; }
[[ -e "$target" ]] || emit FAIL "target missing" 1
hay 'scope matrix|scope_token|scope-token|operation matrix|operation_matrix' && hay 'token.*validat|validat.*token|probe.*operation|operation.*probe' && hay 'resource.?id|tenant|project|environment' && emit PASS "scope matrix validates token/resource/operation path" 0
hay 'cloudflare|supabase|vercel|sharepoint|youtube|nango|railway|azure|provider|token rotation|operator token|tenant' && emit FAIL "provider/token surface lacks scope-token-operation matrix evidence" 1
emit SKIP "not a detected multi-tenant provider token surface" 2
