#!/usr/bin/env bash
set -euo pipefail
mp_id="MP-90"; slug="adjacent-skill-boundary-router"; json=0
[[ "${1:-}" == "--json" ]] && { json=1; shift; }
target="${1:-}"
emit(){ local status="$1" reason="$2" rc="$3"; if [[ "$json" -eq 1 ]]; then jq -nc --arg mp "$mp_id" --arg slug "$slug" --arg target "$target" --arg status "$status" --arg reason "$reason" '{schema_version:"mp-validator.row/v1",mp_id:$mp,slug:$slug,validator:"MP-90-adjacent-skill-boundary-router-validator.sh",target:$target,status:$status,reason:$reason}'; else printf '%s %s: %s\n' "$status" "$mp_id" "$reason"; fi; exit "$rc"; }
hay(){ rg -qi "$1" "$target" 2>/dev/null; }
[[ -e "$target" ]] || emit FAIL "target missing" 1
hay 'smell-test matrix|smell test|if not, use|if not use' && hay 'boundary|boundaries|sibling' && hay 'companion skill|handoff output|input shape' && emit PASS "skill routes adjacent boundaries with sibling/companion handoff shape" 0
hay 'skill|jsm|practice group|expertise|router|handoff|companion' && emit FAIL "skill-like surface lacks adjacent boundary router evidence" 1
emit SKIP "not a detected skill-boundary routing surface" 2
