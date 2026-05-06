---
name: validation-fixture-contract
description: Candidate skill for turning validation claims into schema-versioned fixtures, golden outputs, replay commands, and frontmatter checks.
status: approval_only
source_bead: flywheel-w3pr.3
phase4_verdict: ADOPT
---

# Validation Fixture Contract

Use this candidate skill when a new flywheel surface claims validation, schema,
frontmatter, fixture, or replay coverage.

## Trigger

- A receipt schema, callback validator, CLI, doctor signal, skill, command, or
  doctrine artifact gains tests.
- A worker says "validated" but evidence is fixture-light or prose-only.

## Contract

Every validation fixture set should name:

- `fixture_id`
- input artifact path
- expected output path or inline JSON expectation
- replay command
- `schema_version`
- failure class covered
- owner bead
- whether stdout/stderr cleanliness is asserted

Frontmatter-bearing artifacts should be parsed structurally before propagation.
Grepping for `---` is not validation.

## Source Evidence

- Phase 4 verdict: `.flywheel/jeff-corpus/v1/learnings/04-adopt-extend-avoid.md`, "Testing patterns and fixture conventions" = ADOPT.
- `aadc/AGENTS.md:171` cites fixture-based input/expected tests.
- `aadc/tests/e2e_fixtures.sh:2` implements E2E fixture tests.
- `frankenscipy/docs/TEST_CONVENTIONS.md:1` is a dedicated test convention surface.
- `franken_numpy/artifacts/contracts/TESTING_AND_LOGGING_CONVENTIONS_V1.md:1` versions testing/logging conventions.
- `pi_agent_rust/tests/ext_conformance/artifacts/templates-davila7/cli-tool/components/skills/productivity/skill-creator/scripts/quick_validate.py:1` validates skill/frontmatter shape.

## Approval Gates

- Install only after `flywheel-0egk` proves the contract against flywheel fixtures.
- Keep this draft approval-only until the live skill destination and owner are approved.
