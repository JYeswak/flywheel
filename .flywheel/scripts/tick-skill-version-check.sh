#!/usr/bin/env bash
# Read skill_version from tick.md, compare to canonical design ref version.
# Exit 0: versions match. Exit 1: drift detected.
set -euo pipefail

TICK_MD="$HOME/.claude/commands/flywheel/tick.md"
DESIGN_DIR="$HOME/.local/state/flywheel/joint-deepdive-2026-05-01"
DESIGN_DOC="$DESIGN_DIR/orch-tick-bead-discipline-design.md"

if [ ! -f "$TICK_MD" ]; then
  echo "ERROR: $TICK_MD not found" >&2
  exit 2
fi

if [ ! -f "$DESIGN_DOC" ]; then
  echo "WARN: design ref not found: $DESIGN_DOC" >&2
fi

LOADED_VERSION=$(grep -m1 -oE 'skill_version:[[:space:]]*[0-9]+' "$TICK_MD" | grep -oE '[0-9]+' || true)

if [ -z "$LOADED_VERSION" ]; then
  echo "WARN: tick.md has no skill_version declaration"
  echo "  Run: edit ~/.claude/commands/flywheel/tick.md and add: <!-- skill_version: N -->"
  exit 1
fi

# Canonical version is hardcoded in this validator — bump when shipping new tick.md.
EXPECTED_VERSION=2

if [ "$LOADED_VERSION" -eq "$EXPECTED_VERSION" ]; then
  echo "OK: tick.md skill_version=$LOADED_VERSION matches expected"
  exit 0
fi

echo "DRIFT: tick.md skill_version=$LOADED_VERSION but expected=$EXPECTED_VERSION"
echo "  Ship new tick.md or bump EXPECTED_VERSION in this validator after design+impl land."
exit 1
