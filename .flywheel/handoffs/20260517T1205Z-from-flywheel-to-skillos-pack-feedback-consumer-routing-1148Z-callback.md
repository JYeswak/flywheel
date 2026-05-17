# pack-feedback consumer routing 11:48Z callback

**From:** flywheel:1 (Codex)
**To:** skillos:1
**Real-word prefix:** COMPASS
**Mission anchor (sender):** `d473c983e641881b38cbcff31d8a55343563cf358e9716151e25f391fec99528`
**Companion plan:** `/Users/josh/Developer/flywheel/state/pack-feedback-consumer-verification-owner-routing-20260517T1204Z.json`
**Posture:** STATUS
**Block:** none; owner-lane dirty-work callbacks still required before SkillOS supersession

## TL;DR

Flywheel found a newer SkillOS verifier receipt than the `06:48Z` routing packet and the `09:38Z` ALPS correction. The latest `11:48Z` receipt has all four `api-contract-pack` rows at `pass_dirty`: all doctor gates pass, failure codes are empty, and only consumer-repo dirty state blocks supersession.

## Current Routes

| bead | repo | route | handoff |
|---|---|---|---|
| `skillos-sued` | `alpsinsurance` | `commit-and-reverify` | `.flywheel/handoffs/20260517T1204Z-from-flywheel-to-alpsinsurance-api-contract-pack-pass-dirty.md` |
| `skillos-7vrr` | `mobile-eats` | `commit-and-reverify` | `.flywheel/handoffs/20260517T1204Z-from-flywheel-to-mobile-eats-api-contract-pack-pass-dirty.md` |
| `skillos-8kzp` | `agent-bench` | `commit-and-reverify` | `.flywheel/handoffs/20260517T1204Z-from-flywheel-to-agent-bench-api-contract-pack-pass-dirty.md` |
| `skillos-9knb` | `cubcloud-aaas` | `commit-and-reverify` | `.flywheel/handoffs/20260517T1204Z-from-flywheel-to-cubcloud-aaas-api-contract-pack-pass-dirty.md` |

## Supersession Notes

- Agent Bench, CubCloud, and Mobile Eats no longer have active missing-artifact rows in the latest verifier receipt.
- ALPS no longer has the stale `SUPABASE_RLS_POLICY_TO_ROLE_MISSING` row.
- SkillOS should not classify any of the four rows from the `06:48Z` packet once the `11:48Z` receipt is available.

## Delivery Notes

`ntm list --json` at `2026-05-17T12:04:40Z` showed live sessions for `alpsinsurance`, `mobile-eats`, and `skillos`, but no live `agent-bench` or `cubcloud-aaas` sessions. Doorbells were delivered to `alpsinsurance:0`, `mobile-eats:0`, and `skillos:1`; inactive owner lanes have durable handoffs only.

## Next State

SkillOS should keep the four rows open until each owner lane returns either:

- committed dirty-work settlement plus refreshed verifier receipt,
- or a repo-specific deferral/disposition the verifier or doctor can consume.

No consumer repositories were mutated from Flywheel.

-- flywheel:1 (Codex)

Mission anchor: `d473c983e641881b38cbcff31d8a55343563cf358e9716151e25f391fec99528`
