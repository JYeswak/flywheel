#!/usr/bin/env bash
# test-flywheel-owns-continuous-productivity-no-downtime-unless-josh-blocker.sh
# Structural gate coverage test for META-RULE: flywheel-owns-continuous-productivity-no-downtime-unless-josh-blocker
# Verifies the rule is registered in the consolidated batch gate.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
GATE="$ROOT/.flywheel/scripts/meta-rule-structural-batch-gate.sh"

[[ -x "$GATE" ]] || { printf 'FAIL gate script not executable: %s\n' "$GATE" >&2; exit 1; }

output="$("$GATE" "flywheel-owns-continuous-productivity-no-downtime-unless-josh-blocker" 2>&1)"
rc=$?

if [[ "$rc" -eq 0 && "$output" == *"REGISTERED"* ]]; then
  printf 'PASS flywheel-owns-continuous-productivity-no-downtime-unless-josh-blocker is registered in meta-rule-structural-batch-gate\n'
  exit 0
else
  printf 'FAIL flywheel-owns-continuous-productivity-no-downtime-unless-josh-blocker not registered (rc=%s output=%s)\n' "$rc" "$output" >&2
  exit 1
fi
