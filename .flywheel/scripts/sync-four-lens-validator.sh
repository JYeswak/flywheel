#!/usr/bin/env bash
set -euo pipefail

VERSION="sync-four-lens-validator.v1.0.0"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
TEMPLATE="${FLYWHEEL_FOUR_LENS_TEMPLATE:-$ROOT/templates/flywheel-install/validate-callback-before-close.sh.tmpl}"
MODE="audit"
JSON_OUT=0
REPOS=""

usage() {
  cat <<'EOF'
usage: sync-four-lens-validator.sh [--audit|--dry-run|--apply] [--json] [--repo PATH ...]

Audits or syncs the four-lens close validator into active flywheel fleet repos.
Default active fleet: flywheel, skillos, mobile-eats, clutterfreespaces, alpsinsurance.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --audit) MODE="audit"; shift ;;
    --dry-run) MODE="dry-run"; shift ;;
    --apply) MODE="apply"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --repo)
      [ -n "${2:-}" ] || { echo "ERR: --repo requires PATH" >&2; exit 2; }
      REPOS="${REPOS}${REPOS:+
}$2"
      shift 2
      ;;
    --help|-h) usage; exit 0 ;;
    --version) printf '%s\n' "$VERSION"; exit 0 ;;
    *) echo "ERR: unknown argument: $1" >&2; exit 2 ;;
  esac
done

[ -r "$TEMPLATE" ] || { echo "ERR: template missing: $TEMPLATE" >&2; exit 2; }

if [ -z "$REPOS" ]; then
  REPOS="/Users/josh/Developer/flywheel
/Users/josh/Developer/skillos
/Users/josh/Developer/mobile-eats
/Users/josh/Developer/clutterfreespaces
/Users/josh/Developer/alpsinsurance"
fi

tmp="$(mktemp "${TMPDIR:-/tmp}/four-lens-sync.XXXXXX")"
trap 'rm -f "$tmp"' EXIT
: >"$tmp"
total=0
present=0
executable=0
synced=0
missing_repo=0

while IFS= read -r repo; do
  [ -n "$repo" ] || continue
  total=$((total + 1))
  if [ ! -d "$repo" ]; then
    missing_repo=$((missing_repo + 1))
    printf '{"repo":"%s","status":"missing_repo","target":null,"synced":false}\n' "$repo" >>"$tmp"
    continue
  fi
  target="$repo/.flywheel/scripts/validate-callback-before-close.sh"
  status="missing"
  did_sync=false
  if [ "$MODE" = "apply" ]; then
    mkdir -p "$(dirname "$target")"
    cp "$TEMPLATE" "$target"
    chmod 0755 "$target"
    synced=$((synced + 1))
    did_sync=true
  fi
  if [ -f "$target" ]; then
    present=$((present + 1))
    status="present"
    if [ -x "$target" ]; then
      executable=$((executable + 1))
      status="executable"
    fi
  fi
  printf '{"repo":"%s","status":"%s","target":"%s","synced":%s}\n' "$repo" "$status" "$target" "$did_sync" >>"$tmp"
done <<EOF
$REPOS
EOF

if [ "$JSON_OUT" -eq 1 ]; then
  jq -s --arg version "$VERSION" --arg mode "$MODE" --arg template "$TEMPLATE" \
    --argjson total "$total" --argjson present "$present" --argjson executable "$executable" --argjson synced "$synced" --argjson missing_repo "$missing_repo" \
    '{schema_version:"four-lens-validator-fleet-sync/v1",version:$version,mode:$mode,template:$template,total:$total,present:$present,executable:$executable,synced:$synced,missing_repo:$missing_repo,all_executable:($total > 0 and $executable == $total),repos:.}' "$tmp"
else
  echo "sync-four-lens-validator mode=$MODE total=$total present=$present executable=$executable synced=$synced missing_repo=$missing_repo"
  cat "$tmp"
fi

[ "$executable" -eq "$total" ] || exit 1
