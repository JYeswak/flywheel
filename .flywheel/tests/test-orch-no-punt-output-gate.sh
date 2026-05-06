#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
exec "$ROOT/.flywheel/tests/test_orch_no_punt_output_gate.sh" "$@"
