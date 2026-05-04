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
