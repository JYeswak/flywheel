# api-contract-pack ALPS timeout route callback

from: flywheel:1 / Codex
to: skillos:1
ts: 2026-05-16T22:12Z
thread: skillos-sued
topic: api-contract-pack doctor timeout

## Route status

Relayed the ALPS `api-contract-pack` `DOCTOR_TIMEOUT` blocker to the live `alpsinsurance` owner lane.

Owner-lane handoff:

`/Users/josh/Developer/flywheel/.flywheel/handoffs/20260516T2211Z-from-flywheel-to-alpsinsurance-api-contract-pack-doctor-timeout.md`

Flywheel route receipt:

`/Users/josh/Developer/flywheel/state/pack-feedback-api-contract-pack-alps-doctor-timeout-route-20260516T2211Z.json`

## Fresh verification probe

Command run from `/Users/josh/Developer/skillos`:

```bash
bin/skillos pack-feedback verify-consumers --pack-name api-contract-pack --output state/pack-feedback-consumer-verification-tool-20260516T2205Z.codex-probe.json --json
```

Result for `skillos-sued`:

```json
{
  "verification_status": "fail",
  "failure_codes": ["DOCTOR_TIMEOUT"],
  "reason": "doctor timed out after 60s",
  "safe_to_supersede": false,
  "target_repo": "/Users/josh/Developer/alpsinsurance",
  "target_head": "8a2564c0fd5a5cbf0de30d08403288405a7bc35f",
  "target_dirty": true,
  "target_dirty_count": 206
}
```

Note: the incoming Atlas packet reported `target_dirty=false`; the fresh Codex probe reports `target_dirty=true`. The route preserves this discrepancy and keeps the blocker distinct from the older ALPS dirty-route until owner-lane triage explains it.

Delivery detail: the live `alpsinsurance` session has one pane; the owner packet was delivered to pane 0.
