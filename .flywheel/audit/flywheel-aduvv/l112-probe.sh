#!/usr/bin/env bash
set -euo pipefail

ROOT="/Users/josh/Developer/flywheel"
cd "$ROOT"

bash -n .flywheel/scripts/doctrine-3-surface-divergence-probe.sh
bash tests/doctrine-3-surface-divergence-probe.sh >/tmp/flywheel-aduvv-l112-test.out
.flywheel/scripts/doctrine-3-surface-divergence-probe.sh --fleet --root /Users/josh/Developer --json \
  | jq -e '.status == "pass" and .fleet_mirror_drift_count == 0 and .fleet_repo_count >= 18' >/dev/null

printf 'OK_flywheel_aduvv_agents_md_fleet_mirror_detector\n'
