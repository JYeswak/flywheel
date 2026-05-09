#!/usr/bin/env bash
set -euo pipefail

tmp="$(mktemp "${TMPDIR:-/tmp}/flywheel-se7p-gh.XXXXXX.json")"
trap 'rm -f "$tmp"' EXIT

gh issue view 109 \
  --repo Dicklesworthstone/destructive_command_guard \
  --json number,title,state,url,comments \
  --comments >"$tmp"

jq -e '
  .number == 109
  and .state == "CLOSED"
  and (.url | contains("/destructive_command_guard/issues/109"))
  and ([.comments[].body] | any(contains("f3c96bd")) and any(contains("a739dc9")))
' "$tmp" >/dev/null

printf 'pass\n'
