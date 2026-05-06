#!/usr/bin/env bash
set -u

VERSION="jeff-clone-symlink-converter.v1"
SCHEMA_VERSION="jeff-clone-symlink-receipt/v1"
ROOT_BASE="${JEFF_CLONE_ROOT_BASE:-/Users/josh/Developer}"
CORPUS_BASE="${JEFF_CLONE_CORPUS_BASE:-$ROOT_BASE/jeff-corpus}"
PAIR=""
CANONICAL_SIDE="corpus"
MODE="dry-run"
BACKUP_DIR="$HOME/.local/state/flywheel/jeff-clone-backups"
JSON_OUT=0

usage() {
  cat <<'EOF'
usage:
  jeff-clone-symlink-converter.sh --pair NAME [--canonical-side root|corpus] [--mode dry-run|apply] [--backup-dir PATH] [--json]
  jeff-clone-symlink-converter.sh --info
EOF
}

emit() {
  local payload="$1"
  if [[ "$JSON_OUT" -eq 1 ]]; then jq -c . <<<"$payload"; else jq . <<<"$payload"; fi
}

fail_json() {
  local code="$1" reason="$2" exit_code="$3"
  emit "$(jq -nc --arg schema_version "$SCHEMA_VERSION" --arg status "$code" --arg reason "$reason" \
    '{schema_version:$schema_version,status:$status,reason:$reason}')"
  exit "$exit_code"
}

info() {
  jq -nc --arg version "$VERSION" --arg schema_version "$SCHEMA_VERSION" \
    '{name:"jeff-clone-symlink-converter.sh",version:$version,schema_version:$schema_version,exit_codes:{"0":"success","1":"verify-fail","2":"safety-check-fail","3":"invalid-args"},defaults:{canonical_side:"corpus",mode:"dry-run"}}'
}

norm_origin() {
  git -C "$1" config --get remote.origin.url 2>/dev/null | sed 's/[.]git$//'
}

git_head() {
  git -C "$1" rev-parse HEAD 2>/dev/null
}

dirty() {
  [[ -n "$(git -C "$1" status --porcelain 2>/dev/null)" ]]
}

dir_file_bytes() {
  find -P "$1" -type f -exec stat -f %z {} + 2>/dev/null | awk '{s+=$1} END{print s+0}'
}

dir_disk_bytes() {
  du -sk "$1" 2>/dev/null | awk '{print $1 * 1024}'
}

archive_member_bytes() {
  tar -tvzf "$1" 2>/dev/null | awk '{s+=$5} END{print s+0}'
}

tree_hash() {
  (cd "$1" && find . -type f -print0 | sort -z | while IFS= read -r -d '' f; do
    shasum -a 256 "$f"
  done) | shasum -a 256 | awk '{print $1}'
}

valid_pair() {
  [[ -n "$PAIR" && "$PAIR" != .* && "$PAIR" != *"/"* && "$PAIR" != ".." ]]
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pair) [[ -n "${2:-}" ]] || fail_json invalid_args missing_pair_value 3; PAIR="$2"; shift 2 ;;
    --canonical-side) [[ -n "${2:-}" ]] || fail_json invalid_args missing_canonical_side 3; CANONICAL_SIDE="$2"; shift 2 ;;
    --mode) [[ -n "${2:-}" ]] || fail_json invalid_args missing_mode 3; MODE="$2"; shift 2 ;;
    --backup-dir) [[ -n "${2:-}" ]] || fail_json invalid_args missing_backup_dir 3; BACKUP_DIR="$2"; shift 2 ;;
    --json) JSON_OUT=1; shift ;;
    --info) info; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) fail_json invalid_args "unknown_arg:$1" 3 ;;
  esac
done

case "$CANONICAL_SIDE" in root|corpus) ;; *) fail_json invalid_args invalid_canonical_side 3 ;; esac
case "$MODE" in dry-run|apply) ;; *) fail_json invalid_args invalid_mode 3 ;; esac
valid_pair || fail_json invalid_args invalid_pair 3

ROOT_PATH="$ROOT_BASE/$PAIR"
CORPUS_PATH="$CORPUS_BASE/$PAIR"
if [[ "$CANONICAL_SIDE" == "corpus" ]]; then
  CANONICAL_PATH="$CORPUS_PATH"; NONCANONICAL_PATH="$ROOT_PATH"
else
  CANONICAL_PATH="$ROOT_PATH"; NONCANONICAL_PATH="$CORPUS_PATH"
fi

[[ ! -L "$NONCANONICAL_PATH" ]] || fail_json safety_check_failed noncanonical_already_symlink 2
[[ ! -L "$CANONICAL_PATH" ]] || fail_json safety_check_failed canonical_is_symlink 2
[[ -d "$ROOT_PATH" && -d "$CORPUS_PATH" ]] || fail_json safety_check_failed missing_pair_path 2
git -C "$ROOT_PATH" rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail_json safety_check_failed root_not_git_repo 2
git -C "$CORPUS_PATH" rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail_json safety_check_failed corpus_not_git_repo 2

root_origin="$(norm_origin "$ROOT_PATH")"
corpus_origin="$(norm_origin "$CORPUS_PATH")"
[[ -n "$root_origin" && "$root_origin" == "$corpus_origin" ]] || fail_json safety_check_failed origin_mismatch 2
root_head="$(git_head "$ROOT_PATH")"
corpus_head="$(git_head "$CORPUS_PATH")"
[[ -n "$root_head" && "$root_head" == "$corpus_head" ]] || fail_json safety_check_failed commit_mismatch 2
dirty "$ROOT_PATH" && fail_json safety_check_failed root_dirty 2
dirty "$CORPUS_PATH" && fail_json safety_check_failed corpus_dirty 2

ts="$(date -u +%Y%m%dT%H%M%SZ)"
backup_dir_expanded="${BACKUP_DIR/#\~/$HOME}"
backup_path="$backup_dir_expanded/$PAIR-$ts.tar.gz"
receipt_path="$backup_dir_expanded/$PAIR-$ts.receipt.json"
moved_path="$backup_dir_expanded/$PAIR-$ts.original-dir"
orig_file_bytes="$(dir_file_bytes "$NONCANONICAL_PATH")"
orig_disk_bytes="$(dir_disk_bytes "$NONCANONICAL_PATH")"
orig_tree_hash="$(tree_hash "$NONCANONICAL_PATH")"

base_receipt() {
  jq -nc \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg version "$VERSION" \
    --arg ts "$ts" \
    --arg pair "$PAIR" \
    --arg canonical_side "$CANONICAL_SIDE" \
    --arg canonical_path "$CANONICAL_PATH" \
    --arg noncanonical_path "$NONCANONICAL_PATH" \
    --arg backup_path "$backup_path" \
    --arg receipt_path "$receipt_path" \
    --arg moved_path "$moved_path" \
    --arg origin "$root_origin" \
    --arg head "$root_head" \
    --arg tree_hash "$orig_tree_hash" \
    --argjson file_bytes "$orig_file_bytes" \
    --argjson disk_bytes "$orig_disk_bytes" \
    '{schema_version:$schema_version,version:$version,ts:$ts,pair:$pair,canonical_side:$canonical_side,canonical_path:$canonical_path,noncanonical_path:$noncanonical_path,backup_path:$backup_path,receipt_path:$receipt_path,moved_path:$moved_path,origin:$origin,head:$head,byte_counts:{original_file_bytes:$file_bytes,original_disk_bytes:$disk_bytes},original_tree_hash:$tree_hash}'
}

if [[ "$MODE" == "dry-run" ]]; then
  emit "$(base_receipt | jq '. + {status:"dry_run",would_convert:true}')"
  exit 0
fi

mkdir -p "$backup_dir_expanded" || fail_json verify_failed backup_dir_unwritable 1
[[ ! -e "$backup_path" && ! -e "$receipt_path" && ! -e "$moved_path" ]] || fail_json verify_failed backup_collision 1
tar -czf "$backup_path" -C "$(dirname "$NONCANONICAL_PATH")" "$(basename "$NONCANONICAL_PATH")" || fail_json verify_failed backup_tar_failed 1
archive_bytes="$(archive_member_bytes "$backup_path")"
if [[ "${JEFF_CLONE_FORCE_BYTE_MISMATCH:-0}" == "1" ]]; then archive_bytes=0; fi
tolerance="${JEFF_CLONE_BYTE_TOLERANCE:-0}"
if [[ "$archive_bytes" -lt $((orig_file_bytes - tolerance)) ]]; then
  fail_json verify_failed backup_byte_count_mismatch 1
fi

mv "$NONCANONICAL_PATH" "$moved_path" || fail_json verify_failed move_original_failed 1
ln -s "$CANONICAL_PATH" "$NONCANONICAL_PATH" || fail_json verify_failed symlink_create_failed 1
resolved="$(cd "$(dirname "$NONCANONICAL_PATH")" && cd "$(basename "$NONCANONICAL_PATH")" && pwd -P 2>/dev/null)" || fail_json verify_failed symlink_unresolvable 1
expected="$(cd "$CANONICAL_PATH" && pwd -P)" || fail_json verify_failed canonical_unresolvable 1
[[ "$resolved" == "$expected" ]] || fail_json verify_failed symlink_wrong_target 1
ls "$NONCANONICAL_PATH" >/dev/null 2>&1 || fail_json verify_failed ls_failed 1
git -C "$NONCANONICAL_PATH" rev-parse HEAD >/dev/null 2>&1 || fail_json verify_failed git_failed_after_symlink 1

receipt="$(base_receipt | jq \
  --argjson archive_bytes "$archive_bytes" \
  '. + {status:"applied",byte_counts:(.byte_counts + {archive_member_bytes:$archive_bytes}),post_state:{symlink:true,verified:true}}')"
printf '%s\n' "$receipt" >"$receipt_path" || fail_json verify_failed receipt_write_failed 1
emit "$receipt"
