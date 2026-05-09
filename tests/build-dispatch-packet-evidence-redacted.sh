#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PACKET_DIR="$(mktemp -d -t flywheel-kvt8v-packet.XXXXXX)"
cleanup() {
  rm -rf "$PACKET_DIR"
}
trap cleanup EXIT

builder="$ROOT/.flywheel/scripts/build-dispatch-packet.sh"
packet_json="$PACKET_DIR/packet.json"

(
  cd "$ROOT"
  FLYWHEEL_PACKET_BUILT_AT=2026-05-09T00:00:00Z \
    "$builder" \
      --bead-id flywheel-spdu \
      --target-pane 2 \
      --target-session flywheel \
      --task-id flywheel-kvt8v-evidence-redacted-fixture \
      --output-dir "$PACKET_DIR" \
      --apply \
      --json
) >"$packet_json"

packet_path="$(jq -r '.packet_path' "$packet_json")"

grep -Fq 'evidence=<path-or-command-ref> evidence_redacted=<yes|no|n/a> tests=PASS|FAIL|SKIPPED' "$packet_path"
grep -Fq 'BLOCKED flywheel-kvt8v-evidence-redacted-fixture reason=<short> need=<short>' "$packet_path"
grep -Fq 'evidence=<path> evidence_redacted=<yes|no|n/a> worker_substrate=codex-pane' "$packet_path"

echo "build-dispatch-packet evidence_redacted callback contract: PASS"
