# flywheel-ttyg Evidence

## Scope

- Added `/flywheel:mission-lock --status` to `/Users/josh/.claude/commands/flywheel/mission-lock.md`.
- Extended `.flywheel/scripts/mission-lock-age-probe.sh` with `--status`.
- Added `tests/mission-lock-status.sh`.
- No mutation to `.flywheel/MISSION.md` or `.flywheel/lock-log.jsonl`.

## Verification

```text
$ bash -n .flywheel/scripts/mission-lock-age-probe.sh
PASS

$ bash -n tests/mission-lock-status.sh
PASS

$ tests/mission-lock-status.sh
PASS: status mode emits read-only lock state
PASS: status mode degrades on invalid lock hash evidence
OK mission-lock status

$ bash .flywheel/validation-schema/v1/dispatch-template-audit.sh /tmp/dispatch_flywheel-ttyg-238a15.md
valid=true errors=[]
```

Live status proof:

```text
$ .flywheel/scripts/mission-lock-age-probe.sh --repo /Users/josh/Developer/flywheel --status --json | jq '{schema_version,mode,status,mission_schema_version,locked_at,mission_lock_age_hours,lock_hash_valid,lock_hash_matches_body,lock_hash_matches_lock_log,last_lock_log_action:.last_lock_log_row.action,warnings}'
{
  "schema_version": "flywheel.mission_lock_age.v1",
  "mode": "status",
  "status": "degraded",
  "mission_schema_version": "1",
  "locked_at": "2026-05-07T04:07:55Z",
  "lock_hash_valid": false,
  "lock_hash_matches_body": false,
  "lock_hash_matches_lock_log": true,
  "last_lock_log_action": "doc-lock-refresh",
  "warnings": ["lock_hash_body_mismatch"]
}
```

The live degraded result is expected for this bead: the new mode reports existing lock evidence; it does not repair mission-lock drift.

## Acceptance

- AG1: command surface updated and this evidence exists.
- AG2: targeted test and dispatch-template audit passed.
- AG3: `br show flywheel-ttyg` remained open while this evidence was created.

## L52 Receipt

No new bead filed. The only discovered gap is pre-existing live lock-hash drift already surfaced by the status output; this bead's scope is read-only status reporting, not repair.

## Four-Lens Self-Grade

- brand: 9
- sniff: 9
- jeff: 9
- public: 8

Three Judges check: a skeptical operator can rerun the status command, a maintainer can inspect the fixture test, and a future worker sees the no-repair boundary.
