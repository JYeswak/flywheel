#!/usr/bin/env bash
# test-misbehaving-substrate-orch-disables-does-not-ask.sh
# Structural gate coverage test for META-RULE: misbehaving-substrate-orch-disables-does-not-ask
# Verifies the rule is registered in the consolidated batch gate.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
GATE="$ROOT/.flywheel/scripts/meta-rule-structural-batch-gate.sh"

[[ -x "$GATE" ]] || { printf 'FAIL gate script not executable: %s\n' "$GATE" >&2; exit 1; }

output="$("$GATE" "misbehaving-substrate-orch-disables-does-not-ask" 2>&1)"
rc=$?

if [[ "$rc" -eq 0 && "$output" == *"REGISTERED"* ]]; then
  printf 'PASS misbehaving-substrate-orch-disables-does-not-ask is registered in meta-rule-structural-batch-gate\n'
  exit 0
else
  printf 'FAIL misbehaving-substrate-orch-disables-does-not-ask not registered (rc=%s output=%s)\n' "$rc" "$output" >&2
  exit 1
fi
