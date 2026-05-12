#!/usr/bin/env bash
# test-three-audit-questions-per-surface.sh
# Structural gate coverage test for META-RULE: three-audit-questions-per-surface
# Verifies the rule is registered in the consolidated batch gate.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
GATE="$ROOT/.flywheel/scripts/meta-rule-structural-batch-gate.sh"

[[ -x "$GATE" ]] || { printf 'FAIL gate script not executable: %s\n' "$GATE" >&2; exit 1; }

output="$("$GATE" "three-audit-questions-per-surface" 2>&1)"
rc=$?

if [[ "$rc" -eq 0 && "$output" == *"REGISTERED"* ]]; then
  printf 'PASS three-audit-questions-per-surface is registered in meta-rule-structural-batch-gate\n'
  exit 0
else
  printf 'FAIL three-audit-questions-per-surface not registered (rc=%s output=%s)\n' "$rc" "$output" >&2
  exit 1
fi
