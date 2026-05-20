#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
Usage: install-review-branch-mergeback-launchd.sh --repo PATH --branch BRANCH (--dry-run|--apply|--status|--uninstall) [--base main] [--hour 20] [--minute 30] [--json]
USAGE
}

json_escape() {
  local value=${1-}
  value=${value//\\/\\\\}; value=${value//\"/\\\"}; value=${value//$'\n'/\\n}; value=${value//$'\r'/\\r}; value=${value//$'\t'/\\t}
  printf '%s' "$value"
}
json_string() { printf '"%s"' "$(json_escape "${1-}")"; }
xml_escape() {
  local value=${1-}
  value=${value//&/&amp;}; value=${value//</&lt;}; value=${value//>/&gt;}; value=${value//\"/&quot;}; value=${value//\'/&apos;}
  printf '%s' "$value"
}

emit_json() {
  printf '{"schema_version":"review_branch_mergeback_launchd.v1","repo":'
  json_string "$repo"; printf ',"branch":'; json_string "$branch"; printf ',"base":'; json_string "$base"
  printf ',"mode":'; json_string "$mode"; printf ',"outcome":'; json_string "$outcome"; printf ',"reason":'; json_string "$reason"
  printf ',"label":'; json_string "$label"; printf ',"plist_path":'; json_string "$plist_path"
  printf ',"hour":%s,"minute":%s,"cadence_started":%s}\n' "$hour" "$minute" "$cadence_started"
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
    <string>$(xml_escape "$runner")</string>
    <string>run</string>
    <string>--repo</string>
    <string>$(xml_escape "$repo")</string>
    <string>--branch</string>
    <string>$(xml_escape "$branch")</string>
    <string>--base</string>
    <string>$(xml_escape "$base")</string>
    <string>--apply</string>
    <string>--push</string>
    <string>--conflict-action</string>
    <string>issue</string>
    <string>--json</string>
  </array>
  <key>StartCalendarInterval</key>
  <dict>
    <key>Hour</key>
    <integer>$hour</integer>
    <key>Minute</key>
    <integer>$minute</integer>
  </dict>
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

repo=""; branch=""; base="main"; mode=""; json=0; hour=${REVIEW_BRANCH_MERGEBACK_HOUR:-20}; minute=${REVIEW_BRANCH_MERGEBACK_MINUTE:-30}
launch_agents_dir=${REVIEW_BRANCH_MERGEBACK_LAUNCH_AGENTS_DIR:-$HOME/Library/LaunchAgents}
state_dir=${REVIEW_BRANCH_MERGEBACK_STATE_DIR:-$HOME/.local/state/flywheel/review-branch-mergeback}
launchctl_bin=${REVIEW_BRANCH_MERGEBACK_LAUNCHCTL:-launchctl}
cadence_started=false; outcome="dry-run"; reason=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) repo=$2; shift 2 ;;
    --branch) branch=$2; shift 2 ;;
    --base) base=$2; shift 2 ;;
    --hour) hour=$2; shift 2 ;;
    --minute) minute=$2; shift 2 ;;
    --dry-run|--apply|--status|--uninstall) mode=${1#--}; shift ;;
    --json) json=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
done
: "${json:=0}"
[[ -n $repo && -n $branch && -n $mode ]] || { usage; exit 2; }
repo=$(cd "$repo" && pwd -P)
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
runner="$script_dir/review-branch-mergeback.sh"
safe_branch=$(printf '%s' "$branch" | tr '[:upper:]/' '[:lower:]-' | tr -c 'a-z0-9._-' '-')
label="ai.zeststream.review-branch-mergeback.$(basename "$repo").$safe_branch"
plist_path="$launch_agents_dir/$label.plist"
stdout_log="$state_dir/$(basename "$repo")-$safe_branch.log"
stderr_log="$state_dir/$(basename "$repo")-$safe_branch.err.log"

[[ -x $runner ]] || { outcome="error"; reason="runner-not-executable"; emit_json; exit 1; }
tmp_plist=$(mktemp)
trap 'rm -f "$tmp_plist"' EXIT
render_plist > "$tmp_plist"
command -v plutil >/dev/null 2>&1 && plutil -lint "$tmp_plist" >/dev/null

case "$mode" in
  dry-run) outcome="dry-run"; reason="plist-install-planned" ;;
  status) [[ -f $plist_path ]] && outcome="installed" reason="plist-present" || outcome="missing" reason="plist-missing" ;;
  uninstall)
    if [[ -f $plist_path ]]; then "$launchctl_bin" bootout "gui/$(id -u)" "$plist_path" >/dev/null 2>&1 || true; rm -f "$plist_path"; outcome="uninstalled"; reason="plist-removed"; else outcome="missing"; reason="plist-missing"; fi
    ;;
  apply)
    mkdir -p "$launch_agents_dir" "$state_dir"
    if [[ -f $plist_path ]] && cmp -s "$tmp_plist" "$plist_path"; then outcome="unchanged"; reason="plist-already-current"; else cp "$tmp_plist" "$plist_path"; "$launchctl_bin" bootout "gui/$(id -u)" "$plist_path" >/dev/null 2>&1 || true; "$launchctl_bin" bootstrap "gui/$(id -u)" "$plist_path"; cadence_started=true; outcome="installed"; reason="plist-written"; fi
    ;;
esac
emit_json
