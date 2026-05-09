#!/usr/bin/env bash
set -euo pipefail

script="/Users/josh/.claude/skills/.flywheel/scripts/idle-drifted-panes.sh"
plist="/Users/josh/Library/LaunchAgents/com.zeststream.flywheel-idle-pane-watch.plist"
config="/Users/josh/.claude/skills/.flywheel/config/plist-classes.json"
doctor="/Users/josh/.claude/skills/.flywheel/bin/flywheel"

test -x "$script"
bash -n "$script"

rg -n 'IPW_SCRIPT="\$HOME/\.claude/skills/\.flywheel/scripts/idle-drifted-panes\.sh"|idle-pane-watch invariant' "$doctor" >/dev/null
/usr/libexec/PlistBuddy -c 'Print :ProgramArguments:2' "$plist" | rg -x "$script" >/dev/null
jq -e '.classes."com.zeststream.flywheel-idle-pane-watch".class == "HEALTHY"' "$config" >/dev/null

tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-2xdi.3-l112.XXXXXX")"
trap 'rm -rf "$tmp_dir"' EXIT

topology="$tmp_dir/session-topology.jsonl"
sentinel="$tmp_dir/idle-pane-last-notify.txt"
stderr="$tmp_dir/stderr.json"

cat >"$topology" <<'JSON'
{"session":"flywheel-l112-fixture","worker_panes":[2],"orchestrator_pane":0,"callback_pane":1,"human_pane":0}
JSON

FLYWHEEL_SESSION_TOPOLOGY="$topology" \
IDLE_PANE_SENTINEL="$sentinel" \
NOTIFY_BIN="/bin/false" \
"$script" 2>"$stderr" >/dev/null

jq -e '.all_idle == false and .ready_count == 0 and .topology_file == "'"$topology"'"' "$stderr" >/dev/null

printf 'OK_idle_drifted_panes_load_bearing\n'
