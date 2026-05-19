#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/oar1m-replay.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

bash "$ROOT/tests/w10-mission-lock-cadence-tick.sh" >"$TMP/w10.out"
bash "$ROOT/tests/repo-local-cli-floor-bare-root-guard.sh" >"$TMP/root.out"
bash "$ROOT/tests/canonical-cli-checker-timeout.sh" >"$TMP/checker.out"
bash "$ROOT/tests/check-cli-scoping-per-probe-timeout.sh" >"$TMP/probe.out"

cat <<'EOF'
PASS oar1m defense-in-depth replay:
  layer1: W10 cadence calls flywheel-loop doctor with --repo and --json.
  layer2: repo_local_cli_floor_json refuses REPO_ABS=/ with warn-not-scan.
  layer3: repo_local_cli_floor_json bounds check-cli-scoping.sh and classifies rc=124.
  layer4: check-cli-scoping.sh bounds every CLI probe and continues after a timed-out probe.
EOF
