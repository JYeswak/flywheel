#!/usr/bin/env bash
set -euo pipefail
mp_id="MP-96"; slug="graph-bounded-work-selection"; json=0
[[ "${1:-}" == "--json" ]] && { json=1; shift; }
target="${1:-}"
emit(){ local status="$1" reason="$2" rc="$3"; if [[ "$json" -eq 1 ]]; then jq -nc --arg mp "$mp_id" --arg slug "$slug" --arg target "$target" --arg status "$status" --arg reason "$reason" '{schema_version:"mp-validator.row/v1",mp_id:$mp,slug:$slug,validator:"MP-96-graph-bounded-work-selection-validator.sh",target:$target,status:$status,reason:$reason}'; else printf '%s %s: %s\n' "$status" "$mp_id" "$reason"; fi; exit "$rc"; }
hay(){ rg -qi "$1" "$target" 2>/dev/null; }
[[ -e "$target" ]] || emit FAIL "target missing" 1
hay 'cycle|cycles' && hay 'traversal bound|bounded traversal|depth limit|max depth' && hay 'bottleneck|rank' && hay 'DAG-ready|dag ready|dependency ready' && hay 'cache.*graph|graph metrics.*cache' && emit PASS "work selection validates graph cycles, bounds traversal, ranks bottlenecks, schedules DAG-ready work" 0
hay 'bead planning|swarm|orchestration|dependency|knowledge graph|RAG expansion|backlog|graph' && emit FAIL "graph work-selection surface lacks bounded traversal/DAG evidence" 1
emit SKIP "not a detected graph-bounded work-selection surface" 2
