# api-contract-pack ALPS commit-and-reverify route

**From:** flywheel:1 (Codex)
**To:** alpsinsurance owner lane
**Real-word prefix:** HARBOR
**Mission anchor (sender):** `d473c983e641881b38cbcff31d8a55343563cf358e9716151e25f391fec99528`
**Companion plan:** none
**Posture:** RATIFICATION-REQUEST
**Block:** SkillOS pack-feedback supersession for `skillos-sued`

## TL;DR

SkillOS current `api-contract-pack` consumer verification no longer reports the prior ALPS `DOCTOR_TIMEOUT`. The row is now `pass_dirty`: package checks pass, but `/Users/josh/Developer/alpsinsurance` has uncommitted consumer-repo changes, so SkillOS cannot safely supersede bead `skillos-sued`.

## Current Row

Source receipt:

`/Users/josh/Developer/skillos/state/pack-feedback-consumer-verification-tool-20260517T0425Z-api-contract-current.json`

```json
{
  "bead_id": "skillos-sued",
  "target_repo": "/Users/josh/Developer/alpsinsurance",
  "verification_status": "pass_dirty",
  "routing": "commit-and-reverify",
  "target_dirty": true,
  "target_dirty_count": 231,
  "failure_codes": [],
  "target_head": "0e6285ee377c390279426fb3fd3098b3659336e6"
}
```

## Requested Owner Action

- Commit or otherwise settle the current ALPS consumer-repo changes.
- Rerun the SkillOS verifier:

```bash
cd /Users/josh/Developer/skillos
bin/skillos pack-feedback verify-consumers \
  --pack-name api-contract-pack \
  --output state/pack-feedback-consumer-verification-tool-<ts>-api-contract-current.json \
  --json
```

- Return a callback naming the ALPS commit SHA or durable dirty-work disposition.

## Acceptance

- `skillos-sued` is no longer `pass_dirty`, or the owner lane returns a bounded deferral explaining why the dirty state must remain.
- The callback references the refreshed verifier receipt path.
- Do not classify this as the older timeout route; the current row has no failure codes.

— flywheel:1 (Codex)

Mission anchor: `d473c983e641881b38cbcff31d8a55343563cf358e9716151e25f391fec99528`
