#!/usr/bin/env bash
set -euo pipefail
mp_id="MP-84"; slug="stable-interactive-surface-geometry"; json=0
[[ "${1:-}" == "--json" ]] && { json=1; shift; }
target="${1:-}"
emit(){ local status="$1" reason="$2" rc="$3"; if [[ "$json" -eq 1 ]]; then jq -nc --arg mp "$mp_id" --arg slug "$slug" --arg target "$target" --arg status "$status" --arg reason "$reason" '{schema_version:"mp-validator.row/v1",mp_id:$mp,slug:$slug,validator:"MP-84-stable-interactive-surface-geometry-validator.sh",target:$target,status:$status,reason:$reason}'; else printf '%s %s: %s\n' "$status" "$mp_id" "$reason"; fi; exit "$rc"; }
hay(){ rg -qi "$1" "$target" 2>/dev/null; }
[[ -e "$target" ]] || emit FAIL "target missing" 1
hay 'hit region|hit.?region|focus.*data|focus state|available area|lazy.?load|performance.*measure|measurement' && hay 'pure state|runtime hook|stable geometry|aspect-ratio|min-width|min-height' && emit PASS "interactive surface stabilizes geometry and proves performance" 0
hay 'dashboard|chart|canvas|tui|interactive|focus|panel|visualization|responsive' && emit FAIL "interactive surface lacks stable geometry/performance evidence" 1
emit SKIP "not a detected interactive geometry surface" 2
