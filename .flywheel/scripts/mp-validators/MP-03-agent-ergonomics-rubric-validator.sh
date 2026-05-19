#!/usr/bin/env bash
set -euo pipefail
mp_id="MP-03"; slug="agent-ergonomics-rubric"; json=0
[[ "${1:-}" == "--json" ]] && { json=1; shift; }
target="${1:-}"
emit(){ local status="$1" reason="$2" rc="$3"; if [[ "$json" -eq 1 ]]; then jq -nc --arg mp "$mp_id" --arg slug "$slug" --arg target "$target" --arg status "$status" --arg reason "$reason" '{schema_version:"mp-validator.row/v1",mp_id:$mp,slug:$slug,validator:"MP-03-agent-ergonomics-rubric-validator.sh",target:$target,status:$status,reason:$reason}'; else printf '%s %s: %s\n' "$status" "$mp_id" "$reason"; fi; exit "$rc"; }
[[ -e "$target" ]] || emit FAIL "target missing" 1
content_target="$target"; [[ -d "$target" ]] && content_target="$target"
rg -qi "capabilities --json|robot-docs|robot docs|stdout.*stderr|exit[-_ ]code|schema_version.*capabilities|agent[-_ ]ergonomics" "$content_target" 2>/dev/null && emit PASS "agent ergonomics contract marker present" 0
if [[ -f "$target" ]] && { [[ -x "$target" ]] || [[ "$target" =~ \.(sh|py|js|ts|mjs)$ ]]; }; then
  rg -qi "case \"\\$\\{1:-\\}\"|argparse|click|commander|--json|doctor|health|validate|audit" "$target" 2>/dev/null && emit FAIL "agent-facing CLI lacks capabilities/robot-docs ergonomics marker" 1
fi
emit SKIP "target is not a detected agent-facing CLI surface" 2
