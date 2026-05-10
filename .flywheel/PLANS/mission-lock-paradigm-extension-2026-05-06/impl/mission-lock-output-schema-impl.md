---
title: "Mission-Lock Output Schema Implementation"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# Mission-Lock Output Schema Implementation

Date: 2026-05-06
Bead: `flywheel-mission-lock-output-schema-amendments-2026-05-06`
Wave: Phase 4 Wave 2 #4

## Scope

This implementation adds the canonical mission-lock output envelope for Wave 3
scaffold validation. It does not mutate `.flywheel/MISSION.md`, Wave 1
deliverables, or earlier Wave 2 contracts.

## Shipped Artifacts

- Schema: `.flywheel/validation-schema/v1/mission-lock-output.schema.json`
- Validator: `.flywheel/scripts/mission-lock-output-schema-validator.sh`
- Golden test: `.flywheel/tests/test_mission_lock_output_schema_validator.sh`

## Contract

The schema is JSON Schema draft-07. The root object remains additive so Wave 3
can add fields without breaking older consumers, while the required nested
objects are strict enough to close the security, idempotency, and
cross-cutting audit findings.

Required root fields:

- `schema_version`
- `mission_anchor_rev`
- `lock_hash`
- `locked_at`
- `status`
- `mission_license`
- `negative_invariants`
- `cross_cutting_concerns_addressed`
- `mission_anchor_text`
- `provenance`
- `surface_principal_metadata`
- `skill_surface_map`
- `failure_mode_matrix`
- `receipt_identity_envelope`

The `lock_hash` pattern accepts both `sha256:<64 hex>` and bare 64-hex hashes
because the live repo-local mission currently uses bare lock hashes.

## Validator Behavior

The validator is read-only and exposes the canonical CLI flags:
`--info`, `--help`, `--examples`, `--json`, and `--quiet`.

Input sources:

- Full JSON payload files.
- Simple YAML frontmatter in `MISSION.md`, with scalar or inline JSON values.
- Sidecar JSON files next to `MISSION.md`.
- Top-of-file key/value metadata before the first second-level heading.

The validator returns a pass/fail JSON envelope with stable error codes such as
`missing_mission_anchor_rev`, `missing_lock_hash`, `invalid_status`,
`missing_negative_invariants`, and
`missing_cross_cutting_concerns_addressed`.

## Golden Coverage

The test generates six golden cases required by dispatch:

- Valid `MISSION.md` with all required fields passes.
- Missing `mission_anchor_rev` fails.
- Missing `lock_hash` fails.
- Bad `status` enum fails.
- Missing `negative_invariants` fails.
- Missing `cross_cutting_concerns_addressed` fails.

It also checks script syntax, schema parse, draft-07 schema validity when the
`jsonschema` Python module is available, canonical CLI flags, quiet mode, and
sidecar JSON input.

## Research Receipt

Socraticode pre-flight used seven queries against canonical
`/Users/josh/Developer/flywheel`. Relevant precedents:

- Existing draft-07 schema style in
  `.flywheel/validation-schema/v1/recovery-ledger.schema.json`.
- Existing schema-validation style under
  `templates/flywheel-install/polish-gate/`.
- Existing MISSION frontmatter fixture style in
  `tests/flywheel-loop-core.sh` and install-contract tests.
- Wave 1 security and cross-cutting INCIDENTS entries that define the required
  negative-invariant and skill-routing fields.

## Validation

Primary test:

```bash
bash .flywheel/tests/test_mission_lock_output_schema_validator.sh
```

Dispatch L112 gate:

```bash
test -f /Users/josh/Developer/flywheel/.flywheel/validation-schema/v1/mission-lock-output.schema.json && \
  test -x /Users/josh/Developer/flywheel/.flywheel/scripts/mission-lock-output-schema-validator.sh && \
  bash /Users/josh/Developer/flywheel/.flywheel/scripts/mission-lock-output-schema-validator.sh --info > /dev/null 2>&1 && \
  bash /Users/josh/Developer/flywheel/.flywheel/tests/test_mission_lock_output_schema_validator.sh > /dev/null 2>&1 && \
  grep -q "Phase 4 Wave 2 #4 shipped: mission-lock output schema" /Users/josh/Developer/flywheel/INCIDENTS.md && \
  echo OK_wave2_mission_lock_output_schema_shipped
```
