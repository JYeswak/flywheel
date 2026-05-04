#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
exec python3 "$ROOT/.flywheel/scripts/jeff-corpus-storage-projection.py" "$@"
