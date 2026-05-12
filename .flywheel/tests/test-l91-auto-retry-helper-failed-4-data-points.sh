#!/usr/bin/env bash
# test-l91-auto-retry-helper-failed-4-data-points.sh
# Structural gate coverage test for META-RULE: l91-auto-retry-helper-failed-4-data-points
# Verifies the rule is registered in the consolidated batch gate.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
GATE="$ROOT/.flywheel/scripts/meta-rule-structural-batch-gate.sh"

[[ -x "$GATE" ]] || { printf 'FAIL gate script not executable: %s\n' "$GATE" >&2; exit 1; }

output="$("$GATE" "l91-auto-retry-helper-failed-4-data-points" 2>&1)"
rc=$?

if [[ "$rc" -eq 0 && "$output" == *"REGISTERED"* ]]; then
  printf 'PASS l91-auto-retry-helper-failed-4-data-points is registered in meta-rule-structural-batch-gate\n'
  exit 0
else
  printf 'FAIL l91-auto-retry-helper-failed-4-data-points not registered (rc=%s output=%s)\n' "$rc" "$output" >&2
  exit 1
fi
