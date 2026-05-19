#!/usr/bin/env bash
set -euo pipefail
mp_id="MP-02"; slug="conformance-fixtures"; json=0
[[ "${1:-}" == "--json" ]] && { json=1; shift; }
target="${1:-}"
emit(){ local status="$1" reason="$2" rc="$3"; if [[ "$json" -eq 1 ]]; then jq -nc --arg mp "$mp_id" --arg slug "$slug" --arg target "$target" --arg status "$status" --arg reason "$reason" '{schema_version:"mp-validator.row/v1",mp_id:$mp,slug:$slug,validator:"MP-02-conformance-fixtures-validator.sh",target:$target,status:$status,reason:$reason}'; else printf '%s %s: %s\n' "$status" "$mp_id" "$reason"; fi; exit "$rc"; }
[[ -e "$target" ]] || emit FAIL "target missing" 1
if [[ -f "$target" ]]; then
  case "$target" in
    */fixtures/*|*/tests/fixtures/*) [[ -f "$(dirname "$target")/PROVENANCE.md" ]] && emit PASS "fixture file directory has PROVENANCE.md" 0 || emit FAIL "fixture file directory lacks PROVENANCE.md" 1 ;;
    *) emit SKIP "target is not a fixture surface" 2 ;;
  esac
fi
dirs=()
while IFS= read -r d; do dirs+=("$d"); done < <(find "$target" \( -path '*/fixtures*' -o -path '*/tests/fixtures*' \) -type d 2>/dev/null | sort)
[[ "${#dirs[@]}" -gt 0 ]] || emit SKIP "no fixture directories found" 2
missing=()
for d in "${dirs[@]}"; do [[ -f "$d/PROVENANCE.md" ]] || missing+=("$d"); done
[[ "${#missing[@]}" -eq 0 ]] && emit PASS "all ${#dirs[@]} fixture directories have PROVENANCE.md" 0
emit FAIL "${#missing[@]} fixture directories lack PROVENANCE.md" 1
