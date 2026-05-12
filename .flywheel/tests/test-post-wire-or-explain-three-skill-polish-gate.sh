#!/usr/bin/env bash
# test-post-wire-or-explain-three-skill-polish-gate.sh
# Structural gate coverage test for META-RULE: post-wire-or-explain-three-skill-polish-gate
# Verifies the rule is registered in the consolidated batch gate.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
GATE="$ROOT/.flywheel/scripts/meta-rule-structural-batch-gate.sh"

[[ -x "$GATE" ]] || { printf 'FAIL gate script not executable: %s\n' "$GATE" >&2; exit 1; }

output="$("$GATE" "post-wire-or-explain-three-skill-polish-gate" 2>&1)"
rc=$?

if [[ "$rc" -eq 0 && "$output" == *"REGISTERED"* ]]; then
  printf 'PASS post-wire-or-explain-three-skill-polish-gate is registered in meta-rule-structural-batch-gate\n'
  exit 0
else
  printf 'FAIL post-wire-or-explain-three-skill-polish-gate not registered (rc=%s output=%s)\n' "$rc" "$output" >&2
  exit 1
fi
