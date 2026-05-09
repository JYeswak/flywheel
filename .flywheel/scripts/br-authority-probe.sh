#!/usr/bin/env bash
# br-authority-probe.sh — flywheel-side diagnostic equivalent of the upstream
# `br authority` command sketched in `bead-isolation-fix-2026-04-30.md` Change
# 4.3. Reports DB path, mutability, discovery method, source_repo (last-touched),
# and walk-up status without requiring an upstream patch in beads_rust.
#
# Boundary: read-only against the local `br` install + the current working
# directory's `.beads/` resolution path. Never writes to any beads DB.
set -euo pipefail

SCHEMA_VERSION="br-authority-probe.v1"
BR_BIN="${BR_AUTHORITY_BR_BIN:-$(command -v br 2>/dev/null || echo /Users/josh/.cargo/bin/br)}"
TARGET_DIR="${BR_AUTHORITY_TARGET_DIR:-$PWD}"

MODE=run
JSON_OUT=0

usage() {
  cat <<'USAGE'
usage: br-authority-probe.sh [--target-dir PATH] [--json]
       br-authority-probe.sh --doctor|--health|--schema|--info [--json]

Reports authority/discovery metadata for the local br install + a target
directory's .beads resolution path:

  - br_bin:           path to the resolved br executable
  - br_version:       output of `br --version`
  - target_dir:       resolved absolute path of the target directory
  - db_path:          .beads/beads.db path discovered from target_dir
  - db_writable:      whether the discovered DB file is writable by the user
  - discovery_method: local | walk-up | none | strict-error
  - walk_up_distance: directory levels traversed to find .beads (0 = same dir)
  - walk_up_dirs:     ordered list of paths walked
  - source_repo_last: source_repo field on the most-recent-touched row, if any
  - is_symlink:       whether the resolved .beads is a symlink
  - symlink_target:   resolved target if .beads is a symlink (absolute)
  - cross_tree:       true if symlink target is outside target_dir tree
USAGE
}

doctor() {
  jq -nc --arg schema "$SCHEMA_VERSION" --arg bin "$BR_BIN" \
    '{schema_version:$schema, success:true, mode:"doctor",
      br_bin_present:($bin | test("^/")),
      native_surface:["br --version","br where","br list --json"],
      reads_only:true}'
}

info() {
  jq -nc --arg schema "$SCHEMA_VERSION" \
    '{schema_version:$schema, success:true, mode:"info",
      fields:["br_bin","br_version","target_dir","db_path","db_writable","discovery_method","walk_up_distance","walk_up_dirs","source_repo_last","is_symlink","symlink_target","cross_tree"]}'
}

schema() {
  jq -nc --arg schema "$SCHEMA_VERSION" \
    '{schema_version:$schema,
      properties:{
        br_bin:{type:"string"},
        br_version:{type:"string"},
        target_dir:{type:"string"},
        db_path:{type:["string","null"]},
        db_writable:{type:"boolean"},
        discovery_method:{type:"string", enum:["local","walk-up","none","strict-error"]},
        walk_up_distance:{type:"integer"},
        walk_up_dirs:{type:"array"},
        source_repo_last:{type:["string","null"]},
        is_symlink:{type:"boolean"},
        symlink_target:{type:["string","null"]},
        cross_tree:{type:"boolean"}}}'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target-dir) TARGET_DIR="${2:?--target-dir requires PATH}"; shift 2;;
    --json) JSON_OUT=1; shift;;
    --doctor|--health) MODE=doctor; shift;;
    --info) MODE=info; shift;;
    --schema) MODE=schema; shift;;
    -h|--help) usage; exit 0;;
    *) echo "ERR: unknown arg $1" >&2; usage >&2; exit 2;;
  esac
done

case "$MODE" in
  doctor) doctor; exit 0;;
  info) info; exit 0;;
  schema) schema; exit 0;;
esac

[[ -x "$BR_BIN" ]] || { echo "ERR: br binary not executable: $BR_BIN" >&2; exit 2; }

TARGET_DIR_ABS="$(cd "$TARGET_DIR" 2>/dev/null && pwd)" || {
  echo "ERR: target dir does not exist: $TARGET_DIR" >&2; exit 2; }

BR_VERSION="$("$BR_BIN" --version 2>/dev/null | head -1 || echo unknown)"

# Walk up from TARGET_DIR_ABS until .beads is found or root reached.
DB_PATH=""
DISCOVERY_METHOD="none"
WALK_UP_DISTANCE=0
WALK_UP_DIRS_TMP="$(mktemp "${TMPDIR:-/tmp}/br-authority.XXXXXX")"
trap 'rm -f "$WALK_UP_DIRS_TMP"' EXIT
: >"$WALK_UP_DIRS_TMP"

probe_dir="$TARGET_DIR_ABS"
while :; do
  printf '%s\n' "$probe_dir" >>"$WALK_UP_DIRS_TMP"
  if [[ -d "$probe_dir/.beads" ]]; then
    DB_PATH="$probe_dir/.beads/beads.db"
    if [[ "$probe_dir" == "$TARGET_DIR_ABS" ]]; then
      DISCOVERY_METHOD="local"
    else
      DISCOVERY_METHOD="walk-up"
    fi
    break
  fi
  parent="$(dirname "$probe_dir")"
  [[ "$parent" == "$probe_dir" ]] && break
  probe_dir="$parent"
  WALK_UP_DISTANCE=$((WALK_UP_DISTANCE + 1))
done

# If BEADS_STRICT_LOCAL=1 was the operating mode and discovery walked up, that's a strict-error.
if [[ "${BEADS_STRICT_LOCAL:-0}" == "1" && "$DISCOVERY_METHOD" == "walk-up" ]]; then
  DISCOVERY_METHOD="strict-error"
fi

DB_WRITABLE=false
if [[ -n "$DB_PATH" && -w "$DB_PATH" ]]; then DB_WRITABLE=true; fi

IS_SYMLINK=false
SYMLINK_TARGET=""
CROSS_TREE=false
if [[ -n "$DB_PATH" ]]; then
  beads_dir="$(dirname "$DB_PATH")"
  if [[ -L "$beads_dir" ]]; then
    IS_SYMLINK=true
    SYMLINK_TARGET="$(readlink -f "$beads_dir" 2>/dev/null || readlink "$beads_dir")"
    if [[ -n "$SYMLINK_TARGET" && "$SYMLINK_TARGET" != "$TARGET_DIR_ABS"* ]]; then
      CROSS_TREE=true
    fi
  fi
fi

SOURCE_REPO_LAST=""
if [[ "$DISCOVERY_METHOD" != "strict-error" && "$DISCOVERY_METHOD" != "none" ]]; then
  SOURCE_REPO_LAST="$(cd "$TARGET_DIR_ABS" && "$BR_BIN" list --limit 1 --json 2>/dev/null | jq -r '.issues[0].source_repo // ""' 2>/dev/null || echo "")"
fi

# Build walk_up_dirs JSON array.
WALK_UP_DIRS_JSON="$(jq -R -s 'split("\n") | map(select(length > 0))' "$WALK_UP_DIRS_TMP")"

PAYLOAD="$(jq -nc \
  --arg schema "$SCHEMA_VERSION" \
  --arg br_bin "$BR_BIN" \
  --arg br_version "$BR_VERSION" \
  --arg target_dir "$TARGET_DIR_ABS" \
  --arg db_path "$DB_PATH" \
  --argjson db_writable "$DB_WRITABLE" \
  --arg discovery_method "$DISCOVERY_METHOD" \
  --argjson walk_up_distance "$WALK_UP_DISTANCE" \
  --argjson walk_up_dirs "$WALK_UP_DIRS_JSON" \
  --arg source_repo_last "$SOURCE_REPO_LAST" \
  --argjson is_symlink "$IS_SYMLINK" \
  --arg symlink_target "$SYMLINK_TARGET" \
  --argjson cross_tree "$CROSS_TREE" \
  '{schema_version:$schema, success:true, mode:"run",
    br_bin:$br_bin, br_version:$br_version, target_dir:$target_dir,
    db_path:(if $db_path == "" then null else $db_path end),
    db_writable:$db_writable,
    discovery_method:$discovery_method,
    walk_up_distance:$walk_up_distance,
    walk_up_dirs:$walk_up_dirs,
    source_repo_last:(if $source_repo_last == "" then null else $source_repo_last end),
    is_symlink:$is_symlink,
    symlink_target:(if $symlink_target == "" then null else $symlink_target end),
    cross_tree:$cross_tree}')"

if [[ "$JSON_OUT" == 1 ]]; then
  printf '%s\n' "$PAYLOAD"
else
  jq -r '"br-authority target=\(.target_dir) db=\(.db_path // "none") method=\(.discovery_method) walk_up=\(.walk_up_distance) symlink=\(.is_symlink) cross_tree=\(.cross_tree) source_repo_last=\(.source_repo_last // "none")"' <<<"$PAYLOAD"
fi
