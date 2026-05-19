#!/usr/bin/env bash
set -euo pipefail
mp_id="MP-91"; slug="progress-counter-forced-motion-loop"; json=0
[[ "${1:-}" == "--json" ]] && { json=1; shift; }
target="${1:-}"
emit(){ local status="$1" reason="$2" rc="$3"; if [[ "$json" -eq 1 ]]; then jq -nc --arg mp "$mp_id" --arg slug "$slug" --arg target "$target" --arg status "$status" --arg reason "$reason" '{schema_version:"mp-validator.row/v1",mp_id:$mp,slug:$slug,validator:"MP-91-progress-counter-forced-motion-loop-validator.sh",target:$target,status:$status,reason:$reason}'; else printf '%s %s: %s\n' "$status" "$mp_id" "$reason"; fi; exit "$rc"; }
hay(){ rg -qi "$1" "$target" 2>/dev/null; }
[[ -e "$target" ]] || emit FAIL "target missing" 1
hay 'productive event|progress counter|moved the system' && hay 'no-op|noop|stall counter|repeated.*stall' && hay 'threshold.*behavior|behavior.*threshold|append-only receipt' && emit PASS "loop records progress/stall counters and thresholded append-only movement receipts" 0
hay 'cron|dispatch loop|retry|batch processor|blocker|tick|HOLD|stall' && emit FAIL "loop-like surface lacks progress-counter forced-motion evidence" 1
emit SKIP "not a detected progress-loop surface" 2
