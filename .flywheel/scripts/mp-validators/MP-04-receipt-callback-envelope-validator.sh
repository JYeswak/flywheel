#!/usr/bin/env bash
set -euo pipefail
mp_id="MP-04"; slug="receipt-callback-envelope"; json=0
[[ "${1:-}" == "--json" ]] && { json=1; shift; }
target="${1:-}"
emit(){ local status="$1" reason="$2" rc="$3"; if [[ "$json" -eq 1 ]]; then jq -nc --arg mp "$mp_id" --arg slug "$slug" --arg target "$target" --arg status "$status" --arg reason "$reason" '{schema_version:"mp-validator.row/v1",mp_id:$mp,slug:$slug,validator:"MP-04-receipt-callback-envelope-validator.sh",target:$target,status:$status,reason:$reason}'; else printf '%s %s: %s\n' "$status" "$mp_id" "$reason"; fi; exit "$rc"; }
[[ -e "$target" ]] || emit FAIL "target missing" 1
if [[ -f "$target" && "$target" =~ \.json$ ]]; then
  jq -e '.schema_version // .schemaVersion // empty' "$target" >/dev/null 2>&1 && emit PASS "JSON artifact has schema_version" 0 || emit FAIL "JSON artifact lacks schema_version" 1
fi
rg -qi "schema_version|schemaVersion" "$target" 2>/dev/null || { rg -qi "callback|receipt|evidence_path|evidence=|dispatch-log|validation[-_ ]receipt" "$target" 2>/dev/null && emit FAIL "receipt/callback surface lacks schema_version" 1 || emit SKIP "target is not a receipt/callback surface" 2; }
rg -qi "evidence_path|evidence=|receipt|callback|validation[-_ ]receipt|artifact_checks|schema_version" "$target" 2>/dev/null && emit PASS "schema-versioned receipt/callback evidence marker present" 0
emit SKIP "target has schema marker but no callback/receipt role" 2
