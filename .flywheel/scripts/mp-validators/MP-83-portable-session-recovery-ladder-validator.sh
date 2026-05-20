#!/usr/bin/env bash
set -euo pipefail
mp_id="MP-83"; slug="portable-session-recovery-ladder"; json=0
[[ "${1:-}" == "--json" ]] && { json=1; shift; }
target="${1:-}"
emit(){ local status="$1" reason="$2" rc="$3"; if [[ "$json" -eq 1 ]]; then jq -nc --arg mp "$mp_id" --arg slug "$slug" --arg target "$target" --arg status "$status" --arg reason "$reason" '{schema_version:"mp-validator.row/v1",mp_id:$mp,slug:$slug,validator:"MP-83-portable-session-recovery-ladder-validator.sh",target:$target,status:$status,reason:$reason}'; else printf '%s %s: %s\n' "$status" "$mp_id" "$reason"; fi; exit "$rc"; }
hay(){ rg -qi "$1" "$target" 2>/dev/null; }
[[ -e "$target" ]] || emit FAIL "target missing" 1
hay 'recent sessions|list.*sessions|session archaeology|/tmp/dispatch_|dispatch_\\*' && hay 'conversion risk|respawn|recover' && hay 'provenance|re-?assert.*context|task context' && emit PASS "portable recovery lists sessions, handles respawn risk, preserves provenance/context" 0
hay 'session|respawn|recover|resume|pane|mux|tmux|account switching' && emit FAIL "session recovery surface lacks portable recovery ladder evidence" 1
emit SKIP "not a detected portable session recovery surface" 2
