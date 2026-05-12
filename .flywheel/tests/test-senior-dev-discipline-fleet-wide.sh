#!/usr/bin/env bash
# test-senior-dev-discipline-fleet-wide.sh
# Structural gate coverage test for META-RULE: senior-dev-discipline-fleet-wide
# Verifies the rule is registered in the consolidated batch gate.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
GATE="$ROOT/.flywheel/scripts/meta-rule-structural-batch-gate.sh"

[[ -x "$GATE" ]] || { printf 'FAIL gate script not executable: %s\n' "$GATE" >&2; exit 1; }

output="$("$GATE" "senior-dev-discipline-fleet-wide" 2>&1)"
rc=$?

if [[ "$rc" -eq 0 && "$output" == *"REGISTERED"* ]]; then
  printf 'PASS senior-dev-discipline-fleet-wide is registered in meta-rule-structural-batch-gate\n'
  exit 0
else
  printf 'FAIL senior-dev-discipline-fleet-wide not registered (rc=%s output=%s)\n' "$rc" "$output" >&2
  exit 1
fi
