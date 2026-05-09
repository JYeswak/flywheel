#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../../.."

bash -n .flywheel/scripts/bv-readiness-probe.sh
bash -n tests/bv-readiness-probe.sh
bash -n .flywheel/scripts/dispatch-deferral-lint.sh
tests/bv-readiness-probe.sh
.flywheel/scripts/bv-readiness-probe.sh --schema >/dev/null
.flywheel/scripts/bv-readiness-probe.sh --json \
  | jq -e '.schema_version == "bv-readiness-probe/v1" and (.ready_count | type == "number") and (.source | type == "string")' >/dev/null
grep -q 'BV_READINESS_PROBE' .flywheel/scripts/dispatch-deferral-lint.sh

printf '%s\n' 'OK_bv_readiness_probe_stable'
