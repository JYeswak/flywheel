#!/usr/bin/env bash
# test-no-ad-hoc-per-repo-doctrine-edits.sh
# Structural gate coverage test for META-RULE: no-ad-hoc-per-repo-doctrine-edits
# Verifies the rule is registered in the consolidated batch gate.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
GATE="$ROOT/.flywheel/scripts/meta-rule-structural-batch-gate.sh"

[[ -x "$GATE" ]] || { printf 'FAIL gate script not executable: %s\n' "$GATE" >&2; exit 1; }

output="$("$GATE" "no-ad-hoc-per-repo-doctrine-edits" 2>&1)"
rc=$?

if [[ "$rc" -eq 0 && "$output" == *"REGISTERED"* ]]; then
  printf 'PASS no-ad-hoc-per-repo-doctrine-edits is registered in meta-rule-structural-batch-gate\n'
  exit 0
else
  printf 'FAIL no-ad-hoc-per-repo-doctrine-edits not registered (rc=%s output=%s)\n' "$rc" "$output" >&2
  exit 1
fi
