#!/usr/bin/env bash
set -euo pipefail

MP_ID="MP-89"
SLUG="mode-scoped-phase-workspace"
MARKER="Meta-pattern Adoption stance: MP-89 mode-scoped-phase-workspace"
DIR_FILE=".flywheel-mp-89-adoption.md"

usage() {
  cat <<'USAGE'
usage: MP-89-mode-scoped-phase-workspace-scaffold.sh [--dry-run|--apply] [--target PATH] PATH

Dry-run is default and prints the proposed unified diff. --apply writes the
bounded MP-89 adoption block to the target file, or to
<target-dir>/.flywheel-mp-89-adoption.md for directory targets.
USAGE
}

block() {
  cat <<'BLOCK'

# Meta-pattern Adoption stance: MP-89 mode-scoped-phase-workspace
# Adoption signal:
# - Start with a scope decision or scope probe before mutation.
# - Choose the smallest valid mode that fully covers the request.
# - List phases and activated bundles before writing files.
# - Mark out-of-scope adjacent work explicitly.
# - Emit expected output path values before mutation.
#
# Scope decision:
# mode="smallest valid mode"
# phases="probe, scaffold, validate"
# activated_bundle="targeted MP adoption block only"
# skipped_bundle="full audit, real fleet apply, adjacent work"
# out-of-scope="Track 1/2, consumer repo writes, unrelated refactors"
# expected_output_path="<target file or target dir adoption sidecar>"
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
  tmp="$(mktemp "${TMPDIR:-/tmp}/mp89.XXXXXX")"
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

tmp="$(mktemp "${TMPDIR:-/tmp}/mp89.XXXXXX")"
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
