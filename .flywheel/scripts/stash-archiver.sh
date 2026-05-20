#!/usr/bin/env bash
# stash-archiver.sh — Weekly cron that auto-archives stale git stashes fleet-wide.
#
# Joshua-direct 2026-05-20T20:00Z: "this needs to be a scripted process — you cannot
# expect me to come in every single day and run this type of stuff to clean up
# projects trash". 206 stashes accreted fleet-wide as of audit; manual triage is
# not a structural fix. This script is the structural fix.
#
# Consumes:    .flywheel/schemas/STASH-POLICY.schema.json (flywheel-m9yxr)
# Sister to:   temp-janitor.sh, developer-cache-janitor.sh, worktree-reaper.sh
# Implements:  bead flywheel-k078i (Mission Duty 3)
#
# For each repo in ~/Developer/*/ that has stashes:
#   - Enumerate via `git stash list --format='%gd|%ci|%s'`
#   - For each stash: compute age in days
#   - If age > max_age_days (default 30, per STASH-POLICY):
#       * Honor exempt_stash_message_prefixes (scratch:, recover:) up to hard_cap_days (90)
#       * Save `git stash show -p stash@{N}` to .flywheel/stash-archive/<ts>-<subject-slug>.patch
#       * Verify patch file size > 0 BEFORE dropping (never lossy)
#       * `git stash drop stash@{N}` — by ref captured *before* enumeration, descending,
#         because dropping renumbers; we iterate descending stash indices to be safe.
#   - Append .flywheel/stash-archive/ to repo's .gitignore if absent
#
# Note on archive location: the STASH-POLICY schema default is
# ~/.local/state/flywheel/stash-archive/<repo>/ (off-tree). Joshua's dispatch
# packet for flywheel-k078i explicitly specified per-repo in-repo path
# .flywheel/stash-archive/ with .gitignore. We follow the dispatch.
#
# Safety:
#   - NEVER drop without successful archive write (size > 0)
#   - Halt+alert if archiving >50 stashes in one run (Joshua-prompt protection)
#   - --dry-run is default-safe; --apply must be explicit
#   - Iterate stash indices DESCENDING (drop renumbers lower indices)
#
# Exit codes:
#   0 = ok
#   1 = config error
#   2 = halted (>HALT_CAP stashes — Joshua-prompt protection)
#   3 = archive write failed (would-be-lossy drop refused)

set -euo pipefail

MAX_AGE_DAYS="${STASH_ARCHIVER_MAX_AGE_DAYS:-30}"
HARD_CAP_DAYS="${STASH_ARCHIVER_HARD_CAP_DAYS:-90}"
HALT_CAP="${STASH_ARCHIVER_HALT_CAP:-50}"
DEVELOPER_DIR="${STASH_ARCHIVER_DEVELOPER_DIR:-$HOME/Developer}"
EXEMPT_PREFIXES_DEFAULT="scratch:,recover:"
EXEMPT_PREFIXES="${STASH_ARCHIVER_EXEMPT_PREFIXES:-$EXEMPT_PREFIXES_DEFAULT}"

DRY_RUN=true
APPLY=false
JSON_OUT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; APPLY=false; shift ;;
    --apply) APPLY=true; DRY_RUN=false; shift ;;
    --json) JSON_OUT=true; shift ;;
    --max-age-days) MAX_AGE_DAYS="$2"; shift 2 ;;
    --hard-cap-days) HARD_CAP_DAYS="$2"; shift 2 ;;
    --halt-cap) HALT_CAP="$2"; shift 2 ;;
    --developer-dir) DEVELOPER_DIR="$2"; shift 2 ;;
    --exempt-prefixes) EXEMPT_PREFIXES="$2"; shift 2 ;;
    -h|--help) sed -n '2,45p' "$0"; exit 0 ;;
    *) echo "unknown flag: $1" >&2; exit 1 ;;
  esac
done

[[ -d "$DEVELOPER_DIR" ]] || { echo "DEVELOPER_DIR does not exist: $DEVELOPER_DIR" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq not found in PATH" >&2; exit 1; }
command -v git >/dev/null 2>&1 || { echo "git not found in PATH" >&2; exit 1; }

NOW_TS=$(date -u +%s)
NOW_ISO=$(date -u +%Y-%m-%dT%H:%M:%SZ)
TS_FILE=$(date -u +%Y%m%dT%H%M%SZ)

log() { [[ "$JSON_OUT" == "true" ]] && return 0; printf '%s\n' "$*" >&2; }

slugify() {
  # Sanitize stash subject into a filename-safe slug, max 60 chars.
  printf '%s' "$1" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9._-]+/-/g; s/^-+//; s/-+$//' \
    | cut -c1-60
}

strip_stash_prefix() {
  # `git stash list --format=%s` returns "On <branch>: <msg>" or "WIP on <branch>: <msg>".
  # Strip that wrapping so user-facing exempt-prefix matching works against the actual msg.
  local s="$1"
  s="${s#WIP on *: }"
  s="${s#On *: }"
  printf '%s' "$s"
}

is_exempt() {
  # Args: subject prefixes-csv. Matches against the stripped (post-"On <branch>: ") msg.
  local subj; subj=$(strip_stash_prefix "$1")
  local csv="$2" p
  IFS=',' read -ra arr <<<"$csv"
  for p in "${arr[@]}"; do
    [[ -z "$p" ]] && continue
    if [[ "$subj" == "$p"* ]]; then
      return 0
    fi
  done
  return 1
}

# Aggregate counters
repos_scanned=0
stashes_found=0
stashes_archived=0
stashes_skipped_fresh=0
stashes_skipped_exempt=0
archive_failed=0
halted=false

# Per-repo JSONL accumulator (built into single array later)
PER_REPO_TMP=$(mktemp -t stash-archiver-perrepo.XXXXXX)
trap 'rm -f "$PER_REPO_TMP"' EXIT

log "=== stash-archiver v1 — $NOW_ISO ==="
log "  developer_dir=$DEVELOPER_DIR max_age=${MAX_AGE_DAYS}d hard_cap=${HARD_CAP_DAYS}d halt_cap=${HALT_CAP} dry_run=$DRY_RUN apply=$APPLY"

while IFS= read -r repo; do
  [[ -z "$repo" ]] && continue
  [[ ! -d "$repo/.git" ]] && continue
  repos_scanned=$((repos_scanned + 1))

  # Snapshot stash list *before* any mutation; we'll iterate descending indices.
  # Format: <ref>|<commit-iso>|<subject>
  mapfile -t stash_lines < <(cd "$repo" && git stash list --format='%gd|%ci|%s' 2>/dev/null || true)
  (( ${#stash_lines[@]} == 0 )) && continue

  repo_name=$(basename "$repo")
  repo_found=0
  repo_archived=0
  repo_skipped_fresh=0
  repo_skipped_exempt=0
  repo_failed=0

  archive_dir="$repo/.flywheel/stash-archive"

  # Iterate indices DESCENDING so drops don't shift remaining indices.
  # Capture (index, age_days, subject, exempt?) up front in arrays, then process from highest.
  indices=()
  ages=()
  subjects=()
  for line in "${stash_lines[@]}"; do
    ref="${line%%|*}"
    rest="${line#*|}"
    ci="${rest%%|*}"
    subj="${rest#*|}"
    idx="${ref#stash@\{}"; idx="${idx%\}}"
    # Parse commit iso to epoch (gnu/bsd-compatible: %ci is `2026-05-20 12:34:56 -0700`)
    # Use git itself for portability: ask git for the unix ts of the stash commit
    commit_ts=$(cd "$repo" && git log -1 --format=%ct "$ref" 2>/dev/null || echo 0)
    [[ "$commit_ts" == 0 ]] && continue
    age_days=$(( (NOW_TS - commit_ts) / 86400 ))
    indices+=("$idx")
    ages+=("$age_days")
    subjects+=("$subj")
    repo_found=$((repo_found + 1))
    stashes_found=$((stashes_found + 1))
  done

  if (( repo_found == 0 )); then
    continue
  fi

  log ""
  log "--- $repo_name (${repo_found} stashes) ---"

  # Sort indices descending. They were enumerated in display order (0..N-1) already,
  # so reverse iteration is just walking the arrays back-to-front.
  for ((i=${#indices[@]}-1; i>=0; i--)); do
    idx="${indices[$i]}"
    age="${ages[$i]}"
    subj="${subjects[$i]}"

    # Halt-cap check (Joshua-prompt protection)
    if (( stashes_archived >= HALT_CAP )); then
      halted=true
      log "  HALT: archived $stashes_archived stashes; halt cap=$HALT_CAP reached — stopping for Joshua review"
      break
    fi

    threshold=$MAX_AGE_DAYS
    exempt_flag=""
    if is_exempt "$subj" "$EXEMPT_PREFIXES"; then
      threshold=$HARD_CAP_DAYS
      exempt_flag=" exempt(${EXEMPT_PREFIXES})"
    fi

    if (( age <= threshold )); then
      if [[ -n "$exempt_flag" ]]; then
        log "  keep stash@{$idx} age=${age}d ≤ hard_cap=${threshold}d$exempt_flag  subj='${subj:0:60}'"
        repo_skipped_exempt=$((repo_skipped_exempt + 1))
        stashes_skipped_exempt=$((stashes_skipped_exempt + 1))
      else
        log "  keep stash@{$idx} age=${age}d ≤ max_age=${threshold}d  subj='${subj:0:60}'"
        repo_skipped_fresh=$((repo_skipped_fresh + 1))
        stashes_skipped_fresh=$((stashes_skipped_fresh + 1))
      fi
      continue
    fi

    # Archive + drop path
    slug=$(slugify "$(strip_stash_prefix "$subj")")
    [[ -z "$slug" ]] && slug="no-message"
    patch_file="$archive_dir/${TS_FILE}--stash-${idx}--${slug}.patch"

    if [[ "$APPLY" == "true" ]]; then
      mkdir -p "$archive_dir"
      if ! (cd "$repo" && git stash show -p "stash@{$idx}" > "$patch_file" 2>/dev/null); then
        log "  ARCHIVE-FAIL stash@{$idx} — refusing drop"
        rm -f "$patch_file" 2>/dev/null || true
        repo_failed=$((repo_failed + 1))
        archive_failed=$((archive_failed + 1))
        continue
      fi
      # Verify patch size > 0
      if [[ ! -s "$patch_file" ]]; then
        log "  ARCHIVE-EMPTY stash@{$idx} — refusing drop"
        rm -f "$patch_file" 2>/dev/null || true
        repo_failed=$((repo_failed + 1))
        archive_failed=$((archive_failed + 1))
        continue
      fi
      # Patch written and non-empty — safe to drop
      if ! (cd "$repo" && git stash drop "stash@{$idx}" >/dev/null 2>&1); then
        log "  DROP-FAIL stash@{$idx} (patch preserved at $patch_file)"
        repo_failed=$((repo_failed + 1))
        archive_failed=$((archive_failed + 1))
        continue
      fi
      log "  ARCHIVED stash@{$idx} age=${age}d → ${patch_file##$repo/}"
    else
      log "  WOULD ARCHIVE stash@{$idx} age=${age}d → ${patch_file##$repo/}  subj='${subj:0:60}'"
    fi
    repo_archived=$((repo_archived + 1))
    stashes_archived=$((stashes_archived + 1))
  done

  # Append archive dir to .gitignore if needed (only on --apply with mutations)
  if [[ "$APPLY" == "true" ]] && (( repo_archived > 0 )); then
    gitignore="$repo/.gitignore"
    pattern=".flywheel/stash-archive/"
    if [[ ! -f "$gitignore" ]] || ! grep -qxF "$pattern" "$gitignore" 2>/dev/null; then
      {
        [[ -f "$gitignore" ]] && tail -c1 "$gitignore" | od -An -c | grep -q '\\n' || echo ""
        echo "# stash-archiver: local-only forensic patches (added $NOW_ISO)"
        echo "$pattern"
      } >> "$gitignore" 2>/dev/null || true
    fi
  fi

  # Per-repo JSON row
  jq -nc \
    --arg repo "$repo_name" \
    --arg path "$repo" \
    --argjson found "$repo_found" \
    --argjson archived "$repo_archived" \
    --argjson skipped_fresh "$repo_skipped_fresh" \
    --argjson skipped_exempt "$repo_skipped_exempt" \
    --argjson failed "$repo_failed" \
    '{repo:$repo, path:$path, stashes_found:$found, stashes_archived:$archived, stashes_skipped_fresh:$skipped_fresh, stashes_skipped_exempt:$skipped_exempt, archive_failed:$failed}' \
    >> "$PER_REPO_TMP"

  if [[ "$halted" == "true" ]]; then
    break
  fi
done < <(find "$DEVELOPER_DIR" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort)

# Archive dir total size (sum across all repos) — best effort
archive_size_mb=0
while IFS= read -r d; do
  [[ -z "$d" ]] && continue
  kb=$(du -sk "$d" 2>/dev/null | awk '{print $1}' || echo 0)
  archive_size_mb=$(( archive_size_mb + (kb / 1024) ))
done < <(find "$DEVELOPER_DIR" -maxdepth 3 -type d -path '*/.flywheel/stash-archive' 2>/dev/null)

# Outcome status
status="ok"
exit_code=0
if [[ "$halted" == "true" ]]; then
  status="halted-halt-cap-reached"
  exit_code=2
elif (( archive_failed > 0 )); then
  status="partial-archive-failures"
  exit_code=3
fi

# Dashboard line
mode_tag="DRY"
[[ "$APPLY" == "true" ]] && mode_tag="APPLY"
dashboard_line=$(printf 'fleet_stash_hygiene[%s]: %d repos · %d stashes · arch=%d skip_fresh=%d skip_exempt=%d fail=%d size=%dMB status=%s' \
  "$mode_tag" "$repos_scanned" "$stashes_found" "$stashes_archived" \
  "$stashes_skipped_fresh" "$stashes_skipped_exempt" "$archive_failed" "$archive_size_mb" "$status")

if [[ "$JSON_OUT" == "true" ]]; then
  by_repo=$(jq -cs '.' "$PER_REPO_TMP" 2>/dev/null || echo '[]')
  jq -nc \
    --arg schema "stash_archiver.v1" \
    --arg ts "$NOW_ISO" \
    --arg status "$status" \
    --arg dashboard "$dashboard_line" \
    --argjson dry_run "$( [[ $DRY_RUN == true ]] && echo true || echo false )" \
    --argjson apply "$( [[ $APPLY == true ]] && echo true || echo false )" \
    --argjson max_age "$MAX_AGE_DAYS" \
    --argjson hard_cap "$HARD_CAP_DAYS" \
    --argjson halt_cap "$HALT_CAP" \
    --argjson repos "$repos_scanned" \
    --argjson found "$stashes_found" \
    --argjson archived "$stashes_archived" \
    --argjson skip_fresh "$stashes_skipped_fresh" \
    --argjson skip_exempt "$stashes_skipped_exempt" \
    --argjson failed "$archive_failed" \
    --argjson size_mb "$archive_size_mb" \
    --argjson by_repo "$by_repo" \
    '{schema_version:$schema, ts:$ts, status:$status, dry_run:$dry_run, apply:$apply,
      max_age_days:$max_age, hard_cap_days:$hard_cap, halt_cap:$halt_cap,
      repos_scanned:$repos, stashes_found:$found, stashes_archived:$archived,
      stashes_skipped_fresh:$skip_fresh, stashes_skipped_exempt:$skip_exempt,
      archive_failed:$failed, archive_dir_total_size_mb:$size_mb,
      by_repo:$by_repo, dashboard_line:$dashboard,
      doctor_field:"fleet_stash_hygiene",
      dashboard_field:"fleet_stash_hygiene_line"}'
else
  log ""
  log "=== SUMMARY ==="
  log "  repos_scanned=$repos_scanned stashes_found=$stashes_found"
  log "  archived=$stashes_archived skipped_fresh=$stashes_skipped_fresh skipped_exempt=$stashes_skipped_exempt failed=$archive_failed"
  log "  archive_dir_total_size=${archive_size_mb}MB status=$status"
  log "  $dashboard_line"
fi

exit $exit_code
