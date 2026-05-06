#!/usr/bin/env bash
set -euo pipefail

BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
CHECKER="${CANONICAL_CLI_CHECKER:-$HOME/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh}"
REPO="${FLYWHEEL_LOOP_HEALTH_REPO:-/Users/josh/Developer/flywheel}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-loop-canonical-health.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/state"
printf '{"status":"ok"}\n' >"$TMP/state/last_tick.json"
printf '{"session":"fixture","effective_at":"2026-05-05T00:00:00Z"}\n' >"$TMP/topology.jsonl"

env_base=(
  "FLYWHEEL_LOOP_STATE_DIR=$TMP/state"
  "FLYWHEEL_SESSION_TOPOLOGY=$TMP/topology.jsonl"
)

bash "$CHECKER" flywheel-loop >"$TMP/check-cli-scoping.txt"
rg -q 'Summary: 4 pass, 0 fail' "$TMP/check-cli-scoping.txt"

env "${env_base[@]}" "$BIN" health --repo "$REPO" --json \
  | jq -e '.success == true and .version == "flywheel-loop.health.v1" and (.subsystems | length) >= 5' >/dev/null

env "${env_base[@]}" "$BIN" schema health --json \
  | jq -e '.schema_version == "flywheel-loop.health.v1" and (.required | index("subsystems"))' >/dev/null

env "${env_base[@]}" "$BIN" --info --json \
  | jq -e '.subcommands | index("doctor") and index("health") and index("repair")' >/dev/null

env "${env_base[@]}" "$BIN" --examples --json \
  | jq -e 'any(.examples[]; .name == "health_watch") and any(.examples[]; .name == "health_json_filter")' >/dev/null

echo "PASS canonical-cli-scoping flywheel-loop health triad"
