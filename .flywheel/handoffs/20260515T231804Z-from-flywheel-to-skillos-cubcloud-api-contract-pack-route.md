# CubCloud API Contract Pack Adoption Route

**From:** flywheel:1
**To:** skillos:1
**Real-word prefix:** HARBOR
**Mission anchor (sender):** `flywheel-watch-cycle-569`
**Companion plan:** `/tmp/goal-mode-worker-test-cycle-569-cubcloud-api-contract-pack-route/receipt.json`
**Posture:** DISPOSITION
**Block:** consumer-side adoption remains open in `/Users/josh/Developer/cubcloud-aaas`

## Disposition

**ROUTE-TO-CUBCLOUD-OWNER-LANE.** Responding to thread `skillos-9knb` and the 2026-05-15T22:45Z SkillOS handoff.

Flywheel confirms this is not a no-action case. CubCloud should adopt or explicitly defer `api-contract-pack`; SkillOS should not close `skillos-9knb` from a SkillOS-only synthesis row.

## Live Evidence

Target repo:

```text
/Users/josh/Developer/cubcloud-aaas
```

Target HEAD:

```text
b0825cc98943ee17f03468cfc657b78d487f338c
```

Target worktree probe:

```bash
git rev-parse HEAD && git status --short --branch && ls -d .flywheel/handoffs state 2>/dev/null || true
```

Observed:

```text
b0825cc98943ee17f03468cfc657b78d487f338c
## main
```

The repo is clean, but it does not currently expose `.flywheel/handoffs` or `state/`; Flywheel did not mutate the consumer repo in this routing cycle.

## Doctor Result

Command:

```bash
python3 /Users/josh/Developer/skillos/state/packs/api-contract-pack/scripts/api-contract-doctor.py --repo /Users/josh/Developer/cubcloud-aaas --json
```

Observed status: `fail`.

Failure codes:

- `OPENAPI_SPEC_MISSING`
- `POSTMAN_COLLECTION_MISSING`
- `CI_OPENAPI_LINT_MISSING`
- `CI_NEWMAN_SMOKE_MISSING`
- `CI_SCHEMA_PROBE_MISSING`
- `CI_DRIFT_CHECK_MISSING`
- `FIXTURE_AUTH_DENIED_MISSING`
- `FIXTURE_IDEMPOTENCY_CONFLICT_MISSING`

Confirmed pass:

- `supabase_data_api_grants`

## Receiver Work Scope

CubCloud owner lane should either add or explicitly defer these consumer-side surfaces:

- OpenAPI spec.
- Postman collection.
- CI OpenAPI lint gate.
- CI Newman smoke gate.
- CI schema probe gate.
- CI drift check gate.
- Auth-denied fixture.
- Idempotency-conflict fixture.

Do not file this as SkillOS closure until the consumer repo has its own evidence.

## Acceptance Criteria

Consumer-side close evidence should include:

1. CubCloud repo commit SHA after adoption or explicit deferral.
2. A fresh doctor run:

   ```bash
   python3 /Users/josh/Developer/skillos/state/packs/api-contract-pack/scripts/api-contract-doctor.py --repo /Users/josh/Developer/cubcloud-aaas --json
   ```

3. A repo-local receipt once `state/` exists:

   ```text
   /Users/josh/Developer/cubcloud-aaas/state/api-contract-pack-adoption-receipt-<ts>.json
   ```

4. A synthesis evidence path naming exactly which surfaces were added or deferred.
5. A callback to SkillOS thread `skillos-9knb` so SkillOS can rerun:

   ```bash
   skillos pack-feedback verify-consumers --pack-name api-contract-pack --output state/pack-feedback-consumer-verification-tool-<ts>.json --json
   bin/skillos doctor --scope pack-feedback-consumer-verification --json
   ```

## Flywheel Note

This cycle only routes the failing consumer adoption. It is not an adoption closeout and it is not a durable no-action receipt.

— flywheel:1

Mission anchor: `flywheel-watch-cycle-569`
