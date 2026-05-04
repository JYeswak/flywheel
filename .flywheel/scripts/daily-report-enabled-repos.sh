#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
GENERATOR="${FLYWHEEL_DAILY_REPORT_GENERATOR:-$ROOT/.flywheel/scripts/daily-report.sh}"
REPO_ROOTS="${FLYWHEEL_DAILY_REPORT_REPO_ROOTS:-$HOME/Developer}"
DATE_ARG=""
DRY_RUN=0
NOTIFY_FLAG="--notify"

usage() {
  printf 'usage: daily-report-enabled-repos.sh [--date YYYY-MM-DD] [--dry-run] [--no-notify] [--json]\n'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --date)
      [[ -n "${2:-}" ]] || { echo "ERR: --date requires YYYY-MM-DD" >&2; exit 64; }
      DATE_ARG="$2"; shift 2 ;;
    --dry-run)
      DRY_RUN=1; shift ;;
    --no-notify)
      NOTIFY_FLAG="--no-notify"; shift ;;
    --json)
      shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "ERR: unknown argument: $1" >&2
      usage >&2
      exit 64 ;;
  esac
done

is_enabled_repo() {
  local repo="$1" config="$repo/.flywheel/daily-report-config.json"
  if [[ -f "$config" ]]; then
    jq -e '.enabled == true' "$config" >/dev/null 2>&1
    return $?
  fi
  [[ "$(cd "$repo" 2>/dev/null && pwd -P)" == "$HOME/Developer/flywheel" ]]
}

repo_list="$(
  while IFS=: read -r root; do
    [[ -n "$root" && -d "$root" ]] || continue
    for candidate in "$root" "$root"/* "$root"/*/* "$root"/*/*/*; do
      [[ -d "$candidate/.flywheel" ]] || continue
      cd "$candidate" 2>/dev/null && pwd -P
    done
  done <<<"$REPO_ROOTS" | sort -u
)"

tmp="$(mktemp "${TMPDIR:-/tmp}/daily-report-enabled.XXXXXX")"
trap 'rm -f "$tmp"' EXIT

generated=0
skipped=0
failed=0

while IFS= read -r repo; do
  [[ -n "$repo" ]] || continue
  if ! is_enabled_repo "$repo"; then
    jq -nc --arg repo "$repo" '{repo:$repo,status:"skipped",reason:"daily_report_disabled"}' >>"$tmp"
    skipped=$((skipped + 1))
    continue
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    jq -nc --arg repo "$repo" '{repo:$repo,status:"would_generate"}' >>"$tmp"
    generated=$((generated + 1))
    continue
  fi
  args=(--repo "$repo" "$NOTIFY_FLAG" --json)
  [[ -z "$DATE_ARG" ]] || args+=(--date "$DATE_ARG")
  if output="$("$GENERATOR" "${args[@]}" 2>&1)"; then
    jq -nc --arg repo "$repo" --argjson result "$output" '{repo:$repo,status:"generated",result:$result}' >>"$tmp"
    generated=$((generated + 1))
  else
    jq -nc --arg repo "$repo" --arg output "$output" '{repo:$repo,status:"failed",error:$output}' >>"$tmp"
    failed=$((failed + 1))
  fi
done <<<"$repo_list"

jq -cs \
  --arg generated "$generated" \
  --arg skipped "$skipped" \
  --arg failed "$failed" \
  '{schema_version:"daily-report-enabled-repos/v1",generated:($generated|tonumber),skipped:($skipped|tonumber),failed:($failed|tonumber),repos:.}' \
  "$tmp"

[[ "$failed" -eq 0 ]]
