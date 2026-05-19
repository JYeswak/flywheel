#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/inventory/2026-05-19-rebuild/inventory-rebuild-diff.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); exit 1; }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    jq . "$file" >&2 || true
    fail "$label"
  fi
}

repo="$TMP/repo-a"
mkdir -p "$repo/scripts" "$repo/tests"
for file in kept added orphan removed; do
  printf '#!/usr/bin/env bash\nprintf %s\\\\n\n' "$file" >"$repo/scripts/$file.sh"
  chmod +x "$repo/scripts/$file.sh"
done
printf 'bash scripts/added.sh\n' >"$repo/tests/ref-added.sh"

baseline="$TMP/baseline.jsonl"
rebuild="$TMP/rebuild.jsonl"
jq -nc --arg repo_path "$repo" '{repo:"repo-a",repo_path:$repo_path,path:"scripts/kept.sh",class:"CLI",invoke_count_30d:1,age_days:9}' >>"$baseline"
jq -nc --arg repo_path "$repo" '{repo:"repo-a",repo_path:$repo_path,path:"scripts/removed.sh",class:"CLI",invoke_count_30d:0,age_days:9}' >>"$baseline"
jq -nc --arg repo_path "$repo" '{repo:"repo-a",repo_path:$repo_path,path:"scripts/kept.sh",class:"CLI",invoke_count_30d:1,age_days:9}' >>"$rebuild"
jq -nc --arg repo_path "$repo" '{repo:"repo-a",repo_path:$repo_path,path:"scripts/added.sh",class:"CLI",invoke_count_30d:0,age_days:9}' >>"$rebuild"
jq -nc --arg repo_path "$repo" '{repo:"repo-a",repo_path:$repo_path,path:"scripts/orphan.sh",class:"CLI",invoke_count_30d:0,age_days:9}' >>"$rebuild"

bash -n "$SCRIPT" && pass "script_syntax"
"$SCRIPT" --baseline "$baseline" --rebuild "$rebuild" --output "$TMP/REBUILD-DIFF.md" --json >"$TMP/result.json"
assert_jq "$TMP/result.json" '.new_surfaces_count == 2' "detects_added"
assert_jq "$TMP/result.json" '.removed_surfaces_count == 1' "detects_removed"
assert_jq "$TMP/result.json" '.orphaned_surface_count == 1 and .orphaned[0].path == "scripts/orphan.sh"' "detects_orphan"
grep -q 'new_surfaces_count: 2' "$TMP/REBUILD-DIFF.md" && pass "markdown_names_added_count" || fail "markdown_names_added_count"
grep -q 'removed_surfaces_count: 1' "$TMP/REBUILD-DIFF.md" && pass "markdown_names_removed_count" || fail "markdown_names_removed_count"
grep -q 'orphaned_surface_count: 1' "$TMP/REBUILD-DIFF.md" && pass "markdown_names_orphan_count" || fail "markdown_names_orphan_count"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
