#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
DEFAULT_LEDGER="${WIRE_OR_EXPLAIN_LEDGER:-$HOME/.local/state/flywheel/wire-or-explain-ledger.jsonl}"

exec python3 "$ROOT/.flywheel/scripts/wire_or_explain_chain_verifier.py" "$DEFAULT_LEDGER" "$@"
