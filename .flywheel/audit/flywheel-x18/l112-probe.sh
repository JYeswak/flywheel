#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)"
test -x "$ROOT/.flywheel/scripts/tentacle-drift-sweep.sh"
test -s "$ROOT/.flywheel/audit/flywheel-x18/live-dry-run.json"
jq -e '.repo_count == 177 and .alert_count == 11 and .ledger_path == "/Users/josh/.local/state/flywheel/tentacle-drift.jsonl"' \
  "$ROOT/.flywheel/audit/flywheel-x18/live-dry-run.json" >/dev/null
printf 'OK_tentacle_drift_sweep\n'
