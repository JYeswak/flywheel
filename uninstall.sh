#!/usr/bin/env bash
set -euo pipefail

PREFIX="${FLYWHEEL_PREFIX:-$HOME/.flywheel/engine}"
RECEIPT=""
CONFIRM=0
JSON_OUT=0

usage() {
  cat <<'EOF'
usage: uninstall.sh --confirm [--prefix PATH] [--receipt PATH] [--json]

Removes files listed in the install receipt after verifying their checksums.
EOF
}

die_usage() {
  printf 'ERROR: %s\n' "$1" >&2
  usage >&2
  exit 64
}

need() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'ERROR: missing required uninstaller command: %s\n' "$1" >&2
    exit 30
  }
}

sha256_file() {
  shasum -a 256 "$1" | awk '{print $1}'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix) [[ $# -ge 2 ]] || die_usage "--prefix requires PATH"; PREFIX="$2"; shift 2 ;;
    --prefix=*) PREFIX="${1#*=}"; shift ;;
    --receipt) [[ $# -ge 2 ]] || die_usage "--receipt requires PATH"; RECEIPT="$2"; shift 2 ;;
    --receipt=*) RECEIPT="${1#*=}"; shift ;;
    --confirm) CONFIRM=1; shift ;;
    --json) JSON_OUT=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die_usage "unknown argument: $1" ;;
  esac
done

[[ "$CONFIRM" -eq 1 ]] || die_usage "--confirm is required"
need jq
need shasum

PREFIX="$(cd "$PREFIX" 2>/dev/null && pwd -P)" || {
  printf 'ERROR: prefix not found: %s\n' "$PREFIX" >&2
  exit 30
}
[[ -n "$RECEIPT" ]] || RECEIPT="$PREFIX/install-receipt.json"
[[ -f "$RECEIPT" ]] || {
  printf 'ERROR: install receipt not found: %s\n' "$RECEIPT" >&2
  exit 30
}

tmp_removed="$(mktemp -t flywheel-uninstall-removed.XXXXXX)"
trap 'rm -f "$tmp_removed"' EXIT

jq -e '.schema_version == "flywheel.install.v0" and (.files | type == "array")' "$RECEIPT" >/dev/null || {
  printf 'ERROR: invalid install receipt: %s\n' "$RECEIPT" >&2
  exit 40
}

while IFS=$'\t' read -r rel expected; do
  target="$PREFIX/$rel"
  case "$target" in
    "$PREFIX"/*) ;;
    *) printf 'ERROR: refusing path outside prefix: %s\n' "$rel" >&2; exit 40 ;;
  esac
  [[ -f "$target" ]] || {
    printf 'ERROR: installed file missing before uninstall: %s\n' "$rel" >&2
    exit 40
  }
  actual="$(sha256_file "$target")"
  [[ "$actual" == "$expected" ]] || {
    printf 'ERROR: installed file changed; refusing removal: %s\n' "$rel" >&2
    exit 40
  }
done < <(jq -r '.files[] | [.path,.sha256] | @tsv' "$RECEIPT")

while IFS= read -r rel; do
  target="$PREFIX/$rel"
  rm -f -- "$target"
  jq -nc --arg path "$rel" '{path:$path}' >>"$tmp_removed"
done < <(jq -r '.files[].path' "$RECEIPT")

rm -f -- "$RECEIPT"
find "$PREFIX" -depth -type d -empty -exec rmdir {} \; 2>/dev/null || true

if [[ "$JSON_OUT" -eq 1 ]]; then
  jq -nc --arg prefix "$PREFIX" --slurpfile removed "$tmp_removed" '{
    schema_version:"flywheel.uninstall.result.v0",
    command:"uninstall",
    status:"removed",
    prefix:$prefix,
    removed_files:$removed
  }'
else
  printf 'Flywheel removed from %s\n' "$PREFIX"
fi
