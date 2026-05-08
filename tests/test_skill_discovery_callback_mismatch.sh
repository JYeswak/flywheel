#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/validate-skill-discovery-callback.sh"
TMP="$(mktemp -d -t skill-disc.XXXXXX)"
trap 'chmod -R u+w "$TMP" 2>/dev/null || true; find "$TMP" -mindepth 1 -type f -delete 2>/dev/null || true; find "$TMP" -mindepth 1 -type d -delete 2>/dev/null || true; rmdir "$TMP" 2>/dev/null || true' EXIT

callback='DONE flywheel-fixture task_id=fixture did=1/1 didnt=none gaps=none evidence=/tmp/fixture tests=PASS skill_discoveries=2 sd_ids=none'

set +e
"$SCRIPT" --callback "$callback" --json >"$TMP/out.json"
rc=$?
set -e

[[ "$rc" -ne 0 ]]
jq -e '.status == "fail" and .reason_code == "skill_discovery_ids_missing"' "$TMP/out.json" >/dev/null

printf 'PASS skill_discovery_callback_mismatch\n'
