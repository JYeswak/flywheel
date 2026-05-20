#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: $0 <tool> <version>" >&2
  exit 64
fi

TOOL="$1"
VERSION="$2"
REPO="Dicklesworthstone/${TOOL}"
STATE_DIR="${DICKLESWORTHSTONE_UPGRADE_STATE:-$HOME/.local/state/flywheel/dicklesworthstone-upgrades}"
WORK_DIR="$STATE_DIR/work/${TOOL}-${VERSION}"
BACKUP_DIR="$STATE_DIR/backups"
INSTALL_DIR="${DICKLESWORTHSTONE_INSTALL_DIR:-$HOME/.local/bin}"

version_key() {
  sed -E 's/^v//' <<<"$1" | grep -Eo '[0-9]+(\.[0-9]+){1,3}([-+][A-Za-z0-9._-]+)?' | head -1
}

installed_line() {
  "$TOOL" --version 2>&1 | head -1 || "$TOOL" version 2>&1 | head -1 || true
}

version_line() {
  "$TOOL" version 2>&1 | head -1 || "$TOOL" --version 2>&1 | head -1 || true
}

smoke() {
  local expected="$1" observed observed_key expected_key
  observed="$(installed_line)"
  observed_key="$(version_key "$observed")"
  expected_key="$(version_key "$expected")"
  [[ -n "$observed_key" && -n "$expected_key" && "$observed_key" == "$expected_key" ]]
}

post_install_verify() {
  local expected="$1" output expected_key
  expected_key="$(version_key "$expected")"
  output="$(version_line)"
  [[ -n "$expected_key" ]] || return 1
  grep -Eq "(^|[^0-9])${expected_key}([^0-9]|$)" <<<"$output"
}

escape_ere() {
  sed -E 's/[][(){}.^$*+?|\\]/\\&/g' <<<"$1"
}

select_asset() {
  jq -r '
    [.assets[]?
     | select((.name | test("(?i)darwin|macos|apple|aarch64|arm64"))
              and (.name | test("(?i)tar\\.gz$|tgz$|zip$")))
    ][0].name // empty
  ' "$WORK_DIR/release.json"
}

select_checksum_asset() {
  jq -r '
    [.assets[]?
     | select(.name | test("(?i)sha256|checksums|checksum|\\.sha256$|\\.sha256sum$"))
    ][0].name // empty
  ' "$WORK_DIR/release.json"
}

rollback() {
  local install_path="$1" backup_path="$2" prev_backup="${3:-}"
  if [[ -n "${backup_path:-}" && -e "$backup_path" ]]; then
    install -m 0755 "$backup_path" "$install_path"
  elif [[ -n "$prev_backup" && -e "$prev_backup" ]]; then
    install -m 0755 "$prev_backup" "$install_path"
  elif [[ -e "$install_path.prev.bak" ]]; then
    install -m 0755 "$install_path.prev.bak" "$install_path"
  fi
}

checksum_line_for() {
  local checksum_file="$1" asset="$2" tool="$3" version="$4" exact_tarball exact_asset version_no_v
  version_no_v="$(version_key "$version")"
  exact_tarball="$(escape_ere "${tool}_${version_no_v}_darwin_all.tar.gz")"
  exact_asset="$(escape_ere "$asset")"

  if grep -E "[[:space:]]${exact_tarball}$" "$checksum_file"; then
    return 0
  fi

  grep -E "[[:space:]]${exact_asset}$" "$checksum_file"
}

main() {
  if ! command -v "$TOOL" >/dev/null 2>&1; then
    echo "tool not installed: $TOOL" >&2
    exit 69
  fi

  if smoke "$VERSION"; then
    echo "$TOOL already at $VERSION"
    exit 0
  fi

  mkdir -p "$WORK_DIR" "$BACKUP_DIR"
  gh api "repos/${REPO}/releases/tags/${VERSION}" > "$WORK_DIR/release.json"

  local asset checksum_asset install_path backup_path prev_backup
  asset="$(select_asset)"
  [[ -n "$asset" ]] || { echo "no darwin arm64 archive asset for ${REPO} ${VERSION}" >&2; exit 66; }

  checksum_asset="$(select_checksum_asset)"
  [[ -n "$checksum_asset" ]] || { echo "no checksum asset for ${REPO} ${VERSION}" >&2; exit 66; }

  gh release download "$VERSION" --repo "$REPO" --pattern "$asset" --dir "$WORK_DIR" --clobber
  gh release download "$VERSION" --repo "$REPO" --pattern "$checksum_asset" --dir "$WORK_DIR" --clobber

  checksum_line_for "$WORK_DIR/$checksum_asset" "$asset" "$TOOL" "$VERSION" > "$WORK_DIR/${asset}.sha256"
  (cd "$WORK_DIR" && shasum -a 256 -c "${asset}.sha256")

  install_path="$INSTALL_DIR/$TOOL"
  prev_backup="$install_path.prev.bak"
  backup_path="$BACKUP_DIR/${TOOL}.$(date -u '+%Y%m%dT%H%M%SZ').bak"
  cp "$(command -v "$TOOL")" "$backup_path"
  cp "$backup_path" "$prev_backup"

  rm -rf "$WORK_DIR/extract"
  mkdir -p "$WORK_DIR/extract"
  case "$asset" in
    *.zip) unzip -q "$WORK_DIR/$asset" -d "$WORK_DIR/extract" ;;
    *) tar -xzf "$WORK_DIR/$asset" -C "$WORK_DIR/extract" ;;
  esac

  local candidate
  candidate="$(find "$WORK_DIR/extract" -type f -perm -111 -name "$TOOL" | head -1)"
  [[ -n "$candidate" ]] || candidate="$(find "$WORK_DIR/extract" -type f -name "$TOOL" | head -1)"
  [[ -n "$candidate" ]] || { rollback "$install_path" "$backup_path" "$prev_backup"; echo "no executable named $TOOL in asset" >&2; exit 66; }

  mkdir -p "$(dirname "$install_path")"
  install -m 0755 "$candidate" "$install_path"

  if ! post_install_verify "$VERSION"; then
    rollback "$install_path" "$backup_path" "$prev_backup"
    echo "smoke failed; rolled back $TOOL" >&2
    exit 70
  fi

  jq -c -n \
    --arg ts "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
    --arg tool "$TOOL" \
    --arg version "$VERSION" \
    --arg repo "$REPO" \
    --arg asset "$asset" \
    --arg backup "$backup_path" \
    --arg prev_backup "$prev_backup" \
    --arg install_path "$install_path" \
    '{ts:$ts,status:"upgraded",tool:$tool,version:$version,repo:$repo,asset:$asset,backup:$backup,prev_backup:$prev_backup,install_path:$install_path}'
}

main "$@"
