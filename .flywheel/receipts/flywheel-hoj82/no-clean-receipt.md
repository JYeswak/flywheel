# flywheel-hoj82 No-Clean Receipt

Task: `[storage] investigate private var folders d0 pressure after mobile-eats tmp cleanup`

## Verdict

No destructive cleanup was performed against `/private/var/folders/d0`.

The inspected pressure is real temp/cache pressure, not an APFS snapshot illusion:

- Data volume: 926Gi total, 871Gi used, 31Gi available, 97% capacity.
- `/private/var/folders/d0`: 206G.
- Per-user root: `/private/var/folders/d0/09qgt_0n1m1ff8nyzbxppx9c0000gn`: 206G.
- `T`: 201G.
- `C`: 385M.
- `X`: 3.9G.
- `0`: 8K.

## Classification

`/private/var/folders/d0/.../T` is macOS per-user temporary space. It is mostly
rebuildable scratch, but it is not safe to blind-delete while the machine is
active:

- live handles exist under `T` from macOS/app services including
  `IMTransferAgent`, `OrbStack`, Logitech Options, FileProvider, and NTM
  subprocesses;
- FileProvider has an open 4.0G temp database under
  `com.apple.fileproviderd/TemporaryItems/fileprovider-fpck/...`;
- multiple Claude Code processes have the `T` directory open;
- `T` contains active worker scratch, including this dispatch tmpdir.

The dominant disposable-looking stock is `beads_mem_*_0.db` and
`beads_mem_*_0.db-wal` top-level temp files:

- `beads_mem_db`: 9,845 files, 89.34G.
- `beads_mem_db_wal`: 9,845 files, 96.77G.
- combined `beads_mem_*_0.db*`: 19,690 files, 186.11G.
- observed mtime range: 2026-05-03T12:15:14-0600 through
  2026-05-08T23:17:30-0600.
- no `lsof` sample rows matched `/T/beads_mem_`.

## Policy Decision

The safe next policy is a protected, dry-run-first cleanup/offload primitive for
`beads_mem_*_0.db*`, not a broad `/private/var/folders/d0` prune.

Minimum policy gates:

- scope only top-level files in the current user's `TMPDIR`;
- match only `beads_mem_[0-9]+_0.db`, `.db-wal`, and `.db-shm`;
- require age threshold and dry-run evidence before apply;
- skip every path with an open handle;
- require an idempotency key for apply;
- write a JSONL ledger with byte counts, age thresholds, lsof result, and
  deleted/skipped counts;
- re-run `storage-pressure-doctor` after apply.

Until that primitive exists, this receipt is an explicit no-clean closeout.

## Live Doctor Rerun

`.flywheel/scripts/storage-pressure-doctor.sh --doctor --json` rerun:

- `status=fail`
- `storage.tier=FIRE`
- `disk_free_gb=31.23`
- `disk_free_pct=3.37`
- top visible consumer: `/private/var/folders/d0` at 206G
- `/private/tmp`: 47.28G, 3,866 entries, prune ledger present

## Evidence

- `.flywheel/audit/flywheel-hoj82/d0-shallow-inspection.txt`
- `.flywheel/audit/flywheel-hoj82/d0-T-inspection.txt`
- `.flywheel/audit/flywheel-hoj82/d0-T-top-sizes.txt`
- `.flywheel/audit/flywheel-hoj82/d0-T-pattern-summary.txt`

## Socraticode Survey

- `socraticode_queries=4`
- `indexed_chunks_observed=1497`

The survey found the existing read-only `storage-pressure-doctor`, repo storage
policy in `.flywheel/STORAGE.md`, and prior tests for protected temp pruning.

## Four-Lens Self-Grade

- brand: 9
- sniff: 9
- jeff: 9
- public: 8

Three Judges check: a skeptical operator can rerun the exact read-only probes, a
maintainer can see why broad var-folder deletion is unsafe, and a future worker
has a precise target for the protected cleanup primitive.
