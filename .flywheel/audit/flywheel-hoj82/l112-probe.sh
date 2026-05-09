#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
receipt="$ROOT/receipts/flywheel-hoj82/no-clean-receipt.md"
audit="$ROOT/audit/flywheel-hoj82"

test -f "$receipt"
test -f "$audit/compliance.md"
test -f "$audit/d0-shallow-inspection.txt"
test -f "$audit/d0-T-pattern-summary.txt"

grep -q 'No destructive cleanup was performed' "$receipt"
grep -q 'combined `beads_mem_\*_0.db\*`: 19,690 files, 186.11G' "$receipt"
grep -q 'storage.tier=FIRE' "$receipt"
grep -q 'count=19690 total_gib=186.11' "$audit/d0-T-pattern-summary.txt"

printf 'OK_storage_var_folders_receipt\n'
