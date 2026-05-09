#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
HELPER="$ROOT/.flywheel/scripts/cleanup-scratch.sh"
WRAPPER="/Users/josh/.local/bin/flywheel-cleanup-scratch"
SYNC="/Users/josh/.claude/skills/.flywheel/bin/flywheel-doctrine-sync"
TMP_ROOT="$(mktemp -d -t flywheel-l95he-l112.XXXXXX)"

cleanup() {
  "$WRAPPER" --apply --json "$TMP_ROOT" >/dev/null 2>&1 || true
}
trap cleanup EXIT

cd "$ROOT"

"$HELPER" schema --json \
  | jq -e '.command == "cleanup-scratch" and .default_mode == "dry-run" and (.mutation_modes | index("--apply"))' >/dev/null

bash tests/cleanup-scratch.sh >/dev/null

"$SYNC" --dry-run --json --repo "$ROOT" >"$TMP_ROOT/doctrine-sync.json"
jq -e '[.managed_details[] | select(type == "object") | select(((.source // "") | contains("cleanup-scratch.sh")) and (.action == "copy_shared_script"))] | length >= 1' \
  "$TMP_ROOT/doctrine-sync.json" >/dev/null

printf 'true\n'

