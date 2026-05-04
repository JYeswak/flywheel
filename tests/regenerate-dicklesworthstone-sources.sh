#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/regenerate-dicklesworthstone-sources.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/regenerate-dicklesworthstone-sources.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

assert_jq() {
  local label="$1" file="$2" filter="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" || true
  fi
}

assert_contains() {
  local label="$1" file="$2" pattern="$3"
  if rg -q "$pattern" "$file"; then
    pass "$label"
  else
    fail "$label"
    sed -n '1,120p' "$file"
  fi
}

assert_not_contains() {
  local label="$1" file="$2" pattern="$3"
  if rg -q "$pattern" "$file"; then
    fail "$label"
    rg -n "$pattern" "$file" || true
  else
    pass "$label"
  fi
}

fixture="$TMP/repos.json"
sources="$TMP/sources.txt"
dry_render="$TMP/dry-rendered-sources.txt"
dry_json="$TMP/dry.json"
apply_json="$TMP/apply.json"
apply_again_json="$TMP/apply-again.json"

cat >"$fixture" <<'JSON'
[
  {
    "name": "AlphaExact",
    "description": "active main branch",
    "isArchived": false,
    "updatedAt": "2026-05-04T01:00:00Z",
    "defaultBranchRef": {"name": "main"}
  },
  {
    "name": "BetaMaster",
    "description": "active master branch",
    "isArchived": false,
    "updatedAt": "2026-05-04T02:00:00Z",
    "defaultBranchRef": {"name": "master"}
  },
  {
    "name": "ArchivedRepo",
    "description": "archived",
    "isArchived": true,
    "updatedAt": "2026-05-04T03:00:00Z",
    "defaultBranchRef": {"name": "main"}
  }
]
JSON

cat >"$sources" <<'TXT'
# Dicklesworthstone Stack - old generated block
# MANUAL_EDIT_THIS_LINE_SHOULD_BE_CLOBBERED
https://github.com/Dicklesworthstone/OldRepo/commits/main.atom

# === Doctrine canon (HIGH priority) ===
https://agent-flywheel.com/core-flywheel

# === X / Twitter live signal (HIGH priority) ===
x:@doodlestein
TXT

"$SCRIPT" \
  --fixture "$fixture" \
  --sources-file "$sources" \
  --output "$dry_render" \
  --now 2026-05-04T00:00:00Z \
  --dry-run \
  --json >"$dry_json"

assert_jq "dry-run summary counts active/archived/feeds" "$dry_json" \
  '.active_repo_count == 2 and .archived_repo_count == 1 and .commit_feed_count == 2 and .release_feed_count == 2 and .persistent_url_failures == 0'
assert_jq "manual edit clobber warning surfaced" "$dry_json" '.manual_edit_clobber_warning == true'
assert_contains "main branch feed rendered" "$dry_render" 'AlphaExact/commits/main\.atom'
assert_contains "master branch feed rendered" "$dry_render" 'BetaMaster/commits/master\.atom'
assert_not_contains "archived repo excluded" "$dry_render" 'ArchivedRepo'
assert_contains "non-GitHub doctrine tail preserved" "$dry_render" 'agent-flywheel\.com/core-flywheel'
assert_contains "non-GitHub X tail preserved" "$dry_render" 'x:@doodlestein'
assert_contains "dry-run leaves source manual line intact" "$sources" 'MANUAL_EDIT_THIS_LINE_SHOULD_BE_CLOBBERED'

"$SCRIPT" \
  --fixture "$fixture" \
  --sources-file "$sources" \
  --now 2026-05-04T00:00:00Z \
  --apply \
  --json >"$apply_json"

assert_jq "apply writes backup and changed true" "$apply_json" \
  '.changed == true and (.backup_path | type == "string")'
backup_path="$(jq -r '.backup_path' "$apply_json")"
if [[ -f "$backup_path" ]]; then pass "timestamped backup exists"; else fail "timestamped backup exists"; fi
assert_not_contains "manual edit in generated block clobbered on apply" "$sources" 'MANUAL_EDIT_THIS_LINE_SHOULD_BE_CLOBBERED'
assert_contains "apply source has generated warning" "$sources" 'Manual edits inside the GitHub block are clobbered'

"$SCRIPT" \
  --fixture "$fixture" \
  --sources-file "$sources" \
  --now 2026-05-04T00:00:00Z \
  --apply \
  --json >"$apply_again_json"
assert_jq "second apply is idempotent" "$apply_again_json" '.changed == false'

if [[ "$fail_count" -gt 0 ]]; then
  printf 'FAIL regenerate-dicklesworthstone-sources tests pass=%s fail=%s\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'PASS regenerate-dicklesworthstone-sources tests pass=%s fail=%s\n' "$pass_count" "$fail_count"
