#!/usr/bin/env bash
set -euo pipefail

HOOK="${JOSH_REQUEST_CAPTURE_HOOK:-$HOME/.claude/hooks/josh-request-capture.sh}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0

ok() {
  local name="$1"; shift
  if "$@"; then
    pass=$((pass + 1)); printf 'ok %d - %s\n' "$pass" "$name"
  else
    fail=$((fail + 1)); printf 'not ok %d - %s\n' "$((pass + fail))" "$name"
  fi
}

ok_jq() {
  local name="$1" expr="$2" file="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass=$((pass + 1)); printf 'ok %d - %s\n' "$pass" "$name"
  else
    fail=$((fail + 1)); printf 'not ok %d - %s\n' "$((pass + fail))" "$name"
    jq . "$file" >&2 || true
  fi
}

repo="$TMP/repo"
mkdir -p "$repo/.flywheel"
cat >"$repo/.flywheel/MISSION.md" <<'MD'
# Mission

schema_version: 1
status: locked
lock_hash: fixture

## Joshua Requests

journal split out 2026-05-20 per frozen-projection class.
Archived mirror: `.flywheel/josh-requests-archive/2026-05.md`.
MD
before_hash="$(shasum -a 256 "$repo/.flywheel/MISSION.md" | awk '{print $1}')"

state="$TMP/josh-requests.jsonl"
input="$TMP/input.json"
jq -nc \
  --arg cwd "$repo" \
  --arg prompt "please fix the capture archive path" \
  '{cwd:$cwd,prompt:$prompt,session_id:"fixture-session",pane:null,transcript_path:"/tmp/transcript.jsonl",message_id:"msg-1"}' \
  >"$input"

JOSH_REQUEST_REPO="$repo" \
JOSH_REQUEST_STATE_FILE="$state" \
JOSH_REQUEST_NOW="2026-05-20T01:02:03Z" \
  "$HOOK" <"$input" >/dev/null

archive="$repo/.flywheel/josh-requests-archive/2026-05.md"
after_hash="$(shasum -a 256 "$repo/.flywheel/MISSION.md" | awk '{print $1}')"

ok "hook syntax" bash -n "$HOOK"
ok "mission left untouched" test "$before_hash" = "$after_hash"
ok "archive created" test -s "$archive"
ok "archive contains request row" grep -Eq '^### jr-2026-05-20T010203Z-[0-9]{3}$' "$archive"
ok_jq "jsonl row written" '(.id|test("^jr-2026-05-20T010203Z-[0-9]{3}$")) and .state=="needs_triage"' "$state"

printf 'SUMMARY pass=%d fail=%d\n' "$pass" "$fail"
[[ "$fail" -eq 0 && "$pass" -ge 5 ]]
