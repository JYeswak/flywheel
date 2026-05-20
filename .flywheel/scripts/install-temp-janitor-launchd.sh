#!/usr/bin/env bash
# Install temp-janitor as launchd cadence — runs every 60min as foundational hygiene.
# Joshua-direct 2026-05-20: foundational temp-dir cleanup, not one-shot.
set -euo pipefail

LABEL="ai.zeststream.flywheel-temp-janitor"
PLIST="$HOME/Library/LaunchAgents/${LABEL}.plist"
SCRIPT="/Users/josh/Developer/flywheel/.flywheel/scripts/temp-janitor.sh"
LOG_DIR="$HOME/.local/state/flywheel/temp-janitor"

mkdir -p "$LOG_DIR" "$(dirname "$PLIST")"

cat > "$PLIST" <<PLISTXML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${LABEL}</string>
  <key>Program</key>
  <string>${SCRIPT}</string>
  <key>ProgramArguments</key>
  <array>
    <string>${SCRIPT}</string>
    <string>--json</string>
  </array>
  <key>StartInterval</key>
  <integer>3600</integer>
  <key>RunAtLoad</key>
  <true/>
  <key>StandardOutPath</key>
  <string>${LOG_DIR}/janitor.stdout.log</string>
  <key>StandardErrorPath</key>
  <string>${LOG_DIR}/janitor.stderr.log</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
  </dict>
</dict>
</plist>
PLISTXML

# Bootload (idempotent — unload first if exists)
launchctl unload "$PLIST" 2>/dev/null || true
launchctl load "$PLIST"

echo "  installed: $PLIST"
echo "  cadence: every 3600s (60min) + at load"
echo "  logs: $LOG_DIR/janitor.{stdout,stderr}.log"
echo "  status:"
launchctl list "$LABEL" 2>/dev/null | head -5 || echo "    (not yet loaded — check after a few seconds)"
