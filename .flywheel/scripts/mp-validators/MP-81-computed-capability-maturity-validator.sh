#!/usr/bin/env bash
set -euo pipefail
mp_id="MP-81"; slug="computed-capability-maturity"; json=0
[[ "${1:-}" == "--json" ]] && { json=1; shift; }
target="${1:-}"
emit(){ local status="$1" reason="$2" rc="$3"; if [[ "$json" -eq 1 ]]; then jq -nc --arg mp "$mp_id" --arg slug "$slug" --arg target "$target" --arg status "$status" --arg reason "$reason" '{schema_version:"mp-validator.row/v1",mp_id:$mp,slug:$slug,validator:"MP-81-computed-capability-maturity-validator.sh",target:$target,status:$status,reason:$reason}'; else printf '%s %s: %s\n' "$status" "$mp_id" "$reason"; fi; exit "$rc"; }
hay(){ rg -qi "$1" "$target" 2>/dev/null; }
[[ -e "$target" ]] || emit FAIL "target missing" 1
hay 'trigger coverage|structural validator|self-?test|replay fixture' && hay 'maturity|quality score|capability score|computed.*score|score.*telemetry' && hay 'promotion.*metadata|metadata.*alone|not.*metadata' && emit PASS "capability maturity is computed from validation and telemetry" 0
hay 'skill publishing|rollout|quality gate|capability|maturity|promotion|metadata' && emit FAIL "capability surface lacks computed maturity/promotion gate evidence" 1
emit SKIP "not a detected reusable capability maturity surface" 2
