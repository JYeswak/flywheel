#!/usr/bin/env bash
# Install ntm-fleet-health daemon using modern launchctl bootstrap/kickstart sequence.
# Idempotent: bootstraps if not loaded, kickstarts if already loaded.
set -euo pipefail

LABEL="ai.zeststream.ntm-fleet-health"
PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"
DOMAIN="gui/$UID"
TARGET="$DOMAIN/${LABEL}"

if [ ! -f "$PLIST" ]; then
  echo "ERROR: $PLIST does not exist" >&2
  exit 1
fi

if launchctl print "$TARGET" >/dev/null 2>&1; then
  echo "Already loaded; warm-restarting via kickstart"
  launchctl kickstart -k "$TARGET"
else
  echo "Bootstrapping into $DOMAIN"
  launchctl bootstrap "$DOMAIN" "$PLIST"
fi

for _ in {1..10}; do
  PID=$(launchctl print "$TARGET" 2>/dev/null | awk '/^[[:space:]]*pid =/ {print $3; exit}')
  if [ -n "${PID:-}" ] && [ "$PID" != "0" ]; then
    echo "OK: $LABEL running as PID $PID"
    exit 0
  fi
  sleep 0.5
done

echo "WARN: $LABEL bootstrapped but no PID after 5s (may run on schedule, not at-load)"
launchctl print "$TARGET" 2>&1 | head -20
exit 0

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
