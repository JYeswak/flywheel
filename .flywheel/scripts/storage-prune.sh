#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-/Users/josh/Developer/flywheel}"
APPLY=0
JSON_OUT=0
DAYS="${FLYWHEEL_STORAGE_PRUNE_DAYS:-7}"
IDEMPOTENCY_KEY="${FLYWHEEL_STORAGE_PRUNE_IDEMPOTENCY_KEY:-manual}"

usage() {
  printf '%s\n' \
    "Usage: storage-prune.sh [--repo PATH] [--days N] [--dry-run|--apply] [--json] --idempotency-key KEY" \
    "Default is dry-run. Removes stale .beads.bak.* dirs and tmp dispatch artifacts older than N days." \
    "Docker dangling cleanup is reported as a manual command; this script never prunes docker volumes."
}

cutoff_find_args() {
  printf '%s\n' "+${DAYS}"
}

plan_json() {
  local tmp_dirs tmp_files bak_count file_count
  tmp_dirs="$(mktemp "${TMPDIR:-/tmp}/storage-prune-dirs.XXXXXX")"
  tmp_files="$(mktemp "${TMPDIR:-/tmp}/storage-prune-files.XXXXXX")"
  find "$REPO" -maxdepth 1 -type d -name '.beads.bak.*' -mtime "$(cutoff_find_args)" 2>/dev/null | sort >"$tmp_dirs"
  find /tmp -maxdepth 1 -type f \( -name 'dispatch_*' -o -name '*dispatch*.txt' -o -name '*dispatch*.md' \) -mtime "$(cutoff_find_args)" 2>/dev/null | sort >"$tmp_files"
  bak_count="$(wc -l <"$tmp_dirs" | tr -d ' ')"
  file_count="$(wc -l <"$tmp_files" | tr -d ' ')"
  jq -nc \
    --arg repo "$REPO" \
    --arg key "$IDEMPOTENCY_KEY" \
    --argjson apply "$APPLY" \
    --argjson days "$DAYS" \
    --argjson bak_count "$bak_count" \
    --argjson file_count "$file_count" \
    --argjson bak_dirs "$(jq -R . "$tmp_dirs" | jq -s .)" \
    --argjson tmp_files_json "$(jq -R . "$tmp_files" | jq -s .)" \
    '{
      status:"ok",
      apply:($apply==1),
      repo:$repo,
      idempotency_key:$key,
      older_than_days:$days,
      planned:{stale_bak_dirs:$bak_count,tmp_dispatch_artifacts:$file_count},
      paths:{stale_bak_dirs:$bak_dirs,tmp_dispatch_artifacts:$tmp_files_json},
      docker_manual_command:"docker system prune --force",
      docker_volumes_pruned:false
    }'
  rm -f "$tmp_dirs" "$tmp_files"
}

apply_plan() {
  local path
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    case "$path" in
      "$REPO"/.beads.bak.*) rm -rf "$path" ;;
    esac
  done < <(find "$REPO" -maxdepth 1 -type d -name '.beads.bak.*' -mtime "$(cutoff_find_args)" 2>/dev/null)
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    case "$path" in
      /tmp/*dispatch*) rm -f "$path" ;;
    esac
  done < <(find /tmp -maxdepth 1 -type f \( -name 'dispatch_*' -o -name '*dispatch*.txt' -o -name '*dispatch*.md' \) -mtime "$(cutoff_find_args)" 2>/dev/null)
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --help|-h) usage; exit 0 ;;
      --repo) [ $# -ge 2 ] || { printf 'ERROR: --repo requires PATH\n' >&2; exit 2; }; REPO="$2"; shift 2 ;;
      --days) [ $# -ge 2 ] || { printf 'ERROR: --days requires N\n' >&2; exit 2; }; DAYS="$2"; shift 2 ;;
      --dry-run) APPLY=0; shift ;;
      --apply) APPLY=1; shift ;;
      --json) JSON_OUT=1; shift ;;
      --idempotency-key) [ $# -ge 2 ] || { printf 'ERROR: --idempotency-key requires KEY\n' >&2; exit 2; }; IDEMPOTENCY_KEY="$2"; shift 2 ;;
      *) printf 'ERROR: unknown argument: %s\n' "$1" >&2; exit 2 ;;
    esac
  done
}

main() {
  parse_args "$@"
  if [ "$APPLY" -eq 1 ] && [ "$IDEMPOTENCY_KEY" = "manual" ]; then
    printf 'ERROR: --apply requires --idempotency-key\n' >&2
    exit 2
  fi
  [ "$APPLY" -eq 0 ] || apply_plan
  if [ "$JSON_OUT" -eq 1 ]; then
    plan_json
  else
    plan_json | jq -r '"storage-prune apply=\(.apply) stale_bak_dirs=\(.planned.stale_bak_dirs) tmp_dispatch_artifacts=\(.planned.tmp_dispatch_artifacts)"'
  fi
}

main "$@"
