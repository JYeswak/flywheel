#!/usr/bin/env bash
set -euo pipefail

MP_ID="MP-82"
SLUG="hook-lifecycle-guardrail-chain"
MARKER="Meta-pattern Adoption stance: MP-82 hook-lifecycle-guardrail-chain"
DIR_FILE=".flywheel-mp-82-adoption.md"

usage() {
  cat <<'USAGE'
usage: MP-82-hook-lifecycle-guardrail-chain-scaffold.sh [--dry-run|--apply] [--target PATH] PATH

Dry-run is default and prints the proposed unified diff. --apply writes the
bounded MP-82 adoption block to the target file, or to
<target-dir>/.flywheel-mp-82-adoption.md for directory targets.
USAGE
}

block() {
  cat <<'BLOCK'

# Meta-pattern Adoption stance: MP-82 hook-lifecycle-guardrail-chain
# Adoption signal:
# - Each event / hook has one named lifecycle purpose.
# - Blocking behavior and non-blocking feedback behavior are explicit.
# - stdin schema and stdout schema are documented.
# - Recursive hook re-entry is guarded by an active flag or equivalent latch.
# - Mutating repairs are dry-run by default and every action has an audit path.
#
# Hook lifecycle table:
# | event | trigger | blocking behavior | stdin schema | stdout schema | audit path |
# |---|---|---|---|---|---|
# | pre-action hook | before mutation | block on unsafe input | JSON envelope | JSON verdict | append-only receipt |
# | post-action hook | after mutation | non-blocking feedback | JSON envelope | JSON receipt | append-only receipt |
#
# Recursion guard: refuse re-entry when hook_active=true.
# Repair contract: dry-run first; --apply requires explicit scope and audit receipt.
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
  tmp="$(mktemp "${TMPDIR:-/tmp}/mp82.XXXXXX")"
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

tmp="$(mktemp "${TMPDIR:-/tmp}/mp82.XXXXXX")"
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
