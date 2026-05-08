#!/usr/bin/env bash
set -euo pipefail

BIN="${FLYWHEEL_AUTOLOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-autoloop}"
TMP="$(mktemp -d -t autoloop-exec.XXXXXX)"
trap 'rm -r "$TMP"' EXIT

mkdir -p "$TMP/fw/config" "$TMP/state" "$TMP/repo"
git -C "$TMP/repo" init -q
printf 'changed\n' >"$TMP/repo/dirty.txt"
jq -n '{schema_version:"flywheel-autoloop.config.v1",dispatch:{auto_spawn:true}}' >"$TMP/fw/config/autoloop.json"
jq -n --arg repo "$TMP/repo" '{repo:$repo,score:120,actions:["summarize_dirty_worktree","run_baseline_validation"]}' >"$TMP/candidate.json"

HOME="$TMP/home" \
FLYWHEEL_HOME="$TMP/fw" \
FLYWHEEL_AUTOLOOP_CONFIG="$TMP/fw/config/autoloop.json" \
FLYWHEEL_AUTOLOOP_STATE_DIR="$TMP/state" \
  "$BIN" executor --candidate "$TMP/candidate.json" --json >"$TMP/out.json"

jq -e '
  .status == "executed"
  and .auto_spawn == true
  and .score == 120
  and .max_actions_per_run == 1
  and .requested_action_count == 2
  and .action_count == 1
  and .executed_actions[0].action == "summarize_dirty_worktree"
  and (.artifact_path | type) == "string"
' "$TMP/out.json" >/dev/null

artifact="$(jq -r '.artifact_path' "$TMP/out.json")"
test -s "$artifact"
jq -e '.dirty_count == 1 and .status == "pass"' "$artifact" >/dev/null

printf 'PASS autoloop executor high score one action\n'
