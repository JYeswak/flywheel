#!/usr/bin/env bash
# josh-review-poll.sh — discover approved/denied items needing this repo's action.
#
# Read-only against ~/Josh-Review/. Joshua moves files; we OBSERVE.
# Emits dashboard line to stderr, JSON receipt to stdout.
# Tracks "acted on" via append-only ledger ~/.local/state/flywheel/josh-review/acted-on.jsonl.
#
# Usage:
#   josh-review-poll.sh                 # JSON to stdout, dashboard line to stderr
#   josh-review-poll.sh --json          # alias (default behavior)
#   josh-review-poll.sh --quiet         # JSON only, no stderr line
#   josh-review-poll.sh --repo <name>   # override repo discovery (default: cwd basename)
#
# Canonical doctrine:
#   /Users/josh/Developer/flywheel/.flywheel/doctrine/meta-learnings/josh-review-canonical-decision-surface.md

set -euo pipefail

SCHEMA_VERSION="josh-review-poll.v1"
REVIEW_ROOT="${JOSH_REVIEW_ROOT:-$HOME/Josh-Review}"
LEDGER_DIR="$HOME/.local/state/flywheel/josh-review"
LEDGER="$LEDGER_DIR/acted-on.jsonl"

QUIET=0
REPO=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) shift ;;
    --quiet) QUIET=1; shift ;;
    --repo) REPO="$2"; shift 2 ;;
    --help|-h)
      sed -n '1,/^set -euo/p' "$0" | sed 's/^# \{0,1\}//' | sed '$d'
      exit 0 ;;
    *) printf 'unknown arg: %s\n' "$1" >&2; exit 2 ;;
  esac
done

if [[ -z "$REPO" ]]; then
  REPO="$(basename "$(pwd)")"
fi

mkdir -p "$LEDGER_DIR"
[[ -f "$LEDGER" ]] || : > "$LEDGER"

# Build the set of sha256s already acted on.
acted_shas_tmp="$(mktemp -t josh-review-acted.XXXXXX)"
trap 'rm -f "$acted_shas_tmp"' EXIT
if [[ -s "$LEDGER" ]]; then
  jq -r 'select(.file_sha256 != null) | .file_sha256' "$LEDGER" 2>/dev/null \
    | sort -u > "$acted_shas_tmp" || : > "$acted_shas_tmp"
else
  : > "$acted_shas_tmp"
fi

# Collect candidate files for this repo in approved/ and denied/.
# Naming convention: YYYY-MM-DD-<repo>-<kind>-<slug>.md
collect_for_dir() {
  local dir="$1"
  if [[ ! -d "$REVIEW_ROOT/$dir" ]]; then
    printf '[]'
    return
  fi
  # BSD-compatible: avoid -printf, use find + while.
  local items='[]'
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    local base
    base="$(basename "$f")"
    # Match YYYY-MM-DD-<repo>-... (repo segment)
    case "$base" in
      [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-"$REPO"-*) : ;;
      *) continue ;;
    esac
    local sha
    sha="$(shasum -a 256 "$f" 2>/dev/null | awk '{print $1}')"
    [[ -z "$sha" ]] && continue
    if grep -qx "$sha" "$acted_shas_tmp" 2>/dev/null; then
      continue
    fi
    local mtime size title
    mtime="$(stat -f '%Sm' -t '%Y-%m-%dT%H:%M:%SZ' "$f" 2>/dev/null || echo "")"
    size="$(stat -f '%z' "$f" 2>/dev/null || echo 0)"
    # First non-empty, non-fence, non-blockquote line as title-ish hint.
    title="$(awk '
      /^[[:space:]]*$/ {next}
      /^```/ {next}
      /^>/ {next}
      /^═+$/ {next}
      {gsub(/^#+ */,""); print; exit}
    ' "$f" 2>/dev/null | head -c 200)"
    items="$(printf '%s' "$items" | jq --arg p "$f" --arg b "$base" --arg s "$sha" --arg m "$mtime" --arg z "$size" --arg t "$title" \
      '. + [{path:$p, basename:$b, sha256:$s, mtime:$m, size_bytes:($z|tonumber? // 0), title_hint:$t}]')"
  done < <(find "$REVIEW_ROOT/$dir" -type f -name '*.md' 2>/dev/null)
  printf '%s' "$items"
}

approved_json="$(collect_for_dir approved)"
denied_json="$(collect_for_dir denied)"

approved_count="$(printf '%s' "$approved_json" | jq 'length')"
denied_count="$(printf '%s' "$denied_json" | jq 'length')"

ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
dashboard_line="📁 Josh-Review: ${approved_count} approved-pending-action, ${denied_count} denied-pending-ack"

jq -n \
  --arg schema "$SCHEMA_VERSION" \
  --arg ts "$ts" \
  --arg repo "$REPO" \
  --arg review_root "$REVIEW_ROOT" \
  --arg ledger "$LEDGER" \
  --arg dl "$dashboard_line" \
  --argjson approved "$approved_json" \
  --argjson denied "$denied_json" \
  '{
    schema: $schema,
    ts: $ts,
    this_repo: $repo,
    review_root: $review_root,
    acted_on_ledger: $ledger,
    approved_pending_action: $approved,
    denied_pending_act: $denied,
    josh_review_pending_action: ($approved | length) + ($denied | length),
    dashboard_line: $dl
  }'

if [[ $QUIET -eq 0 ]]; then
  printf '%s\n' "$dashboard_line" >&2
fi
