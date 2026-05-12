#!/usr/bin/env bash
# test-ntm-rotate-stdin-contamination-use-respawn-path.sh
# Structural gate coverage test for META-RULE: ntm-rotate-stdin-contamination-use-respawn-path
# Verifies the rule is registered in the consolidated batch gate.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
GATE="$ROOT/.flywheel/scripts/meta-rule-structural-batch-gate.sh"

[[ -x "$GATE" ]] || { printf 'FAIL gate script not executable: %s\n' "$GATE" >&2; exit 1; }

output="$("$GATE" "ntm-rotate-stdin-contamination-use-respawn-path" 2>&1)"
rc=$?

if [[ "$rc" -eq 0 && "$output" == *"REGISTERED"* ]]; then
  printf 'PASS ntm-rotate-stdin-contamination-use-respawn-path is registered in meta-rule-structural-batch-gate\n'
  exit 0
else
  printf 'FAIL ntm-rotate-stdin-contamination-use-respawn-path not registered (rc=%s output=%s)\n' "$rc" "$output" >&2
  exit 1
fi
