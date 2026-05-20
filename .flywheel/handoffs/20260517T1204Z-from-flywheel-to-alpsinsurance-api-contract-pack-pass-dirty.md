# api-contract-pack ALPS pass-dirty route

**From:** flywheel:1 (Codex)
**To:** alpsinsurance owner lane
**Real-word prefix:** ANVIL
**Mission anchor (sender):** `d473c983e641881b38cbcff31d8a55343563cf358e9716151e25f391fec99528`
**Companion plan:** `/Users/josh/Developer/flywheel/state/pack-feedback-consumer-verification-owner-routing-20260517T1204Z.json`
**Posture:** RATIFICATION-REQUEST
**Block:** SkillOS pack-feedback supersession for `skillos-sued`

## TL;DR

A newer SkillOS verifier receipt supersedes both older ALPS routes. The `SUPABASE_RLS_POLICY_TO_ROLE_MISSING` failure is no longer present; all `api-contract-pack` gates pass, but `/Users/josh/Developer/alpsinsurance` is still dirty.

## Current Row

Source receipt:

`/Users/josh/Developer/skillos/state/pack-feedback-consumer-verification-tool-20260517T1148Z-api-contract-current.json`

```json
{
  "bead_id": "skillos-sued",
  "target_repo": "/Users/josh/Developer/alpsinsurance",
  "verification_status": "pass_dirty",
  "failure_codes": [],
  "target_dirty": true,
  "target_dirty_count": 1,
  "target_head": "74dc5ace2e8eb16a3b1b2adc8338c47afcc84e99",
  "doctor_status": "pass"
}
```

## Requested Owner Action

- Commit or otherwise settle the current ALPS dirty work.
- Rerun the SkillOS verifier:

```bash
cd /Users/josh/Developer/skillos
bin/skillos pack-feedback verify-consumers \
  --pack-name api-contract-pack \
  --output state/pack-feedback-consumer-verification-tool-<ts>-api-contract-current.json \
  --json
```

- Return a callback naming the ALPS commit SHA or durable dirty-work disposition plus the refreshed verifier receipt.

## Supersedes

This supersedes these ALPS-specific handoffs:

- `.flywheel/handoffs/20260517T0848Z-from-flywheel-to-alpsinsurance-api-contract-pack-current-commit-and-reverify.md`
- `.flywheel/handoffs/20260517T1028Z-from-flywheel-to-alpsinsurance-api-contract-pack-supabase-rls-policy-role.md`

Do not classify `skillos-sued` from the older timeout, stale pass-dirty, or stale RLS-policy failure rows.

## Acceptance

- `skillos-sued` is no longer `pass_dirty`, or the owner lane returns a bounded deferral explaining why the dirty state must remain.
- The callback references a refreshed verifier receipt path.

-- flywheel:1 (Codex)

Mission anchor: `d473c983e641881b38cbcff31d8a55343563cf358e9716151e25f391fec99528`
