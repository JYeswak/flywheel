#!/usr/bin/env bash
# worktree-reaper.sh — Daily reaper for orphan/stale git worktrees across ~/Developer/*.
#
# Joshua-direct 2026-05-20T20:00Z: "this needs to be a scripted process - you cannot expect me
# to come in every single day and run this type of stuff to clean up projects trash"
#
# Bead: flywheel-awn6w (P1). Schema: .flywheel/schemas/WORKTREE-MANIFEST.schema.json (m9yxr).
# Sister janitors: temp-janitor.sh (/private/tmp), developer-cache-janitor.sh (build artifacts).
# Trauma class: storage-pressure-blocks-substrate.
#
# Per-repo flow:
#   1. git worktree list --porcelain → enumerate non-primary worktrees
#   2. If repo has .flywheel/WORKTREE-MANIFEST.json → respect declared lifecycle + expires_at
#   3. Else heuristic: reap if HEAD commit older than --min-age-days AND no uncommitted changes
#   4. git worktree prune (handles externally-removed dirs)
#
# Safety:
#   - NEVER reap primary worktree (porcelain shows it first with no detached/branch context)
#   - NEVER reap a worktree with uncommitted changes (git status --porcelain non-empty)
#   - Halt + alert if planned reap count > MAX_REAP_PER_RUN (default 20)
#
# Exit codes:
#   0 = ok (any reap count, including zero)
#   1 = config error
#   2 = sanity gate tripped (>MAX_REAP_PER_RUN candidates — Joshua review required)

set -euo pipefail

DEVELOPER_DIR="${WT_REAPER_DEVELOPER_DIR:-$HOME/Developer}"
MIN_AGE_DAYS="${WT_REAPER_MIN_AGE_DAYS:-14}"
MAX_REAP_PER_RUN="${WT_REAPER_MAX_PER_RUN:-20}"
MODE="dry-run"
JSON_OUT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) MODE="dry-run"; shift ;;
    --apply) MODE="apply"; shift ;;
    --json) JSON_OUT=true; shift ;;
    --min-age-days) MIN_AGE_DAYS="$2"; shift 2 ;;
    --max-per-run) MAX_REAP_PER_RUN="$2"; shift 2 ;;
    --developer-dir) DEVELOPER_DIR="$2"; shift 2 ;;
    -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
    *) echo "unknown flag: $1" >&2; exit 1 ;;
  esac
done

[[ -d "$DEVELOPER_DIR" ]] || { echo "DEVELOPER_DIR does not exist: $DEVELOPER_DIR" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq not on PATH" >&2; exit 1; }

NOW_TS=$(date -u +%s)
START_TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)

log() { [[ "$JSON_OUT" == "true" ]] && return 0; printf '%s\n' "$1" >&2; }

log "=== worktree-reaper — $START_TS ==="
log "  DEVELOPER_DIR=$DEVELOPER_DIR mode=$MODE min_age_days=$MIN_AGE_DAYS max_per_run=$MAX_REAP_PER_RUN"

repos_scanned=0
worktrees_found=0
worktrees_reaped=0
declare -a skipped_entries=()   # JSON-shaped strings
declare -a by_repo_entries=()
declare -a planned_reaps=()     # "repo|path" pairs; gated by sanity check

# Read WORKTREE-MANIFEST entry, if any, for a given path.
# Returns lifecycle_state|expires_at|created_for_bead OR empty.
manifest_lookup() {
  local repo="$1" path="$2"
  local manifest="$repo/.flywheel/WORKTREE-MANIFEST.json"
  [[ -f "$manifest" ]] || return 0
  jq -r --arg p "$path" '
    .active_worktrees[]? | select(.path == $p)
    | "\(.lifecycle_state)|\(.expires_at // "")|\(.created_for_bead // "")|\((.labels // []) | join(","))"
  ' "$manifest" 2>/dev/null || true
}

# Enumerate primary + non-primary worktrees via porcelain.
# Emits: path<TAB>branch<TAB>is_primary("1"|"0")
enumerate_worktrees() {
  local repo="$1"
  git -C "$repo" worktree list --porcelain 2>/dev/null | awk '
    /^worktree / { if (path != "") { print path "\t" branch "\t" (idx == 0 ? "1" : "0"); idx++ }
                    path=$2; branch=""; bare=0 }
    /^branch /   { branch=$2 }
    /^detached/  { branch="DETACHED" }
    /^bare/      { bare=1 }
    END { if (path != "") print path "\t" branch "\t" (idx == 0 ? "1" : "0") }
  '
}

# Per-repo loop
for repo in "$DEVELOPER_DIR"/*/; do
  repo="${repo%/}"
  [[ -d "$repo/.git" ]] || continue
  repos_scanned=$((repos_scanned + 1))

  repo_found=0
  repo_reaped=0
  repo_skipped=0

  # First: prune any worktrees whose dirs are gone
  if [[ "$MODE" == "apply" ]]; then
    git -C "$repo" worktree prune 2>/dev/null || true
  fi

  while IFS=$'\t' read -r wt_path wt_branch wt_is_primary; do
    [[ -z "$wt_path" ]] && continue
    repo_found=$((repo_found + 1))
    worktrees_found=$((worktrees_found + 1))

    # Skip primary
    if [[ "$wt_is_primary" == "1" ]]; then
      continue
    fi

    # Skip if path doesn't exist (will get pruned)
    if [[ ! -d "$wt_path" ]]; then
      skipped_entries+=("$(jq -nc --arg r "$repo" --arg p "$wt_path" --arg reason "path-missing-will-prune" '{repo:$r,path:$p,reason:$reason}')")
      repo_skipped=$((repo_skipped + 1))
      continue
    fi

    # Safety: uncommitted changes → never reap
    dirty=$(git -C "$wt_path" status --porcelain 2>/dev/null | head -1 || true)
    if [[ -n "$dirty" ]]; then
      skipped_entries+=("$(jq -nc --arg r "$repo" --arg p "$wt_path" --arg reason "uncommitted-changes" '{repo:$r,path:$p,reason:$reason}')")
      repo_skipped=$((repo_skipped + 1))
      continue
    fi

    # Last commit age
    last_commit=$(git -C "$wt_path" log -1 --format=%ct 2>/dev/null || echo 0)
    [[ -z "$last_commit" || "$last_commit" == "0" ]] && last_commit=$NOW_TS
    age_days=$(( (NOW_TS - last_commit) / 86400 ))

    # Manifest consultation
    manifest_row="$(manifest_lookup "$repo" "$wt_path")"
    if [[ -n "$manifest_row" ]]; then
      IFS='|' read -r m_state m_expires m_bead m_labels <<<"$manifest_row"
      # Honor keep-alive / joshua-gated / pending-pr labels
      if [[ ",$m_labels," == *",keep-alive,"* || ",$m_labels," == *",joshua-gated,"* || ",$m_labels," == *",pending-pr,"* ]]; then
        skipped_entries+=("$(jq -nc --arg r "$repo" --arg p "$wt_path" --arg reason "manifest-label-protected" --arg labels "$m_labels" '{repo:$r,path:$p,reason:$reason,labels:$labels}')")
        repo_skipped=$((repo_skipped + 1))
        continue
      fi
      # If lifecycle_state terminal (merged/abandoned/extracted/closed) → reap candidate
      if [[ "$m_state" == "merged" || "$m_state" == "abandoned" || "$m_state" == "extracted" || "$m_state" == "closed" ]]; then
        planned_reaps+=("$repo|$wt_path|manifest-lifecycle-$m_state|$age_days")
        continue
      fi
      # If expires_at < now → reap
      if [[ -n "$m_expires" ]]; then
        expires_ts=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$m_expires" "+%s" 2>/dev/null || echo 0)
        if [[ "$expires_ts" -gt 0 && "$expires_ts" -lt "$NOW_TS" ]]; then
          planned_reaps+=("$repo|$wt_path|manifest-expired|$age_days")
          continue
        fi
      fi
      # Active + not expired → keep
      skipped_entries+=("$(jq -nc --arg r "$repo" --arg p "$wt_path" --arg reason "manifest-active" --arg state "$m_state" '{repo:$r,path:$p,reason:$reason,lifecycle_state:$state}')")
      repo_skipped=$((repo_skipped + 1))
      continue
    fi

    # Heuristic: no manifest entry
    if (( age_days >= MIN_AGE_DAYS )); then
      planned_reaps+=("$repo|$wt_path|heuristic-stale-${age_days}d|$age_days")
    else
      skipped_entries+=("$(jq -nc --arg r "$repo" --arg p "$wt_path" --arg reason "heuristic-young" --arg age "$age_days" '{repo:$r,path:$p,reason:$reason,age_days:($age|tonumber)}')")
      repo_skipped=$((repo_skipped + 1))
    fi
  done < <(enumerate_worktrees "$repo")

  by_repo_entries+=("$(jq -nc --arg r "$repo" --argjson f "$repo_found" --argjson s "$repo_skipped" '{repo:$r,worktrees_found:$f,skipped:$s}')")
done

# Sanity gate
planned_count=${#planned_reaps[@]}
status="ok"
exit_code=0
sanity_tripped=false

if (( planned_count > MAX_REAP_PER_RUN )); then
  status="sanity-gate-tripped"
  sanity_tripped=true
  exit_code=2
  log ""
  log "*** SANITY GATE TRIPPED: $planned_count planned reaps > max_per_run=$MAX_REAP_PER_RUN ***"
  log "*** Refusing to apply. Re-run with --max-per-run $planned_count after Joshua review. ***"
fi

# Execute reaps (or log dry-run)
log ""
log "--- Reaping (mode=$MODE, planned=$planned_count) ---"
if [[ "$sanity_tripped" == "false" ]]; then
  for entry in "${planned_reaps[@]+"${planned_reaps[@]}"}"; do
    IFS='|' read -r r_repo r_path r_reason r_age <<<"$entry"
    if [[ "$MODE" == "apply" ]]; then
      if git -C "$r_repo" worktree remove --force "$r_path" 2>/dev/null; then
        log "  reaped: $r_path (reason=$r_reason age=${r_age}d)"
        worktrees_reaped=$((worktrees_reaped + 1))
      else
        log "  FAILED to reap: $r_path (reason=$r_reason)"
        skipped_entries+=("$(jq -nc --arg r "$r_repo" --arg p "$r_path" --arg reason "git-worktree-remove-failed" '{repo:$r,path:$p,reason:$reason}')")
      fi
    else
      log "  WOULD reap: $r_path (reason=$r_reason age=${r_age}d)"
      worktrees_reaped=$((worktrees_reaped + 1))   # dry-run counts as "would-reap"
    fi
  done
else
  # Sanity tripped — emit planned list as skipped (gated)
  for entry in "${planned_reaps[@]+"${planned_reaps[@]}"}"; do
    IFS='|' read -r r_repo r_path r_reason r_age <<<"$entry"
    skipped_entries+=("$(jq -nc --arg r "$r_repo" --arg p "$r_path" --arg reason "sanity-gate-deferred-$r_reason" '{repo:$r,path:$p,reason:$reason}')")
  done
  worktrees_reaped=0
fi

dashboard_line="worktree-reaper: ${repos_scanned} repos | ${worktrees_found} worktrees | ${worktrees_reaped} reaped (${MODE}) | ${planned_count} planned | gate=${status}"

if [[ "$JSON_OUT" == "true" ]]; then
  skipped_json="[$(IFS=,; echo "${skipped_entries[*]+"${skipped_entries[*]}"}")]"
  by_repo_json="[$(IFS=,; echo "${by_repo_entries[*]+"${by_repo_entries[*]}"}")]"
  jq -nc \
    --arg schema "worktree_reaper.v1" \
    --arg ts "$START_TS" \
    --arg status "$status" \
    --arg mode "$MODE" \
    --argjson rs "$repos_scanned" \
    --argjson wf "$worktrees_found" \
    --argjson wr "$worktrees_reaped" \
    --argjson pc "$planned_count" \
    --argjson mad "$MIN_AGE_DAYS" \
    --argjson mpr "$MAX_REAP_PER_RUN" \
    --argjson skipped "$skipped_json" \
    --argjson by_repo "$by_repo_json" \
    --arg dash "$dashboard_line" \
    '{schema:$schema, ts:$ts, status:$status, mode:$mode, repos_scanned:$rs, worktrees_found:$wf, worktrees_reaped:$wr, planned_reap_count:$pc, min_age_days:$mad, max_per_run:$mpr, worktrees_skipped:$skipped, by_repo:$by_repo, dashboard_line:$dash}'
else
  log ""
  log "=== SUMMARY ==="
  log "  $dashboard_line"
fi

exit $exit_code
