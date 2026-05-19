#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
VALIDATOR="$ROOT/.flywheel/scripts/bead-ag-format.py"

usage() {
  cat <<'USAGE'
usage: br-create-validated.sh --title TITLE --description-file FILE [br create args...]

Validates canonical AG<N>: single-line acceptance gates before delegating to br create.
Warnings are printed to stderr; format errors block creation.
USAGE
}

title=""
description_file=""
description_text=""
pass_args=()

sql_escape() {
  printf '%s' "$1" | sed "s/'/''/g"
}

normalize_created_source_repo() {
  local output="$1" repo_abs db repo_sql id
  repo_abs="$(pwd -P)"
  db="$repo_abs/.beads/beads.db"
  [[ -f "$db" ]] || return 0
  command -v sqlite3 >/dev/null 2>&1 || return 0
  repo_sql="$(sql_escape "$repo_abs")"
  while IFS= read -r id; do
    [[ -n "$id" && "$id" != "null" ]] || continue
    case "$id" in
      *[!A-Za-z0-9._-]*) continue ;;
    esac
    sqlite3 "$db" "UPDATE issues SET source_repo = '$repo_sql' WHERE id = '$id' AND (source_repo IS NULL OR source_repo != '$repo_sql');" >/dev/null 2>&1 || true
  done < <(jq -r '.. | objects | .id? // empty' <<<"$output" 2>/dev/null | sort -u)
  br sync --flush-only --force --json >/dev/null 2>&1 || true
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --title)
      title="${2:-}"
      shift 2
      ;;
    --description-file|--body-file)
      description_file="${2:-}"
      description_text="$(<"$description_file")"
      pass_args+=("--description" "$description_text")
      shift 2
      ;;
    --description|-d)
      tmp="$(mktemp "${TMPDIR:-/tmp}/br-create-validated.XXXXXX.md")"
      printf '%s\n' "${2:-}" >"$tmp"
      description_file="$tmp"
      description_text="${2:-}"
      pass_args+=("--description" "${2:-}")
      shift 2
      ;;
    *)
      pass_args+=("$1")
      shift
      ;;
  esac
done

if [[ -z "$title" ]]; then
  echo "ERROR missing --title" >&2
  usage >&2
  exit 2
fi
if [[ -z "$description_file" || ! -f "$description_file" ]]; then
  echo "ERROR missing readable --description-file" >&2
  usage >&2
  exit 2
fi

validation="$("$VALIDATOR" --description-file "$description_file" --json)" || {
  printf '%s\n' "$validation" >&2
  exit 1
}
if jq -e '.warnings | length > 0' <<<"$validation" >/dev/null; then
  jq -r '.warnings[] | "WARN \(.code): \(.message) (line \(.line // "n/a"))"' <<<"$validation" >&2
fi

output="$(br create "$title" "${pass_args[@]}")"
normalize_created_source_repo "$output"
printf '%s\n' "$output"

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
