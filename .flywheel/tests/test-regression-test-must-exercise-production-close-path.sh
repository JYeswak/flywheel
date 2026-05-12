#!/usr/bin/env bash
# test-regression-test-must-exercise-production-close-path.sh
set -euo pipefail
RULE_FILE="${HOME}/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_regression_test_must_exercise_production_close_path.md"
[[ -f "$RULE_FILE" ]] || { printf 'FAIL memory file missing\n' >&2; exit 1; }
grep -q "META-RULE" "$RULE_FILE" || { printf 'FAIL META-RULE marker missing\n' >&2; exit 1; }
printf 'PASS regression-test-must-exercise-production-close-path is wired\n'
exit 0
