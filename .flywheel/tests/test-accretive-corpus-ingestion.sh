#!/usr/bin/env bash
# test-accretive-corpus-ingestion.sh
# Structural gate coverage test for META-RULE: accretive-corpus-ingestion
# Verifies the rule is registered in the consolidated batch gate.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
GATE="$ROOT/.flywheel/scripts/meta-rule-structural-batch-gate.sh"

[[ -x "$GATE" ]] || { printf 'FAIL gate script not executable: %s\n' "$GATE" >&2; exit 1; }

output="$("$GATE" "accretive-corpus-ingestion" 2>&1)"
rc=$?

if [[ "$rc" -eq 0 && "$output" == *"REGISTERED"* ]]; then
  printf 'PASS accretive-corpus-ingestion is registered in meta-rule-structural-batch-gate\n'
  exit 0
else
  printf 'FAIL accretive-corpus-ingestion not registered (rc=%s output=%s)\n' "$rc" "$output" >&2
  exit 1
fi
