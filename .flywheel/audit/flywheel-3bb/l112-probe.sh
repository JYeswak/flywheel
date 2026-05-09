#!/usr/bin/env bash
set -euo pipefail

repo="${1:-/Users/josh/Developer/flywheel}"
cd "$repo"

if /Users/josh/.local/bin/ntm list --json \
  | jq -e '[.sessions[].name] | any(. == "zeststream-v2")' >/dev/null; then
  printf 'ZESTSTREAM_V2_NTM_SESSION_PRESENT\n'
  exit 1
fi

if tmux list-sessions -F '#{session_name}' 2>/dev/null | grep -qx 'zeststream-v2'; then
  printf 'ZESTSTREAM_V2_TMUX_SESSION_PRESENT\n'
  exit 1
fi

latest_sessions="$(
  jq -sr 'sort_by(.effective_at) | group_by(.session) | map(max_by(.effective_at)) | map(.session)' \
    ~/.local/state/flywheel/session-topology.jsonl
)"
jq -e 'index("zeststream-v2") | not' >/dev/null <<<"$latest_sessions"

if launchctl list 2>/dev/null | grep -q 'zeststream-v2'; then
  printf 'ZESTSTREAM_V2_LAUNCHD_LABEL_PRESENT\n'
  exit 1
fi

printf 'OK_zeststream_v2_teardown_confirmed\n'
