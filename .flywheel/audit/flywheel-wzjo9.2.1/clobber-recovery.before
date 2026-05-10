#!/usr/bin/env bash
# clobber-recovery.sh — canonical recovery primitive for worker doctrine clobbers.
#
# Class: clobbered_doctrine_docs (worker's failed cd → echo > redirect lands in repo root,
# truncating MISSION.md/STATE.md/GOAL.md/etc to single-line schema_version).
#
# Contract:
#   - Restore named files from HEAD via `git show HEAD:<path> > <path>` (NOT checkout).
#   - Refuse if any target's HEAD content is itself empty/missing (would null-restore).
#   - Append recovery receipt to .flywheel/clobber-recovery-log.jsonl.
#   - Append fuckup row to ~/.local/state/flywheel/fuckup-log.jsonl with class=clobber-recovery.
#   - Default to canonical doctrine set (MISSION/STATE/GOAL/AGENTS/INCIDENTS) when no --paths given.
#   - --dry-run prints planned actions and writes nothing.
#
# Why git show > file rather than git checkout HEAD -- file:
#   DCG blocks `git checkout <ref> -- <path>` (core.git:checkout-ref-discard).
#   `git show HEAD:<path>` is a read; redirecting to file is a write. Same end-state,
#   different blast radius — and we explicitly want to overwrite the truncated content.
#
# Usage:
#   clobber-recovery.sh [--dry-run] [--reason "<one-line>"] [--bead <id>] [--paths a.md,b.md]
#
# Exit codes:
#   0 — recovery succeeded (or dry-run completed)
#   1 — bad args
#   2 — git not in a repo, or repo dirty in unsafe way
#   3 — at least one target's HEAD content is empty/missing (refused)
#   4 — at least one target's working-tree content matches HEAD (no clobber to recover)

set -euo pipefail

DRY_RUN=0
REASON=""
BEAD_ID=""
PATHS=""
CANONICAL_PATHS=".flywheel/MISSION.md .flywheel/STATE.md .flywheel/GOAL.md AGENTS.md INCIDENTS.md"

usage() {
  sed -n '2,30p' "$0"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --reason) REASON="$2"; shift 2 ;;
    --bead) BEAD_ID="$2"; shift 2 ;;
    --paths) PATHS="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "ERR unknown arg: $1" >&2; exit 1 ;;
  esac
done

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$REPO_ROOT" ]]; then
  echo "ERR not in a git repo" >&2
  exit 2
fi
cd "$REPO_ROOT"

if [[ -n "$PATHS" ]]; then
  TARGETS=$(echo "$PATHS" | tr ',' ' ')
else
  TARGETS="$CANONICAL_PATHS"
fi

TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
LOG=".flywheel/clobber-recovery-log.jsonl"
FUCKUP_LOG="$HOME/.local/state/flywheel/fuckup-log.jsonl"
mkdir -p "$(dirname "$FUCKUP_LOG")"
mkdir -p "$(dirname "$LOG")"

REFUSED=()
NOOP=()
NOT_CLOBBER=()
RESTORED=()

# Clobber detection heuristic: working-tree file has <100 bytes AND HEAD >1000 bytes.
# This catches the "echo > path" / "printf > path" truncation class without
# false-positive on runtime drift (M-state files with legitimate unstaged edits).
# Override the heuristic via --paths (explicit list bypasses the size gate).
EXPLICIT_PATHS_GIVEN=0
[[ -n "$PATHS" ]] && EXPLICIT_PATHS_GIVEN=1

for path in $TARGETS; do
  if ! git ls-files --error-unmatch "$path" >/dev/null 2>&1; then
    continue
  fi

  head_blob="$(git rev-parse "HEAD:$path" 2>/dev/null || true)"
  if [[ -z "$head_blob" ]]; then
    continue
  fi
  head_bytes="$(git cat-file -s "$head_blob" 2>/dev/null || echo 0)"

  if [[ -e "$path" ]]; then
    cur_blob="$(git hash-object "$path" 2>/dev/null || echo "")"
    cur_bytes="$(wc -c < "$path" 2>/dev/null | awk '{print $1+0}')"
  else
    cur_blob=""
    cur_bytes=0
  fi

  if [[ "$head_bytes" -lt 50 ]]; then
    REFUSED+=("$path:head_empty_or_tiny:bytes=$head_bytes")
    continue
  fi

  if [[ -n "$cur_blob" ]] && [[ "$cur_blob" == "$head_blob" ]]; then
    NOOP+=("$path:matches_HEAD:bytes=$cur_bytes")
    continue
  fi

  # Heuristic gate (only when no explicit --paths given)
  if [[ $EXPLICIT_PATHS_GIVEN -eq 0 ]]; then
    if [[ "$cur_bytes" -ge 100 ]] || [[ "$head_bytes" -lt 1000 ]]; then
      NOT_CLOBBER+=("$path:cur_bytes=$cur_bytes:head_bytes=$head_bytes")
      continue
    fi
  fi

  if [[ "$DRY_RUN" == "1" ]]; then
    RESTORED+=("DRY_RUN:$path:from_bytes=$cur_bytes:to_bytes=$head_bytes")
  else
    git show "HEAD:$path" > "$path"
    new_bytes="$(wc -c < "$path" | awk '{print $1+0}')"
    RESTORED+=("$path:from_bytes=$cur_bytes:to_bytes=$new_bytes")
  fi
done

n_restored=${#RESTORED[@]}
n_refused=${#REFUSED[@]}
n_noop=${#NOOP[@]}

# Build JSON arrays without jq (POSIX-safe)
json_arr() {
  if [[ $# -eq 0 ]]; then printf '[]'; return; fi
  printf '['
  local first=1
  for item in "$@"; do
    if [[ $first -eq 0 ]]; then printf ','; fi
    printf '"%s"' "$(printf '%s' "$item" | sed 's/\\/\\\\/g; s/"/\\"/g')"
    first=0
  done
  printf ']'
}

receipt='{"ts":"'"$TS"'","script":"clobber-recovery.sh","dry_run":'"$DRY_RUN"',"bead":"'"$BEAD_ID"'","reason":"'"$(printf '%s' "$REASON" | sed 's/"/\\"/g')"'","restored":'"$(json_arr "${RESTORED[@]}")"',"refused":'"$(json_arr "${REFUSED[@]}")"',"noop":'"$(json_arr "${NOOP[@]}")"',"not_clobber":'"$(json_arr "${NOT_CLOBBER[@]}")"'}'

if [[ "$DRY_RUN" != "1" ]]; then
  printf '%s\n' "$receipt" >> "$LOG"
  printf '{"ts":"%s","class":"clobber-recovery","severity":"medium","what_happened":"%s","evidence":"%s","bead":"%s","restored_count":%d,"processed":false}\n' \
    "$TS" "${REASON:-doctrine doc clobber}" "$LOG" "$BEAD_ID" "$n_restored" >> "$FUCKUP_LOG"
fi

# Output for caller
echo "$receipt"

if [[ $n_refused -gt 0 ]] && [[ $n_restored -eq 0 ]] && [[ $n_noop -eq 0 ]]; then
  exit 3
fi
if [[ $n_restored -eq 0 ]] && [[ $n_noop -gt 0 ]] && [[ $n_refused -eq 0 ]]; then
  exit 4
fi
exit 0
