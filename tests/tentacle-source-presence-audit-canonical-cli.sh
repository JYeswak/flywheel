#!/usr/bin/env bash
# Canonical receiver for .flywheel/scripts/tentacle-source-presence-audit.sh.
# The functional coverage lives in tests/tentacle-source-presence-audit.sh; this
# wrapper keeps the surface visible to gap-hunt's canonical test corpus.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
exec bash "$ROOT/tests/tentacle-source-presence-audit.sh" "$@"
