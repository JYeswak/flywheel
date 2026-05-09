#!/usr/bin/env bash
# promotion-candidate-stale-fire-reaper.sh
#
# flywheel-6s5dt: close stale-fired promotion-candidate beads from the
# 2026-05-09T17:11:17Z burst (and any future bursts before flywheel-iyaym's
# canonical-absolute-path fix propagates).
#
# Root cause (per flywheel-iyaym): doctrine-ladder-promote.sh scanned
# $REPO/INCIDENTS.md, which can resolve to a stale worktree copy. That
# created promotion-candidate beads for classes already covered in main
# canonical INCIDENTS.md.
#
# This reaper iterates open promotion-candidate beads, extracts the class
# name from the title, runs class_in_incidents against the CANONICAL
# absolute INCIDENTS path, and auto-closes the bead if covered.
#
# Usage:
#   promotion-candidate-stale-fire-reaper.sh [--dry-run|--apply] [--json]
#
# Defaults: --dry-run --json (reports planned actions; no mutations).
# Pass --apply to actually close stale-fired beads via `br close`.

set -uo pipefail

VERSION="promotion-candidate-stale-fire-reaper.v1"
SINCE="${PROMOTION_REAPER_SINCE:-2026-05-09T17:11:00Z}"
CANONICAL_INCIDENTS="${PROMOTION_REAPER_CANONICAL_INCIDENTS:-/Users/josh/Developer/flywheel/INCIDENTS.md}"
SKILL_INCIDENTS="${PROMOTION_REAPER_SKILL_INCIDENTS:-$HOME/.claude/skills/.flywheel/INCIDENTS.md}"
BR_BIN="${PROMOTION_REAPER_BR_BIN:-/Users/josh/.cargo/bin/br}"
APPLY=0
JSON_MODE=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) APPLY=1; shift ;;
    --dry-run) APPLY=0; shift ;;
    --json) JSON_MODE=1; shift ;;
    --no-json) JSON_MODE=0; shift ;;
    --since) SINCE="$2"; shift 2 ;;
    --help|-h)
      cat <<USAGE
Usage: promotion-candidate-stale-fire-reaper.sh [--dry-run|--apply] [--json] [--since ISO]

Closes promotion-candidate beads created after --since whose class is
canonically covered in $CANONICAL_INCIDENTS.

--dry-run (default): report planned actions; no mutations.
--apply:             actually close stale-fired beads via 'br close'.
--since:             ISO timestamp; only beads created after this are reaped (default: $SINCE).

Exit codes:
  0  reaper completed cleanly
  2  invalid argument or canonical INCIDENTS missing
  3  br CLI unavailable
USAGE
      exit 0 ;;
    *) printf 'unknown flag: %s\n' "$1" >&2; exit 2 ;;
  esac
done

if [[ ! -f "$CANONICAL_INCIDENTS" ]]; then
  printf 'ERROR: canonical INCIDENTS missing at %s\n' "$CANONICAL_INCIDENTS" >&2
  exit 2
fi
if [[ ! -x "$BR_BIN" ]]; then
  printf 'ERROR: br CLI not executable at %s\n' "$BR_BIN" >&2
  exit 3
fi

class_in_incidents() {
  local class="$1"
  if grep -Fqi -- "$class" "$CANONICAL_INCIDENTS"; then
    return 0
  fi
  if [[ -f "$SKILL_INCIDENTS" ]] && grep -Fqi -- "$class" "$SKILL_INCIDENTS"; then
    return 0
  fi
  return 1
}

# Extract class name from a promotion-candidate title:
# "[promotion-candidate] <class> (N events in 7d)"
extract_class() {
  local title="$1"
  printf '%s\n' "$title" | sed -E 's/^\[promotion-candidate\][[:space:]]*([^[:space:]].*)[[:space:]]*\(.*\)[[:space:]]*$/\1/' | sed -E 's/[[:space:]]+$//'
}

# Build close-reason note linking to flywheel-iyaym
close_reason() {
  local class="$1"
  printf 'BLOCKED-cleared: stale-fire from worktree-INCIDENTS bug pre-canonical-fix [flywheel-iyaym]; canonical INCIDENTS covers class=%s' "$class"
}

# Query open promotion-candidate beads created after $SINCE
candidates_json="$("$BR_BIN" list --json --limit 0 2>/dev/null \
  | jq --arg since "$SINCE" '
    [.issues[]
      | select(.created_at >= $since)
      | select(.title | startswith("[promotion-candidate]"))
      | select(.status != "closed")]
  ')"

candidates_count=$(printf '%s' "$candidates_json" | jq 'length' 2>/dev/null || echo 0)

stale_closed_ids=""
real_kept_ids=""
errored_ids=""
stale_closed_count=0
real_kept_count=0
errored_count=0

while IFS= read -r row; do
  [[ -z "$row" ]] && continue
  bead_id=$(printf '%s' "$row" | jq -r '.id')
  title=$(printf '%s' "$row" | jq -r '.title')
  class=$(extract_class "$title")

  if [[ -z "$class" ]]; then
    errored_ids="${errored_ids}${bead_id}=parse_class_failed,"
    errored_count=$((errored_count + 1))
    continue
  fi

  if class_in_incidents "$class"; then
    # Stale-fire: canonical covers this class
    if [[ "$APPLY" -eq 1 ]]; then
      reason=$(close_reason "$class")
      if "$BR_BIN" close "$bead_id" 2>/dev/null; then
        stale_closed_ids="${stale_closed_ids}${bead_id},"
        stale_closed_count=$((stale_closed_count + 1))
      else
        errored_ids="${errored_ids}${bead_id}=br_close_failed,"
        errored_count=$((errored_count + 1))
      fi
    else
      stale_closed_ids="${stale_closed_ids}${bead_id},"
      stale_closed_count=$((stale_closed_count + 1))
    fi
  else
    real_kept_ids="${real_kept_ids}${bead_id}=class:${class},"
    real_kept_count=$((real_kept_count + 1))
  fi
done < <(printf '%s' "$candidates_json" | jq -c '.[]' 2>/dev/null)

# Strip trailing commas
stale_closed_ids="${stale_closed_ids%,}"
real_kept_ids="${real_kept_ids%,}"
errored_ids="${errored_ids%,}"

if [[ "$JSON_MODE" -eq 1 ]]; then
  jq -nc \
    --arg version "$VERSION" \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg since "$SINCE" \
    --arg canonical_incidents "$CANONICAL_INCIDENTS" \
    --argjson apply "$APPLY" \
    --argjson candidates_count "$candidates_count" \
    --argjson stale_closed_count "$stale_closed_count" \
    --argjson real_kept_count "$real_kept_count" \
    --argjson errored_count "$errored_count" \
    --arg stale_closed_ids "$stale_closed_ids" \
    --arg real_kept_ids "$real_kept_ids" \
    --arg errored_ids "$errored_ids" \
    '{
      schema_version: $version,
      ts: $ts,
      mode: (if $apply == 1 then "apply" else "dry-run" end),
      since: $since,
      canonical_incidents: $canonical_incidents,
      candidates_count: $candidates_count,
      stale_closed_count: $stale_closed_count,
      real_kept_count: $real_kept_count,
      errored_count: $errored_count,
      stale_closed_ids: $stale_closed_ids,
      real_kept_ids: $real_kept_ids,
      errored_ids: $errored_ids
    }'
else
  printf 'Promotion-candidate stale-fire reaper\n'
  printf '  mode: %s\n' "$([[ "$APPLY" -eq 1 ]] && echo "apply" || echo "dry-run")"
  printf '  candidates: %d\n' "$candidates_count"
  printf '  stale_closed: %d\n' "$stale_closed_count"
  printf '  real_kept: %d (need authoritative L56 promotion)\n' "$real_kept_count"
  printf '  errored: %d\n' "$errored_count"
fi
