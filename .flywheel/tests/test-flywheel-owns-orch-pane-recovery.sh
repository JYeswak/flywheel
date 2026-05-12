#!/usr/bin/env bash
# test-flywheel-owns-orch-pane-recovery.sh
# Structural gate coverage test for META-RULE: flywheel-owns-orch-pane-recovery
# Verifies the rule is registered in the consolidated batch gate.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
GATE="$ROOT/.flywheel/scripts/meta-rule-structural-batch-gate.sh"

[[ -x "$GATE" ]] || { printf 'FAIL gate script not executable: %s\n' "$GATE" >&2; exit 1; }

output="$("$GATE" "flywheel-owns-orch-pane-recovery" 2>&1)"
rc=$?

if [[ "$rc" -eq 0 && "$output" == *"REGISTERED"* ]]; then
  printf 'PASS flywheel-owns-orch-pane-recovery is registered in meta-rule-structural-batch-gate\n'
  exit 0
else
  printf 'FAIL flywheel-owns-orch-pane-recovery not registered (rc=%s output=%s)\n' "$rc" "$output" >&2
  exit 1
fi
