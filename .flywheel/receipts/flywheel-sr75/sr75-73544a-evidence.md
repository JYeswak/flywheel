# flywheel-sr75 Evidence

## Scope

- Target repo: `/Users/josh/Developer/gpu-optimization`
- Target artifact: `/Users/josh/Developer/gpu-optimization/.flywheel/lock-log.jsonl`
- Decision: historical backfill row, not re-lock.

The mission file has `status: locked`, `locked_at: 2026-05-02T01:50Z`, and no
frontmatter `lock_hash`. The repair therefore does not forge an original lock
event. It records the observed mission file hash and provenance in an append-only
backfill row.

## Verification

Before writing:

```text
$ shasum -a 256 /Users/josh/Developer/gpu-optimization/.flywheel/MISSION.md
fa189f788f55ed26f8744be04aa90424a99c0ef3c5c4f2d1ae5d0b52661346fa

$ mission-lock-age-probe.sh --repo /Users/josh/Developer/gpu-optimization --status --json
status=degraded
mission_lock_status=stale-warn
last_lock_log_row=null
```

After writing:

```text
$ jq -c . /Users/josh/Developer/gpu-optimization/.flywheel/lock-log.jsonl
PASS

$ wc -l /Users/josh/Developer/gpu-optimization/.flywheel/lock-log.jsonl
1

$ mission-lock-age-probe.sh --repo /Users/josh/Developer/gpu-optimization --status --json | jq '{status,mission_lock_status,last_lock_log_row,warnings}'
{
  "status": "degraded",
  "mission_lock_status": "stale-warn",
  "last_lock_log_row": {
    "schema_version": "mission-lock-log-backfill/v1",
    "action": "mission-lock-log-backfill",
    "mission_file_sha256": "fa189f788f55ed26f8744be04aa90424a99c0ef3c5c4f2d1ae5d0b52661346fa",
    "computed_body_hash": "98dc19a438b8697c7dac6d2a16bbf75aebe0ab7c25a67d9c7b15034dbc9d17df",
    "original_lock_event": false,
    "original_lock_time_forged": false,
    "backfilled_by": "flywheel-sr75-73544a"
  },
  "warnings": ["locked_at_gte_7d"]
}
```

The remaining `degraded` status is non-ambiguous: the audit row now exists, and
the degradation is age-based (`locked_at_gte_7d`), not missing audit evidence.

## Acceptance

- Verified current MISSION.md hash before writing.
- Preserved audit trail with `original_lock_event=false` and `original_lock_time_forged=false`.
- Added append-only historical backfill row.
- Lock-age/status probe now reports the backfill row as `last_lock_log_row`.

## L52 Receipt

No new bead filed. The remaining stale-warn age is expected from the current
mission timestamp and is visible in the status probe; this bead only repairs the
missing audit row.

## Four-Lens Self-Grade

- brand: 9
- sniff: 9
- jeff: 9
- public: 8

Three Judges check: skeptical operator can rerun the hash and probe commands;
maintainer can inspect the single JSONL row; future worker sees this was a
historical backfill, not a live mission lock.
