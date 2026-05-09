#!/usr/bin/env bash
set -euo pipefail

settings=/Users/josh/.claude/settings.json
hook=/Users/josh/.claude/hooks/npm-install-guard-hook.sh

jq empty "$settings"
jq -e '.hooks.PreToolUse[] | select(.matcher=="Bash") | .hooks[] | select(.command=="$HOME/.claude/hooks/npm-install-guard-hook.sh")' "$settings" >/dev/null

printf '%s' '{"tool_name":"Bash","tool_input":{"command":"npm install"}}' | "$hook" >/dev/null
printf '%s' '{"tool_name":"Bash","tool_input":{"command":"FLYWHEEL_NPM_FORCE=1 npm install -g @openai/codex"}}' | "$hook" >/dev/null

set +e
out="$(printf '%s' '{"tool_name":"Bash","tool_input":{"command":"npm install -g @openai/codex"}}' | "$hook" 2>&1)"
rc=$?
set -e

if [[ "$rc" -eq 2 ]]; then
  rg -q 'BLOCKED: codex processes running' <<<"$out"
elif [[ "$rc" -ne 0 ]]; then
  printf 'unexpected global-install hook rc=%s\n%s\n' "$rc" "$out" >&2
  exit 1
fi

printf 'pass\n'
