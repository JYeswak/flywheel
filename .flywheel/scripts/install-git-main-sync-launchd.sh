#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage: install-git-main-sync-launchd.sh --repo PATH (--dry-run|--apply|--status|--uninstall) [--json]
USAGE
}

json_escape() {
  local value=${1-}
  value=${value//\\/\\\\}
  value=${value//\"/\\\"}
  value=${value//$'\n'/\\n}
  value=${value//$'\r'/\\r}
  value=${value//$'\t'/\\t}
  printf '%s' "$value"
}

json_string() {
  printf '"%s"' "$(json_escape "${1-}")"
}

xml_escape() {
  local value=${1-}
  value=${value//&/&amp;}
  value=${value//</&lt;}
  value=${value//>/&gt;}
  value=${value//\"/&quot;}
  value=${value//\'/&apos;}
  printf '%s' "$value"
}

emit_json() {
  printf '{'
  printf '"schema":"git_main_sync_launchd.v1"'
  printf ',"ts":'
  json_string "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf ',"repo":'
  json_string "$repo"
  printf ',"mode":'
  json_string "$mode"
  printf ',"outcome":'
  json_string "$outcome"
  printf ',"reason":'
  json_string "$reason"
  printf ',"label":'
  json_string "$label"
  printf ',"plist_path":'
  json_string "$plist_path"
  printf ',"log_path":'
  json_string "$stdout_log"
  printf ',"interval_seconds":%s' "$interval_seconds"
  printf ',"cadence_started":%s' "$cadence_started"
  printf '}'
  printf '\n'
}

render_plist() {
  cat <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$(xml_escape "$label")</string>
  <key>ProgramArguments</key>
  <array>
    <string>$(xml_escape "$sync_script")</string>
    <string>--repo</string>
    <string>$(xml_escape "$repo")</string>
    <string>--apply</string>
    <string>--json</string>
  </array>
  <key>StartInterval</key>
  <integer>$interval_seconds</integer>
  <key>StandardOutPath</key>
  <string>$(xml_escape "$stdout_log")</string>
  <key>StandardErrorPath</key>
  <string>$(xml_escape "$stderr_log")</string>
  <key>WorkingDirectory</key>
  <string>$(xml_escape "$repo")</string>
</dict>
</plist>
PLIST
}

repo=""
mode=""
json=0
interval_seconds=${GIT_MAIN_SYNC_INTERVAL_SECONDS:-1800}
launch_agents_dir=${GIT_MAIN_SYNC_LAUNCH_AGENTS_DIR:-$HOME/Library/LaunchAgents}
state_dir=${GIT_MAIN_SYNC_STATE_DIR:-$HOME/.local/state/flywheel/git-main-sync}
launchctl_bin=${GIT_MAIN_SYNC_LAUNCHCTL:-launchctl}
cadence_started=false
outcome="dry-run"
reason=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      [[ $# -ge 2 ]] || { usage; exit 2; }
      repo=$2
      shift 2
      ;;
    --dry-run|--apply|--status|--uninstall)
      mode=${1#--}
      shift
      ;;
    --json)
      json=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      exit 2
      ;;
  esac
done

if [[ -z $repo || -z $mode ]]; then
  usage
  exit 2
fi

if [[ ! -d $repo ]]; then
  repo=$(cd "$(dirname "$repo")" 2>/dev/null && pwd -P)/$(basename "$repo")
else
  repo=$(cd "$repo" && pwd -P)
fi

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
sync_script="$script_dir/git-main-sync.sh"
repo_name=$(basename "$repo")
label_suffix=$(printf '%s' "$repo_name" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9._-' '-')
label="ai.zeststream.git-main-sync.$label_suffix"
plist_path="$launch_agents_dir/$label.plist"
stdout_log="$state_dir/$repo_name.log"
stderr_log="$state_dir/$repo_name.err.log"

if [[ ! -x $sync_script ]]; then
  outcome="error"
  reason="sync-script-not-executable"
  emit_json
  exit 1
fi

tmp_plist=$(mktemp)
trap 'rm -f "$tmp_plist"' EXIT
render_plist > "$tmp_plist"
if command -v plutil >/dev/null 2>&1; then
  plutil -lint "$tmp_plist" >/dev/null
fi

case "$mode" in
  dry-run)
    outcome="dry-run"
    reason="plist-install-planned"
    ;;
  status)
    if [[ -f $plist_path ]]; then
      outcome="installed"
      reason="plist-present"
    else
      outcome="missing"
      reason="plist-missing"
    fi
    ;;
  uninstall)
    if [[ -f $plist_path ]]; then
      mkdir -p "$launch_agents_dir" "$state_dir"
      "$launchctl_bin" bootout "gui/$(id -u)" "$plist_path" >/dev/null 2>&1 || true
      rm -f "$plist_path"
      outcome="uninstalled"
      reason="plist-removed"
    else
      outcome="missing"
      reason="plist-missing"
    fi
    ;;
  apply)
    mkdir -p "$launch_agents_dir" "$state_dir"
    if [[ -f $plist_path ]] && cmp -s "$tmp_plist" "$plist_path"; then
      outcome="unchanged"
      reason="plist-already-current"
    else
      cp "$tmp_plist" "$plist_path"
      "$launchctl_bin" bootout "gui/$(id -u)" "$plist_path" >/dev/null 2>&1 || true
      "$launchctl_bin" bootstrap "gui/$(id -u)" "$plist_path"
      cadence_started=true
      outcome="installed"
      reason="plist-written"
    fi
    ;;
esac

if [[ $json -eq 1 ]]; then
  emit_json
else
  emit_json
fi
