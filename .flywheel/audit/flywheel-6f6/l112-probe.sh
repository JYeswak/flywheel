#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../../.."

bash -n .flywheel/scripts/tentacle-launchd-matrix.sh
bash -n tests/tentacle-launchd-matrix.sh
tests/tentacle-launchd-matrix.sh

.flywheel/scripts/tentacle-launchd-matrix.sh --json | jq -e '
  .schema_version == "tentacle-launchd-matrix/v1" and
  .mutation_performed == false and
  (.rows | length) == .total and
  all(.rows[]; (.plist_label | length) > 0 and (.expected_uptime_seconds | type == "number") and (.binary_path | length) > 0 and (.restart_policy | length) > 0)
' >/dev/null

printf '%s\n' 'OK_tentacle_launchd_matrix_stable'
