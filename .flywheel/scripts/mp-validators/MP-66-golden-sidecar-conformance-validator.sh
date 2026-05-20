#!/usr/bin/env bash
set -euo pipefail
mp_id="MP-66"; slug="golden-sidecar-conformance"; json=0
[[ "${1:-}" == "--json" ]] && { json=1; shift; }
target="${1:-}"
emit(){ local status="$1" reason="$2" rc="$3"; if [[ "$json" -eq 1 ]]; then jq -nc --arg mp "$mp_id" --arg slug "$slug" --arg target "$target" --arg status "$status" --arg reason "$reason" '{schema_version:"mp-validator.row/v1",mp_id:$mp,slug:$slug,validator:"MP-66-golden-sidecar-conformance-validator.sh",target:$target,status:$status,reason:$reason}'; else printf '%s %s: %s\n' "$status" "$mp_id" "$reason"; fi; exit "$rc"; }
[[ -e "$target" ]] || emit FAIL "target missing" 1
rg -qi "sidecar|threshold|golden|conformance|input_hash|measured|probe|health|listing|run\\.jsonl" "$target" 2>/dev/null && emit PASS "golden/sidecar conformance marker present" 0
rg -qi "golden|generated|render|media|model output|tts|voice|video|screenshot|fixture" "$target" 2>/dev/null && emit FAIL "subjective/generated output surface lacks sidecar conformance marker" 1
emit SKIP "target is not a golden/generated-output conformance surface" 2
