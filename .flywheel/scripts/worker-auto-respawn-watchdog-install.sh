#!/usr/bin/env bash
set -euo pipefail

VERSION="worker-auto-respawn-watchdog-install.v1.0.0"
SCHEMA_VERSION="worker-auto-respawn-watchdog.install.v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
WATCHDOG="${WORKER_AUTO_RESPAWN_WATCHDOG:-$SCRIPT_DIR/worker-auto-respawn-watchdog.sh}"
LABEL="${WORKER_AUTO_RESPAWN_LABEL:-ai.zeststream.worker-auto-respawn-watchdog}"
LAUNCH_AGENTS_DIR="${WORKER_AUTO_RESPAWN_LAUNCH_AGENTS_DIR:-$HOME/Library/LaunchAgents}"
PLIST_PATH="${WORKER_AUTO_RESPAWN_PLIST_PATH:-$LAUNCH_AGENTS_DIR/$LABEL.plist}"
STATE_DIR="${WORKER_AUTO_RESPAWN_STATE_DIR:-$HOME/.local/state/flywheel}"
LAUNCHCTL="${WORKER_AUTO_RESPAWN_LAUNCHCTL:-launchctl}"
PLUTIL="${WORKER_AUTO_RESPAWN_PLUTIL:-plutil}"
BOOTSTRAP_DOMAIN="${WORKER_AUTO_RESPAWN_BOOTSTRAP_DOMAIN:-gui/$UID}"
JSON_OUT=0
QUIET=0
APPLY=0
MODE="install"

usage() { printf '%s\n' "Usage: worker-auto-respawn-watchdog-install.sh [--apply|--dry-run] [--json] [--quiet]" "Installs $LABEL in launchd $BOOTSTRAP_DOMAIN with StartInterval=60."; }
examples() { printf '%s\n' "worker-auto-respawn-watchdog-install.sh --dry-run --json" "worker-auto-respawn-watchdog-install.sh --apply --json"; }

info_json() { jq -nc --arg schema_version "$SCHEMA_VERSION" --arg version "$VERSION" --arg label "$LABEL" --arg plist "$PLIST_PATH" --arg domain "$BOOTSTRAP_DOMAIN" --arg watchdog "$WATCHDOG" '{schema_version:$schema_version,success:true,mode:"info",version:$version,label:$label,plist_path:$plist,bootstrap_domain:$domain,watchdog:$watchdog,interval_seconds:60,gui_domain:true}'; }

write_plist() {
  mkdir -p "$LAUNCH_AGENTS_DIR" "$STATE_DIR"
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
    <string>$WATCHDOG</string>
    <string>--apply</string>
    <string>--json</string>
    <string>--quiet</string>
  </array>
  <key>StartInterval</key>
  <integer>60</integer>
  <key>RunAtLoad</key>
  <true/>
  <key>StandardOutPath</key>
  <string>$STATE_DIR/worker-auto-respawn-watchdog.out.log</string>
  <key>StandardErrorPath</key>
  <string>$STATE_DIR/worker-auto-respawn-watchdog.err.log</string>
</dict>
</plist>
EOF
}

emit() {
  local payload="$1"
  if (( JSON_OUT )); then
    printf '%s\n' "$payload"
  elif (( ! QUIET )); then
    printf '%s\n' "$payload" | jq -r '"worker-auto-respawn-watchdog-install label=\(.label) domain=\(.bootstrap_domain) loaded=\(.loaded) dry_run=\(.dry_run)"'
  fi
}

install_plist() {
  local loaded=false print_exit=1 plutil_exit=0
  if (( APPLY )); then
    write_plist
    if command -v "$PLUTIL" >/dev/null 2>&1; then
      "$PLUTIL" -lint "$PLIST_PATH" >/dev/null || plutil_exit=$?
    fi
    "$LAUNCHCTL" bootout "$BOOTSTRAP_DOMAIN/$LABEL" >/dev/null 2>&1 || true
    "$LAUNCHCTL" bootstrap "$BOOTSTRAP_DOMAIN" "$PLIST_PATH"
    "$LAUNCHCTL" kickstart -k "$BOOTSTRAP_DOMAIN/$LABEL" >/dev/null 2>&1 || true
    if "$LAUNCHCTL" print "$BOOTSTRAP_DOMAIN/$LABEL" >/dev/null 2>&1; then loaded=true; print_exit=0; fi
  fi
  emit "$(jq -nc --arg schema_version "$SCHEMA_VERSION" --arg version "$VERSION" \
    --arg label "$LABEL" --arg plist "$PLIST_PATH" --arg domain "$BOOTSTRAP_DOMAIN" \
    --arg watchdog "$WATCHDOG" --argjson dry_run "$([[ "$APPLY" == "1" ]] && echo false || echo true)" \
    --argjson apply "$APPLY" --argjson loaded "$loaded" --argjson print_exit "$print_exit" \
    --argjson plutil_exit "$plutil_exit" \
    '{schema_version:$schema_version,version:$version,success:($plutil_exit==0),
      label:$label,plist_path:$plist,bootstrap_domain:$domain,gui_domain:($domain|startswith("gui/")),
      watchdog:$watchdog,interval_seconds:60,dry_run:$dry_run,apply:$apply,
      loaded:$loaded,launchctl_print_exit:$print_exit,plutil_exit:$plutil_exit}')"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) APPLY=1; shift ;;
    --dry-run) APPLY=0; shift ;;
    --json) JSON_OUT=1; shift ;;
    --quiet) QUIET=1; shift ;;
    --info) MODE="info"; shift ;;
    --examples) MODE="examples"; shift ;;
    --help|-h) MODE="help"; shift ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$MODE" in
  info) info_json ;;
  examples) examples ;;
  help) usage ;;
  install) install_plist ;;
esac
