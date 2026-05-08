#!/usr/bin/env bash
set -euo pipefail

# Backfill source_repo in repo-local Beads databases.
# Converts unset/dot/basename source_repo values to the canonical absolute repo path.

DRY_RUN=0
JSON_OUT=0
REPO_FILTER=""

usage() {
    cat <<'EOF'
usage: scripts/backfill-source-repo.sh [--repo PATH] [--dry-run] [--json]

Without --repo, scans /Users/josh/Developer/*/.beads. With --repo, scopes the
backfill to that one repository.
EOF
}

sql_escape() {
    printf '%s' "$1" | sed "s/'/''/g"
}

canonical_dir() {
    (cd "$1" && pwd -P)
}

repo_rows() {
    if [[ -n "$REPO_FILTER" ]]; then
        local repo_abs
        repo_abs="$(canonical_dir "$REPO_FILTER")"
        printf '%s/.beads\n' "$repo_abs"
    else
        find /Users/josh/Developer -maxdepth 2 -name ".beads" -type d 2>/dev/null | sort
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo)
            [[ $# -ge 2 ]] || { usage >&2; exit 2; }
            REPO_FILTER="$2"
            shift 2
            ;;
        --repo=*)
            REPO_FILTER="${1#*=}"
            shift
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --json)
            JSON_OUT=1
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            printf 'ERR unknown argument: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

COUNT=0
UPDATED=0
rows_file="$(mktemp -t source-repo-backfill.XXXXXX)"
trap 'rm -f "$rows_file"' EXIT

while IFS= read -r beads_dir; do
    [[ -n "$beads_dir" ]] || continue
    db="$beads_dir/beads.db"
    [[ -f "$db" ]] || continue

    repo_dir="$(dirname "$beads_dir")"
    canonical="$(canonical_dir "$repo_dir")"
    basename_value="$(basename "$canonical")"
    canonical_sql="$(sql_escape "$canonical")"
    basename_sql="$(sql_escape "$basename_value")"

    needs_update="$(sqlite3 "$db" "SELECT COUNT(*) FROM issues WHERE source_repo = '.' OR source_repo = '' OR source_repo IS NULL OR source_repo = '$basename_sql';" 2>/dev/null || echo 0)"
    total="$(sqlite3 "$db" "SELECT COUNT(*) FROM issues;" 2>/dev/null || echo 0)"
    remaining_leaks="$(sqlite3 "$db" "SELECT COUNT(*) FROM issues WHERE source_repo IS NULL OR source_repo != '$canonical_sql';" 2>/dev/null || echo 0)"

    COUNT=$((COUNT + 1))

    if [[ "$needs_update" -gt 0 ]]; then
        UPDATED=$((UPDATED + 1))
        if [[ "$DRY_RUN" -eq 0 ]]; then
            sqlite3 "$db" "UPDATE issues SET source_repo = '$canonical_sql' WHERE source_repo = '.' OR source_repo = '' OR source_repo IS NULL OR source_repo = '$basename_sql';"
            remaining_leaks="$(sqlite3 "$db" "SELECT COUNT(*) FROM issues WHERE source_repo IS NULL OR source_repo != '$canonical_sql';" 2>/dev/null || echo 0)"
        fi
    fi

    jq -nc \
        --arg repo "$canonical" \
        --arg db "$db" \
        --arg basename_value "$basename_value" \
        --argjson total "$total" \
        --argjson needs_update "$needs_update" \
        --argjson remaining_leaks "$remaining_leaks" \
        --argjson dry_run "$DRY_RUN" \
        '{repo:$repo,db:$db,basename_value:$basename_value,total:$total,needs_update:$needs_update,remaining_leaks:$remaining_leaks,dry_run:($dry_run == 1)}' >>"$rows_file"
done < <(repo_rows)

if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -s -c --argjson scanned "$COUNT" --argjson updated "$UPDATED" --argjson dry_run "$DRY_RUN" \
        '{schema_version:"source-repo-backfill/v1",scanned:$scanned,databases_needing_update:$updated,dry_run:($dry_run == 1),repos:.}' "$rows_file"
else
    jq -r '. | (if .needs_update > 0 then (if .dry_run then "[DRY] " else "[OK]  " end) else "[SKIP] " end) + .repo + ": " + (.needs_update|tostring) + "/" + (.total|tostring) + " source_repo values need basename/null backfill; remaining_leaks=" + (.remaining_leaks|tostring)' "$rows_file"
    printf '\nScanned %s databases, %s needed updates.\n' "$COUNT" "$UPDATED"
fi
