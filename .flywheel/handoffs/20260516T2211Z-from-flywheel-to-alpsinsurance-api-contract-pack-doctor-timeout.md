# api-contract-pack ALPS doctor timeout triage

from: flywheel:1 / Codex
to: alpsinsurance owner lane
ts: 2026-05-16T22:11Z
thread: skillos-sued
topic: api-contract-pack doctor timeout

## Why this route exists

SkillOS `pack-feedback verify-consumers` reports a new ALPS `api-contract-pack` verification blocker for bead `skillos-sued`.

This is distinct from the prior ALPS `pass_dirty` route. The current blocker is `DOCTOR_TIMEOUT`, and `safe_to_supersede=false`.

## Fresh command

From `/Users/josh/Developer/skillos`:

```bash
bin/skillos pack-feedback verify-consumers --pack-name api-contract-pack --output state/pack-feedback-consumer-verification-tool-20260516T2205Z.codex-probe.json --json
```

## Current ALPS row from Codex probe

```json
{
  "bead_id": "skillos-sued",
  "pack_name": "api-contract-pack",
  "verification_status": "fail",
  "failure_codes": ["DOCTOR_TIMEOUT"],
  "reason": "doctor timed out after 60s",
  "safe_to_supersede": false,
  "target_repo": "/Users/josh/Developer/alpsinsurance",
  "target_head": "8a2564c0fd5a5cbf0de30d08403288405a7bc35f",
  "target_dirty": true,
  "target_dirty_count": 206,
  "gap_hash": "1ca63193e22a",
  "gap_type": "wrong_shape"
}
```

The incoming Atlas packet from SkillOS reported the same timeout and head with `target_dirty=false`; the fresh Codex probe at 22:06Z reports `target_dirty=true` with 206 dirty entries. Treat this as a freshness discrepancy to preserve in the owner receipt, not as supersession.

## Doctor command that timed out

```bash
/opt/homebrew/opt/python@3.14/bin/python3.14 /Users/josh/Developer/skillos/state/packs/api-contract-pack/scripts/api-contract-doctor.py --repo /Users/josh/Developer/alpsinsurance --json
```

## Requested owner-lane action

Run timeout triage in `/Users/josh/Developer/alpsinsurance`:

1. Confirm the current dirty/head state before editing.
2. Run the `api-contract-doctor.py` command with timing/instrumentation.
3. Identify whether the 60s timeout is caused by repo state, an external wait, an expensive scan, or a tool regression.
4. Return either a validation pass, a bounded package-doctor fix, or a timeout receipt with the concrete slow step.

Do not classify this as the older dirty-target route without explicit evidence tying the two together.

