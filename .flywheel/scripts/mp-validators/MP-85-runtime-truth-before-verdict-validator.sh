#!/usr/bin/env bash
set -euo pipefail
mp_id="MP-85"; slug="runtime-truth-before-verdict"; json=0
[[ "${1:-}" == "--json" ]] && { json=1; shift; }
target="${1:-}"
emit(){ local status="$1" reason="$2" rc="$3"; if [[ "$json" -eq 1 ]]; then jq -nc --arg mp "$mp_id" --arg slug "$slug" --arg target "$target" --arg status "$status" --arg reason "$reason" '{schema_version:"mp-validator.row/v1",mp_id:$mp,slug:$slug,validator:"MP-85-runtime-truth-before-verdict-validator.sh",target:$target,status:$status,reason:$reason}'; else printf '%s %s: %s\n' "$status" "$mp_id" "$reason"; fi; exit "$rc"; }
hay(){ rg -qi "$1" "$target" 2>/dev/null; }
[[ -e "$target" ]] || emit FAIL "target missing" 1
hay 'inventory|source.?of.?truth|ledger' && hay 'freshness|live capture|primary.?source|runtime truth' && hay 'UNCLEAR|line id|source hash|hash' && emit PASS "verdicts cite fresh runtime inventory/source evidence" 0
hay 'verdict|compliance|privacy|policy audit|billing|legal|source code|stale|tag manager' && emit FAIL "verdict surface lacks runtime truth/freshness evidence" 1
emit SKIP "not a detected runtime-verdict surface" 2
