# flywheel-c5zi rollback schema evidence

did=7/7 didnt=none gaps=none tests=PASS

## Result

Shipped `storage-override/v1` rollback guard alignment. The schema now requires
`rollback_guard` to be an object with `requires_event`, `rollback_id`,
`before_state`, `after_state`, `idempotency_key`, `timestamp`, and
`failure_class`.

Evidence paths:

- `.flywheel/validation-schema/v1/storage-override.schema.json`
- `.flywheel/doctrine/storage-override-schema.md`
- `tests/storage-override.sh`
- `tests/fixtures/storage-override/valid-rollback-guard.json`
- `tests/fixtures/storage-override/invalid-rollback-guard.json`

## Acceptance Gates

- AG1 canonical shape: `rollback_guard` is object-shaped in schema_version
  `storage-override/v1`.
- AG2 schema update: `.flywheel/validation-schema/v1/storage-override.schema.json`
  rejects the old string shape and requires rollback idempotency fields.
- AG3 generated receipts: `tests/storage-override.sh` validates every generated
  receipt with JSON Schema before doctor assertions.
- AG4 expected fixtures: valid, expired, wrong-target, and auto-clear generated
  receipts pass schema validation before behavior checks.
- AG5 invalid fixture: `tests/fixtures/storage-override/invalid-rollback-guard.json`
  proves old string `rollback_guard` is rejected.
- Doctrine: `.flywheel/doctrine/storage-override-schema.md` records the operator
  contract for receipts and fixture authors.
- Failure taxonomy: `dcg_blocked` maps to `dcg_blocked_destructive_command`;
  receipt-local `rollback_failed` routes to taxonomy `persistent` or
  `correctness` until promoted.

## Validation

```bash
jq empty .flywheel/validation-schema/v1/storage-override.schema.json tests/fixtures/storage-override/valid-rollback-guard.json tests/fixtures/storage-override/invalid-rollback-guard.json
```

Result: pass.

```bash
bash tests/storage-override.sh
```

Result: `16 passed, 0 failed`.

## Four-Lens Self-Grade

Brand voice: pass. The receipt states the concrete substrate contract and avoids
claims that do not point at files or tests.

Sniff lens / Three Judges: Jeffrey pass because the schema has executable proof
and rejects the old shape; Donella pass because rollback guards preserve the
feedback loop from override to clear event; Joshua pass because rollback
receipts are operator checkpoints, not paperwork.

Jeff lens: pass. The contract is versioned as `storage-override/v1`, includes
`schema_version`, and the fixture test round-trips generated receipts through
the schema validator.

Public lens: pass. The publishability bar facets are: problem clarity, artifact
completeness, executable proof, operator safety, integration fit, maintenance
cost, and fork-and-star legibility. A public operator can inspect the schema,
fixtures, and test command and see why the rollback chain holds under pressure.

Joshua lens: pass. 25yr ops pattern: rollback receipts that do not validate are
the silent ops failure; every rollback step is a runbook checkpoint, and if the
receipt schema drifts, the rollback chain breaks under load.

## Survey

socraticode_queries=4 indexed_chunks_observed=40 skill_discoveries=0
sd_ids=none
