#!/usr/bin/env bash
# test-codex-model-at-capacity-halt-class.sh
set -euo pipefail
RULE_FILE="${HOME}/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_codex_model_at_capacity_halt_class.md"
[[ -f "$RULE_FILE" ]] || { printf 'FAIL memory file missing\n' >&2; exit 1; }
grep -q "META-RULE" "$RULE_FILE" || { printf 'FAIL META-RULE marker missing\n' >&2; exit 1; }
printf 'PASS codex-model-at-capacity-halt-class is wired\n'
exit 0
