# api-contract-pack Mobile Eats pass-dirty route

**From:** flywheel:1 (Codex)
**To:** mobile-eats owner lane
**Real-word prefix:** SIGNAL
**Mission anchor (sender):** `d473c983e641881b38cbcff31d8a55343563cf358e9716151e25f391fec99528`
**Companion plan:** `/Users/josh/Developer/flywheel/state/pack-feedback-consumer-verification-owner-routing-20260517T1204Z.json`
**Posture:** RATIFICATION-REQUEST
**Block:** SkillOS pack-feedback supersession for `skillos-7vrr`

## TL;DR

A newer SkillOS verifier receipt supersedes the earlier Mobile Eats missing-artifacts route. The `api-contract-pack` gates now pass for `/Users/josh/Developer/mobile-eats`, but the row remains `pass_dirty` because the target repo has uncommitted changes.

## Current Row

Source receipt:

`/Users/josh/Developer/skillos/state/pack-feedback-consumer-verification-tool-20260517T1148Z-api-contract-current.json`

```json
{
  "bead_id": "skillos-7vrr",
  "target_repo": "/Users/josh/Developer/mobile-eats",
  "verification_status": "pass_dirty",
  "failure_codes": [],
  "target_dirty": true,
  "target_dirty_count": 43,
  "target_head": "2c1c99a257544d31644ab85e86c1c1d575b123fb",
  "doctor_status": "pass"
}
```

## Requested Owner Action

- Commit or otherwise settle the current Mobile Eats dirty work.
- Preserve unrelated work; do not discard changes just to clear the row.
- Rerun the SkillOS verifier:

```bash
cd /Users/josh/Developer/skillos
bin/skillos pack-feedback verify-consumers \
  --pack-name api-contract-pack \
  --output state/pack-feedback-consumer-verification-tool-<ts>-api-contract-current.json \
  --json
```

- Return a callback naming the commit SHA or durable dirty-work disposition plus the refreshed verifier receipt.

## Supersedes

This supersedes `.flywheel/handoffs/20260517T0848Z-from-flywheel-to-mobile-eats-api-contract-pack-missing-artifacts.md` for Mobile Eats. The current verifier no longer reports missing CI or fixture artifacts for this row.

## Acceptance

- `skillos-7vrr` is no longer `pass_dirty`, or the owner lane returns a bounded deferral explaining why the dirty state must remain.
- The callback references a refreshed verifier receipt path.

-- flywheel:1 (Codex)

Mission anchor: `d473c983e641881b38cbcff31d8a55343563cf358e9716151e25f391fec99528`
