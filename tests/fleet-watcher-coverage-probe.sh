#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/fleet-watcher-coverage-probe.sh"

bash -n "$SCRIPT"
"$SCRIPT" --info --json | jq -e '.schema_version == "fleet-watcher-coverage/v1" and (.doctor_fields | index("fleet_watcher_coverage_count"))' >/dev/null
"$SCRIPT" --schema --json | jq -e '.properties.fleet_watcher_coverage_total.type == "integer"' >/dev/null
"$SCRIPT" --session flywheel --json | jq -e '.schema_version == "fleet-watcher-coverage/v1" and .fleet_watcher_coverage_total == 1 and (.rows | length) == 1' >/dev/null
printf 'PASS fleet-watcher-coverage-probe\n'
