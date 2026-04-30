#!/usr/bin/env bash
set -euo pipefail

# Backfill source_repo in all repo-local beads databases.
# Sets source_repo to the canonical path of the repo containing the .beads dir.

DRY_RUN="${1:-}"
COUNT=0
UPDATED=0

for beads_dir in $(find /Users/josh/Developer -maxdepth 2 -name ".beads" -type d 2>/dev/null); do
    db="$beads_dir/beads.db"
    [ -f "$db" ] || continue

    repo_dir="$(dirname "$beads_dir")"
    canonical="$(cd "$repo_dir" && pwd -P)"

    needs_update=$(sqlite3 "$db" "SELECT COUNT(*) FROM issues WHERE source_repo = '.' OR source_repo = '' OR source_repo IS NULL;" 2>/dev/null || echo 0)
    total=$(sqlite3 "$db" "SELECT COUNT(*) FROM issues;" 2>/dev/null || echo 0)

    COUNT=$((COUNT + 1))

    if [ "$needs_update" -gt 0 ]; then
        if [ "$DRY_RUN" = "--dry-run" ]; then
            echo "[DRY] $canonical: $needs_update/$total issues need source_repo backfill"
        else
            sqlite3 "$db" "UPDATE issues SET source_repo = '$canonical' WHERE source_repo = '.' OR source_repo = '' OR source_repo IS NULL;"
            echo "[OK]  $canonical: backfilled $needs_update/$total issues"
        fi
        UPDATED=$((UPDATED + 1))
    else
        echo "[SKIP] $canonical: all $total issues already have source_repo"
    fi
done

echo ""
echo "Scanned $COUNT databases, $UPDATED needed updates."
