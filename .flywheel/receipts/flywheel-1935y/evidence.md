# flywheel-1935y Evidence Pack

## Summary

- Added `.flywheel/scripts/beads-mem-tmp-cleanup.py`, a dry-run-first cleanup primitive for current-user `TMPDIR` top-level `beads_mem_[0-9]+_0.db`, `.db-wal`, and `.db-shm` files.
- Added `tests/beads-mem-tmp-cleanup.sh` fixture coverage for non-matching files, nested files, open handles, too-young files, apply key gating, and JSONL ledger fields.
- The script uses one bounded `lsof -F n +d TMPDIR` snapshot and applies that result to every candidate, avoiding the unbounded per-file `lsof` loop found during the first live dry-run attempt.

## Acceptance Gates

AG1: Scoped only to current-user `TMPDIR`, top-level files, and regex:

```text
^beads_mem_[0-9]+_0\.db(?:-wal|-shm)?$
```

AG2: Apply mode requires:

- `--apply`
- `--idempotency-key`
- explicit age threshold, defaulting to 24h if not supplied
- lsof result on every candidate file; open or unchecked files are skipped

AG3: JSONL ledger includes planned bytes, deleted bytes, skipped bytes, age threshold, lsof summary, and post-run storage-pressure-doctor summary. Live storage-pressure-doctor timed out under current storage pressure; the ledger records `status=unknown` with `storage_pressure_doctor_timeout`.

AG4: Fixture-backed tests prove protection for:

- non-matching top-level files
- nested matching files
- open handles
- too-young files

AG5: Live dry-run completed. No apply was run in this worker tick.

## Live Dry-Run

Command:

```bash
.flywheel/scripts/beads-mem-tmp-cleanup.py --dry-run --min-age-hours 24 --doctor-timeout-seconds 5 --ledger .flywheel/receipts/flywheel-1935y/live-dry-run-ledger.jsonl --json > .flywheel/receipts/flywheel-1935y/live-dry-run.json
jq '{schema_version,status,dry_run,tmpdir,age_threshold_seconds,planned_count,planned_bytes,planned_gib:(.planned_bytes/1024/1024/1024),deleted_count,deleted_bytes,skipped_count,skipped_bytes,lsof,post_run_storage_pressure_doctor}' .flywheel/receipts/flywheel-1935y/live-dry-run.json > .flywheel/receipts/flywheel-1935y/live-dry-run-summary.json
```

Summary:

```json
{
  "planned_count": 14832,
  "planned_bytes": 143771503288,
  "planned_gib": 133.8976465985179,
  "skipped_count": 4900,
  "skipped_bytes": 56545475352,
  "open_count": 0,
  "lsof_checked": 19732
}
```

Current storage probe:

```json
{
  "status": "fail",
  "tier": "FIRE",
  "disk_free_gb": 30.66,
  "disk_free_pct": 3.31
}
```

Apply/no-apply decision: no apply in this worker tick. The protected apply command is ready, but deleting 133.9 GiB from live `TMPDIR` should be a deliberate operator/next-dispatch action using a chosen idempotency key:

```bash
.flywheel/scripts/beads-mem-tmp-cleanup.py --apply --idempotency-key flywheel-1935y-YYYYMMDD --min-age-hours 24 --json
```

## Verification

```bash
python3 -m py_compile .flywheel/scripts/beads-mem-tmp-cleanup.py
bash -n tests/beads-mem-tmp-cleanup.sh
tests/beads-mem-tmp-cleanup.sh
.flywheel/scripts/storage-probe.sh --json
```

Observed:

```text
PASS beads_mem_tmp_cleanup: 19 checks
```

## Skill Routes

- `canonical-cli-scoping=yes`: dry-run default, explicit apply, idempotency key, JSON output, schema/examples surfaces, stable exit-code schema.
- `python-best-practices=yes`: typed function signatures, dataclasses for structured plan rows, fixture-backed validation, module below 400 lines.
- `rust-best-practices=n/a`: no Rust touched.
- `readme-writing=n/a`: no README touched.

## Four-Lens Self-Grade

brand: 8
sniff: 9
jeff: 9
public: 8

Three Judges:

- skeptical operator can rerun the live dry-run and inspect the ledger
- maintainer can inspect a focused script plus test
- future worker gets a bounded protected primitive instead of ad hoc `rm`
