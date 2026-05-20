#!/usr/bin/env bash
# Revert branch protection on the 4 repos where flywheel-4xazn applied wrong check names 2026-05-20T02:46Z.
# Idempotent — safe to re-run.
set -u

REPOS=(
  "JYeswak/flywheel:master"
  "JYeswak/zesttube:main"
  "JYeswak/mobile-eats:main"
  "JYeswak/ClutterFreeSpaces:main"
)

echo "=== revert branch protection (idempotent) ==="
for entry in "${REPOS[@]}"; do
  repo="${entry%:*}"
  branch="${entry#*:}"
  printf "  %-40s :%s ... " "$repo" "$branch"
  out=$(gh api -X DELETE "repos/${repo}/branches/${branch}/protection" 2>&1)
  rc=$?
  if [[ $rc -eq 0 ]]; then
    echo "✓ removed"
  elif echo "$out" | grep -q "Branch not protected"; then
    echo "○ already unprotected"
  else
    echo "✗ rc=$rc — $(echo "$out" | head -1)"
  fi
done

echo
echo "=== verify all 4 unprotected ==="
for entry in "${REPOS[@]}"; do
  repo="${entry%:*}"
  branch="${entry#*:}"
  state=$(gh api "repos/${repo}/branches/${branch}/protection" 2>&1 | head -1)
  if echo "$state" | grep -q "Branch not protected"; then
    printf "  %-40s :%s ✓ unprotected\n" "$repo" "$branch"
  else
    printf "  %-40s :%s ⚠ %s\n" "$repo" "$branch" "$(echo "$state" | head -c 60)"
  fi
done
