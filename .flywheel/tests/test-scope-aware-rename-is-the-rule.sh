#!/usr/bin/env bash
# test-scope-aware-rename-is-the-rule.sh
# Structural gate coverage test for META-RULE: scope-aware-rename-is-the-rule
# Verifies the rule is registered in the consolidated batch gate.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
GATE="$ROOT/.flywheel/scripts/meta-rule-structural-batch-gate.sh"

[[ -x "$GATE" ]] || { printf 'FAIL gate script not executable: %s\n' "$GATE" >&2; exit 1; }

output="$("$GATE" "scope-aware-rename-is-the-rule" 2>&1)"
rc=$?

if [[ "$rc" -eq 0 && "$output" == *"REGISTERED"* ]]; then
  printf 'PASS scope-aware-rename-is-the-rule is registered in meta-rule-structural-batch-gate\n'
  exit 0
else
  printf 'FAIL scope-aware-rename-is-the-rule not registered (rc=%s output=%s)\n' "$rc" "$output" >&2
  exit 1
fi
