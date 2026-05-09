#!/usr/bin/env bash
set -euo pipefail

REPO="${REPO:-/Users/josh/Developer/flywheel}"
APPLY=0
JSON_OUT=0
DAYS="${FLYWHEEL_STORAGE_PRUNE_DAYS:-7}"
IDEMPOTENCY_KEY="${FLYWHEEL_STORAGE_PRUNE_IDEMPOTENCY_KEY:-manual}"
BR_RECOVERY_MAX_MB="${FLYWHEEL_STORAGE_PRUNE_BR_RECOVERY_MAX_MB:-50}"
BR_RECOVERY_MAX_ENTRIES="${FLYWHEEL_STORAGE_PRUNE_BR_RECOVERY_MAX_ENTRIES:-1000}"
JEFF_CORPUS_DAYS="${FLYWHEEL_STORAGE_PRUNE_JEFF_CORPUS_DAYS:-14}"
JEFF_CORPUS_DIR="${FLYWHEEL_STORAGE_PRUNE_JEFF_CORPUS_DIR:-$REPO/.flywheel/jeff-corpus}"

usage() {
  printf '%s\n' \
    "Usage: storage-prune.sh [--repo PATH] [--days N] [--dry-run|--apply] [--json] --idempotency-key KEY" \
    "Default is dry-run. Removes stale .beads.bak.* dirs, tmp dispatch artifacts, stale Beads sidecars, and archives recovery/corpus bloat." \
    "Docker dangling cleanup is reported as a manual command; this script never prunes docker volumes."
}

cutoff_find_args() {
  local days="${1:-$DAYS}"
  printf '%s\n' "+${days}"
}

br_recovery_candidates() {
  local path size_kb entries max_kb
  max_kb=$((BR_RECOVERY_MAX_MB * 1024))
  for path in "$REPO/.br_recovery" "$REPO/.beads/.br_recovery"; do
    [ -d "$path" ] || continue
    size_kb="$(du -sk "$path" 2>/dev/null | awk '{print $1+0}')"
    entries="$(find "$path" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l | tr -d ' ')"
    if [ "$size_kb" -gt "$max_kb" ] || [ "$entries" -gt "$BR_RECOVERY_MAX_ENTRIES" ]; then
      printf '%s\n' "$path"
    fi
  done
}

sidecar_candidates() {
  [ -d "$REPO/.beads" ] || return 0
  find "$REPO/.beads" -maxdepth 1 -type f \( -name '*.aside.*' -o -name '*.bak.*' \) -mtime "$(cutoff_find_args "$DAYS")" 2>/dev/null | sort
}

jeff_corpus_candidates() {
  [ -d "$JEFF_CORPUS_DIR" ] || return 0
  find "$JEFF_CORPUS_DIR" -mindepth 1 -maxdepth 1 -mtime "$(cutoff_find_args "$JEFF_CORPUS_DAYS")" 2>/dev/null | sort
}

safe_archive_name() {
  printf '%s' "$1" | tr '/ ' '__' | tr -c 'A-Za-z0-9._-' '_'
}

plan_json() {
  local tmp_dirs tmp_files tmp_recovery tmp_sidecars tmp_jeff
  local bak_count file_count recovery_count sidecar_count jeff_count
  tmp_dirs="$(mktemp "${TMPDIR:-/tmp}/storage-prune-dirs.XXXXXX")"
  tmp_files="$(mktemp "${TMPDIR:-/tmp}/storage-prune-files.XXXXXX")"
  tmp_recovery="$(mktemp "${TMPDIR:-/tmp}/storage-prune-recovery.XXXXXX")"
  tmp_sidecars="$(mktemp "${TMPDIR:-/tmp}/storage-prune-sidecars.XXXXXX")"
  tmp_jeff="$(mktemp "${TMPDIR:-/tmp}/storage-prune-jeff.XXXXXX")"
  find "$REPO" -maxdepth 1 -type d -name '.beads.bak.*' -mtime "$(cutoff_find_args "$DAYS")" 2>/dev/null | sort >"$tmp_dirs"
  find /tmp -maxdepth 1 -type f \( -name 'dispatch_*' -o -name '*dispatch*.txt' -o -name '*dispatch*.md' \) -mtime "$(cutoff_find_args "$DAYS")" 2>/dev/null | sort >"$tmp_files"
  br_recovery_candidates >"$tmp_recovery"
  sidecar_candidates >"$tmp_sidecars"
  jeff_corpus_candidates >"$tmp_jeff"
  bak_count="$(wc -l <"$tmp_dirs" | tr -d ' ')"
  file_count="$(wc -l <"$tmp_files" | tr -d ' ')"
  recovery_count="$(wc -l <"$tmp_recovery" | tr -d ' ')"
  sidecar_count="$(wc -l <"$tmp_sidecars" | tr -d ' ')"
  jeff_count="$(wc -l <"$tmp_jeff" | tr -d ' ')"
  jq -nc \
    --arg repo "$REPO" \
    --arg key "$IDEMPOTENCY_KEY" \
    --arg jeff_corpus_dir "$JEFF_CORPUS_DIR" \
    --argjson apply "$APPLY" \
    --argjson days "$DAYS" \
    --argjson jeff_days "$JEFF_CORPUS_DAYS" \
    --argjson br_recovery_max_mb "$BR_RECOVERY_MAX_MB" \
    --argjson br_recovery_max_entries "$BR_RECOVERY_MAX_ENTRIES" \
    --argjson bak_count "$bak_count" \
    --argjson file_count "$file_count" \
    --argjson recovery_count "$recovery_count" \
    --argjson sidecar_count "$sidecar_count" \
    --argjson jeff_count "$jeff_count" \
    --argjson bak_dirs "$(jq -R . "$tmp_dirs" | jq -s .)" \
    --argjson tmp_files_json "$(jq -R . "$tmp_files" | jq -s .)" \
    --argjson br_recovery_dirs "$(jq -R . "$tmp_recovery" | jq -s .)" \
    --argjson stale_sidecars "$(jq -R . "$tmp_sidecars" | jq -s .)" \
    --argjson jeff_corpus_entries "$(jq -R . "$tmp_jeff" | jq -s .)" \
    '{
      status:"ok",
      apply:($apply==1),
      repo:$repo,
      idempotency_key:$key,
      older_than_days:$days,
      thresholds:{br_recovery_max_mb:$br_recovery_max_mb,br_recovery_max_entries:$br_recovery_max_entries,jeff_corpus_older_than_days:$jeff_days},
      planned:{stale_bak_dirs:$bak_count,tmp_dispatch_artifacts:$file_count,br_recovery_archives:$recovery_count,stale_beads_sidecars:$sidecar_count,jeff_corpus_archives:$jeff_count},
      paths:{stale_bak_dirs:$bak_dirs,tmp_dispatch_artifacts:$tmp_files_json,br_recovery_dirs:$br_recovery_dirs,stale_beads_sidecars:$stale_sidecars,jeff_corpus_entries:$jeff_corpus_entries},
      jeff_corpus_dir:$jeff_corpus_dir,
      docker_manual_command:"docker system prune --force",
      docker_volumes_pruned:false
    }'
  rm -f "$tmp_dirs" "$tmp_files" "$tmp_recovery" "$tmp_sidecars" "$tmp_jeff"
}

apply_plan() {
  local path ts br_archive jeff_archive dest name
  ts="$(date -u +%Y%m%dT%H%M%SZ)"
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    case "$path" in
      "$REPO"/.beads.bak.*) rm -rf "$path" ;;
    esac
  done < <(find "$REPO" -maxdepth 1 -type d -name '.beads.bak.*' -mtime "$(cutoff_find_args "$DAYS")" 2>/dev/null)
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    case "$path" in
      /tmp/*dispatch*) rm -f "$path" ;;
    esac
  done < <(find /tmp -maxdepth 1 -type f \( -name 'dispatch_*' -o -name '*dispatch*.txt' -o -name '*dispatch*.md' \) -mtime "$(cutoff_find_args "$DAYS")" 2>/dev/null)
  br_archive="/tmp/br_recovery.archived-$ts"
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    case "$path" in
      "$REPO"/.br_recovery|"$REPO"/.beads/.br_recovery)
        mkdir -p "$br_archive"
        name="$(safe_archive_name "${path#"$REPO"/}")"
        dest="$br_archive/$name"
        [ -e "$dest" ] && dest="$dest.$$"
        mv "$path" "$dest"
        ;;
    esac
  done < <(br_recovery_candidates)
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    case "$path" in
      "$REPO"/.beads/*.aside.*|"$REPO"/.beads/*.bak.*) rm -f -- "$path" ;;
    esac
  done < <(sidecar_candidates)
  jeff_archive="/tmp/jeff-corpus.archived-$ts"
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    case "$path" in
      "$JEFF_CORPUS_DIR"/*)
        mkdir -p "$jeff_archive"
        dest="$jeff_archive/$(basename "$path")"
        [ -e "$dest" ] && dest="$dest.$$"
        mv "$path" "$dest"
        ;;
    esac
  done < <(jeff_corpus_candidates)
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
  if [ -z "${FLYWHEEL_STORAGE_PRUNE_JEFF_CORPUS_DIR+x}" ]; then
    JEFF_CORPUS_DIR="$REPO/.flywheel/jeff-corpus"
  fi
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
