#!/usr/bin/env bash
# .flywheel/hooks/canonical-cli-lint-pre-commit.sh
#
# Pre-commit guard that runs canonical-cli-lint.sh against every staged
# .sh file under .flywheel/scripts/ or marked with the canonical magic
# comment `# flywheel-cli-surface: true`. Refuses commit if violations
# are found. Honors `git commit --no-verify` (Joshua's prerogative —
# git itself bypasses the hook).
#
# Wire-up: copy or symlink to .git/hooks/pre-commit, e.g.:
#   ln -s ../../.flywheel/hooks/canonical-cli-lint-pre-commit.sh \
#         .git/hooks/pre-commit
# Or call from an existing pre-commit aggregator.
#
# Bead: flywheel-etp5n. Spec: .flywheel/audit/flywheel-jloib.0c/apply-spec.md.
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
LINTER="$REPO_ROOT/.flywheel/scripts/canonical-cli-lint.sh"

[[ -x "$LINTER" ]] || {
  echo "WARN: canonical-cli-lint.sh missing or not executable; skipping pre-commit lint" >&2
  exit 0
}

# Collect staged .sh files (added or modified)
mapfile -t staged < <(git diff --cached --name-only --diff-filter=AM | grep -E '\.sh$' || true)
[[ "${#staged[@]}" -eq 0 ]] && exit 0

# Filter to surfaces the linter should run on:
#  - any .sh under .flywheel/scripts/
#  - any .sh with the magic comment in the first 5 lines
declare -a TARGETS=()
for f in "${staged[@]}"; do
  full="$REPO_ROOT/$f"
  [[ -f "$full" ]] || continue
  if [[ "$f" == .flywheel/scripts/*.sh ]]; then
    TARGETS+=("$full")
    continue
  fi
  if head -5 "$full" 2>/dev/null | grep -q '^#[[:space:]]*flywheel-cli-surface:[[:space:]]*true'; then
    TARGETS+=("$full")
  fi
done

[[ "${#TARGETS[@]}" -eq 0 ]] && exit 0

violations=0
for t in "${TARGETS[@]}"; do
  set +e
  "$LINTER" "$t"
  rc=$?
  set -e
  [[ "$rc" -eq 0 ]] || violations=$((violations + 1))
done

if [[ "$violations" -gt 0 ]]; then
  echo "" >&2
  echo "canonical-cli-lint: $violations file(s) with violations — refusing commit." >&2
  echo "Fix the violations above, or bypass with 'git commit --no-verify' if intentional." >&2
  exit 1
fi

exit 0
