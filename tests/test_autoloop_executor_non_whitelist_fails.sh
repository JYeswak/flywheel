#!/usr/bin/env bash
set -euo pipefail

BIN="${FLYWHEEL_AUTOLOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-autoloop}"
TMP="$(mktemp -d -t autoloop-exec.XXXXXX)"
trap 'rm -r "$TMP"' EXIT

mkdir -p "$TMP/fw/config" "$TMP/state" "$TMP/repo"
git -C "$TMP/repo" init -q
jq -n '{schema_version:"flywheel-autoloop.config.v1",dispatch:{auto_spawn:true}}' >"$TMP/fw/config/autoloop.json"
jq -n --arg repo "$TMP/repo" '{repo:$repo,score:120,action:"edit_source",cost_class:"L1"}' >"$TMP/candidate.json"

if HOME="$TMP/home" \
  FLYWHEEL_HOME="$TMP/fw" \
  FLYWHEEL_AUTOLOOP_CONFIG="$TMP/fw/config/autoloop.json" \
  FLYWHEEL_AUTOLOOP_STATE_DIR="$TMP/state" \
  "$BIN" executor --candidate "$TMP/candidate.json" --json >"$TMP/out.json"; then
  printf 'FAIL non-whitelisted action unexpectedly passed\n' >&2
  exit 1
fi

jq -e '
  .status == "blocked"
  and .reason == "action_not_in_whitelist"
  and .requires_joshua_approval == false
  and .action_count == 0
' "$TMP/out.json" >/dev/null

printf 'PASS autoloop executor non-whitelist fails closed\n'
