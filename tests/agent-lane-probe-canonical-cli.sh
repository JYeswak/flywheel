#!/usr/bin/env bash
# Canonical receiver for scripts/agent-lane-probe.sh.
# The functional support-copy proof lives in tests/agent-lane-probe.sh; this
# wrapper keeps the probe visible to gap-hunt's canonical receiver corpus.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
exec bash "$ROOT/tests/agent-lane-probe.sh" "$@"
