#!/usr/bin/env bash
set -euo pipefail
mp_id="MP-86"; slug="clean-room-reproduction-before-upstream-action"; json=0
[[ "${1:-}" == "--json" ]] && { json=1; shift; }
target="${1:-}"
emit(){ local status="$1" reason="$2" rc="$3"; if [[ "$json" -eq 1 ]]; then jq -nc --arg mp "$mp_id" --arg slug "$slug" --arg target "$target" --arg status "$status" --arg reason "$reason" '{schema_version:"mp-validator.row/v1",mp_id:$mp,slug:$slug,validator:"MP-86-clean-room-reproduction-before-upstream-action-validator.sh",target:$target,status:$status,reason:$reason}'; else printf '%s %s: %s\n' "$status" "$mp_id" "$reason"; fi; exit "$rc"; }
hay(){ rg -qi "$1" "$target" 2>/dev/null; }
[[ -e "$target" ]] || emit FAIL "target missing" 1
hay 'clean clone|clean room|current environment|minimal test|fixture' && hay 'old/new behavior|old behavior|new behavior|bounded issue|PR template|issue template' && emit PASS "upstream action is gated by clean-room repro and bounded communication" 0
hay 'github issue|upstream|bug report|security report|e2e bug|third-party report|third party report' && emit FAIL "upstream/bug-report surface lacks clean-room reproduction evidence" 1
emit SKIP "not a detected upstream-action reproduction surface" 2
