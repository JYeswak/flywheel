#!/usr/bin/env bash
set -euo pipefail

BIN="${FLYWHEEL_AUTOLOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-autoloop}"
TMP="$(mktemp -d -t autoloop-exec.XXXXXX)"
trap 'rm -r "$TMP"' EXIT

mkdir -p "$TMP/fw" "$TMP/state"
HOME="$TMP/home" FLYWHEEL_HOME="$TMP/fw" FLYWHEEL_AUTOLOOP_STATE_DIR="$TMP/state" \
  "$BIN" executor --no-op-streak 2 --json >"$TMP/out.json"

jq -e '.status == "warn" and .action == "warn" and .no_op_streak == 2 and (.doctor_surface_marker | type) == "string"' "$TMP/out.json" >/dev/null
marker="$(jq -r '.doctor_surface_marker' "$TMP/out.json")"
test -s "$marker"
test -s "$TMP/state/no-op-ladder.jsonl"

printf 'PASS autoloop no-op streak warn\n'
