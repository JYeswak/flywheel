#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BUILDER="$ROOT/.flywheel/scripts/build-dispatch-packet.sh"
TMP="$(mktemp -d -t build-dispatch-callback-pane.XXXXXX)"
cleanup() {
  rm -rf "$TMP"
}
trap cleanup EXIT

TOPOLOGY="$TMP/session-topology.jsonl"
cat >"$TOPOLOGY" <<'JSONL'
{"session":"fixture","effective_at":"2026-05-20T00:00:00Z","orchestrator_pane":3,"callback_pane":9}
{"session":"fixture","effective_at":"2026-05-20T00:01:00Z","orchestrator_pane":1,"callback_pane":8}
JSONL

packet_json="$TMP/packet.json"
FLYWHEEL_TOPOLOGY="$TOPOLOGY" \
  "$BUILDER" \
    --bead-id flywheel-spdu \
    --target-pane 2 \
    --target-session fixture \
    --task-id cfs-lb61-fixture \
    --output-dir "$TMP" \
    --dry-run \
    --skip-trigger-gated-precheck \
    --json >"$packet_json"

jq -e '.fields_resolved.callback_pane == 1' "$packet_json" >/dev/null

missing_json="$TMP/missing.json"
FLYWHEEL_TOPOLOGY="$TOPOLOGY" \
  "$BUILDER" \
    --bead-id flywheel-spdu \
    --target-pane 2 \
    --target-session no-row \
    --task-id cfs-lb61-missing-fixture \
    --output-dir "$TMP" \
    --dry-run \
    --skip-trigger-gated-precheck \
    --json >"$missing_json"

jq -e '.fields_resolved.callback_pane == 0' "$missing_json" >/dev/null

echo "build-dispatch-packet callback_pane topology resolution: PASS"
