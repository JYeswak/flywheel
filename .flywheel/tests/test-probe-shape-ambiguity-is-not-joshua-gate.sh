#!/usr/bin/env bash
# test-probe-shape-ambiguity-is-not-joshua-gate.sh
set -euo pipefail
RULE_FILE="${HOME}/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_probe_shape_ambiguity_is_not_joshua_gate.md"
[[ -f "$RULE_FILE" ]] || { printf 'FAIL memory file missing\n' >&2; exit 1; }
grep -q "META-RULE" "$RULE_FILE" || { printf 'FAIL META-RULE marker missing\n' >&2; exit 1; }
printf 'PASS probe-shape-ambiguity-is-not-joshua-gate is wired\n'
exit 0
