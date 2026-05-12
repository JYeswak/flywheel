#!/usr/bin/env bash
# test-xpane-recovery-recommendations-must-verify-canonical-flags-and-protections.sh
# Structural gate coverage test for META-RULE: xpane-recovery-recommendations-must-verify-canonical-flags-and-protections
# Verifies the rule is registered in the consolidated batch gate.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
GATE="$ROOT/.flywheel/scripts/meta-rule-structural-batch-gate.sh"

[[ -x "$GATE" ]] || { printf 'FAIL gate script not executable: %s\n' "$GATE" >&2; exit 1; }

output="$("$GATE" "xpane-recovery-recommendations-must-verify-canonical-flags-and-protections" 2>&1)"
rc=$?

if [[ "$rc" -eq 0 && "$output" == *"REGISTERED"* ]]; then
  printf 'PASS xpane-recovery-recommendations-must-verify-canonical-flags-and-protections is registered in meta-rule-structural-batch-gate\n'
  exit 0
else
  printf 'FAIL xpane-recovery-recommendations-must-verify-canonical-flags-and-protections not registered (rc=%s output=%s)\n' "$rc" "$output" >&2
  exit 1
fi
