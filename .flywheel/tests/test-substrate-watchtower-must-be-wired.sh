#!/usr/bin/env bash
# test-substrate-watchtower-must-be-wired.sh
# Structural gate coverage test for META-RULE: substrate-watchtower-must-be-wired
# Verifies the rule is registered in the consolidated batch gate.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
GATE="$ROOT/.flywheel/scripts/meta-rule-structural-batch-gate.sh"

[[ -x "$GATE" ]] || { printf 'FAIL gate script not executable: %s\n' "$GATE" >&2; exit 1; }

output="$("$GATE" "substrate-watchtower-must-be-wired" 2>&1)"
rc=$?

if [[ "$rc" -eq 0 && "$output" == *"REGISTERED"* ]]; then
  printf 'PASS substrate-watchtower-must-be-wired is registered in meta-rule-structural-batch-gate\n'
  exit 0
else
  printf 'FAIL substrate-watchtower-must-be-wired not registered (rc=%s output=%s)\n' "$rc" "$output" >&2
  exit 1
fi
