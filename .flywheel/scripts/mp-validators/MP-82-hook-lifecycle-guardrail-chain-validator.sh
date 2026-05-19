#!/usr/bin/env bash
set -euo pipefail
mp_id="MP-82"; slug="hook-lifecycle-guardrail-chain"; json=0
[[ "${1:-}" == "--json" ]] && { json=1; shift; }
target="${1:-}"
emit(){ local status="$1" reason="$2" rc="$3"; if [[ "$json" -eq 1 ]]; then jq -nc --arg mp "$mp_id" --arg slug "$slug" --arg target "$target" --arg status "$status" --arg reason "$reason" '{schema_version:"mp-validator.row/v1",mp_id:$mp,slug:$slug,validator:"MP-82-hook-lifecycle-guardrail-chain-validator.sh",target:$target,status:$status,reason:$reason}'; else printf '%s %s: %s\n' "$status" "$mp_id" "$reason"; fi; exit "$rc"; }
hay(){ rg -qi "$1" "$target" 2>/dev/null; }
[[ -e "$target" ]] || emit FAIL "target missing" 1
hay 'event|hook' && hay 'blocking|block(ed|ing)? behavior|non.?blocking' && hay 'stdin|stdout|schema' && hay 'recursive|recursion|re-?entry' && hay 'dry.?run|audit' && emit PASS "hook lifecycle names events, schemas, recursion guards, dry-run and audit path" 0
hay 'pretooluse|posttooluse|stop hook|hook|callback|guardrail|lifecycle' && emit FAIL "hook-like surface lacks lifecycle guardrail chain evidence" 1
emit SKIP "not a detected hook or lifecycle automation surface" 2
