#!/usr/bin/env bash
# repo-hygiene-prune.sh — safe, guarded prune of regenerable gitignored surfaces.
#
# The enforcement arm of H-3 (retention) in
# .flywheel/doctrine/repo-hygiene-operational-protocol.md. Reusable: this is
# the retention-prune tool, not a one-off cleanup.
#
# THE CORE SAFETY RULE: this script never deletes a git-tracked file. Every
# path is filtered against `git ls-files` before removal — a tracked file is
# always kept, even inside an allowlisted target. That guard, not the absence
# of `rm`, is what makes this safe.
#
# Additional guards (a target is skipped if ANY fails):
#   1. the target is on PRUNE_TARGETS / node_modules — no arbitrary paths
#   2. the target is gitignored (or, for node_modules, ignored by rule)
#   3. dry-run is the DEFAULT — nothing is removed without --yes
#
# Refuses by omission: .beads (live substrate), anything not on the allowlist.
#
# Usage:
#   repo-hygiene-prune.sh [--repo PATH]            # dry-run (default)
#   repo-hygiene-prune.sh [--repo PATH] --yes      # actually prune
#
# Exit: 0 ok · 2 usage error

set -euo pipefail

REPO="${REPO_HYGIENE_REPO:-$PWD}"
DRY=1
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="$2"; shift 2 ;;
    --yes)  DRY=0; shift ;;
    --help) grep '^#' "$0" | sed 's/^# \?//'; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done
cd "$REPO"

# Allowlist of regenerable, gitignored surfaces safe to prune. Adding a path
# here is a deliberate act — it must be regenerable from a source of truth.
PRUNE_TARGETS=(
  ".flywheel/extraction"   # skill output — regenerates from the extractors
  ".git-archive"           # sediment archive — gitignored; tracked .gitkeep kept
)

freed_total=0

# remove_untracked_within DIR — deletes every untracked path inside DIR,
# keeping any git-tracked file. If DIR has zero tracked files, DIR goes too.
remove_untracked_within() {
  local dir="$1"
  local tracked
  tracked="$(git ls-files "$dir" | wc -l | tr -d ' ')"
  local size_kb
  size_kb="$( { du -sk "$dir" 2>/dev/null || echo 0; } | awk '{print $1}')"
  local size_h
  size_h="$( { du -sh "$dir" 2>/dev/null || echo '?'; } | awk '{print $1}')"

  if [[ "$tracked" -eq 0 ]]; then
    if [[ "$DRY" -eq 1 ]]; then
      echo "  would remove: $dir  ($size_h, 0 tracked)"
    else
      rm -rf "$dir"
      freed_total=$((freed_total + size_kb))
      echo "  removed: $dir  ($size_h freed)"
    fi
  else
    if [[ "$DRY" -eq 1 ]]; then
      echo "  would prune untracked contents of: $dir  ($size_h, $tracked tracked file(s) kept)"
    else
      # -depth so contents are handled before their parent dir
      while IFS= read -r item; do
        git ls-files --error-unmatch "$item" >/dev/null 2>&1 && continue  # tracked → keep
        rm -rf "$item" 2>/dev/null || true
      done < <(find "$dir" -mindepth 1 -depth)
      freed_total=$((freed_total + size_kb))
      echo "  pruned untracked contents of: $dir  ($tracked tracked file(s) kept)"
    fi
  fi
}

echo "Repo Hygiene Prune — $REPO  ($([ "$DRY" -eq 1 ] && echo 'DRY-RUN — pass --yes to execute' || echo 'EXECUTING'))"
echo ""

echo "node_modules (regenerable from lockfiles):"
found_nm=0
while IFS= read -r nm; do
  [[ -z "$nm" ]] && continue
  found_nm=1
  # GUARD: must be ignored by a gitignore rule
  if ! git check-ignore -q "$nm/.probe" 2>/dev/null; then
    echo "  REFUSE (not gitignored): $nm"; continue
  fi
  remove_untracked_within "$nm"
done < <(find . -type d -name node_modules -not -path './.git/*' -prune 2>/dev/null)
[[ "$found_nm" -eq 0 ]] && echo "  (none present)"
echo ""

for target in "${PRUNE_TARGETS[@]}"; do
  echo "$target:"
  if [[ ! -e "$target" ]]; then
    echo "  (absent — nothing to do)"; echo ""; continue
  fi
  # GUARD: must be gitignored
  if ! git check-ignore -q "$target/.probe" 2>/dev/null \
       && ! git check-ignore -q "$target" 2>/dev/null; then
    echo "  REFUSE (not gitignored — not safe to prune): $target"; echo ""; continue
  fi
  remove_untracked_within "$target"
  echo ""
done

if [[ "$DRY" -eq 0 ]]; then
  echo "Freed: ~$((freed_total / 1024)) MB"
else
  echo "Dry-run only. Re-run with --yes to prune."
fi
