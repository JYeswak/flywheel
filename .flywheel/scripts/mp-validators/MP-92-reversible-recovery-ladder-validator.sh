#!/usr/bin/env bash
set -euo pipefail
mp_id="MP-92"; slug="reversible-recovery-ladder"; json=0
[[ "${1:-}" == "--json" ]] && { json=1; shift; }
target="${1:-}"
emit(){ local status="$1" reason="$2" rc="$3"; if [[ "$json" -eq 1 ]]; then jq -nc --arg mp "$mp_id" --arg slug "$slug" --arg target "$target" --arg status "$status" --arg reason "$reason" '{schema_version:"mp-validator.row/v1",mp_id:$mp,slug:$slug,validator:"MP-92-reversible-recovery-ladder-validator.sh",target:$target,status:$status,reason:$reason}'; else printf '%s %s: %s\n' "$status" "$mp_id" "$reason"; fi; exit "$rc"; }
hay(){ rg -qi "$1" "$target" 2>/dev/null; }
[[ -e "$target" ]] || emit FAIL "target missing" 1
hay 'ladder|level' && hay 'preserve|preserves' && hay 're-?probe|probe after' && hay 'failure mode|route.*failure' && hay 'nuclear|approval-only|approval only' && emit PASS "recovery ladder preserves state, re-probes, routes by failure, gates nuclear steps" 0
hay 'docker|storage cleanup|cache pruning|snapshot|container orphan|volume repair|restart|destroy' && emit FAIL "destructive recovery surface lacks reversible ladder evidence" 1
emit SKIP "not a detected destructive recovery surface" 2
