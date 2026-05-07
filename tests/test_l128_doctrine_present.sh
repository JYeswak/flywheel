#!/usr/bin/env bash
# Verify L128 PLAN-CONVERGENCE-PROVED-WITH-DATA is present and cites all 6 implementing beads
set -euo pipefail

DOCTRINE=".flywheel/AGENTS-CANONICAL.md"

grep -q "L128 PLAN-CONVERGENCE-PROVED-WITH-DATA" "$DOCTRINE" || {
  echo "MISSING: L128 entry"
  exit 1
}

for bead_id in flywheel-ykkhv flywheel-gau3q flywheel-2xsag flywheel-xhfbw flywheel-d3q0j flywheel-26hsk; do
  grep -q "$bead_id" "$DOCTRINE" || {
    echo "MISSING: bead $bead_id citation in L128"
    exit 1
  }
done

echo "L128 doctrine present + all 6 implementing beads cited"
