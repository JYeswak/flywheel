---
name: validation-fixture-contract
description: Use when designing or reviewing validation fixtures, fixture IDs, replay commands, expected JSON receipt shapes, schema_version migrations, frontmatter validators, golden fixtures, or self-tests for contract-bearing artifacts.
---

# Validation Fixture Contract

## Status

Draft for skillos review. This file is a flywheel-local request artifact for bead
`flywheel-raq3`; it is not installed as a live skill.

## Trigger Phrases

- validation fixture
- fixture ID
- fixture naming
- replay command
- golden fixture
- expected receipt shape
- expected JSON receipt
- schema_version migration
- frontmatter validation
- mixed-version fixture
- malformed fixture
- self-test generator
- contract fixture
- validation harness
- dry-run validation

## Source Evidence

- New sibling skill request: `.flywheel/jeff-corpus/v1/learnings/06-skill-enhancement-matrix.md:39-42` names `validation-fixture-contract` and defines the owned gap: fixture ID naming, replay commands, receipt shape, and schema/frontmatter validation.
- Testing fixture pattern: `.flywheel/jeff-corpus/v1/learnings/02-code-patterns.md:70-89` says to adopt stable fixture IDs, deterministic seeds, replay commands, and expected receipt shape.
- Schema migration pattern: `.flywheel/jeff-corpus/v1/learnings/02-code-patterns.md:91-110` says schemas need `schema_version`, migration receipts, and mixed-version tests.
- Frontmatter validation pattern: `.flywheel/jeff-corpus/v1/learnings/02-code-patterns.md:154-173` says metadata-bearing skills, commands, plans, and doctrine artifacts need explicit frontmatter validators.
- Doctrine cluster: `.flywheel/jeff-corpus/v1/learnings/01-doctrine-cluster.md:26-42` turns claims into runnable gates, and `.flywheel/jeff-corpus/v1/learnings/01-doctrine-cluster.md:116-132` requires versioned validation and compatibility evidence.
- Receipt adaptation: `.flywheel/jeff-corpus/v1/learnings/01-doctrine-cluster.md:134-150` supports structured evidence receipts; flywheel keeps DID/DIDNT/GAPS fields instead of replacing worker callback shape.

## Hard Rules

1. Every validation fixture has a stable `fixture_id`, `schema_version`, `surface`, `case_class`, `input`, `expected_receipt`, `replay_command`, and explicit pass/fail expectation.
2. Fixture IDs are deterministic kebab-case: `<surface>-<case-class>-<expectation>-v<n>`, for example `callback-missing-evidence-fail-v1`.
3. Replay commands are copy-pasteable, local by default, and include `--json`; mutating validators must default to `--dry-run` or provide `--explain` before `--apply`.
4. Expected receipts are JSON contracts, not prose summaries. Minimum fields: `schema_version`, `status`, `fixture_id`, `failure_class` or `pass_reason`, and `evidence`.
5. Schema/frontmatter validators must include valid, missing-required, malformed, old-version, future-version, duplicate-id, and idempotent-replay fixtures.
6. Schema migrations must accept current and one declared previous version, emit a migration receipt, and fail closed on future unknown versions.
7. Fixtures never depend on live services, wall-clock randomness, external network calls, or ambient credentials.
8. Golden files must include the replay command that regenerates or verifies them.
9. Append-only surfaces are fixed by appended correction fixtures, not history rewrites.
10. Flywheel callback fixtures preserve DID/DIDNT/GAPS, `mission_fitness`, `josh_request_id`, and delivery verification fields.
11. A contract is not ready until its self-test fails against at least one intentionally malformed fixture.

## Fixture ID Taxonomy

Use this shape:

```text
<surface>-<case-class>-<expectation>-v<n>
```

Fields:

- `surface`: command or artifact family, such as `callback`, `mission-lock`, `skill-frontmatter`, or `dispatch`.
- `case-class`: the behavior under test, such as `missing-evidence`, `old-schema`, `future-schema`, `duplicate-id`, or `malformed-yaml`.
- `expectation`: `pass`, `fail`, `warn`, or `migrate`.
- `v<n>`: fixture contract version, not product version.

## Replay Command Template

Every fixture carries a command with no hidden setup:

```bash
<validator> --fixture tests/fixtures/<fixture_id>.json --json --dry-run
```

For read-only validators, `--dry-run` may be omitted only when the validator
declares `read_only_default=true` in `--schema --json` output.

## Expected Receipt Schema

Minimum receipt:

```json
{
  "schema_version": "validation-fixture-receipt/v1",
  "fixture_id": "callback-missing-evidence-fail-v1",
  "status": "pass|fail|warn|migrate",
  "surface": "callback",
  "failure_class": "missing_evidence",
  "pass_reason": null,
  "evidence": ["path/or/line/or/command"],
  "replay_command": "<validator> --fixture ... --json --dry-run"
}
```

Migration receipt extension:

```json
{
  "schema_version": "validation-fixture-receipt/v1",
  "fixture_id": "mission-lock-old-schema-migrate-v1",
  "status": "migrate",
  "from_schema_version": "mission-lock/v1",
  "to_schema_version": "mission-lock/v2",
  "migration_applied": true,
  "compatibility_checked": true
}
```

## Workflow

1. Name the contract surface and its source of truth.
2. Define the fixture ID taxonomy for that surface.
3. Write the smallest fixture matrix that proves valid, invalid, migration, and replay behavior.
4. Define expected JSON receipts before writing validator code.
5. Add the replay command beside each fixture.
6. Run the self-test and at least one intentionally failing fixture.
7. Stage publication instructions for Joshua or skillos review; do not publish JSM-managed skills directly from consumer sessions.

## Exact Prompt For Skillos

```text
Create or revise a skill named validation-fixture-contract for <surface>. Produce a concise SKILL.md plus any deterministic scripts needed to enforce: fixture ID taxonomy, replay command template, expected JSON receipt schemas, schema_version/frontmatter validation, migration fixtures, and an executable self-test. Use local deterministic fixtures only, default mutation commands to --dry-run or --explain, and preserve flywheel DID/DIDNT/GAPS callback fields when the surface is a worker receipt. Cite the Jeff corpus evidence that motivated each hard rule. Do not mutate live skills or run jsm push until Joshua approves publication.
```

## Anti-Patterns

| Anti-pattern | Why it fails | Required replacement |
|---|---|---|
| Narrative-only validation | Cannot replay or compare outcomes | JSON receipt plus replay command |
| Timestamp-derived fixture IDs | Non-deterministic and hard to diff | Stable kebab-case taxonomy |
| Golden file without generator | Artifact cannot be trusted after code drift | Golden plus replay command |
| Missing `schema_version` | No migration or compatibility path | Versioned schema and mixed-version fixtures |
| Live service fixture | Flaky and credential-shaped | Local deterministic fixture |
| Repair rewrites append-only log | Destroys chronology | Append correction with receipt |
| Future schema accepted silently | Fails open | Fail closed with explicit reason |
| Callback envelope replaces DID/DIDNT/GAPS | Breaks flywheel worker contract | Extend existing callback fields |

## Executable Self-Test

Run:

```bash
python3 scripts/self_test.py .
```

Expected pass output:

```json
{"status":"pass","checks":11}
```

## Publication Staging

After skillos review and Joshua approval:

```bash
jsm validate /path/to/validation-fixture-contract --json --offline
jsm push /path/to/validation-fixture-contract
```

No `jsm push` is authorized by this draft.
