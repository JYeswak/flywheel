#!/usr/bin/env bash
set -euo pipefail

MP_ID="MP-90"
SLUG="adjacent-skill-boundary-router"
MARKER="Meta-pattern Adoption stance: MP-90 adjacent-skill-boundary-router"
DIR_FILE=".flywheel-mp-90-adoption.md"

usage() {
  cat <<'USAGE'
usage: MP-90-adjacent-skill-boundary-router-scaffold.sh [--dry-run|--apply] [--target PATH] PATH

Dry-run is default and prints the proposed unified diff. --apply writes the
bounded MP-90 adoption block to the target file, or to
<target-dir>/.flywheel-mp-90-adoption.md for directory targets.
USAGE
}

block() {
  cat <<'BLOCK'

# Meta-pattern Adoption stance: MP-90 adjacent-skill-boundary-router
# Adoption signal:
# - Smell-test matrix names when this surface applies and when it does not.
# - If not, use the named sibling or companion skill instead of expanding scope.
# - Boundaries are explicit against adjacent sibling surfaces.
# - Companion skill handoff output matches the next skill input shape.
#
# Smell-test matrix:
# | Signal | Use this surface? | If not, use |
# |---|---|---|
# | Same operator goal and same write boundary | yes | adjacent sibling surface |
# | Different domain owner or evidence shape | no | companion skill with matching input shape |
#
# Boundary router:
# - Positive boundary: handle only the declared mode, target path, and output.
# - Negative boundary: route adjacent work to the sibling named by the caller.
# - Handoff output: emit target path, receipt path, and next input shape.
BLOCK
}

emit_json() {
  local status="$1" target="$2" planned="$3"
  jq -nc --arg mp "$MP_ID" --arg slug "$SLUG" --arg status "$status" --arg target "$target" --arg planned "$planned" \
    '{schema_version:"mp-scaffolder.result/v1",mp_id:$mp,slug:$slug,status:$status,target:$target,planned_path:$planned}'
}

mode="dry-run"
json=0
target=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) mode="dry-run"; shift ;;
    --apply) mode="apply"; shift ;;
    --target) target="${2:-}"; shift 2 ;;
    --json) json=1; shift ;;
    -h|--help) usage; exit 0 ;;
    --*) printf 'unknown arg: %s\n' "$1" >&2; usage >&2; exit 64 ;;
    *) target="$1"; shift ;;
  esac
done

[[ -n "$target" ]] || { usage >&2; exit 64; }
[[ -e "$target" ]] || { printf 'target missing: %s\n' "$target" >&2; exit 2; }

if [[ -d "$target" ]]; then
  planned="$target/$DIR_FILE"
  if [[ -f "$planned" ]] && rg -q "$MARKER" "$planned"; then
    [[ "$json" -eq 1 ]] && emit_json noop "$target" "$planned" || printf 'NOOP %s already present in %s\n' "$MP_ID" "$planned"
    exit 0
  fi
  tmp="$(mktemp "${TMPDIR:-/tmp}/mp90.XXXXXX")"
  trap 'rm -f "$tmp"' EXIT
  block >"$tmp"
  if [[ "$mode" == "apply" ]]; then
    cp "$tmp" "$planned"
    [[ "$json" -eq 1 ]] && emit_json applied "$target" "$planned" || printf 'APPLIED %s %s\n' "$MP_ID" "$planned"
  else
    diff -u /dev/null "$tmp" || true
    if [[ "$json" -eq 1 ]]; then
      emit_json planned "$target" "$planned"
    fi
  fi
  exit 0
fi

planned="$target"
if rg -q "$MARKER" "$target"; then
  [[ "$json" -eq 1 ]] && emit_json noop "$target" "$planned" || printf 'NOOP %s already present in %s\n' "$MP_ID" "$target"
  exit 0
fi

tmp="$(mktemp "${TMPDIR:-/tmp}/mp90.XXXXXX")"
trap 'rm -f "$tmp"' EXIT
cat "$target" >"$tmp"
block >>"$tmp"

if [[ "$mode" == "apply" ]]; then
  cp "$tmp" "$target"
  [[ "$json" -eq 1 ]] && emit_json applied "$target" "$planned" || printf 'APPLIED %s %s\n' "$MP_ID" "$target"
else
  diff -u "$target" "$tmp" || true
  if [[ "$json" -eq 1 ]]; then
    emit_json planned "$target" "$planned"
  fi
fi
