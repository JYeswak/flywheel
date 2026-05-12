#!/usr/bin/env bash
# test-canonical-recipe-scoped-commit-by-pathspec.sh
# Structural gate coverage test for META-RULE: canonical-recipe-scoped-commit-by-pathspec
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
MEMORY_DIR="${HOME}/.claude/projects/-Users-josh-Developer-flywheel/memory"
RULE_FILE="$MEMORY_DIR/feedback_canonical_recipe_scoped_commit_by_pathspec.md"
[[ -f "$RULE_FILE" ]] || { printf 'FAIL memory file missing: %s\n' "$RULE_FILE" >&2; exit 1; }
grep -q "META-RULE" "$RULE_FILE" || { printf 'FAIL META-RULE marker missing\n' >&2; exit 1; }
printf 'PASS canonical-recipe-scoped-commit-by-pathspec is wired\n'
exit 0
