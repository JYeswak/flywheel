#!/usr/bin/env bash
# Canonical receiver for .flywheel/scripts/worker-deep-liveness-probe-launchd-install.sh.
# The functional coverage lives in tests/worker-deep-liveness-probe-classification.sh;
# this wrapper keeps the installer visible to gap-hunt's canonical test corpus.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
exec bash "$ROOT/tests/worker-deep-liveness-probe-classification.sh" "$@"
