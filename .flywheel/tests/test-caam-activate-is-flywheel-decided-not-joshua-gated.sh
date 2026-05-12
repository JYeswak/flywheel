#!/usr/bin/env bash
# test-caam-activate-is-flywheel-decided-not-joshua-gated.sh
# Structural gate coverage test for META-RULE: caam-activate-is-flywheel-decided-not-joshua-gated
# Verifies the rule is registered in the consolidated batch gate.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
GATE="$ROOT/.flywheel/scripts/meta-rule-structural-batch-gate.sh"

[[ -x "$GATE" ]] || { printf 'FAIL gate script not executable: %s\n' "$GATE" >&2; exit 1; }

output="$("$GATE" "caam-activate-is-flywheel-decided-not-joshua-gated" 2>&1)"
rc=$?

if [[ "$rc" -eq 0 && "$output" == *"REGISTERED"* ]]; then
  printf 'PASS caam-activate-is-flywheel-decided-not-joshua-gated is registered in meta-rule-structural-batch-gate\n'
  exit 0
else
  printf 'FAIL caam-activate-is-flywheel-decided-not-joshua-gated not registered (rc=%s output=%s)\n' "$rc" "$output" >&2
  exit 1
fi
