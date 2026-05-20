#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
DEFAULT_LEDGER="${WIRE_OR_EXPLAIN_LEDGER:-$HOME/.local/state/flywheel/wire-or-explain-ledger.jsonl}"

exec python3 "$ROOT/.flywheel/scripts/wire_or_explain_chain_verifier.py" "$DEFAULT_LEDGER" "$@"

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
