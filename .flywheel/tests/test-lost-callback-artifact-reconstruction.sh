#!/usr/bin/env bash
# test-lost-callback-artifact-reconstruction.sh
set -euo pipefail
RULE_FILE="${HOME}/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_lost_callback_artifact_reconstruction.md"
[[ -f "$RULE_FILE" ]] || { printf 'FAIL memory file missing\n' >&2; exit 1; }
grep -q "META-RULE" "$RULE_FILE" || { printf 'FAIL META-RULE marker missing\n' >&2; exit 1; }
printf 'PASS lost-callback-artifact-reconstruction is wired\n'
exit 0
