#!/usr/bin/env bash
# Canonical receiver for .flywheel/scripts/tentacle-launchd-matrix.sh.
# The functional coverage lives in tests/tentacle-launchd-matrix.sh; this
# wrapper keeps the surface visible to gap-hunt's canonical test corpus.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
exec bash "$ROOT/tests/tentacle-launchd-matrix.sh" "$@"
