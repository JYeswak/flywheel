## L72 — STORAGE-DISCIPLINE-SYSTEM-WIDE

---
id: L72
title: Storage discipline system-wide
status: long_term
shipped: 2026-05-03
review_due: 2026-11-03
trauma_class: storage-headroom-blind-growth
---

Disk headroom is a flywheel doctor gate. Growth-heavy work such as Jeff-corpus
diff pulls, library ingestion, Qdrant expansion, large mirror clones, and
dispatch artifact accumulation MUST probe storage before adding bytes. If
`disk_free_pct < 10`, the work aborts before the pull/clone/index step and
routes to a storage bead or explicit blocked receipt. If `disk_free_pct < 5`,
the worker MUST notify via `~/.local/bin/notify --priority 1 "STORAGE LOW"
"<details>"`.

**How to apply:**
- `flywheel-loop doctor --json` MUST include `.storage` with
  `disk_free_gb`, `disk_free_pct`, `developer_dir_gb`, `local_state_gb`,
  `stale_baks_count`, `stale_baks_size_mb`, `qdrant_volumes_size_mb`, and
  `tmp_dispatch_artifacts_count`.
- Doctor status fails when `disk_free_pct < 10` or `stale_baks_count > 5`.
- `doctor-signal-bead-promotion.sh` promotes storage failures to
  `[auto-doctor:storage-low-headroom]` instead of letting RED storage remain a
  human-observed dashboard fact.
- Daily Jeff ingest and other corpus-growth jobs MUST run the storage probe
  before network pulls, clone operations, or indexing work.
- Pruning defaults to dry-run. Apply requires an idempotency key and never
  prunes Docker volumes automatically.

**Forbidden outputs:**
- Starting a growth-heavy clone, pull, mirror, or index job after a storage
  probe reports `<10%` free.
- Treating "storage seems low" as a prose warning without a doctor field,
  storage-history row, bead promotion path, or blocked receipt.
- Running broad destructive cleanup such as Docker volume pruning as an
  automatic response to low storage.
- Hand-deleting per-repo artifacts instead of using the shared storage policy
  and probe receipts.

**Evidence:** bead `flywheel-2zsj`; memory
`feedback_storage_discipline_global.md`; ground-truth probe
`/tmp/jeff-corpus-ground-truth-2026-05-03.md`; storage history
`~/.local/state/flywheel/storage-history.jsonl`; policy
`.flywheel/STORAGE.md`.

**Companion rules:** L48 (probe ladder before escalation), L52 (issue/no-bead
receipts), L56 (doctor signals promote to durable doctrine), L60 (doctor signals
must surface), L61 (doctrine wires into README and canonical paths), L70
(chain repair work instead of punting), L71 (validate every new surface before
calling it shipped).


