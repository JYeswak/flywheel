#!/usr/bin/env bash
set -euo pipefail
mp_id="MP-01"; slug="sentinel-doctor-surface"; json=0
[[ "${1:-}" == "--json" ]] && { json=1; shift; }
target="${1:-}"
emit(){ local status="$1" reason="$2" rc="$3"; if [[ "$json" -eq 1 ]]; then jq -nc --arg mp "$mp_id" --arg slug "$slug" --arg target "$target" --arg status "$status" --arg reason "$reason" '{schema_version:"mp-validator.row/v1",mp_id:$mp,slug:$slug,validator:"MP-01-sentinel-doctor-surface-validator.sh",target:$target,status:$status,reason:$reason}'; else printf '%s %s: %s\n' "$status" "$mp_id" "$reason"; fi; exit "$rc"; }
[[ -e "$target" ]] || emit FAIL "target missing" 1
if [[ -d "$target" ]]; then
  find "$target" \( -iname '*sentinel*doctor*' -o -iname 'test_doctor_sentinel_probe*' \) -print -quit | grep -q . && emit PASS "sentinel doctor probe artifact exists" 0
  rg -q "__sentinel|sentinel_.*--help|Commands:" "$target" 2>/dev/null && emit PASS "sentinel fallback logic present" 0
  emit SKIP "no CLI doctor sentinel surface detected" 2
fi
rg -q "__sentinel|sentinel_.*--help|Commands:|test_doctor_sentinel_probe" "$target" 2>/dev/null && emit PASS "sentinel probe or Commands fallback present" 0
rg -qi "doctor|subcommand|--help|case \"\\$\\{1:-\\}\"|argparse|click" "$target" 2>/dev/null && emit FAIL "CLI-like surface lacks sentinel fallback evidence" 1
emit SKIP "target is not a detected CLI/doctor surface" 2
