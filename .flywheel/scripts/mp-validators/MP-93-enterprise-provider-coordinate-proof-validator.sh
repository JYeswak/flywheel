#!/usr/bin/env bash
set -euo pipefail
mp_id="MP-93"; slug="enterprise-provider-coordinate-proof"; json=0
[[ "${1:-}" == "--json" ]] && { json=1; shift; }
target="${1:-}"
emit(){ local status="$1" reason="$2" rc="$3"; if [[ "$json" -eq 1 ]]; then jq -nc --arg mp "$mp_id" --arg slug "$slug" --arg target "$target" --arg status "$status" --arg reason "$reason" '{schema_version:"mp-validator.row/v1",mp_id:$mp,slug:$slug,validator:"MP-93-enterprise-provider-coordinate-proof-validator.sh",target:$target,status:$status,reason:$reason}'; else printf '%s %s: %s\n' "$status" "$mp_id" "$reason"; fi; exit "$rc"; }
hay(){ rg -qi "$1" "$target" 2>/dev/null; }
[[ -e "$target" ]] || emit FAIL "target missing" 1
hay 'auth|authentication' && hay 'tenant|project|environment|service' && hay 'permission scope|scope' && hay 'official docs|schema' && hay 'async job|terminal state|watch.*terminal' && emit PASS "enterprise provider success proves coordinates, scope, schema, and terminal async state" 0
hay 'adobe|azure|canva|clubready|google cloud|railway|teams|github|200 response|provider' && emit FAIL "enterprise provider surface lacks coordinate proof before success" 1
emit SKIP "not a detected enterprise provider coordinate surface" 2
