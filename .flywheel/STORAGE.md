# Flywheel Storage Discipline

Storage is a doctor-surfaced operating gate, not a cleanup afterthought.

## Thresholds

- `disk_free_pct >= 15`: OK.
- `10 <= disk_free_pct < 15`: warning; plan soft prune.
- `5 <= disk_free_pct < 10`: fail; abort growth-heavy jobs and file a storage bead.
- `disk_free_pct < 5`: fire; notify via `~/.local/bin/notify --priority 1`.
- `stale_baks_count > 5`: fail; stale `.beads.bak.*` directories need pruning.

## Probe

Run:

```bash
.flywheel/scripts/storage-probe.sh --json
```

The probe reports `disk_free_gb`, `disk_free_pct`, `developer_dir_gb`,
`local_state_gb`, `stale_baks_count`, `stale_baks_size_mb`,
`qdrant_volumes_size_mb`, and `tmp_dispatch_artifacts_count`.

History rows are append-only and retained for 90 days:

```bash
.flywheel/scripts/storage-probe.sh --record-history --json
```

## Prune Posture

Default pruning is dry-run:

```bash
.flywheel/scripts/storage-prune.sh --json
```

Apply requires an idempotency key:

```bash
.flywheel/scripts/storage-prune.sh --apply --idempotency-key "$(date -u +%Y%m%dT%H%M%SZ)" --json
```

The prune script only removes stale `.beads.bak.*` directories and `/tmp`
dispatch artifacts older than 7 days. It never prunes Docker volumes. Docker
cleanup remains a manual command from the receipt: `docker system prune --force`.

## Growth Gates

Jeff-corpus daily ingest records storage history before fetch/pull work. If
`disk_free_pct < 10`, it aborts and notifies instead of cloning or pulling more
data. Qdrant/library ingestion jobs must use the same gate before adding corpus
volume.
