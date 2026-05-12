#!/usr/bin/env bash
# test-orchestrator-must-finish-p0-before-filing-more.sh
set -euo pipefail
RULE_FILE="${HOME}/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_orchestrator_must_finish_p0_before_filing_more.md"
[[ -f "$RULE_FILE" ]] || { printf 'FAIL memory file missing\n' >&2; exit 1; }
grep -q "META-RULE" "$RULE_FILE" || { printf 'FAIL META-RULE marker missing\n' >&2; exit 1; }
printf 'PASS orchestrator-must-finish-p0-before-filing-more is wired\n'
exit 0
