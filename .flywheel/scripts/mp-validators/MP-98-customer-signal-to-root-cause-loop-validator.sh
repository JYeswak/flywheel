#!/usr/bin/env bash
set -euo pipefail
mp_id="MP-98"; slug="customer-signal-to-root-cause-loop"; json=0
[[ "${1:-}" == "--json" ]] && { json=1; shift; }
target="${1:-}"
emit(){ local status="$1" reason="$2" rc="$3"; if [[ "$json" -eq 1 ]]; then jq -nc --arg mp "$mp_id" --arg slug "$slug" --arg target "$target" --arg status "$status" --arg reason "$reason" '{schema_version:"mp-validator.row/v1",mp_id:$mp,slug:$slug,validator:"MP-98-customer-signal-to-root-cause-loop-validator.sh",target:$target,status:$status,reason:$reason}'; else printf '%s %s: %s\n' "$status" "$mp_id" "$reason"; fi; exit "$rc"; }
hay(){ rg -qi "$1" "$target" 2>/dev/null; }
[[ -e "$target" ]] || emit FAIL "target missing" 1
hay 'classif(y|ies|ication).*axis|multiple axes|signal.*axis' && hay 'expertise|urgency|route' && hay 'SLA|clock' && hay 'evidence' && hay 'repeated categor|product issue|process issue|root cause' && emit PASS "customer signal loop classifies, routes, clocks SLA, records evidence, escalates root causes" 0
hay 'support|billing dispute|incident communication|email delivery|appointment|churn|account management|service recovery|customer signal' && emit FAIL "customer-signal surface lacks root-cause loop evidence" 1
emit SKIP "not a detected customer-signal workflow" 2
