#!/usr/bin/env bash
# Uninstall ntm-fleet-health daemon using modern launchctl bootout.
set -euo pipefail

LABEL="ai.zeststream.ntm-fleet-health"
DOMAIN="gui/$UID"
TARGET="$DOMAIN/${LABEL}"

if launchctl print "$TARGET" >/dev/null 2>&1; then
  echo "Booting out $TARGET"
  launchctl bootout "$TARGET"
  echo "OK: $LABEL removed from $DOMAIN"
else
  echo "Not currently loaded; nothing to do"
fi

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
