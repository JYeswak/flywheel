#!/usr/bin/env bash
set -euo pipefail
mp_id="MP-15"; slug="canonical-cli-scoping"; json=0
[[ "${1:-}" == "--json" ]] && { json=1; shift; }
target="${1:-}"
emit(){ local status="$1" reason="$2" rc="$3"; if [[ "$json" -eq 1 ]]; then jq -nc --arg mp "$mp_id" --arg slug "$slug" --arg target "$target" --arg status "$status" --arg reason "$reason" '{schema_version:"mp-validator.row/v1",mp_id:$mp,slug:$slug,validator:"MP-15-canonical-cli-scoping-validator.sh",target:$target,status:$status,reason:$reason}'; else printf '%s %s: %s\n' "$status" "$mp_id" "$reason"; fi; exit "$rc"; }
[[ -e "$target" ]] || emit FAIL "target missing" 1
[[ -f "$target" ]] || emit SKIP "target is not a single CLI file" 2
[[ -x "$target" || "$target" =~ \.(sh|py|js|ts|mjs)$ ]] || emit SKIP "target is not executable/script-like" 2
missing=()
for word in doctor health repair validate audit why; do rg -q "(^|[^A-Za-z])$word([^A-Za-z]|$)" "$target" 2>/dev/null || missing+=("$word"); done
[[ "${#missing[@]}" -eq 0 ]] && emit PASS "canonical CLI doctor/health/repair/validate/audit/why present" 0
rg -qi "case \"\\$\\{1:-\\}\"|argparse|click|commander|subcommand|--json" "$target" 2>/dev/null || emit SKIP "script-like target is not a detected CLI dispatcher" 2
emit FAIL "missing canonical CLI subcommands: ${missing[*]}" 1
