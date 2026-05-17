# api-contract-pack CubCloud missing artifacts route

**From:** flywheel:1 (Codex)
**To:** cubcloud-aaas owner lane
**Real-word prefix:** RIDGE
**Mission anchor (sender):** `d473c983e641881b38cbcff31d8a55343563cf358e9716151e25f391fec99528`
**Companion plan:** none
**Posture:** RATIFICATION-REQUEST
**Block:** SkillOS pack-feedback supersession for `skillos-9knb`

## TL;DR

SkillOS current `api-contract-pack` consumer verification still fails for `/Users/josh/Developer/cubcloud-aaas`. This remains an owner-lane artifact-authoring route; SkillOS should not mutate the consumer repo from the blocker tick.

## Current Row

Source receipt:

`/Users/josh/Developer/skillos/state/pack-feedback-consumer-verification-tool-20260517T0425Z-api-contract-current.json`

```json
{
  "bead_id": "skillos-9knb",
  "target_repo": "/Users/josh/Developer/cubcloud-aaas",
  "verification_status": "fail",
  "routing": "author-missing-artifacts",
  "target_dirty": true,
  "target_dirty_count": 2,
  "failure_codes": [
    "OPENAPI_SPEC_MISSING",
    "POSTMAN_COLLECTION_MISSING",
    "CI_OPENAPI_LINT_MISSING",
    "CI_NEWMAN_SMOKE_MISSING",
    "CI_SCHEMA_PROBE_MISSING",
    "CI_DRIFT_CHECK_MISSING",
    "FIXTURE_AUTH_DENIED_MISSING",
    "FIXTURE_IDEMPOTENCY_CONFLICT_MISSING"
  ]
}
```

## Requested Owner Action

- Author the missing OpenAPI, Postman, CI, and fixture artifacts in `cubcloud-aaas`.
- Preserve the two existing dirty entries unless they are part of the owner-lane fix.
- Rerun the SkillOS verifier:

```bash
cd /Users/josh/Developer/skillos
bin/skillos pack-feedback verify-consumers \
  --pack-name api-contract-pack \
  --output state/pack-feedback-consumer-verification-tool-<ts>-api-contract-current.json \
  --json
```

- Return either a pass receipt, a commit SHA plus verifier receipt, or a repo-specific deferral.

## Acceptance

- `skillos-9knb` no longer reports missing `api-contract-pack` artifacts, or the owner lane returns a durable deferral SkillOS can consume.
- Callback names changed files, commit/disposition evidence, and the refreshed verifier receipt.

— flywheel:1 (Codex)

Mission anchor: `d473c983e641881b38cbcff31d8a55343563cf358e9716151e25f391fec99528`
