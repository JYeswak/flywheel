#!/usr/bin/env bash
# stale-branch-reaper.sh — Weekly reaper for stale local branches across ~/Developer/* repos.
#
# Joshua-direct 2026-05-20T20:00Z: scripted, not manual. Sister janitor to
# temp-janitor.sh, developer-cache-janitor.sh, worktree-reaper.sh, stash-archiver.sh.
#
# Bead: flywheel-466ca. Consumes BRANCH-MANIFEST schema (flywheel-m9yxr 19ff254e).
# Trauma class: branch-substrate-accretion. Audit 2026-05-20 measured 177 unpushed
# branches across JYeswak repos (zesttube 45, zs-v2 35, zs-infra 16, alps 14,
# flywheel 13, skillos 12). This script is the structural fix.
#
# Per branch, classify:
#   (a) Primary (main/master/trunk/develop) -> SKIP (never reap)
#   (b) Has BRANCH-MANIFEST entry            -> respect declared lifecycle/labels
#   (c) No manifest, has open PR             -> SKIP (pending-pr)
#   (d) No manifest, no PR, age >MIN_AGE     -> CANDIDATE (stale class)
#   (e) No manifest, age >MERGED_MIN, all
#       commits on origin/main               -> CANDIDATE (merged-elsewhere class)
#
# Reap modes:
#   - Local-only branch (no upstream)          -> archive + git branch -D
#   - Tracked branch with upstream [gone]      -> archive + git branch -D
#   - DO NOT delete remote branches (out of scope, more dangerous op)
#   - NEVER reap the current HEAD branch
#   - NEVER reap if uncommitted changes exist AND branch is current HEAD
#
# Archive: git log --oneline <main>..<branch> -> <repo>/.flywheel/branch-archive/<ts>-<name>.log
#
# Joshua-prompt safety: if total candidates >MAX_REAP_PER_RUN, halt + alert (no apply).
#
# Flags:
#   --dry-run                 default; preview only
#   --apply                   actually delete branches (after archive)
#   --json                    machine-readable summary
#   --min-age-days N          default 180; stale-class age threshold
#   --merged-min-age N        default 90; merged-elsewhere-class age threshold
#   --max-reap-per-run N      default 30; halt if exceeded
#   --developer-dir DIR       default ~/Developer
#
# Exit codes:
#   0 = ok
#   1 = config error
#   2 = halt (too many candidates; Joshua-prompt required)

set -euo pipefail

MIN_AGE_DAYS="${STALE_BRANCH_MIN_AGE_DAYS:-180}"
MERGED_MIN_AGE_DAYS="${STALE_BRANCH_MERGED_MIN_AGE:-90}"
MAX_REAP_PER_RUN="${STALE_BRANCH_MAX_REAP_PER_RUN:-30}"
DEVELOPER_DIR="${STALE_BRANCH_DEVELOPER_DIR:-$HOME/Developer}"
JSON_OUT=false
DRY_RUN=true
APPLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=true; shift ;;
    --dry-run) DRY_RUN=true; APPLY=false; shift ;;
    --apply) DRY_RUN=false; APPLY=true; shift ;;
    --min-age-days) MIN_AGE_DAYS="$2"; shift 2 ;;
    --merged-min-age) MERGED_MIN_AGE_DAYS="$2"; shift 2 ;;
    --max-reap-per-run) MAX_REAP_PER_RUN="$2"; shift 2 ;;
    --developer-dir) DEVELOPER_DIR="$2"; shift 2 ;;
    -h|--help) sed -n '2,46p' "$0"; exit 0 ;;
    *) echo "unknown flag: $1" >&2; exit 1 ;;
  esac
done

[[ -d "$DEVELOPER_DIR" ]] || { echo "DEVELOPER_DIR does not exist: $DEVELOPER_DIR" >&2; exit 1; }

NOW_TS=$(date -u +%s)
START_TS=$(date -u +%Y-%m-%dT%H:%M:%SZ)
ARCHIVE_TS=$(date -u +%Y%m%dT%H%M%SZ)

PRIMARY_BRANCHES_REGEX='^(main|master|trunk|develop|default)$'

# Reaper accumulators
total_repos=0
total_branches=0
total_skipped_primary=0
total_skipped_manifest=0
total_skipped_pr=0
total_skipped_fresh=0
total_skipped_has_remote=0
total_candidates=0
total_reaped=0
total_archived=0

# Per-repo candidate list (jsonl-ish accumulated to temp file)
TMP_CANDIDATES=$(mktemp -t stale-branch-reaper.XXXXXX)
trap 'rm -f "$TMP_CANDIDATES"' EXIT

log() { [[ "$JSON_OUT" == "true" ]] && return 0; printf '%s\n' "$1" >&2; }

log "=== stale-branch-reaper — $START_TS ==="
log "  DEVELOPER_DIR=$DEVELOPER_DIR dry_run=$DRY_RUN apply=$APPLY"
log "  min_age_days=$MIN_AGE_DAYS merged_min_age=$MERGED_MIN_AGE_DAYS max_reap=$MAX_REAP_PER_RUN"

have_gh=false
command -v gh >/dev/null 2>&1 && have_gh=true

# detect_primary_branch: choose origin/HEAD if available, else main/master/develop
detect_primary_branch() {
  local repo="$1"
  local primary
  primary=$(git -C "$repo" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')
  if [[ -n "${primary:-}" ]]; then
    echo "$primary"; return
  fi
  for cand in main master develop trunk; do
    if git -C "$repo" show-ref --verify --quiet "refs/heads/$cand"; then
      echo "$cand"; return
    fi
  done
  echo "main"
}

# manifest_entry_for: emit JSON object for a branch from BRANCH-MANIFEST, or empty.
manifest_entry_for() {
  local repo="$1" branch="$2"
  local manifest="$repo/.flywheel/BRANCH-MANIFEST.json"
  [[ -f "$manifest" ]] || { echo ""; return; }
  jq -c --arg b "$branch" '.branches[]? | select(.branch_name == $b)' "$manifest" 2>/dev/null || echo ""
}

# has_open_pr: best-effort gh check; fail-open (return 1 = no/unknown PR)
has_open_pr() {
  local repo="$1" branch="$2"
  $have_gh || return 1
  local out
  out=$(gh -R "" --json number --jq '.[0].number' pr list --head "$branch" --state open --limit 1 \
    -R "$(git -C "$repo" config --get remote.origin.url 2>/dev/null | sed -E 's#.*github.com[:/]([^/]+/[^/.]+)(\.git)?#\1#')" 2>/dev/null || true)
  [[ -n "${out:-}" ]]
}

# all_commits_on_main: returns 0 if branch has no commits not already in primary.
# Prefer origin/<primary>; fall back to local <primary> if no remote.
all_commits_on_main() {
  local repo="$1" branch="$2" primary="$3"
  local base=""
  if git -C "$repo" rev-parse --verify --quiet "refs/remotes/origin/$primary" >/dev/null 2>&1; then
    base="origin/$primary"
  elif git -C "$repo" rev-parse --verify --quiet "refs/heads/$primary" >/dev/null 2>&1; then
    base="$primary"
  else
    return 1
  fi
  local ahead
  ahead=$(git -C "$repo" rev-list --count "$base..$branch" 2>/dev/null || echo 0)
  [[ "$ahead" == "0" ]]
}

# archive_branch: write git log to .flywheel/branch-archive/<ts>-<name>.log
archive_branch() {
  local repo="$1" branch="$2" primary="$3"
  local arc_dir="$repo/.flywheel/branch-archive"
  mkdir -p "$arc_dir"
  local safe_name
  safe_name=$(printf '%s' "$branch" | tr '/' '_')
  local target="$arc_dir/${ARCHIVE_TS}-${safe_name}.log"
  {
    echo "# stale-branch-reaper archive"
    echo "# repo:    $repo"
    echo "# branch:  $branch"
    echo "# primary: $primary"
    echo "# reaped_at: $START_TS"
    echo "# sha: $(git -C "$repo" rev-parse "$branch" 2>/dev/null || echo unknown)"
    echo "# --- git log --oneline ${primary}..${branch} ---"
    git -C "$repo" log --oneline "${primary}..${branch}" 2>/dev/null || \
      git -C "$repo" log --oneline -50 "$branch" 2>/dev/null || \
      echo "(no log available)"
  } >"$target"
  total_archived=$((total_archived + 1))
}

# Ensure .flywheel/branch-archive/ ignored once (idempotent)
ensure_gitignore_archive() {
  local repo="$1"
  local gi="$repo/.gitignore"
  [[ -f "$gi" ]] || return 0
  if ! grep -qE '^\.flywheel/branch-archive/?$' "$gi" 2>/dev/null; then
    if [[ "$APPLY" == "true" ]]; then
      printf '\n# stale-branch-reaper archive (flywheel-466ca)\n.flywheel/branch-archive/\n' >>"$gi"
    fi
  fi
}

process_repo() {
  local repo="$1"
  total_repos=$((total_repos + 1))
  local primary
  primary=$(detect_primary_branch "$repo")
  local current_head
  current_head=$(git -C "$repo" symbolic-ref --quiet --short HEAD 2>/dev/null || echo "")
  local dirty=false
  if ! git -C "$repo" diff --quiet 2>/dev/null || ! git -C "$repo" diff --cached --quiet 2>/dev/null; then
    dirty=true
  fi

  # Gather branch info: name, upstream, committerdate, upstream:track
  # Use '|' delimiter; tab is whitespace-IFS and collapses empty fields under read.
  while IFS='|' read -r name upstream cdate track; do
    [[ -z "$name" ]] && continue
    total_branches=$((total_branches + 1))

    if [[ "$name" =~ $PRIMARY_BRANCHES_REGEX ]]; then
      total_skipped_primary=$((total_skipped_primary + 1))
      continue
    fi

    # Never reap current HEAD if dirty
    if [[ "$name" == "$current_head" && "$dirty" == "true" ]]; then
      total_skipped_fresh=$((total_skipped_fresh + 1))
      continue
    fi

    local age_days=$(( (NOW_TS - cdate) / 86400 ))

    # Manifest entry?
    local mentry
    mentry=$(manifest_entry_for "$repo" "$name")
    if [[ -n "$mentry" ]]; then
      # Respect manifest: keep unless lifecycle=abandon AND lifecycle_state=abandoned
      local lifecycle lifecycle_state
      lifecycle=$(jq -r '.lifecycle // ""' <<<"$mentry")
      lifecycle_state=$(jq -r '.lifecycle_state // ""' <<<"$mentry")
      local labels
      labels=$(jq -r '.labels // [] | join(",")' <<<"$mentry")
      if [[ ",$labels," == *",keep-alive,"* || ",$labels," == *",pending-pr,"* || \
            ",$labels," == *",joshua-gated,"* || ",$labels," == *",cross-orch-active,"* || \
            ",$labels," == *",defer-gated,"* || ",$labels," == *",archived-snapshot,"* ]]; then
        total_skipped_manifest=$((total_skipped_manifest + 1))
        continue
      fi
      if [[ "$lifecycle" == "long_running" || "$lifecycle" == "extract_to_repo" ]]; then
        total_skipped_manifest=$((total_skipped_manifest + 1))
        continue
      fi
      # lifecycle=abandon or merge_to_main with stale state -> falls through to candidate logic
    fi

    # Open PR check (only if no manifest, or manifest didn't carve out)
    if has_open_pr "$repo" "$name"; then
      total_skipped_pr=$((total_skipped_pr + 1))
      continue
    fi

    # Determine candidate class
    local class=""
    if (( age_days > MIN_AGE_DAYS )); then
      class="stale-${age_days}d"
    elif (( age_days > MERGED_MIN_AGE_DAYS )) && all_commits_on_main "$repo" "$name" "$primary"; then
      class="merged-elsewhere-${age_days}d"
    else
      total_skipped_fresh=$((total_skipped_fresh + 1))
      continue
    fi

    # Reap-eligibility shape: local-only OR upstream [gone].
    # track is e.g. "[gone]" or "[ahead 2]" or "" depending on upstream presence
    local reap_shape=""
    if [[ -z "$upstream" ]]; then
      reap_shape="local-only"
    elif [[ "$track" == *"gone"* ]]; then
      reap_shape="upstream-gone"
    else
      # Has live upstream; out of scope (remote branch deletion is separate op)
      total_skipped_has_remote=$((total_skipped_has_remote + 1))
      continue
    fi

    # Never reap current HEAD
    if [[ "$name" == "$current_head" ]]; then
      total_skipped_fresh=$((total_skipped_fresh + 1))
      continue
    fi

    total_candidates=$((total_candidates + 1))
    printf '%s\t%s\t%s\t%s\t%d\n' "$repo" "$name" "$class" "$reap_shape" "$age_days" >>"$TMP_CANDIDATES"
  done < <(git -C "$repo" for-each-ref \
    --format='%(refname:short)|%(upstream:short)|%(committerdate:unix)|%(upstream:track)' \
    refs/heads 2>/dev/null)
}

log ""
log "--- Scanning repos under $DEVELOPER_DIR ---"
while IFS= read -r repo; do
  [[ -z "$repo" ]] && continue
  [[ -d "$repo/.git" ]] || continue
  log "  scan: $repo"
  process_repo "$repo"
done < <(find "$DEVELOPER_DIR" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort)

log ""
log "--- Candidate summary ---"
log "  repos_scanned=$total_repos branches_examined=$total_branches"
log "  skipped_primary=$total_skipped_primary skipped_manifest=$total_skipped_manifest"
log "  skipped_pr=$total_skipped_pr skipped_fresh=$total_skipped_fresh skipped_has_remote=$total_skipped_has_remote"
log "  candidates=$total_candidates max_per_run=$MAX_REAP_PER_RUN"

# Joshua-prompt halt
halt_reason=""
if (( total_candidates > MAX_REAP_PER_RUN )); then
  halt_reason="too_many_candidates"
  log ""
  log "HALT: candidates=$total_candidates exceeds max_reap_per_run=$MAX_REAP_PER_RUN."
  log "      Re-run with --max-reap-per-run $total_candidates after Joshua-prompt review."
fi

# Emit candidate list (always)
if [[ "$JSON_OUT" != "true" ]]; then
  log ""
  log "--- Candidates ---"
  if [[ -s "$TMP_CANDIDATES" ]]; then
    awk -F'\t' '{printf "  %s  [%s/%s] %s (age=%sd)\n", $1, $3, $4, $2, $5}' "$TMP_CANDIDATES" >&2
  else
    log "  (none)"
  fi
fi

# Apply phase
if [[ "$APPLY" == "true" && -z "$halt_reason" && -s "$TMP_CANDIDATES" ]]; then
  log ""
  log "--- APPLY: archiving + reaping ---"
  while IFS=$'\t' read -r repo name class shape age; do
    primary=$(detect_primary_branch "$repo")
    ensure_gitignore_archive "$repo"
    archive_branch "$repo" "$name" "$primary"
    if git -C "$repo" branch -D "$name" >/dev/null 2>&1; then
      log "  reaped: $repo $name [$class/$shape]"
      total_reaped=$((total_reaped + 1))
    else
      log "  FAILED reap: $repo $name [$class/$shape]"
    fi
  done <"$TMP_CANDIDATES"
fi

status="ok"
exit_code=0
if [[ -n "$halt_reason" ]]; then
  status="halt-${halt_reason}"
  exit_code=2
fi

# Persist a status snapshot so dashboards / doctors can read fleet_branch_hygiene
# without re-running the reaper.
STATUS_DIR="${STALE_BRANCH_STATUS_DIR:-$HOME/.local/state/flywheel/stale-branch-reaper}"
mkdir -p "$STATUS_DIR" 2>/dev/null || true

if [[ "$JSON_OUT" == "true" ]]; then
  # Build candidates array via jq
  cand_json="[]"
  if [[ -s "$TMP_CANDIDATES" ]]; then
    cand_json=$(awk -F'\t' '{printf "{\"repo\":\"%s\",\"branch\":\"%s\",\"class\":\"%s\",\"shape\":\"%s\",\"age_days\":%s}\n",$1,$2,$3,$4,$5}' "$TMP_CANDIDATES" | jq -s -c '.')
  fi
  jq -nc \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg status "$status" \
    --arg dev "$DEVELOPER_DIR" \
    --argjson dry "$DRY_RUN" \
    --argjson apply "$APPLY" \
    --argjson repos "$total_repos" \
    --argjson branches "$total_branches" \
    --argjson sp "$total_skipped_primary" \
    --argjson sm "$total_skipped_manifest" \
    --argjson spr "$total_skipped_pr" \
    --argjson sf "$total_skipped_fresh" \
    --argjson sr "$total_skipped_has_remote" \
    --argjson cand "$total_candidates" \
    --argjson reaped "$total_reaped" \
    --argjson archived "$total_archived" \
    --argjson max "$MAX_REAP_PER_RUN" \
    --argjson min_age "$MIN_AGE_DAYS" \
    --argjson merged_min "$MERGED_MIN_AGE_DAYS" \
    --argjson candidates "$cand_json" \
    '{schema_version:"stale_branch_reaper.v1",ts:$ts,status:$status,developer_dir:$dev,dry_run:$dry,apply:$apply,min_age_days:$min_age,merged_min_age_days:$merged_min,max_reap_per_run:$max,repos_scanned:$repos,branches_examined:$branches,skipped:{primary:$sp,manifest:$sm,open_pr:$spr,fresh:$sf,has_remote:$sr},candidates_total:$cand,archived:$archived,reaped:$reaped,fleet_branch_hygiene:{candidates:$cand,reaped:$reaped,archived:$archived,status:$status},candidates:$candidates}' \
    | tee "$STATUS_DIR/latest.json"
  # Dashboard line (human-friendly, one-shot append for tailers)
  printf '[%s] fleet_branch_hygiene candidates=%d archived=%d reaped=%d status=%s\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$total_candidates" "$total_archived" "$total_reaped" "$status" \
    >>"$STATUS_DIR/dashboard.log"
else
  log ""
  log "=== SUMMARY ==="
  log "  candidates=$total_candidates  archived=$total_archived  reaped=$total_reaped  status=$status"
fi

exit $exit_code
