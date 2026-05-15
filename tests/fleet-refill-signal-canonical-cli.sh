#!/usr/bin/env bash
# Canonical receiver for .flywheel/scripts/fleet-refill-signal.sh.
# The functional cross-orch coordination proof lives in
# tests/fleet-refill-signal.sh; this wrapper keeps the surface visible to
# gap-hunt's canonical test corpus.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
exec bash "$ROOT/tests/fleet-refill-signal.sh" "$@"
