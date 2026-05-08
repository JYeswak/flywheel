#!/usr/bin/env bash
set -euo pipefail

BIN="${FLYWHEEL_AUTOLOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-autoloop}"
TMP="$(mktemp -d -t autoloop-exec.XXXXXX)"
trap 'rm -r "$TMP"' EXIT

mkdir -p "$TMP/fw/config" "$TMP/state" "$TMP/repo/.flywheel"
git -C "$TMP/repo" init -q
printf '# Mission\n' >"$TMP/repo/.flywheel/MISSION.md"
printf '# Goal\n' >"$TMP/repo/.flywheel/GOAL.md"
printf '# State\n' >"$TMP/repo/.flywheel/STATE.md"
jq -n '{schema_version:"flywheel-autoloop.config.v1",dispatch:{auto_spawn:true}}' >"$TMP/fw/config/autoloop.json"
jq -n --arg repo "$TMP/repo" '{repo:$repo,score:120,action:"run_baseline_validation",cost_class:"L4"}' >"$TMP/candidate.json"

if HOME="$TMP/home" \
  FLYWHEEL_HOME="$TMP/fw" \
  FLYWHEEL_AUTOLOOP_CONFIG="$TMP/fw/config/autoloop.json" \
  FLYWHEEL_AUTOLOOP_STATE_DIR="$TMP/state" \
  "$BIN" executor --candidate "$TMP/candidate.json" --json >"$TMP/out.json"; then
  printf 'FAIL L4 action unexpectedly executed\n' >&2
  exit 1
fi

jq -e '
  .status == "blocked"
  and .reason == "cost_class_l4"
  and .requires_joshua_approval == true
  and .action_count == 0
' "$TMP/out.json" >/dev/null

printf 'PASS autoloop executor L4 requires Joshua approval\n'
