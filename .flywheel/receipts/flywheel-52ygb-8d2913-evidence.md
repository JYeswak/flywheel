# flywheel-52ygb-8d2913 evidence

## Repair

- Restored ledger-backed mode in `.flywheel/scripts/peer-orch-blocker-watch.sh`.
- `--ledger` and `--now` now drive deterministic L75 fixture checks instead of being ignored.
- Doctor-compatible output exposes `peer_orch_blocker_age_seconds`, `stale_blockers_count`, `stale_blockers`, and `status`.

## Verification

```text
$ bash -n .flywheel/scripts/peer-orch-blocker-watch.sh
PASS

$ shellcheck .flywheel/scripts/peer-orch-blocker-watch.sh
PASS

$ tests/peer-orch-blocker-watch.sh
PASS script syntax
PASS stale flywheel blocker trips
PASS blocker type surfaced
PASS flywheel ack clears stale blocker
PASS legacy row infers flywheel_class
PASS malformed rows warn not crash
PASS schema exposes doctor field
PASS flywheel-loop doctor exposes L75 fields
SUMMARY pass=8 fail=0

$ .flywheel/scripts/peer-orch-blocker-watch.sh --json | jq '{status,stale_blockers_count,peer_orch_blocker_age_seconds,schema_version}'
{
  "status": "pass",
  "stale_blockers_count": 0,
  "peer_orch_blocker_age_seconds": 0,
  "schema_version": "peer-orch-blocker-watch/v2"
}

$ FLYWHEEL_DOCTOR_PROBE_TIMEOUT_SECONDS=10 ~/.claude/skills/.flywheel/bin/flywheel-loop doctor --repo /Users/josh/Developer/flywheel --json | jq '{status, peer_orch_idle_on_blocker_count, peer_orch_blocker_age_seconds, peer_orch_blocker_watch:{status:.peer_orch_blocker_watch.status, stale_blockers_count:.peer_orch_blocker_watch.stale_blockers_count, peer_orch_blocker_age_seconds:.peer_orch_blocker_watch.peer_orch_blocker_age_seconds, schema_version:.peer_orch_blocker_watch.schema_version}}'
{
  "status": "fail",
  "peer_orch_idle_on_blocker_count": 0,
  "peer_orch_blocker_age_seconds": 0,
  "peer_orch_blocker_watch": {
    "status": "pass",
    "stale_blockers_count": 0,
    "peer_orch_blocker_age_seconds": 0,
    "schema_version": "peer-orch-blocker-watch/v2"
  }
}
```

## Closeout

- Doctor field repaired/downgraded: `peer_orch_idle_on_blocker_count=0`, `peer_orch_blocker_age_seconds=0`.
- Follow-up bead: `flywheel-08rvw`, closed after restoring the fixture injection path.
- `no_bead_reason`: no additional residual gap observed after `flywheel-08rvw` closure.
