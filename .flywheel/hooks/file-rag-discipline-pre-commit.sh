#!/usr/bin/env bash
# .flywheel/hooks/file-rag-discipline-pre-commit.sh
#
# Pre-commit guard that runs file-rag-discipline-lint.sh on staged .md
# files. Refuses commit on F1 or F4 errors; warns (allow) on F2/F3/F5/F6/F7;
# info (allow) on F8. Honors `git commit --no-verify`.
#
# Wire-up: ln -s ../../.flywheel/hooks/file-rag-discipline-pre-commit.sh \
#                .git/hooks/pre-commit
#
# Bead: flywheel-s8tdd. Spec: .flywheel/audit/flywheel-fs-rag-discipline/apply-spec.md.
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
LINTER="$REPO_ROOT/.flywheel/scripts/file-rag-discipline-lint.sh"

[[ -x "$LINTER" ]] || {
  echo "WARN: file-rag-discipline-lint.sh missing or not executable; skipping" >&2
  exit 0
}

mapfile -t staged < <(git diff --cached --name-only --diff-filter=AM | grep -E '\.md$' || true)
[[ "${#staged[@]}" -eq 0 ]] && exit 0

errors=0
warnings=0
for f in "${staged[@]}"; do
  full="$REPO_ROOT/$f"
  [[ -f "$full" ]] || continue
  set +e
  out=$("$LINTER" "$full" --json 2>/dev/null)
  set -e
  [[ -z "$out" ]] && continue
  err_count=$(echo "$out" | jq '[.violations[] | select(.severity == "error")] | length' 2>/dev/null || echo 0)
  warn_count=$(echo "$out" | jq '[.violations[] | select(.severity == "warn")] | length' 2>/dev/null || echo 0)
  if [[ "$err_count" -gt 0 ]]; then
    echo "$out" | jq -r '.violations[] | select(.severity == "error") | "\(.file): \(.rule) [\(.label)]: \(.message)"'
    errors=$((errors + err_count))
  fi
  if [[ "$warn_count" -gt 0 ]]; then
    echo "$out" | jq -r '.violations[] | select(.severity == "warn") | "  warn: \(.file): \(.rule) [\(.label)]: \(.message)"'
    warnings=$((warnings + warn_count))
  fi
done

if [[ "$errors" -gt 0 ]]; then
  echo "" >&2
  echo "file-rag-discipline: $errors error(s) — refusing commit." >&2
  echo "Fix errors above (typically: missing frontmatter or .bak file)," >&2
  echo "or bypass with 'git commit --no-verify' if intentional." >&2
  exit 1
fi
[[ "$warnings" -gt 0 ]] && echo "file-rag-discipline: $warnings warning(s) (commit allowed)" >&2
exit 0
