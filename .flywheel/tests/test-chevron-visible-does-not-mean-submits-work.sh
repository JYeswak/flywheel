#!/usr/bin/env bash
# test-chevron-visible-does-not-mean-submits-work.sh
# Structural gate coverage test for META-RULE: chevron-visible-does-not-mean-submits-work
# Verifies the rule is registered in the consolidated batch gate.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
GATE="$ROOT/.flywheel/scripts/meta-rule-structural-batch-gate.sh"

[[ -x "$GATE" ]] || { printf 'FAIL gate script not executable: %s\n' "$GATE" >&2; exit 1; }

output="$("$GATE" "chevron-visible-does-not-mean-submits-work" 2>&1)"
rc=$?

if [[ "$rc" -eq 0 && "$output" == *"REGISTERED"* ]]; then
  printf 'PASS chevron-visible-does-not-mean-submits-work is registered in meta-rule-structural-batch-gate\n'
  exit 0
else
  printf 'FAIL chevron-visible-does-not-mean-submits-work not registered (rc=%s output=%s)\n' "$rc" "$output" >&2
  exit 1
fi
