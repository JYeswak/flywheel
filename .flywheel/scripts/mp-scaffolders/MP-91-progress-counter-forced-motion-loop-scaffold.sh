#!/usr/bin/env bash
set -euo pipefail

MP_ID="MP-91"
SLUG="progress-counter-forced-motion-loop"
MARKER="Meta-pattern Adoption stance: MP-91 progress-counter-forced-motion-loop"
DIR_FILE=".flywheel-mp-91-adoption.md"

usage() {
  cat <<'USAGE'
usage: MP-91-progress-counter-forced-motion-loop-scaffold.sh [--dry-run|--apply] [--target PATH] PATH

Dry-run is default and prints the proposed unified diff. --apply writes the
bounded MP-91 adoption block to the target file, or to
<target-dir>/.flywheel-mp-91-adoption.md for directory targets.
USAGE
}

block() {
  cat <<'BLOCK'

# Meta-pattern Adoption stance: MP-91 progress-counter-forced-motion-loop
# Adoption signal:
# - Each tick records a productive event count and whether it moved the system.
# - A no-op / stall counter increments on repeated stall outcomes.
# - A threshold changes behavior from HOLD to probe, repair, redispatch, or bead.
# - Each tick writes an append-only receipt with the movement verdict.
#
# Progress-counter forced-motion loop template:
# productive_event_count=0
# repeated_stall_counter=0
# stall_threshold_behavior="after 2 no-op ticks, forbid another HOLD and force a probe or repair"
# append_only_receipt=".flywheel/state/<surface>-progress-receipts.jsonl"
#
# mp91_record_tick should persist:
# ts, tick_id, productive_event_count, no-op reason, stall counter,
# threshold behavior taken, and moved_the_system=true|false.
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
  tmp="$(mktemp "${TMPDIR:-/tmp}/mp91.XXXXXX")"
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

tmp="$(mktemp "${TMPDIR:-/tmp}/mp91.XXXXXX")"
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
