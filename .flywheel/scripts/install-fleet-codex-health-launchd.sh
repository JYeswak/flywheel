#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
LABEL="ai.zeststream.fleet-codex-health"
SOURCE="${FLEET_CODEX_HEALTH_SOURCE_PLIST:-$ROOT/.flywheel/launchd/$LABEL.plist}"
TARGET="${FLEET_CODEX_HEALTH_TARGET_PLIST:-$HOME/Library/LaunchAgents/$LABEL.plist}"
LAUNCHCTL="${FLEET_CODEX_HEALTH_LAUNCHCTL:-launchctl}"
DOMAIN="${FLEET_CODEX_HEALTH_DOMAIN:-gui/$(id -u)}"
APPLY=0
UNINSTALL=0
JSON_OUT=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) APPLY=1; shift ;;
    --dry-run) APPLY=0; shift ;;
    --uninstall) UNINSTALL=1; shift ;;
    --json) JSON_OUT=1; shift ;;
    *) shift ;;
  esac
done

loaded=false
"$LAUNCHCTL" print "$DOMAIN/$LABEL" >/dev/null 2>&1 && loaded=true
backup=""
action="would_install"

if [[ "$UNINSTALL" -eq 1 ]]; then
  action="would_uninstall"
  if [[ "$APPLY" -eq 1 ]]; then
    action="uninstalled"
    "$LAUNCHCTL" bootout "$DOMAIN/$LABEL" >/dev/null 2>&1 || true
    if [[ -f "$TARGET" ]]; then
      backup="$TARGET.backup.$(date -u +%Y%m%dT%H%M%SZ)"
      cp "$TARGET" "$backup"
      rm -f "$TARGET"
    fi
    loaded=false
  fi
elif [[ "$APPLY" -eq 1 ]]; then
  mkdir -p "$(dirname "$TARGET")"
  if [[ -f "$TARGET" ]]; then
    backup="$TARGET.backup.$(date -u +%Y%m%dT%H%M%SZ)"
    cp "$TARGET" "$backup"
  fi
  cp "$SOURCE" "$TARGET"
  plutil -lint "$TARGET" >/dev/null
  "$LAUNCHCTL" bootout "$DOMAIN/$LABEL" >/dev/null 2>&1 || true
  "$LAUNCHCTL" bootstrap "$DOMAIN" "$TARGET"
  "$LAUNCHCTL" kickstart -k "$DOMAIN/$LABEL" >/dev/null 2>&1 || true
  "$LAUNCHCTL" print "$DOMAIN/$LABEL" >/dev/null 2>&1 && loaded=true
  action="installed"
fi

if [[ "$JSON_OUT" -eq 1 ]]; then
  jq -nc --arg label "$LABEL" --arg source "$SOURCE" --arg target "$TARGET" --arg backup "$backup" --arg action "$action" --argjson apply "$APPLY" --argjson loaded "$loaded" \
    '{schema_version:"flywheel.fleet_codex_health.launchd_install.v1",label:$label,source:$source,target:$target,backup:($backup|if length>0 then . else null end),action:$action,applied:($apply==1),loaded:$loaded,success:(($apply==0) or $loaded or ($action=="uninstalled"))}'
else
  printf 'fleet-codex-health launchd action=%s loaded=%s target=%s\n' "$action" "$loaded" "$TARGET"
fi
