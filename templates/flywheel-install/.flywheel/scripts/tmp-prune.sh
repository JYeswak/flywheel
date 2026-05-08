#!/usr/bin/env bash
set -euo pipefail

ROOT_PATH="${FLYWHEEL_TMP_PRUNE_ROOT:-/private/tmp}"
RECEIPT_DIR="${FLYWHEEL_TMP_PRUNE_RECEIPT_DIR:-$HOME/.local/state/flywheel/tmp-prune-receipts}"
DAYS="${FLYWHEEL_TMP_PRUNE_DAYS:-1}"
APPLY=0
JSON_OUT=0
IDEMPOTENCY_KEY="${FLYWHEEL_TMP_PRUNE_IDEMPOTENCY_KEY:-}"
TMP_PRUNE_WORKDIR=""

usage() {
  printf '%s\n' \
    "Usage: tmp-prune.sh [--root PATH] [--days N] [--dry-run|--apply --idempotency-key KEY] [--json]" \
    "Default is dry-run. Candidates are limited to explicit fleet scratch prefixes under the selected tmp root."
}

json_bool() {
  if [ "$1" -eq 1 ]; then printf 'true'; else printf 'false'; fi
}

is_allowed_base() {
  case "$1" in
    alps.*|alpsinsurance*|flywheel-*|beads.*|beads_*|claude-skills-sync|mobile-eats-*|br-*) return 0 ;;
    *) return 1 ;;
  esac
}

is_forbidden_base() {
  case "$1" in
    com.apple.*|launchd-*) return 0 ;;
    *) return 1 ;;
  esac
}

validate_days() {
  case "$DAYS" in
    ''|*[!0-9]*) printf 'ERROR: --days must be a non-negative integer\n' >&2; exit 2 ;;
  esac
}

validate_root() {
  case "$ROOT_PATH" in
    /private/tmp|/private/tmp/*|/tmp/*|/var/folders/*) ;;
    *) printf 'ERROR: root is outside allowed tmp roots: %s\n' "$ROOT_PATH" >&2; exit 2 ;;
  esac
  [ -d "$ROOT_PATH" ] || { printf 'ERROR: root is not a directory: %s\n' "$ROOT_PATH" >&2; exit 2; }
}

candidate_find() {
  find "$ROOT_PATH" -mindepth 1 -maxdepth 1 \
    \( -name 'alps.*' -o -name 'alpsinsurance*' -o -name 'flywheel-*' -o -name 'beads.*' -o -name 'beads_*' -o -name 'claude-skills-sync' -o -name 'mobile-eats-*' -o -name 'br-*' \) \
    -mtime "+$DAYS" -print 2>/dev/null | sort
}

forbidden_find() {
  find "$ROOT_PATH" -mindepth 1 -maxdepth 1 \( -name 'com.apple.*' -o -name 'launchd-*' \) -mtime "+$DAYS" -print 2>/dev/null | sort
}

unknown_find() {
  find "$ROOT_PATH" -mindepth 1 -maxdepth 1 \
    ! \( -name 'alps.*' -o -name 'alpsinsurance*' -o -name 'flywheel-*' -o -name 'beads.*' -o -name 'beads_*' -o -name 'claude-skills-sync' -o -name 'mobile-eats-*' -o -name 'br-*' -o -name 'com.apple.*' -o -name 'launchd-*' \) \
    -mtime "+$DAYS" -print 2>/dev/null | sort
}

path_bytes() {
  du -sk "$1" 2>/dev/null | awk '{print $1 * 1024}'
}

path_mtime() {
  stat -f '%m' "$1" 2>/dev/null || printf '0'
}

append_path_object() {
  local path="$1" out="$2" base bytes mtime
  base="${path##*/}"
  if is_forbidden_base "$base"; then
    printf 'ERROR: forbidden tmp prefix reached candidate set: %s\n' "$path" >&2
    exit 3
  fi
  if ! is_allowed_base "$base"; then
    printf 'ERROR: unknown tmp prefix reached candidate set: %s\n' "$path" >&2
    exit 3
  fi
  bytes="$(path_bytes "$path")"
  mtime="$(path_mtime "$path")"
  jq -nc \
    --arg path "$path" \
    --arg base "$base" \
    --argjson bytes "${bytes:-0}" \
    --argjson mtime "${mtime:-0}" \
    '{path:$path,basename:$base,bytes:$bytes,mtime_epoch:$mtime}' >>"$out"
}

build_path_jsonl() {
  local candidates="$1" objects="$2" path
  : >"$objects"
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    append_path_object "$path" "$objects"
  done <"$candidates"
}

write_receipt() {
  local tmpdir="$1" status="$2" receipt_path="$3" apply_json dry_run_json
  apply_json="$(json_bool "$APPLY")"
  if [ "$APPLY" -eq 1 ]; then dry_run_json=false; else dry_run_json=true; fi
  mkdir -p "$RECEIPT_DIR"
  jq -nc \
    --arg schema_version "tmp-prune/v1" \
    --arg status "$status" \
    --arg root "$ROOT_PATH" \
    --arg idempotency_key "$IDEMPOTENCY_KEY" \
    --arg receipt_path "$receipt_path" \
    --argjson apply "$apply_json" \
    --argjson dry_run "$dry_run_json" \
    --argjson days "$DAYS" \
    --slurpfile paths "$tmpdir/path-objects.jsonl" \
    --argjson forbidden_count "$(wc -l <"$tmpdir/forbidden.txt" | tr -d ' ')" \
    --argjson unknown_count "$(wc -l <"$tmpdir/unknown.txt" | tr -d ' ')" \
    '{
      schema_version:$schema_version,
      status:$status,
      root:$root,
      apply:$apply,
      dry_run:$dry_run,
      older_than_mtime_days:$days,
      idempotency_key:$idempotency_key,
      receipt_path:$receipt_path,
      allowlist_prefixes:["alps.*","alpsinsurance*","flywheel-*","beads.*","beads_*","claude-skills-sync","mobile-eats-*","br-*"],
      forbidden_prefixes:["com.apple.*","launchd-*"],
      paths_to_prune:$paths,
      paths_to_prune_count:($paths | length),
      bytes_to_prune:($paths | map(.bytes) | add // 0),
      excluded:{forbidden_prefix_count:$forbidden_count,unknown_prefix_count:$unknown_count}
    }' >"$receipt_path"
}

apply_candidates() {
  local candidates="$1" path base
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    base="${path##*/}"
    is_allowed_base "$base" || { printf 'ERROR: unknown tmp prefix reached apply set: %s\n' "$path" >&2; exit 3; }
    is_forbidden_base "$base" && { printf 'ERROR: forbidden tmp prefix reached apply set: %s\n' "$path" >&2; exit 3; }
    case "$path" in
      "$ROOT_PATH"/*) rm -rf -- "$path" ;;
      *) printf 'ERROR: candidate outside tmp root: %s\n' "$path" >&2; exit 3 ;;
    esac
  done <"$candidates"
}

parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --help|-h) usage; exit 0 ;;
      --root) [ $# -ge 2 ] || { printf 'ERROR: --root requires PATH\n' >&2; exit 2; }; ROOT_PATH="$2"; shift 2 ;;
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
  local tmpdir ts receipt_path status
  parse_args "$@"
  validate_days
  validate_root
  if [ "$APPLY" -eq 1 ] && [ -z "$IDEMPOTENCY_KEY" ]; then
    printf 'ERROR: --apply requires --idempotency-key\n' >&2
    exit 2
  fi
  if [ -z "$IDEMPOTENCY_KEY" ]; then
    IDEMPOTENCY_KEY="dry-run"
  fi

  tmpdir="$(mktemp -d -t tmp-prune.XXXXXX)"
  TMP_PRUNE_WORKDIR="$tmpdir"
  trap 'if [ -n "${TMP_PRUNE_WORKDIR:-}" ]; then rm -rf "$TMP_PRUNE_WORKDIR"; fi' EXIT
  candidate_find >"$tmpdir/candidates.txt"
  forbidden_find >"$tmpdir/forbidden.txt"
  unknown_find >"$tmpdir/unknown.txt"
  build_path_jsonl "$tmpdir/candidates.txt" "$tmpdir/path-objects.jsonl"

  status="dry_run"
  if [ "$APPLY" -eq 1 ]; then
    apply_candidates "$tmpdir/candidates.txt"
    status="applied"
  fi

  ts="$(date -u +%Y%m%dT%H%M%SZ)"
  receipt_path="$RECEIPT_DIR/$ts.json"
  if [ -e "$receipt_path" ]; then
    receipt_path="$RECEIPT_DIR/$ts.$$.json"
  fi
  write_receipt "$tmpdir" "$status" "$receipt_path"
  if [ "$JSON_OUT" -eq 1 ]; then
    cat "$receipt_path"
  else
    jq -r '"tmp-prune status=\(.status) paths_to_prune=\(.paths_to_prune_count) bytes_to_prune=\(.bytes_to_prune) receipt=\(.receipt_path)"' "$receipt_path"
  fi
}

main "$@"
