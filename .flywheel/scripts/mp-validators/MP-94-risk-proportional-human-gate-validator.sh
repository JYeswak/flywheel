#!/usr/bin/env bash
set -euo pipefail
mp_id="MP-94"; slug="risk-proportional-human-gate"; json=0
[[ "${1:-}" == "--json" ]] && { json=1; shift; }
target="${1:-}"
emit(){ local status="$1" reason="$2" rc="$3"; if [[ "$json" -eq 1 ]]; then jq -nc --arg mp "$mp_id" --arg slug "$slug" --arg target "$target" --arg status "$status" --arg reason "$reason" '{schema_version:"mp-validator.row/v1",mp_id:$mp,slug:$slug,validator:"MP-94-risk-proportional-human-gate-validator.sh",target:$target,status:$status,reason:$reason}'; else printf '%s %s: %s\n' "$status" "$mp_id" "$reason"; fi; exit "$rc"; }
hay(){ rg -qi "$1" "$target" 2>/dev/null; }
[[ -e "$target" ]] || emit FAIL "target missing" 1
hay 'confidence threshold|confidence_threshold|risk tier|risk_tier' && hay 'approval context|human approval|approval' && hay 'escalation timeout|timeout' && hay 'override metric|override' && hay 'automation can proceed|proceed alone' && emit PASS "human gate scales by confidence, risk, approval context, timeout, override metrics" 0
hay 'human-in-the-loop|human in the loop|approval|consent|healthcare|KYC|AML|billing credit|regulated|security testing' && emit FAIL "human-gated surface lacks risk-proportional gate evidence" 1
emit SKIP "not a detected risk/human gate surface" 2
