#!/usr/bin/env bash
set -euo pipefail

VERSION="regenerate-dicklesworthstone-sources.v1"
ORG="Dicklesworthstone"
DEFAULT_SOURCES_FILE="$HOME/.claude/skills/dicklesworthstone-stack/data/sources.txt"
GH_JSON_FIELDS="name,description,isArchived,updatedAt,defaultBranchRef"

MODE="dry-run"
JSON_OUT=0
FIXTURE=""
SOURCES_FILE="$DEFAULT_SOURCES_FILE"
OUTPUT_FILE=""
NOW_ISO=""

usage() {
  cat <<'USAGE'
Usage:
  regenerate-dicklesworthstone-sources.sh [--dry-run|--apply] [--json]
  regenerate-dicklesworthstone-sources.sh --fixture repos.json --sources-file path --output path --dry-run --json
  regenerate-dicklesworthstone-sources.sh --help

Options:
  --dry-run            Render without modifying sources.txt. Default.
  --apply              Rewrite sources.txt when rendered content differs.
  --fixture PATH       Use gh-compatible JSON fixture instead of live GitHub.
  --sources-file PATH  Target sources file. Default: ~/.claude/skills/dicklesworthstone-stack/data/sources.txt
  --output PATH        Write rendered content to PATH in dry-run mode.
  --now ISO8601        Test-only regenerated timestamp.
  --json               Emit JSON summary.
  --help               Show this help.

Live source command:
  gh repo list Dicklesworthstone --limit 200 --json name,description,isArchived,updatedAt,defaultBranchRef

Schedule:
  Documented runner: invoke this script before daily-jeff-ingest.sh in the existing Jeff ingest launchd/cron path.
USAGE
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 2
}

have() {
  command -v "$1" >/dev/null 2>&1
}

json_summary() {
  local status="$1" changed="$2" backup_path="$3" rendered_path="$4" active_count="$5" archived_count="$6"
  jq -n \
    --arg schema_version "dicklesworthstone-sources-regeneration/v1" \
    --arg version "$VERSION" \
    --arg status "$status" \
    --arg mode "$MODE" \
    --arg sources_file "$SOURCES_FILE" \
    --arg backup_path "$backup_path" \
    --arg rendered_path "$rendered_path" \
    --arg gh_command "gh repo list $ORG --limit 200 --json $GH_JSON_FIELDS" \
    --argjson active_repo_count "$active_count" \
    --argjson archived_repo_count "$archived_count" \
    --argjson commit_feed_count "$active_count" \
    --argjson release_feed_count "$active_count" \
    --argjson persistent_url_failures 0 \
    --argjson changed "$changed" \
    --argjson manual_edit_clobber_warning true \
    '{
      schema_version: $schema_version,
      version: $version,
      status: $status,
      mode: $mode,
      sources_file: $sources_file,
      backup_path: (if ($backup_path | length) > 0 then $backup_path else null end),
      rendered_path: (if ($rendered_path | length) > 0 then $rendered_path else null end),
      source_command: $gh_command,
      active_repo_count: $active_repo_count,
      archived_repo_count: $archived_repo_count,
      commit_feed_count: $commit_feed_count,
      release_feed_count: $release_feed_count,
      persistent_url_failures: $persistent_url_failures,
      changed: $changed,
      manual_edit_clobber_warning: $manual_edit_clobber_warning
    }'
}

preserved_tail() {
  local file="$1" start
  if [[ -f "$file" ]]; then
    start="$(grep -n '^# === Doctrine canon' "$file" | head -1 | cut -d: -f1 || true)"
    if [[ -n "$start" ]]; then
      sed -n "${start},\$p" "$file"
      return 0
    fi
  fi

  cat <<'TAIL'
# === Doctrine canon (HIGH priority) ===
https://agent-flywheel.com/complete-guide
https://agent-flywheel.com/core-flywheel
https://agent-flywheel.com/flywheel
https://agent-flywheel.com/tldr
https://agent-flywheel.com/learn/welcome
https://jeffreyemanuel.com/rss.xml
https://jeffreyemanuel.com/writing/overprompting

# === X / Twitter live signal (HIGH priority) ===
x:@doodlestein
x:search:dicklesworthstone OR "agent flywheel" -is:retweet
x:search:from:doodlestein (rust OR mcp OR beads OR socraticode)
TAIL
}

render_sources() {
  local repos_json="$1" out="$2" now="$3"

  {
    printf '# Dicklesworthstone Stack - Jeff Emanuel signal extraction sources\n'
    printf '# AUTO-GENERATED GitHub repo feed block. Manual edits inside the GitHub block are clobbered.\n'
    printf '# Non-GitHub doctrine/X/RSS sections are preserved below the Doctrine canon marker.\n'
    printf '# Regenerated: %s\n' "$now"
    printf '# Source command: gh repo list %s --limit 200 --json %s\n\n' "$ORG" "$GH_JSON_FIELDS"
    printf '# === GitHub: org root + all active repositories (HIGH priority) ===\n'
    printf 'https://github.com/%s.atom\n\n' "$ORG"
    printf '# Auto-generated per-repo release/commit feeds.\n'
    printf '# Only non-archived repos are included; branch names come from defaultBranchRef.\n'
    jq -r --arg org "$ORG" '
      [.[] | select((.isArchived // false) == false)
        | {
            name: .name,
            updatedAt: (.updatedAt // "unknown"),
            branch: (.defaultBranchRef.name // "main")
          }]
      | sort_by(.updatedAt) | reverse
      | .[]
      | "# \(.name) — updated \(.updatedAt) — default_branch=\(.branch)\nhttps://github.com/\($org)/\(.name)/commits/\(.branch).atom\nhttps://github.com/\($org)/\(.name)/releases.atom"
    ' "$repos_json"
    printf '\n'
    preserved_tail "$SOURCES_FILE"
  } >"$out"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) MODE="dry-run"; shift ;;
    --apply) MODE="apply"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --fixture) FIXTURE="${2:-}"; [[ -n "$FIXTURE" ]] || die "--fixture requires PATH"; shift 2 ;;
    --sources-file) SOURCES_FILE="${2:-}"; [[ -n "$SOURCES_FILE" ]] || die "--sources-file requires PATH"; shift 2 ;;
    --output) OUTPUT_FILE="${2:-}"; [[ -n "$OUTPUT_FILE" ]] || die "--output requires PATH"; shift 2 ;;
    --now) NOW_ISO="${2:-}"; [[ -n "$NOW_ISO" ]] || die "--now requires timestamp"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

have jq || die "jq is required"
NOW_ISO="${NOW_ISO:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dicklesworthstone-sources.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

REPOS_JSON="$TMP_DIR/repos.json"
RENDERED="$TMP_DIR/sources.txt"

if [[ -n "$FIXTURE" ]]; then
  [[ -f "$FIXTURE" ]] || die "fixture not found: $FIXTURE"
  cp "$FIXTURE" "$REPOS_JSON"
else
  have gh || die "gh is required for live regeneration"
  gh repo list "$ORG" --limit 200 --json "$GH_JSON_FIELDS" >"$REPOS_JSON"
fi

jq -e 'type == "array"' "$REPOS_JSON" >/dev/null || die "repo JSON must be an array"

ACTIVE_COUNT="$(jq '[.[] | select((.isArchived // false) == false)] | length' "$REPOS_JSON")"
ARCHIVED_COUNT="$(jq '[.[] | select((.isArchived // false) == true)] | length' "$REPOS_JSON")"

render_sources "$REPOS_JSON" "$RENDERED" "$NOW_ISO"

BACKUP_PATH=""
CHANGED=true
if [[ -f "$SOURCES_FILE" ]] && cmp -s "$RENDERED" "$SOURCES_FILE"; then
  CHANGED=false
fi

if [[ "$MODE" == "apply" ]]; then
  mkdir -p "$(dirname "$SOURCES_FILE")"
  if [[ "$CHANGED" == "true" ]]; then
    if [[ -f "$SOURCES_FILE" ]]; then
      BACKUP_PATH="${SOURCES_FILE}.bak.$(date -u +%Y%m%dT%H%M%SZ)"
      cp "$SOURCES_FILE" "$BACKUP_PATH"
    fi
    mv "$RENDERED" "$SOURCES_FILE"
    RENDERED_PATH="$SOURCES_FILE"
  else
    RENDERED_PATH="$SOURCES_FILE"
  fi
else
  if [[ -n "$OUTPUT_FILE" ]]; then
    mkdir -p "$(dirname "$OUTPUT_FILE")"
    cp "$RENDERED" "$OUTPUT_FILE"
    RENDERED_PATH="$OUTPUT_FILE"
  else
    RENDERED_PATH="$RENDERED"
  fi
fi

if [[ "$JSON_OUT" -eq 1 ]]; then
  json_summary "ok" "$CHANGED" "$BACKUP_PATH" "$RENDERED_PATH" "$ACTIVE_COUNT" "$ARCHIVED_COUNT"
else
  printf 'regenerate-dicklesworthstone-sources: mode=%s active_repo_count=%s changed=%s sources=%s\n' \
    "$MODE" "$ACTIVE_COUNT" "$CHANGED" "$SOURCES_FILE"
fi
