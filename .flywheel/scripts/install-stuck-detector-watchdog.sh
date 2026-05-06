#!/usr/bin/env bash
set -euo pipefail

LABEL="ai.zeststream.codex-stuck-detector-watchdog"
SOURCE_PLIST="${STUCK_DETECTOR_WATCHDOG_SOURCE_PLIST:-/Users/josh/Developer/flywheel/.flywheel/scripts/codex-template-stuck-detector-watchdog.plist}"
TARGET_PLIST="${STUCK_DETECTOR_WATCHDOG_TARGET_PLIST:-$HOME/Library/LaunchAgents/${LABEL}.plist}"
INSTALL_LOG="${STUCK_DETECTOR_WATCHDOG_INSTALL_LOG:-$HOME/.local/state/flywheel/watcher-launchd-install.jsonl}"
LAUNCHCTL="${STUCK_DETECTOR_WATCHDOG_LAUNCHCTL:-launchctl}"
PLUTIL="${STUCK_DETECTOR_WATCHDOG_PLUTIL:-plutil}"
WATCHERS_BIN="${STUCK_DETECTOR_WATCHERS_BIN:-$HOME/.local/bin/flywheel-watchers}"
BEAD_ID="${STUCK_DETECTOR_WATCHDOG_BEAD:-flywheel-2jvz2}"
BOOTSTRAP_DOMAIN="${STUCK_DETECTOR_WATCHDOG_BOOTSTRAP_DOMAIN:-gui/$UID}"
LEGACY_DOMAIN="${STUCK_DETECTOR_WATCHDOG_LEGACY_DOMAIN:-user/$UID}"
PRINT_DOMAIN="$BOOTSTRAP_DOMAIN"
BOOTSTRAP_TARGET="$BOOTSTRAP_DOMAIN/$LABEL"
LEGACY_TARGET="$LEGACY_DOMAIN/$LABEL"
PRINT_TARGET="$PRINT_DOMAIN/$LABEL"
ENABLE=1
DRY_RUN=0
JSON_OUT=0

usage() {
  cat <<'EOF'
usage: install-stuck-detector-watchdog.sh [--enable] [--dry-run] [--json]

Copies and enables the watchdog plist idempotently. The installed LaunchAgent
uses the stable label ai.zeststream.codex-stuck-detector-watchdog.
EOF
}

loaded() {
  "$LAUNCHCTL" print "$PRINT_TARGET" >/dev/null 2>&1
}

legacy_loaded() {
  "$LAUNCHCTL" print "$LEGACY_TARGET" >/dev/null 2>&1
}

status_json() {
  local copied="$1" loaded_state="$2" enabled="$3" dry="$4" print_exit="$5" interval="$6"
  jq -nc \
    --arg label "$LABEL" \
    --arg source "$SOURCE_PLIST" \
    --arg target "$TARGET_PLIST" \
    --arg bootstrap_domain "$BOOTSTRAP_DOMAIN" \
    --arg print_domain "$PRINT_DOMAIN" \
    --arg install_log "$INSTALL_LOG" \
    --argjson copied "$copied" \
    --argjson loaded "$loaded_state" \
    --argjson enabled "$enabled" \
    --argjson dry_run "$dry" \
    --argjson print_exit "$print_exit" \
    --argjson interval "$interval" \
    '{schema_version:"codex-template-stuck-detector-watchdog.install.v1",label:$label,source_plist:$source,target_plist:$target,bootstrap_domain:$bootstrap_domain,print_domain:$print_domain,copied:$copied,loaded:$loaded,enabled:($enabled == 1),dry_run:($dry_run == 1),launchctl_print_exit:$print_exit,interval_sec:$interval,installer_idempotent:true,install_log:$install_log}'
}

write_target_plist() {
  local tmp="$1"
  python3 -c 'import plistlib, sys
src, target, label = sys.argv[1:4]
with open(src, "rb") as handle:
    data = plistlib.load(handle)
data["Label"] = label
data["RunAtLoad"] = True
data["StartInterval"] = 60
with open(target, "wb") as handle:
    plistlib.dump(data, handle, sort_keys=False)' "$SOURCE_PLIST" "$tmp" "$LABEL"
}

plist_interval() {
  python3 -c 'import plistlib, sys
with open(sys.argv[1], "rb") as handle:
    data = plistlib.load(handle)
print(int(data.get("StartInterval", 0)))' "$TARGET_PLIST"
}

append_install_log() {
  local print_exit="$1" interval="$2"
  mkdir -p "$(dirname "$INSTALL_LOG")"
  jq -nc \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg action "install" \
    --arg plist_path "$TARGET_PLIST" \
    --arg label "$LABEL" \
    --argjson launchctl_print_exit "$print_exit" \
    --argjson interval_sec "$interval" \
    '{ts:$ts,action:$action,plist_path:$plist_path,label:$label,launchctl_print_exit:$launchctl_print_exit,interval_sec:$interval_sec,installer_idempotent:true}' >>"$INSTALL_LOG"
}

ensure_registered() {
  [[ -x "$WATCHERS_BIN" ]] || return 0
  if "$WATCHERS_BIN" registry --json 2>/dev/null | jq -e --arg label "$LABEL" '.active[]? | select(.label == $label and (.active // true))' >/dev/null; then
    return 0
  fi
  "$WATCHERS_BIN" register \
    --label "$LABEL" \
    --owner flywheel-orch \
    --reason "watcher-launchd-enable schedule activation" \
    --bead "$BEAD_ID" \
    --apply \
    --idempotency-key "watcher-launchd-enable-${LABEL}" \
    --json >/dev/null
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --enable) ENABLE=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --json) JSON_OUT=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; exit 2 ;;
  esac
done

[[ -f "$SOURCE_PLIST" ]] || { printf 'missing source plist: %s\n' "$SOURCE_PLIST" >&2; exit 1; }
"$PLUTIL" -lint "$SOURCE_PLIST" >/dev/null

copied=false
if [[ "$DRY_RUN" -eq 0 ]]; then
  mkdir -p "$(dirname "$TARGET_PLIST")" "$HOME/.local/logs" "$(dirname "$INSTALL_LOG")"
  tmp="${TARGET_PLIST}.$$.$RANDOM.tmp"
  write_target_plist "$tmp"
  mv "$tmp" "$TARGET_PLIST"
  copied=true
  ensure_registered
fi

if [[ "$ENABLE" -eq 1 && "$DRY_RUN" -eq 0 ]]; then
  if loaded; then
    "$LAUNCHCTL" kickstart -k "$BOOTSTRAP_TARGET" >/dev/null 2>&1 || "$LAUNCHCTL" kickstart -k "$PRINT_TARGET" >/dev/null 2>&1 || true
  else
    if legacy_loaded; then
      "$LAUNCHCTL" bootout "$LEGACY_TARGET" >/dev/null 2>&1 || true
    fi
    "$LAUNCHCTL" bootstrap "$BOOTSTRAP_DOMAIN" "$TARGET_PLIST"
    "$LAUNCHCTL" kickstart -k "$BOOTSTRAP_TARGET" >/dev/null 2>&1 || "$LAUNCHCTL" kickstart -k "$PRINT_TARGET" >/dev/null 2>&1 || true
  fi
fi

loaded_state=false
print_exit=1
if "$LAUNCHCTL" print "$PRINT_TARGET" >/dev/null 2>&1; then
  loaded_state=true
  print_exit=0
fi

interval=60
if [[ -f "$TARGET_PLIST" ]]; then
  interval="$(plist_interval)"
fi

if [[ "$DRY_RUN" -eq 0 ]]; then
  append_install_log "$print_exit" "$interval"
fi

if [[ "$JSON_OUT" -eq 1 ]]; then
  status_json "$copied" "$loaded_state" "$ENABLE" "$DRY_RUN" "$print_exit" "$interval"
else
  printf 'label=%s copied=%s loaded=%s enabled=%s launchctl_print_exit=%s interval_sec=%s\n' "$LABEL" "$copied" "$loaded_state" "$ENABLE" "$print_exit" "$interval"
fi
