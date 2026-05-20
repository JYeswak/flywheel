#!/usr/bin/env bash
set -euo pipefail

VERSION="install-pane1-bridge-tailer-launchd.v0.1.0"
SCHEMA_VERSION="flywheel.pane1-bridge-tailer.launchd-install.v1"

LABEL="${PANE1_BRIDGE_LABEL:-ai.zeststream.flywheel-pane1-bridge-tailer}"
REPO_ROOT="${PANE1_BRIDGE_REPO:-/Users/josh/Developer/flywheel}"
TAILER="${PANE1_BRIDGE_TAILER:-$REPO_ROOT/.flywheel/scripts/pane1-bridge-tailer.sh}"
LAUNCH_AGENTS_DIR="${PANE1_BRIDGE_LAUNCH_AGENTS_DIR:-$HOME/Library/LaunchAgents}"
LAUNCHCTL="${PANE1_BRIDGE_LAUNCHCTL:-launchctl}"
PLUTIL="${PANE1_BRIDGE_PLUTIL:-plutil}"
WATCHERS_BIN="${PANE1_BRIDGE_WATCHERS_BIN:-$HOME/.local/bin/flywheel-watchers}"
LOG_DIR="${PANE1_BRIDGE_LOG_DIR:-$HOME/.local/state/flywheel/launchd}"
BOOTSTRAP_DOMAIN="${PANE1_BRIDGE_BOOTSTRAP_DOMAIN:-gui/$(id -u)}"
PATH_VALUE="${PANE1_BRIDGE_PATH:-/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$HOME/.local/bin}"
TODAY_UTC="${PANE1_BRIDGE_LOG_DATE:-$(date -u +%Y%m%d)}"
PLIST="$LAUNCH_AGENTS_DIR/$LABEL.plist"
STDOUT_PATH="$LOG_DIR/pane1-bridge-tailer-$TODAY_UTC.stdout.log"
STDERR_PATH="$LOG_DIR/pane1-bridge-tailer-$TODAY_UTC.stderr.log"

MODE="install"
APPLY=0
JSON_OUT=0

usage() {
  cat <<USAGE
Usage:
  install-pane1-bridge-tailer-launchd.sh --dry-run|--apply [--json]
  install-pane1-bridge-tailer-launchd.sh --uninstall --dry-run|--apply [--json]
  install-pane1-bridge-tailer-launchd.sh --status [--json]

Installs $LABEL as a per-user LaunchAgent that runs:
  $TAILER --follow
USAGE
}

json_bool() {
  [[ "${1:-false}" == "true" ]] && printf 'true' || printf 'false'
}

loaded_label() {
  "$LAUNCHCTL" print "$BOOTSTRAP_DOMAIN/$LABEL" >/dev/null 2>&1
}

render_plist() {
  local target="$1"
  mkdir -p "$(dirname "$target")" "$LOG_DIR"
  cat >"$target" <<PLIST_XML
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$TAILER</string>
    <string>--follow</string>
  </array>
  <key>WorkingDirectory</key>
  <string>$REPO_ROOT</string>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>EnvironmentVariables</key>
  <dict>
    <key>HOME</key>
    <string>$HOME</string>
    <key>PATH</key>
    <string>$PATH_VALUE</string>
  </dict>
  <key>StandardOutPath</key>
  <string>$STDOUT_PATH</string>
  <key>StandardErrorPath</key>
  <string>$STDERR_PATH</string>
</dict>
</plist>
PLIST_XML
}

backup_existing() {
  local backup=""
  if [[ -f "$PLIST" ]]; then
    backup="$PLIST.backup.$(date -u +%Y%m%dT%H%M%SZ)"
    cp "$PLIST" "$backup"
  fi
  printf '%s\n' "$backup"
}

ensure_registered() {
  [[ -x "$WATCHERS_BIN" ]] || return 0
  if "$WATCHERS_BIN" registry --json 2>/dev/null | jq -e --arg label "$LABEL" '.active[]? | select(.label == $label and (.active // true))' >/dev/null; then
    return 0
  fi
  "$WATCHERS_BIN" register \
    --label "$LABEL" \
    --owner flywheel-orch \
    --reason "pane1 bridge callback tailer launchd daemon" \
    --bead flywheel-yo59t \
    --apply \
    --idempotency-key "pane1-bridge-tailer-launchd-flywheel-yo59t" \
    --json >/dev/null
}

emit_json() {
  local status="$1" action="$2" dry_run="$3" backup_path="$4" loaded="$5" target_exists="$6" lint_ok="$7" bootout="$8" bootstrap="$9" kickstart="${10}"
  local applied=false
  [[ "$dry_run" == true ]] || applied=true
  jq -nc \
    --arg schema "$SCHEMA_VERSION" \
    --arg version "$VERSION" \
    --arg status "$status" \
    --arg action "$action" \
    --arg label "$LABEL" \
    --arg plist "$PLIST" \
    --arg tailer "$TAILER" \
    --arg bootstrap_domain "$BOOTSTRAP_DOMAIN" \
    --arg stdout_path "$STDOUT_PATH" \
    --arg stderr_path "$STDERR_PATH" \
    --arg backup_path "$backup_path" \
    --argjson dry_run "$(json_bool "$dry_run")" \
    --argjson applied "$(json_bool "$applied")" \
    --argjson loaded "$(json_bool "$loaded")" \
    --argjson target_exists "$(json_bool "$target_exists")" \
    --argjson plist_lint_ok "$(json_bool "$lint_ok")" \
    --argjson bootout_called "$(json_bool "$bootout")" \
    --argjson bootstrap_called "$(json_bool "$bootstrap")" \
    --argjson kickstart_called "$(json_bool "$kickstart")" \
    '{success:($status=="pass"),schema_version:$schema,version:$version,status:$status,action:$action,dry_run:$dry_run,applied:$applied,label:$label,plist_path:$plist,tailer:$tailer,bootstrap_domain:$bootstrap_domain,stdout_path:$stdout_path,stderr_path:$stderr_path,backup_path:($backup_path|if length > 0 then . else null end),loaded:$loaded,target_exists:$target_exists,plist_lint_ok:$plist_lint_ok,bootout_called:$bootout_called,bootstrap_called:$bootstrap_called,kickstart_called:$kickstart_called}'
}

emit_text() {
  local status="$1" action="$2" loaded="$3"
  printf '%s action=%s label=%s loaded=%s plist=%s\n' "$status" "$action" "$LABEL" "$loaded" "$PLIST"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply)
      APPLY=1; shift ;;
    --dry-run)
      APPLY=0; shift ;;
    --uninstall)
      MODE="uninstall"; shift ;;
    --status|status)
      MODE="status"; shift ;;
    --json)
      JSON_OUT=1; shift ;;
    --help|-h)
      usage; exit 0 ;;
    --version)
      printf '%s\n' "$VERSION"; exit 0 ;;
    *)
      echo "ERR: unknown argument: $1" >&2
      usage >&2
      exit 2 ;;
  esac
done

loaded=false
loaded_label && loaded=true
target_exists=false
[[ -f "$PLIST" ]] && target_exists=true
lint_ok=false
[[ -f "$PLIST" ]] && "$PLUTIL" -lint "$PLIST" >/dev/null 2>&1 && lint_ok=true
bootout=false
bootstrap=false
kickstart=false
backup_path=""
action="already_current"

if [[ "$MODE" == "status" ]]; then
  [[ "$JSON_OUT" -eq 1 ]] && emit_json pass status true "" "$loaded" "$target_exists" "$lint_ok" false false false || emit_text pass status "$loaded"
  exit 0
fi

if [[ "$MODE" == "uninstall" ]]; then
  action="would_uninstall"
  if [[ "$APPLY" -eq 1 ]]; then
    action="uninstalled"
    if [[ "$loaded" == true ]]; then
      "$LAUNCHCTL" bootout "$BOOTSTRAP_DOMAIN/$LABEL" >/dev/null 2>&1 || true
      bootout=true
    fi
    backup_path="$(backup_existing)"
    rm -f "$PLIST"
    loaded=false
    loaded_label && loaded=true
    target_exists=false
    [[ -f "$PLIST" ]] && target_exists=true
    lint_ok=false
  fi
  [[ "$JSON_OUT" -eq 1 ]] && emit_json pass "$action" "$([[ "$APPLY" -eq 1 ]] && echo false || echo true)" "$backup_path" "$loaded" "$target_exists" "$lint_ok" "$bootout" false false || emit_text pass "$action" "$loaded"
  exit 0
fi

if [[ ! -x "$TAILER" ]]; then
  [[ "$JSON_OUT" -eq 1 ]] && emit_json fail missing_tailer true "" "$loaded" "$target_exists" "$lint_ok" false false false || echo "ERR: tailer is not executable: $TAILER" >&2
  exit 3
fi

tmp_plist="$(mktemp "${TMPDIR:-/tmp}/pane1-bridge-tailer.XXXXXX.plist")"
trap 'rm -f "$tmp_plist"' EXIT
render_plist "$tmp_plist"
"$PLUTIL" -lint "$tmp_plist" >/dev/null

changed=true
[[ -f "$PLIST" ]] && cmp -s "$tmp_plist" "$PLIST" && changed=false
if [[ "$APPLY" -eq 0 ]]; then
  if [[ "$target_exists" != true ]]; then
    action="would_install_and_bootstrap"
  elif [[ "$changed" == true ]]; then
    action="would_replace_and_reload"
  elif [[ "$loaded" != true ]]; then
    action="would_bootstrap"
  else
    action="already_current"
  fi
  [[ "$JSON_OUT" -eq 1 ]] && emit_json pass "$action" true "" "$loaded" "$target_exists" "$lint_ok" false false false || emit_text pass "$action" "$loaded"
  exit 0
fi

mkdir -p "$LAUNCH_AGENTS_DIR" "$LOG_DIR"
if [[ "$changed" == true || "$target_exists" != true ]]; then
  backup_path="$(backup_existing)"
  cp "$tmp_plist" "$PLIST"
  action="installed"
else
  action="already_current"
fi

if [[ "$loaded" == true && "$changed" == true ]]; then
  "$LAUNCHCTL" bootout "$BOOTSTRAP_DOMAIN/$LABEL" >/dev/null 2>&1 || true
  bootout=true
  loaded=false
fi
if [[ "$loaded" != true ]]; then
  ensure_registered
  "$LAUNCHCTL" bootstrap "$BOOTSTRAP_DOMAIN" "$PLIST"
  bootstrap=true
fi
"$LAUNCHCTL" kickstart -k "$BOOTSTRAP_DOMAIN/$LABEL" >/dev/null 2>&1 || true
kickstart=true

loaded=false
loaded_label && loaded=true
target_exists=false
[[ -f "$PLIST" ]] && target_exists=true
lint_ok=false
[[ -f "$PLIST" ]] && "$PLUTIL" -lint "$PLIST" >/dev/null 2>&1 && lint_ok=true

status="pass"
[[ "$loaded" == true && "$target_exists" == true && "$lint_ok" == true ]] || status="fail"
[[ "$JSON_OUT" -eq 1 ]] && emit_json "$status" "$action" false "$backup_path" "$loaded" "$target_exists" "$lint_ok" "$bootout" "$bootstrap" "$kickstart" || emit_text "$status" "$action" "$loaded"
[[ "$status" == "pass" ]]
