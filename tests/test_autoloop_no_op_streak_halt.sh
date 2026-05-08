#!/usr/bin/env bash
set -euo pipefail

BIN="${FLYWHEEL_AUTOLOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-autoloop}"
TMP="$(mktemp -d -t autoloop-exec.XXXXXX)"
trap 'rm -r "$TMP"' EXIT

mkdir -p "$TMP/fw" "$TMP/state"
if HOME="$TMP/home" FLYWHEEL_HOME="$TMP/fw" FLYWHEEL_AUTOLOOP_STATE_DIR="$TMP/state" \
  "$BIN" executor --no-op-streak 4 --json >"$TMP/out.json"; then
  printf 'FAIL no-op streak 4 unexpectedly returned success\n' >&2
  exit 1
fi

jq -e '.status == "halt" and .action == "halt" and .no_op_streak == 4 and (.halt_sentinel | type) == "string"' "$TMP/out.json" >/dev/null
halt="$(jq -r '.halt_sentinel' "$TMP/out.json")"
test -s "$halt"

jq -n --arg repo "$TMP/repo" '{repo:$repo,score:120,action:"summarize_dirty_worktree"}' >"$TMP/candidate.json"
if HOME="$TMP/home" FLYWHEEL_HOME="$TMP/fw" FLYWHEEL_AUTOLOOP_STATE_DIR="$TMP/state" \
  "$BIN" executor --candidate "$TMP/candidate.json" --json >"$TMP/halted.json"; then
  printf 'FAIL halted executor unexpectedly ran\n' >&2
  exit 1
fi
jq -e '.status == "halt" and .reason == "manual_unblock_required"' "$TMP/halted.json" >/dev/null

printf 'PASS autoloop no-op streak halt\n'
