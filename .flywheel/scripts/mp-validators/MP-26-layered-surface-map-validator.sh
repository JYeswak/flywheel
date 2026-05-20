#!/usr/bin/env bash
set -euo pipefail
mp_id="MP-26"; slug="layered-surface-map"; json=0
[[ "${1:-}" == "--json" ]] && { json=1; shift; }
target="${1:-}"
emit(){ local status="$1" reason="$2" rc="$3"; if [[ "$json" -eq 1 ]]; then jq -nc --arg mp "$mp_id" --arg slug "$slug" --arg target "$target" --arg status "$status" --arg reason "$reason" '{schema_version:"mp-validator.row/v1",mp_id:$mp,slug:$slug,validator:"MP-26-layered-surface-map-validator.sh",target:$target,status:$status,reason:$reason}'; else printf '%s %s: %s\n' "$status" "$mp_id" "$reason"; fi; exit "$rc"; }
[[ -e "$target" ]] || emit FAIL "target missing" 1
rg -qi "The Layers|by Layer|Entry[[:space:]]*[-=]>|entry.*storage|Boundary.*Service|Build != Runtime|browser.*CDN.*application|producer.*measurement.*consumer.*promotion_path" "$target" 2>/dev/null && emit PASS "layer map or responsibility chain present" 0
if [[ -f "$target" && "$target" =~ \.(md|mdx)$ ]]; then emit FAIL "architecture/method markdown lacks layer map" 1; fi
emit SKIP "target is not a layer-mapped surface" 2
