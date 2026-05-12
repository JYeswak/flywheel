---
contract: jeff-validation-fixture-contract
status: locked
source_bead: flywheel-0egk
parent_synthesis: flywheel-avlj
phase4_verdict: ADOPT
jeff_patterns: [P03, P04, P07]
doctrine_refs: [L71, L80]
related_skills: [testing-conformance-harnesses, testing-schema-pinned-fixtures, testing-golden-artifacts, migration-architect, parity-contract-markdown-json]
created: 2026-05-06
---

# Jeff Validation Fixture Contract

Codifies how flywheel surfaces import Jeff Emanuel's fixture / schema-version /
frontmatter validation conventions (`aadc`, `franken_numpy`, `franken_engine`,
`meta_skill`, `beads_rust`) so that "validated" actually carries weight when a
worker writes it in a callback.

This contract is load-bearing for any new validation substrate: receipt
schemas, callback validators, doctor signals, dispatch templates, skill
frontmatter, and AGENTS L-rule additions.

## When to apply

ALWAYS apply when:

- A new `*.schema.json` lands under `.flywheel/validation-schema/v1/`.
- A worker callback claims "tests pass" or "validated" against a new gate.
- A receipt envelope, doctor signal, or dispatch template is added or
  expanded (PASS/WARN/FAIL contract).
- A skill, command, or AGENTS L-rule is authored, edited, or propagated and
  carries YAML frontmatter.
- A schema is bumped (e.g. `tick-receipt/v1` -> `v2`).

DO NOT apply when:

- The artifact has no durable consumers (one-shot dispatch prose, scratch
  notes in `.flywheel/PLANS/.../scratch/`).
- The change is a literal string fix in a non-schema file (typo in prose).
- The validation is performed by an upstream Jeff binary whose contract is
  already pinned via `dicklesworthstone-stack` (do not re-author its tests).

## Pattern (Jeff source)

| Pattern | Jeff source | ZestStream adaptation |
|---|---|---|
| Input/expected fixture pairs | `aadc/AGENTS.md:217`, `aadc/tests/e2e_fixtures.sh:2` | `.flywheel/fixtures/*.input.*` + `*.expected.*` |
| Structured fixture metadata | `franken_numpy/TODO_GRANULAR_EXECUTION.md:240` (`fixture_id`, `seed`, `mode`, `env_fingerprint`, `artifact_refs`, `reason_code`) | every fixture row carries `fixture_id` + `failure_class` + `replay_command` |
| Schema-version constants in code | `franken_engine/crates/franken-engine/src/lowering_gap_inventory.rs:11`, `:880`, `:1799` | `schema_version: "<surface>/v1"` field MUST appear in every receipt JSON, asserted in tests |
| Schema-mismatch fail-closed | `beads_rust/tests/bench_contention_replay.rs:355` | replay/validators reject unknown `schema_version` rather than coercing |
| Frontmatter structural validation | `meta_skill/BEST_PRACTICES_FOR_WRITING_AND_USING_SKILLS_MD_FILES.md:61`, `meta_skill/PLAN_TO_MAKE_METASKILL_CLI.md:2111` | parse YAML, do not grep `^---` |

## Required fixture fields

Every validation-fixture row MUST name:

1. `fixture_id` — stable string (e.g. `tick-receipt-malformed-schema-v1`).
2. `input_path` — file under repo, deterministic content.
3. `expected_path` OR `expected_inline` — golden output (JSON or text).
4. `replay_command` — copy-pasteable; runs from repo root; no env coupling
   beyond what fixture itself names.
5. `schema_version` — surface-tagged version pin (e.g. `tick-receipt/v1`).
6. `failure_class` — trauma class or invariant the fixture exercises.
7. `owner_bead` — `flywheel-XXXX` ID accountable for the fixture.
8. `stdout_clean` / `stderr_clean` — booleans, asserted explicitly.

A fixture missing any of these MUST fail the contract probe, not pass with a
warning. "Soft warn" is how validation-theater leaks in.

## Frontmatter validation expectations

- Skills (`SKILL.md`), commands (`*.md` under `.claude/commands/`), AGENTS
  rules, and dispatch templates with YAML frontmatter MUST be parsed via
  `yaml.safe_load` (Python) or equivalent — never `grep -E '^---'`.
- Required-section validation lifts from `meta_skill/PLAN_TO_MAKE_METASKILL_CLI.md:2111`:
  the parser knows the schema; the schema knows what is mandatory.
- AGENTS L-rule frontmatter (the L## numbering header in
  `.flywheel/AGENTS-CANONICAL.md`) MUST validate before any `agents-md-fleet-propagator.sh`
  run pushes it across the ecosystem.

## Existing flywheel surfaces this contract covers

- `.flywheel/validation-schema/v1/tick-receipt.schema.json`
- `.flywheel/validation-schema/v1/recovery-receipt.schema.json`
- `.flywheel/validation-schema/v1/wire-or-explain-ledger.schema.json`
- `.flywheel/validation-schema/v1/mission-lock-output.schema.json`
- `.flywheel/validation-schema/v1/dispatch-canonical-cli-decision.schema.json`
- `.flywheel/validation-schema/v1/identity-registration-deferral.schema.json`
- `.flywheel/validation-schema/v1/orch-donella-trace-decision.schema.json`
- `.flywheel/validation-schema/v1/skillos-template-handshake-request.schema.json`

Each of these MUST grow a fixture set under `.flywheel/fixtures/<surface>/`
with the eight fields above when next touched. Existing
`.flywheel/fixtures/fleet-coherence-fixtures.jsonl` is the closest reference
implementation for the JSONL fixture shape.

## Compliance probe (how the contract is enforced)

A doctor probe (per `jeff-doctor-repair-contract`) MUST exist for this
contract and MUST emit:

```json
{
  "schema_version": "validation-fixture-contract-doctor/v1",
  "status": "pass|warn|fail",
  "surfaces_audited": <int>,
  "fixtures_total": <int>,
  "missing_schema_version": [...],
  "missing_replay_command": [...],
  "missing_expected_output": [...],
  "frontmatter_grep_only": [...]
}
```

`fail` when any required field is absent on a `*.schema.json` consumer or any
frontmatter-bearing artifact in the propagation set.

## Negative example (the contract catches this)

A receipt schema lands without `schema_version` in the JSON envelope and the
test asserts only "field X exists". This contract:

1. Flags missing `schema_version` constant.
2. Refuses to accept a "validated" callback for the surface.
3. Files an auto-bead under owner_bead for the gap.

## Anti-patterns (DIVERGE from Jeff)

- Do NOT inline expected outputs in test source files. Use sidecar
  `.expected.*` files so updates show as content diffs, not code diffs.
- Do NOT version-bump silently. A schema version bump triggers a mixed-version
  fixture pair (v1 input + v1 expected, v1 input + v2 expected) before any
  consumer migrates.

## DOD reference

This contract document satisfies `flywheel-0egk` acceptance gates 1, 3, 4
prose-side. Gate 2 (existing fixtures audited) and gate 5 (tests pass) are
follow-on beads filed against this contract path.
