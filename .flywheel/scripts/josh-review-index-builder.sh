#!/usr/bin/env bash
# josh-review-index-builder.sh — rebuild ~/Josh-Review/_INDEX.md.
#
# - Top-10 pending items grouped by repo
# - Sorted by priority_weight × age_hours
# - Yellow indicator for items > 72h
# - Auto-deny candidate flag for items > 7d
# - TL;DR excerpt per item
#
# Read-only against pending/ contents (we WRITE _INDEX.md only).
#
# Usage:
#   josh-review-index-builder.sh         # write ~/Josh-Review/_INDEX.md
#   josh-review-index-builder.sh --stdout  # emit to stdout instead

set -euo pipefail

REVIEW_ROOT="${JOSH_REVIEW_ROOT:-$HOME/Josh-Review}"
PENDING="$REVIEW_ROOT/pending"
OUT="$REVIEW_ROOT/_INDEX.md"
STDOUT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --stdout) STDOUT=1; shift ;;
    --help|-h) sed -n '1,/^set -euo/p' "$0" | sed 's/^# \{0,1\}//' | sed '$d'; exit 0 ;;
    *) printf 'unknown arg: %s\n' "$1" >&2; exit 2 ;;
  esac
done

if [[ ! -d "$PENDING" ]]; then
  printf 'pending dir not found: %s\n' "$PENDING" >&2
  exit 0
fi

now_epoch="$(date -u +%s)"
ts_iso="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Build per-file metadata into a TSV: repo<TAB>basename<TAB>path<TAB>age_h<TAB>urgency<TAB>weight<TAB>tldr
tsv="$(mktemp -t josh-review-index.XXXXXX)"
trap 'rm -f "$tsv"' EXIT

while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  base="$(basename "$f")"
  # Extract <repo> from YYYY-MM-DD-<repo>-<rest>
  repo="$(printf '%s' "$base" | awk -F'-' '{print $4}')"
  [[ -z "$repo" ]] && repo="unknown"
  mt="$(stat -f '%m' "$f" 2>/dev/null || echo 0)"
  age_h=$(( (now_epoch - mt) / 3600 ))
  urgency="$(grep -E -m1 '^\*\*Urgency:\*\*' "$f" 2>/dev/null | sed -E 's/^\*\*Urgency:\*\*[[:space:]]*//' | head -c 80)"
  [[ -z "$urgency" ]] && urgency="P2"
  case "$urgency" in
    P0*) weight=10 ;;
    P1*) weight=4 ;;
    *)   weight=1 ;;
  esac
  score=$(( weight * (age_h + 1) ))
  # TL;DR — first paragraph after a "## TL;DR" header, falling back to first non-fence non-quote line.
  tldr="$(awk '
    /^## *TL;DR/ {flag=1; next}
    flag && /^[[:space:]]*$/ && captured {exit}
    flag && /^#/ {exit}
    flag {print; captured=1; next}
  ' "$f" 2>/dev/null | tr '\n' ' ' | sed -E 's/[[:space:]]+/ /g' | head -c 240)"
  if [[ -z "$tldr" ]]; then
    tldr="$(awk '
      /^```/ {next}
      /^>/ {next}
      /^═+$/ {next}
      /^[[:space:]]*$/ {next}
      {gsub(/^#+ */,""); print; exit}
    ' "$f" 2>/dev/null | head -c 240)"
  fi
  # Strip tabs/newlines from tldr for TSV safety.
  tldr="$(printf '%s' "$tldr" | tr '\t\n' '  ')"
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$repo" "$base" "$f" "$age_h" "$urgency" "$weight" "$score" "$tldr" >> "$tsv"
done < <(find "$PENDING" -type f -name '*.md' 2>/dev/null)

# Compose output.
{
  printf '# Josh-Review pending index\n\n'
  printf '_Auto-generated %s by `josh-review-index-builder.sh` — DO NOT EDIT BY HAND._\n\n' "$ts_iso"

  total="$(wc -l < "$tsv" | tr -d ' ')"
  printf '**Total pending:** %s (fleet-wide cap = 25)\n\n' "$total"

  # Legend
  printf '**Legend:** 🟢 fresh (<72h) · 🟡 stale (>72h) · 🔴 auto-deny candidate (>7d)\n\n'
  printf -- '---\n\n'

  if [[ "$total" == "0" ]]; then
    printf 'No pending items. Inbox zero.\n'
  else
    # Top-10 overall by score
    printf '## Top 10 by priority × age\n\n'
    printf '| # | Repo | Urgency | Age | File | TL;DR |\n'
    printf '|---|---|---|---|---|---|\n'
    sort -t $'\t' -k7 -n -r "$tsv" | head -10 | awk -F'\t' '
      BEGIN{i=0}
      {
        i++
        age = $4
        flag = "🟢"
        if (age >= 168) flag = "🔴"
        else if (age >= 72) flag = "🟡"
        # markdown-safe TL;DR (escape pipes)
        tldr = $8
        gsub(/\|/, "\\|", tldr)
        printf("| %d | %s | %s | %s %dh | `%s` | %s |\n", i, $1, $5, flag, age, $2, tldr)
      }
    '
    printf '\n---\n\n## Grouped by repo\n\n'
    # Group by repo, ordered by max score per repo
    repos="$(awk -F'\t' '{print $1"\t"$7}' "$tsv" | sort -t $'\t' -k1,1 -k2,2nr | awk -F'\t' '!seen[$1]++ {print $1"\t"$2}' | sort -t $'\t' -k2 -n -r | awk -F'\t' '{print $1}')"
    while IFS= read -r repo; do
      [[ -z "$repo" ]] && continue
      count="$(awk -F'\t' -v r="$repo" '$1==r' "$tsv" | wc -l | tr -d ' ')"
      printf '### %s (%s pending)\n\n' "$repo" "$count"
      awk -F'\t' -v r="$repo" '$1==r' "$tsv" | sort -t $'\t' -k7 -n -r | awk -F'\t' '
        {
          age = $4
          flag = "🟢"
          note = ""
          if (age >= 168) { flag = "🔴"; note = " (auto-deny candidate)" }
          else if (age >= 72) { flag = "🟡"; note = " (stale)" }
          tldr = $8
          printf("- %s **%s** · %s · age %dh%s\n  - `%s`\n  - %s\n", flag, $5, $1, age, note, $2, tldr)
        }
      '
      printf '\n'
    done <<<"$repos"
  fi

  printf '\n---\n\n_Canonical doctrine: `/Users/josh/Developer/flywheel/.flywheel/doctrine/meta-learnings/josh-review-canonical-decision-surface.md`_\n'
} > "${OUT}.tmp"

if [[ $STDOUT -eq 1 ]]; then
  cat "${OUT}.tmp"
  rm -f "${OUT}.tmp"
else
  mv "${OUT}.tmp" "$OUT"
  printf 'wrote %s\n' "$OUT"
fi
