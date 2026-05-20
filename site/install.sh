#!/usr/bin/env bash
set -euo pipefail

VERSION="flywheel-installer/v0"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PREFIX="${FLYWHEEL_PREFIX:-$HOME/.flywheel/engine}"
DRY_RUN=0
JSON_OUT=0
ALLOW_BLOCKED=0

usage() {
  cat <<'EOF'
usage: install.sh [--prefix PATH] [--dry-run] [--json] [--allow-blocked]

Installs the current public Flywheel spine into PREFIX. The installer is scoped
to PREFIX and does not edit shell profiles, agent settings, tmux state, or
private fleet databases.
EOF
}

die_usage() {
  printf 'ERROR: %s\n' "$1" >&2
  usage >&2
  exit 64
}

need() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'ERROR: missing required installer command: %s\n' "$1" >&2
    exit 30
  }
}

sha256_file() {
  shasum -a 256 "$1" | awk '{print $1}'
}

install_plan_tsv() {
  cat <<'EOF'
bin/flywheel	bin/flywheel	755
scripts/preflight.sh	scripts/preflight.sh	755
fixtures/preflight/existing.json	fixtures/preflight/existing.json	644
fixtures/preflight/fresh.json	fixtures/preflight/fresh.json	644
fixtures/preflight/malformed.json	fixtures/preflight/malformed.json	644
fixtures/preflight/misconfigured.json	fixtures/preflight/misconfigured.json	644
fixtures/preflight/partial.json	fixtures/preflight/partial.json	644
fixtures/preflight/reduced.json	fixtures/preflight/reduced.json	644
docs/getting-started/first-run.md	docs/getting-started/first-run.md	644
CHARTER.md	CHARTER.md	644
README.md	README.md	644
EOF
}

json_plan() {
  install_plan_tsv | jq -Rsc '
    split("\n")[:-1]
    | map(split("\t") | {source:.[0], target:.[1], mode:.[2]})
  '
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prefix) [[ $# -ge 2 ]] || die_usage "--prefix requires PATH"; PREFIX="$2"; shift 2 ;;
    --prefix=*) PREFIX="${1#*=}"; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --json) JSON_OUT=1; shift ;;
    --allow-blocked) ALLOW_BLOCKED=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die_usage "unknown argument: $1" ;;
  esac
done

need jq
need shasum

PREFIX="$(mkdir -p "$(dirname "$PREFIX")" && cd "$(dirname "$PREFIX")" && pwd -P)/$(basename "$PREFIX")"
RECEIPT="$PREFIX/install-receipt.json"

set +e
preflight_json="$("$ROOT/scripts/preflight.sh" --json 2>/tmp/flywheel-install-preflight.err)"
preflight_rc=$?
set -e

if [[ "$preflight_rc" -ge 30 && "$ALLOW_BLOCKED" -eq 0 ]]; then
  printf 'ERROR: preflight blocked install with exit code %s\n' "$preflight_rc" >&2
  printf 'Suggested action: install required dependencies or rerun with --allow-blocked for fixture/testing only.\n' >&2
  exit 30
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  jq -nc \
    --arg version "$VERSION" --arg prefix "$PREFIX" --argjson plan "$(json_plan)" --argjson preflight "$preflight_json" \
    '{schema_version:"flywheel.install.v0",command:"install",dry_run:true,version:$version,prefix:$prefix,planned_files:$plan,preflight:{mode:$preflight.mode,exit_code:$preflight.exit_code,summary:$preflight.summary}}'
  exit 0
fi

tmp_files="$(mktemp -t flywheel-install-files.XXXXXX)"
trap 'rm -f "$tmp_files"' EXIT

mkdir -p "$PREFIX"
while IFS=$'\t' read -r src dst mode; do
  src_path="$ROOT/$src"
  dst_path="$PREFIX/$dst"
  [[ -f "$src_path" ]] || {
    printf 'ERROR: install source missing: %s\n' "$src" >&2
    exit 40
  }
  mkdir -p "$(dirname "$dst_path")"
  cp "$src_path" "$dst_path"
  chmod "$mode" "$dst_path"
  sha="$(sha256_file "$dst_path")"
  jq -nc --arg path "$dst" --arg sha "$sha" --arg mode "$mode" '{path:$path,sha256:$sha,mode:$mode}' >>"$tmp_files"
done < <(install_plan_tsv)

jq -nc \
  --arg version "$VERSION" \
  --arg prefix "$PREFIX" \
  --arg generated "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
  --argjson preflight "$preflight_json" \
  --slurpfile files "$tmp_files" \
  '{
    schema_version:"flywheel.install.v0",
    command:"install",
    dry_run:false,
    version:$version,
    prefix:$prefix,
    generated_at:$generated,
    preflight:{mode:$preflight.mode,exit_code:$preflight.exit_code,summary:$preflight.summary},
    files:$files
  }' >"$RECEIPT"

if [[ "$JSON_OUT" -eq 1 ]]; then
  jq -nc --arg prefix "$PREFIX" --arg receipt "$RECEIPT" --argjson file_count "$(jq '.files | length' "$RECEIPT")" --argjson preflight "$preflight_json" '{
    schema_version:"flywheel.install.result.v0",
    command:"install",
    status:"installed",
    prefix:$prefix,
    receipt:$receipt,
    installed_files:$file_count,
    preflight:{mode:$preflight.mode,exit_code:$preflight.exit_code}
  }'
else
  printf 'Flywheel installed to %s\nReceipt: %s\n' "$PREFIX" "$RECEIPT"
fi
