#!/usr/bin/env bash
# test-private-tmp-accretes-until-disk-dies.sh
set -euo pipefail
RULE_FILE="${HOME}/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_private_tmp_accretes_until_disk_dies.md"
[[ -f "$RULE_FILE" ]] || { printf 'FAIL memory file missing\n' >&2; exit 1; }
grep -q "META-RULE" "$RULE_FILE" || { printf 'FAIL META-RULE marker missing\n' >&2; exit 1; }
printf 'PASS private-tmp-accretes-until-disk-dies is wired\n'
exit 0
