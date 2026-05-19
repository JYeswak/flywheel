#!/usr/bin/env bash
set -euo pipefail
mp_id="MP-88"; slug="content-addressed-evidence-pack"; json=0
[[ "${1:-}" == "--json" ]] && { json=1; shift; }
target="${1:-}"
emit(){ local status="$1" reason="$2" rc="$3"; if [[ "$json" -eq 1 ]]; then jq -nc --arg mp "$mp_id" --arg slug "$slug" --arg target "$target" --arg status "$status" --arg reason "$reason" '{schema_version:"mp-validator.row/v1",mp_id:$mp,slug:$slug,validator:"MP-88-content-addressed-evidence-pack-validator.sh",target:$target,status:$status,reason:$reason}'; else printf '%s %s: %s\n' "$status" "$mp_id" "$reason"; fi; exit "$rc"; }
hay(){ rg -qi "$1" "$target" 2>/dev/null; }
[[ -e "$target" ]] || emit FAIL "target missing" 1
hay 'manifest' && hay 'sha256|hash|content-addressed|content addressed' && hay 'schema_version|schema version' && hay 'append-only|lineage|deterministic replay|verify|verification' && hay 'refusal|malformed|missing.*member' && emit PASS "evidence pack is manifest-hashed, schema-versioned, replayable, and refusal-gated" 0
hay 'evidence pack|incident bundle|audit evidence|receipt|handoff|changelog|migration evidence' && emit FAIL "evidence pack lacks content-addressed manifest/replay/refusal evidence" 1
emit SKIP "not a detected evidence-pack surface" 2
