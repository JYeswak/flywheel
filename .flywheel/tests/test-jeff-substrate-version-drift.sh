#!/usr/bin/env bash
# test-jeff-substrate-version-drift.sh
set -euo pipefail
RULE_FILE="${HOME}/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_jeff_substrate_version_drift.md"
[[ -f "$RULE_FILE" ]] || { printf 'FAIL memory file missing\n' >&2; exit 1; }
grep -q "META-RULE" "$RULE_FILE" || { printf 'FAIL META-RULE marker missing\n' >&2; exit 1; }
printf 'PASS jeff-substrate-version-drift is wired\n'
exit 0
