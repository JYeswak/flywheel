#!/usr/bin/env bash
# fleet-mission-alignment-probe.sh
#
# Purpose:
#   Fleet-wide aggregator for the per-repo mission-lock-age-probe.sh primitive.
#   Discovers every flywheel-installed repo under ~/Developer/*/, classifies
#   each by mission_lock age (fresh/stale-warn/stale-error/missing/unlocked),
#   and emits aggregated JSON for doctor + dashboard consumption.
#
# Bead: flywheel-4cbbr (Duty 5a — Mission-alignment surveillance)
# Mission anchor: .flywheel/MISSION.md (lock 2026-05-20T19:40Z, a59529f3)
# Schema: fleet-mission-alignment.v1
#
# Integration points:
#   - Doctor JSON key: fleet_mission_alignment (consumed by flywheel-doctor)
#   - Dashboard line: rendered in /flywheel:status step 4g (mission surveillance)
#   - Cron-friendly: use --quiet --json to suppress per-repo stderr chatter
#
# Read-only: never mutates any repo's MISSION.md or lock-log.
#
# Usage:
#   fleet-mission-alignment-probe.sh                 # human stdout summary
#   fleet-mission-alignment-probe.sh --json          # aggregated JSON
#   fleet-mission-alignment-probe.sh --json --quiet  # JSON, no stderr noise
#   fleet-mission-alignment-probe.sh --root <dir>    # override discovery root
#
set -euo pipefail

SCHEMA_VERSION="fleet-mission-alignment.v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROBE="${SCRIPT_DIR}/mission-lock-age-probe.sh"

FRESH_HOURS=168
STALE_ERROR_HOURS=720

ROOT="${FLEET_MISSION_ROOT:-/Users/josh/Developer}"
OUTPUT_MODE="text"
QUIET=0

usage() {
  cat <<'USAGE'
Usage:
  fleet-mission-alignment-probe.sh [--json] [--quiet] [--root <dir>]

Options:
  --json         Emit aggregated JSON to stdout (default: human summary)
  --quiet        Suppress per-repo stderr progress lines (cron-friendly)
  --root <dir>   Override discovery root (default: /Users/josh/Developer)
  -h, --help     Show this help

Aggregated JSON schema: fleet-mission-alignment.v1
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --json) OUTPUT_MODE="json" ;;
    --quiet) QUIET=1 ;;
    --root) shift; ROOT="${1:?--root requires arg}" ;;
    --root=*) ROOT="${1#--root=}" ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [ ! -x "$PROBE" ]; then
  printf 'fleet-mission-alignment-probe: missing primitive: %s\n' "$PROBE" >&2
  exit 3
fi

if [ ! -d "$ROOT" ]; then
  printf 'fleet-mission-alignment-probe: root does not exist: %s\n' "$ROOT" >&2
  exit 3
fi

log() { [ "$QUIET" -eq 1 ] || printf '%s\n' "$*" >&2; }

ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Discover candidate repos.
mapfile -t MISSION_FILES < <(find "$ROOT" -mindepth 3 -maxdepth 3 -type f -path '*/.flywheel/MISSION.md' 2>/dev/null | sort)

per_repo_json="[]"
fresh=0; stale_warn=0; stale_error=0; missing=0; unlocked=0
worst_status="fresh"; worst_age=-1; worst_repo=""

# Priority ranking for "worst" selection.
rank() {
  case "$1" in
    missing)      printf '5' ;;
    unlocked)     printf '4' ;;
    stale-error)  printf '3' ;;
    stale-warn)   printf '2' ;;
    fresh)        printf '1' ;;
    *)            printf '0' ;;
  esac
}

current_worst_rank="$(rank fresh)"

for mission in "${MISSION_FILES[@]}"; do
  repo_dir="${mission%/.flywheel/MISSION.md}"
  repo_name="$(basename "$repo_dir")"
  log "probe: $repo_name"

  if ! probe_json="$("$PROBE" --repo "$repo_dir" --doctor --json 2>/dev/null)"; then
    log "  warn: probe failed for $repo_name; classifying as missing"
    probe_json="$(jq -nc --arg repo "$repo_dir" '{
      status:"blocked", mission_lock_status:"missing",
      mission_lock_age_hours:null, lock_hash_valid:null, locked_at:null,
      repo:$repo
    }')"
  fi

  status="$(jq -r '.mission_lock_status // "missing"' <<<"$probe_json")"
  age_h="$(jq -r '.mission_lock_age_hours // empty' <<<"$probe_json")"
  hash_valid="$(jq -r '.lock_hash_valid // empty' <<<"$probe_json")"
  locked_at="$(jq -r '.locked_at // empty' <<<"$probe_json")"

  case "$status" in
    fresh)        fresh=$((fresh+1)) ;;
    stale-warn)   stale_warn=$((stale_warn+1)) ;;
    stale-error)  stale_error=$((stale_error+1)) ;;
    missing)      missing=$((missing+1)) ;;
    unlocked)     unlocked=$((unlocked+1)) ;;
    *)            missing=$((missing+1)); status="missing" ;;
  esac

  this_rank="$(rank "$status")"
  if [ "$this_rank" -gt "$current_worst_rank" ]; then
    current_worst_rank="$this_rank"
    worst_status="$status"
    worst_repo="$repo_name"
    worst_age="${age_h:--1}"
  elif [ "$this_rank" -eq "$current_worst_rank" ] && [ -n "${age_h:-}" ]; then
    # Tie-break by age (oldest wins) when comparable numerically.
    if awk "BEGIN{exit !($age_h > $worst_age)}" 2>/dev/null; then
      worst_repo="$repo_name"
      worst_age="$age_h"
    fi
  fi

  per_repo_json="$(jq -c \
    --arg repo "$repo_name" \
    --arg repo_path "$repo_dir" \
    --arg status "$status" \
    --arg age "$age_h" \
    --arg hash_valid "$hash_valid" \
    --arg locked_at "$locked_at" \
    '. + [{
      repo:$repo,
      repo_path:$repo_path,
      status:$status,
      age_hours:( ($age|tonumber?) // null ),
      lock_hash_valid:( if $hash_valid=="true" then true elif $hash_valid=="false" then false else null end ),
      last_locked_at:( if $locked_at=="" then null else $locked_at end )
    }]' <<<"$per_repo_json")"
done

total="${#MISSION_FILES[@]}"

if [ "$stale_error" -gt 0 ] || [ "$missing" -gt 0 ] || [ "$unlocked" -gt 0 ]; then
  agg_status="critical"
elif [ "$stale_warn" -gt 0 ]; then
  agg_status="degraded"
else
  agg_status="ok"
fi

if [ -z "$worst_repo" ]; then
  worst_repo="(none)"
fi
worst_age_out="null"
if [ "$worst_age" != "-1" ] && [ -n "$worst_age" ]; then
  worst_age_out="$worst_age"
fi

dashboard_line="Mission alignment: ${fresh}/${total} fresh, $((stale_warn+stale_error)) stale (worst=${worst_repo}:${worst_status})"

aggregated="$(jq -nc \
  --arg schema "$SCHEMA_VERSION" \
  --arg ts "$ts" \
  --arg status "$agg_status" \
  --argjson total "$total" \
  --argjson fresh "$fresh" \
  --argjson stale_warn "$stale_warn" \
  --argjson stale_error "$stale_error" \
  --argjson missing "$missing" \
  --argjson unlocked "$unlocked" \
  --arg worst_repo "$worst_repo" \
  --arg worst_status "$worst_status" \
  --argjson worst_age "$worst_age_out" \
  --argjson per_repo "$per_repo_json" \
  --arg dashboard "$dashboard_line" \
  --argjson fresh_hours "$FRESH_HOURS" \
  --argjson stale_error_hours "$STALE_ERROR_HOURS" \
  --arg root "$ROOT" \
  '{
    schema_version:$schema,
    ts:$ts,
    root:$root,
    status:$status,
    total_repos:$total,
    fresh_count:$fresh,
    stale_warn_count:$stale_warn,
    stale_error_count:$stale_error,
    missing_count:$missing,
    unlocked_count:$unlocked,
    worst_repo:$worst_repo,
    worst_status:$worst_status,
    worst_age_hours:$worst_age,
    thresholds:{fresh_hours:$fresh_hours, stale_error_hours:$stale_error_hours},
    per_repo:$per_repo,
    dashboard_line:$dashboard
  }')"

if [ "$OUTPUT_MODE" = "json" ]; then
  printf '%s\n' "$aggregated"
else
  printf 'Fleet mission alignment @ %s\n' "$ts"
  printf '  root        : %s\n' "$ROOT"
  printf '  status      : %s\n' "$agg_status"
  printf '  total repos : %d\n' "$total"
  printf '  fresh       : %d\n' "$fresh"
  printf '  stale-warn  : %d\n' "$stale_warn"
  printf '  stale-error : %d\n' "$stale_error"
  printf '  missing     : %d\n' "$missing"
  printf '  unlocked    : %d\n' "$unlocked"
  printf '  worst       : %s (%s, age=%s h)\n' "$worst_repo" "$worst_status" "$worst_age_out"
  printf '  dashboard   : %s\n' "$dashboard_line"
fi
