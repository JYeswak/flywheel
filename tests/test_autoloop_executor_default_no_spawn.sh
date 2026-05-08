#!/usr/bin/env bash
set -euo pipefail

BIN="${FLYWHEEL_AUTOLOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-autoloop}"
TMP="$(mktemp -d -t autoloop-exec.XXXXXX)"
trap 'rm -r "$TMP"' EXIT

mkdir -p "$TMP/fw" "$TMP/state" "$TMP/repo"
git -C "$TMP/repo" init -q
jq -n --arg repo "$TMP/repo" '{repo:$repo,score:100,action:"summarize_dirty_worktree"}' >"$TMP/candidate.json"

HOME="$TMP/home" \
FLYWHEEL_HOME="$TMP/fw" \
FLYWHEEL_AUTOLOOP_STATE_DIR="$TMP/state" \
  "$BIN" executor --candidate "$TMP/candidate.json" --json >"$TMP/out.json"

jq -e '
  .schema_version == "flywheel-autoloop.executor.v1"
  and .status == "no_spawn"
  and .reason == "auto_spawn_disabled"
  and .auto_spawn == false
  and .whitelist_count == 2
  and .cost_class_levels_implemented == 5
' "$TMP/out.json" >/dev/null

printf 'PASS autoloop executor default auto_spawn=false\n'
