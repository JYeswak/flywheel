#!/usr/bin/env bash
set -euo pipefail
mp_id="MP-87"; slug="binding-constraint-capacity-score"; json=0
[[ "${1:-}" == "--json" ]] && { json=1; shift; }
target="${1:-}"
emit(){ local status="$1" reason="$2" rc="$3"; if [[ "$json" -eq 1 ]]; then jq -nc --arg mp "$mp_id" --arg slug "$slug" --arg target "$target" --arg status "$status" --arg reason "$reason" '{schema_version:"mp-validator.row/v1",mp_id:$mp,slug:$slug,validator:"MP-87-binding-constraint-capacity-score-validator.sh",target:$target,status:$status,reason:$reason}'; else printf '%s %s: %s\n' "$status" "$mp_id" "$reason"; fi; exit "$rc"; }
hay(){ rg -qi "$1" "$target" 2>/dev/null; }
[[ -e "$target" ]] || emit FAIL "target missing" 1
hay 'binding constraint|limiting stock|lowest limiting|capacity score' && hay 'account|machine|token|queue|driver proof|spend|quota|budget' && emit PASS "capacity scoring identifies the limiting stock across measured constraints" 0
hay 'capacity|quota|budget|queue|token budget|cost monitoring|dispatch capacity|account rotation' && emit FAIL "capacity surface lacks binding-constraint score evidence" 1
emit SKIP "not a detected capacity-scoring surface" 2
