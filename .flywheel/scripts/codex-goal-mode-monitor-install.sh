#!/usr/bin/env bash
set -euo pipefail

SCHEMA_VERSION="codex-goal-mode-monitor-install/v0.1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
LABEL="ai.zeststream.codex-goal-mode-monitor"
PLIST="${CODEX_GOAL_MODE_MONITOR_PLIST:-$HOME/Library/LaunchAgents/${LABEL}.plist}"
BRIDGE_PLIST="${CODEX_GOAL_MODE_BRIDGE_PLIST:-$HOME/Library/LaunchAgents/ai.zeststream.flywheel-coordinator-daemon.plist}"
LAUNCHCTL="${CODEX_GOAL_MODE_LAUNCHCTL:-launchctl}"
PLUTIL="${CODEX_GOAL_MODE_PLUTIL:-plutil}"
BOOTSTRAP_DOMAIN="${CODEX_GOAL_MODE_BOOTSTRAP_DOMAIN:-gui/$UID}"
DAEMON_COMMAND="${ROOT}/.flywheel/scripts/codex-goal-mode-monitor-daemon.sh --repo ${ROOT} --interval-s 60"
JSON_OUT=0
DRY_RUN=0
UNINSTALL=0

usage() {
  cat <<'EOF'
usage: codex-goal-mode-monitor-install.sh [--json] [--dry-run] [--uninstall]

Installs the flywheel-local codex goal-mode monitor launchd plist.
EOF
}

emit() {
  local status="$1" action="$2" loaded="$3"
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc \
      --arg schema_version "$SCHEMA_VERSION" \
      --arg status "$status" \
      --arg action "$action" \
      --arg label "$LABEL" \
      --arg plist "$PLIST" \
      --arg bridge_plist "$BRIDGE_PLIST" \
      --arg bridge_sha256 "$(if [[ -f "$BRIDGE_PLIST" ]]; then shasum -a 256 "$BRIDGE_PLIST" | awk '{print $1}'; fi)" \
      --argjson loaded "$loaded" \
      '{schema_version:$schema_version,status:$status,action:$action,label:$label,plist:$plist,bridge_plist:$bridge_plist,bridge_sha256:$bridge_sha256,loaded:$loaded}'
  else
    printf 'codex-goal-mode-monitor-install status=%s action=%s loaded=%s plist=%s\n' "$status" "$action" "$loaded" "$PLIST"
  fi
}

loaded() {
  "$LAUNCHCTL" print "$BOOTSTRAP_DOMAIN/$LABEL" >/dev/null 2>&1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'unknown arg: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ "$UNINSTALL" -eq 1 ]]; then
  if [[ "$DRY_RUN" -eq 0 ]]; then
    "$LAUNCHCTL" bootout "$BOOTSTRAP_DOMAIN/$LABEL" >/dev/null 2>&1 || true
    rm -f "$PLIST"
  fi
  emit "pass" "uninstalled" false
  exit 0
fi

tmp="$(mktemp "${TMPDIR:-/tmp}/codex-goal-mode-monitor.XXXXXX")"
trap 'rm -f "$tmp"' EXIT
cat >"$tmp" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${LABEL}</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>-lc</string>
    <string>exec ${DAEMON_COMMAND}</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>EnvironmentVariables</key>
  <dict>
    <key>HOME</key>
    <string>${HOME}</string>
    <key>PATH</key>
    <string>/Users/josh/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
  </dict>
  <key>StandardOutPath</key>
  <string>/tmp/codex-goal-mode-monitor.log</string>
  <key>StandardErrorPath</key>
  <string>/tmp/codex-goal-mode-monitor.err.log</string>
</dict>
</plist>
PLIST

"$PLUTIL" -lint "$tmp" >/dev/null
if [[ "$DRY_RUN" -eq 1 ]]; then
  emit "pass" "would_install" false
  exit 0
fi

mkdir -p "$(dirname "$PLIST")"
if [[ -f "$PLIST" ]] && cmp -s "$tmp" "$PLIST"; then
  action="already_current"
else
  cp "$tmp" "$PLIST"
  action="installed"
fi

if loaded; then
  "$LAUNCHCTL" bootout "$BOOTSTRAP_DOMAIN/$LABEL" >/dev/null 2>&1 || true
fi
pkill -f "$DAEMON_COMMAND" >/dev/null 2>&1 || true
"$LAUNCHCTL" bootstrap "$BOOTSTRAP_DOMAIN" "$PLIST" >/dev/null 2>&1 || true
"$LAUNCHCTL" kickstart -k "$BOOTSTRAP_DOMAIN/$LABEL" >/dev/null 2>&1 || true
if loaded; then
  emit "pass" "$action" true
else
  emit "warn" "$action" false
  exit 1
fi
