#!/usr/bin/env bash
set -euo pipefail

BIN="${FLYWHEEL_AUTOLOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-autoloop}"
TMP="$(mktemp -d -t autoloop-exec.XXXXXX)"
trap 'rm -r "$TMP"' EXIT

mkdir -p "$TMP/fw" "$TMP/state"
HOME="$TMP/home" FLYWHEEL_HOME="$TMP/fw" FLYWHEEL_AUTOLOOP_STATE_DIR="$TMP/state" \
  "$BIN" executor --no-op-streak 3 --json >"$TMP/out.json"

jq -e '.status == "force_replan" and .action == "force_replan" and .no_op_streak == 3 and (.replan_artifact | type) == "string"' "$TMP/out.json" >/dev/null
replan="$(jq -r '.replan_artifact' "$TMP/out.json")"
test -s "$replan"
jq -e '.status == "force_replan"' "$replan" >/dev/null

printf 'PASS autoloop no-op streak force replan\n'
