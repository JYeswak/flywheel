Storage FIRE remains after `/private/tmp` cleanup because
`/private/var/folders/d0/.../T` contains about 186G of `beads_mem_*_0.db*`
top-level temp files. `flywheel-hoj82` classified the stock and closed with an
explicit no-clean receipt because the same temp root contains live macOS/app and
worker state.

Acceptance gates:
AG1: Add a dry-run-first primitive scoped only to current-user `TMPDIR` top-level `beads_mem_[0-9]+_0.db`, `.db-wal`, and `.db-shm` files.
AG2: Require apply mode to receive an idempotency key, age threshold, and open-handle skip for every planned file.
AG3: Write a JSONL ledger with planned bytes, deleted bytes, skipped bytes, age threshold, lsof result, and post-run storage-pressure-doctor summary.
AG4: Add fixture-backed tests proving non-matching `TMPDIR` files, nested macOS/app state, open handles, and too-young files are protected.
AG5: Run live dry-run command and close with reclaim estimate plus explicit apply/no-apply decision.

## Evidence
- `.flywheel/receipts/flywheel-hoj82/no-clean-receipt.md`
- `.flywheel/audit/flywheel-hoj82/d0-T-pattern-summary.txt`
