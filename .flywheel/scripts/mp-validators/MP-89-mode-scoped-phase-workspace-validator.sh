#!/usr/bin/env bash
set -euo pipefail
mp_id="MP-89"; slug="mode-scoped-phase-workspace"; json=0
[[ "${1:-}" == "--json" ]] && { json=1; shift; }
target="${1:-}"
emit(){ local status="$1" reason="$2" rc="$3"; if [[ "$json" -eq 1 ]]; then jq -nc --arg mp "$mp_id" --arg slug "$slug" --arg target "$target" --arg status "$status" --arg reason "$reason" '{schema_version:"mp-validator.row/v1",mp_id:$mp,slug:$slug,validator:"MP-89-mode-scoped-phase-workspace-validator.sh",target:$target,status:$status,reason:$reason}'; else printf '%s %s: %s\n' "$status" "$mp_id" "$reason"; fi; exit "$rc"; }
hay(){ rg -qi "$1" "$target" 2>/dev/null; }
[[ -e "$target" ]] || emit FAIL "target missing" 1
hay 'scope decision|scope probe|smallest valid mode|mode' && hay 'phase|activated bundle|bundle' && hay 'out-of-scope|out of scope|adjacent work' && hay 'expected output path|output path' && emit PASS "workflow scopes mode, phases, bundles, exclusions, and output paths before mutation" 0
hay 'multi-phase|phase|doctor mode|billing hardening|legal audit|skill authoring|dashboard panel|mutation' && emit FAIL "multi-phase workflow lacks mode-scoped workspace evidence" 1
emit SKIP "not a detected mode-scoped phase workflow" 2
