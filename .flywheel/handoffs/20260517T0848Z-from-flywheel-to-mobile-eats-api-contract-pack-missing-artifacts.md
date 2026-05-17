# api-contract-pack mobile-eats missing artifacts route

**From:** flywheel:1 (Codex)
**To:** mobile-eats owner lane
**Real-word prefix:** PINNACLE
**Mission anchor (sender):** `d473c983e641881b38cbcff31d8a55343563cf358e9716151e25f391fec99528`
**Companion plan:** none
**Posture:** RATIFICATION-REQUEST
**Block:** SkillOS pack-feedback supersession for `skillos-7vrr`

## TL;DR

SkillOS current `api-contract-pack` consumer verification still fails for `/Users/josh/Developer/mobile-eats`. OpenAPI and Postman gates pass; the remaining gap is missing CI coverage and a validation-error fixture artifact.

## Current Row

Source receipt:

`/Users/josh/Developer/skillos/state/pack-feedback-consumer-verification-tool-20260517T0425Z-api-contract-current.json`

```json
{
  "bead_id": "skillos-7vrr",
  "target_repo": "/Users/josh/Developer/mobile-eats",
  "verification_status": "fail",
  "routing": "author-missing-artifacts",
  "target_dirty": true,
  "target_dirty_count": 40,
  "failure_codes": [
    "CI_OPENAPI_LINT_MISSING",
    "CI_NEWMAN_SMOKE_MISSING",
    "CI_SCHEMA_PROBE_MISSING",
    "CI_DRIFT_CHECK_MISSING",
    "FIXTURE_VALIDATION_ERROR_MISSING"
  ]
}
```

## Requested Owner Action

- Author the missing `api-contract-pack` CI checks and validation-error fixture in `mobile-eats`.
- Preserve existing dirty work; do not discard unrelated changes.
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

- `skillos-7vrr` no longer reports the five missing CI/fixture artifacts, or the owner lane returns a durable deferral SkillOS can consume.
- Callback names changed files, commit/disposition evidence, and the refreshed verifier receipt.

— flywheel:1 (Codex)

Mission anchor: `d473c983e641881b38cbcff31d8a55343563cf358e9716151e25f391fec99528`
