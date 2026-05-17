# api-contract-pack ALPS Supabase RLS policy-to-role route

**From:** flywheel:1 (Codex)  
**To:** alpsinsurance owner lane  
**Real-word prefix:** HARBOR  
**Mission anchor (sender):** `d473c983e641881b38cbcff31d8a55343563cf358e9716151e25f391fec99528`  
**Companion plan:** `/Users/josh/Developer/flywheel/state/pack-feedback-consumer-verification-owner-routing-20260517T1028Z.json`  
**Posture:** RATIFICATION-REQUEST  
**Block:** SkillOS pack-feedback supersession for `skillos-sued`

## TL;DR

The earlier ALPS `commit-and-reverify` handoff is stale. A newer SkillOS verifier receipt reports `skillos-sued` as `fail` with `SUPABASE_RLS_POLICY_TO_ROLE_MISSING`; dirty count is now 1, not the prior 231-row pass-dirty state.

## Current Row

Source receipt:

`/Users/josh/Developer/skillos/state/pack-feedback-consumer-verification-tool-20260517T0938Z-api-contract-current.json`

```json
{
  "bead_id": "skillos-sued",
  "target_repo": "/Users/josh/Developer/alpsinsurance",
  "verification_status": "fail",
  "failure_codes": ["SUPABASE_RLS_POLICY_TO_ROLE_MISSING"],
  "target_dirty": true,
  "target_dirty_count": 1,
  "target_head": "8fd7be59f8ccb9e2c6f192ba78d795bbc93485f4",
  "open_gate": "supabase_data_api_grants"
}
```

## Requested Owner Action

Add or document the Supabase RLS policy-to-role mapping required by `api-contract-pack`, then rerun the SkillOS verifier:

```bash
cd /Users/josh/Developer/skillos
bin/skillos pack-feedback verify-consumers \
  --pack-name api-contract-pack \
  --output state/pack-feedback-consumer-verification-tool-<ts>-api-contract-current.json \
  --json
```

Return a callback naming the ALPS commit SHA or durable policy disposition and the refreshed verifier receipt path.

## Supersedes

This supersedes `.flywheel/handoffs/20260517T0848Z-from-flywheel-to-alpsinsurance-api-contract-pack-current-commit-and-reverify.md` for ALPS only. The older route was based on `/Users/josh/Developer/skillos/state/pack-feedback-consumer-verification-tool-20260517T0425Z-api-contract-current.json`.

## Acceptance

- `skillos-sued` no longer reports `SUPABASE_RLS_POLICY_TO_ROLE_MISSING`, or the owner lane returns a bounded deferral explaining why the policy mapping is intentionally absent.
- The callback references a refreshed verifier receipt path.
- Do not classify this as the older timeout route or stale pass-dirty route.

-- flywheel:1 (Codex)

Mission anchor: `d473c983e641881b38cbcff31d8a55343563cf358e9716151e25f391fec99528`
