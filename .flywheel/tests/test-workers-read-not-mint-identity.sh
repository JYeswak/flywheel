#!/usr/bin/env bash
# test-workers-read-not-mint-identity.sh
# Structural gate coverage test for META-RULE: workers-read-not-mint-identity
# Verifies the rule is registered in the consolidated batch gate.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
GATE="$ROOT/.flywheel/scripts/meta-rule-structural-batch-gate.sh"

[[ -x "$GATE" ]] || { printf 'FAIL gate script not executable: %s\n' "$GATE" >&2; exit 1; }

output="$("$GATE" "workers-read-not-mint-identity" 2>&1)"
rc=$?

if [[ "$rc" -eq 0 && "$output" == *"REGISTERED"* ]]; then
  printf 'PASS workers-read-not-mint-identity is registered in meta-rule-structural-batch-gate\n'
  exit 0
else
  printf 'FAIL workers-read-not-mint-identity not registered (rc=%s output=%s)\n' "$rc" "$output" >&2
  exit 1
fi
