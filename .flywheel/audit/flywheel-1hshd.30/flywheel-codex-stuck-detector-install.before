#!/usr/bin/env bash
set -euo pipefail

VERSION="flywheel-codex-stuck-detector-install.v1.0.0"
SCHEMA_VERSION="flywheel-codex-stuck-detector.install.v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DETECTOR="${FLYWHEEL_CODEX_STUCK_DETECTOR:-$SCRIPT_DIR/codex-template-stuck-detector.sh}"
LABEL="${FLYWHEEL_CODEX_STUCK_DETECTOR_LABEL:-ai.zeststream.flywheel-codex-stuck-detector}"
LAUNCH_AGENTS_DIR="${FLYWHEEL_CODEX_STUCK_DETECTOR_LAUNCH_AGENTS_DIR:-$HOME/Library/LaunchAgents}"
PLIST_PATH="${FLYWHEEL_CODEX_STUCK_DETECTOR_PLIST_PATH:-$LAUNCH_AGENTS_DIR/$LABEL.plist}"
STATE_DIR="${FLYWHEEL_CODEX_STUCK_DETECTOR_STATE_DIR:-$HOME/.local/state/flywheel}"
BOOTSTRAP_DOMAIN="${FLYWHEEL_CODEX_STUCK_DETECTOR_BOOTSTRAP_DOMAIN:-gui/$UID}"
LAUNCHCTL="${FLYWHEEL_CODEX_STUCK_DETECTOR_LAUNCHCTL:-launchctl}"
PLUTIL="${FLYWHEEL_CODEX_STUCK_DETECTOR_PLUTIL:-plutil}"
APPLY=0
JSON_OUT=0

usage() { printf '%s\n' "Usage: flywheel-codex-stuck-detector-install.sh [--apply|--dry-run] [--json]"; }

write_plist() {
  local command
  mkdir -p "$LAUNCH_AGENTS_DIR" "$STATE_DIR"
  command='set -euo pipefail; topo="${TMPDIR:-/tmp}/codex-stuck-detector-flywheel-topology.jsonl"; jq -c '\''select(.session=="flywheel")'\'' "$HOME/.local/state/flywheel/session-topology.jsonl" | jq -s -c '\''group_by(.session) | map(max_by(.effective_at))[]'\'' > "$topo"; jq -nc --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg session "flywheel" --arg label "'"$LABEL"'" '\''{schema_version:"codex-stuck-detector.launchd-fire.v1",event:"launchd_fire",ts:$ts,session:$session,label:$label}'\''; CODEX_STUCK_DETECTOR_TOPOLOGY="$topo" exec "'"$DETECTOR"'" --session flywheel --worker-panes-from-topology --apply --auto-recover --json'
  cat >"$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>-lc</string>
    <string>$command</string>
  </array>
  <key>StartInterval</key>
  <integer>60</integer>
  <key>RunAtLoad</key>
  <true/>
  <key>StandardOutPath</key>
  <string>$STATE_DIR/codex-stuck-detector.flywheel.log</string>
  <key>StandardErrorPath</key>
  <string>$STATE_DIR/codex-stuck-detector.flywheel.err</string>
</dict>
</plist>
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) APPLY=1; shift ;;
    --dry-run) APPLY=0; shift ;;
    --json) JSON_OUT=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

loaded=false
print_exit=1
plutil_exit=0
if (( APPLY )); then
  write_plist
  "$PLUTIL" -lint "$PLIST_PATH" >/dev/null || plutil_exit=$?
  "$LAUNCHCTL" bootout "$BOOTSTRAP_DOMAIN/$LABEL" >/dev/null 2>&1 || true
  "$LAUNCHCTL" bootstrap "$BOOTSTRAP_DOMAIN" "$PLIST_PATH"
  "$LAUNCHCTL" kickstart -k "$BOOTSTRAP_DOMAIN/$LABEL" >/dev/null 2>&1 || true
  if "$LAUNCHCTL" print "$BOOTSTRAP_DOMAIN/$LABEL" >/dev/null 2>&1; then
    loaded=true
    print_exit=0
  fi
fi

payload="$(jq -nc --arg schema_version "$SCHEMA_VERSION" --arg version "$VERSION" --arg label "$LABEL" --arg plist "$PLIST_PATH" --arg domain "$BOOTSTRAP_DOMAIN" --arg detector "$DETECTOR" --argjson apply "$APPLY" --argjson loaded "$loaded" --argjson plutil_exit "$plutil_exit" --argjson print_exit "$print_exit" '{schema_version:$schema_version,version:$version,success:($plutil_exit == 0),label:$label,plist_path:$plist,bootstrap_domain:$domain,detector:$detector,interval_seconds:60,apply:($apply == 1),dry_run:($apply == 0),loaded:$loaded,plutil_exit:$plutil_exit,launchctl_print_exit:$print_exit}')"
if (( JSON_OUT )); then
  printf '%s\n' "$payload"
else
  printf '%s\n' "$payload" | jq -r '"flywheel-codex-stuck-detector-install label=\(.label) loaded=\(.loaded) dry_run=\(.dry_run)"'
fi
