#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PACKET_DIR="$(mktemp -d -t flywheel-ftj0m-packet.XXXXXX)"
cleanup() {
  rm -rf "$PACKET_DIR"
}
trap cleanup EXIT

doctrine="$ROOT/.flywheel/doctrine/skill-autoresearch-tooling-preference-class.md"
builder="$ROOT/.flywheel/scripts/build-dispatch-packet.sh"

grep -q 'flywheel-spdu' "$doctrine"
grep -q 'flywheel-2gvl' "$doctrine"
grep -q 'flywheel-njzi' "$doctrine"
grep -q 'canonical-cli-scoping.*jsm.*beads-br.*agent-orchestration' "$doctrine"
grep -q 'skill_autoresearch_primary_route' "$builder"

packet_json="$PACKET_DIR/packet.json"
(
  cd "$ROOT"
  FLYWHEEL_PACKET_BUILT_AT=2026-05-09T00:00:00Z \
    "$builder" \
      --bead-id flywheel-spdu \
      --target-pane 2 \
      --target-session flywheel \
      --task-id flywheel-ftj0m-routing-test \
      --output-dir "$PACKET_DIR" \
      --apply \
      --json
) >"$packet_json"

packet_path="$(jq -r '.packet_path' "$packet_json")"
grep -q '^## SKILL-AUTORESEARCH TOOLING PREFERENCE BLOCK' "$packet_path"
grep -q 'Detected target class: `shell_first`' "$packet_path"
grep -q '`shell_first_skill_target=yes`' "$packet_path"
grep -q '`skill_autoresearch_primary_route=forbidden`' "$packet_path"
grep -q 'Shell-first targets (`canonical-cli-scoping`, `jsm`, `beads-br`, `agent-orchestration`) MUST NOT use `skill-autoresearch` as the primary evaluator' "$packet_path"

echo "skill-autoresearch tooling preference contract: PASS"
