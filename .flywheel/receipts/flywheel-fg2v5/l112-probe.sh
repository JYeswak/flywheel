#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)"

bash -n "$ROOT/.flywheel/scripts/ntm-pane-sidecar-respawn.sh"
bash "$ROOT/tests/ntm-pane-sidecar-respawn.sh"

printf 'OK_flywheel_fg2v5_sidecar_respawn_surface\n'
