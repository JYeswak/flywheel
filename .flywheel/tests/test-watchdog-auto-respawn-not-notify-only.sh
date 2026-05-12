#!/usr/bin/env bash
# test-watchdog-auto-respawn-not-notify-only.sh
set -euo pipefail
RULE_FILE="${HOME}/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_watchdog_auto_respawn_not_notify_only.md"
[[ -f "$RULE_FILE" ]] || { printf 'FAIL memory file missing\n' >&2; exit 1; }
grep -q "META-RULE" "$RULE_FILE" || { printf 'FAIL META-RULE marker missing\n' >&2; exit 1; }
printf 'PASS watchdog-auto-respawn-not-notify-only is wired\n'
exit 0
