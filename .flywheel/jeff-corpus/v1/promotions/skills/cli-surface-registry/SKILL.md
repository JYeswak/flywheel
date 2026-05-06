---
name: cli-surface-registry
description: Candidate skill for deriving CLI help, examples, schemas, output modes, and ownership from a single registry.
status: approval_only
source_bead: flywheel-w3pr.3
phase4_verdict: ADOPT
---

# CLI Surface Registry

Use this candidate skill when a flywheel CLI adds commands, flags, schemas,
examples, or machine-readable output.

## Contract

Every CLI command should have one registry row with:

- command name
- owner
- lane
- schema id
- supported output formats
- examples
- canonical exit codes
- mutation posture
- docs path

Help, info, examples, version, schema, and JSON checks should derive from or
validate against that row.

## Source Evidence

- Phase 4 verdict: `.flywheel/jeff-corpus/v1/learnings/04-adopt-extend-avoid.md`, "Canonical CLI surface registry" = ADOPT.
- `ntm/docs/robot-command-registry.md:1` makes the robot registry the source of truth.
- `ntm/docs/robot-surface-taxonomy.md:1` defines canonical operator-loop lanes.
- `coding_agent_session_search/src/lib.rs:2902` suppresses logs in robot mode.
- `destructive_command_guard/docs/adr-002-robot-mode-api.md:91` standardizes robot mode stdout/stderr, exit codes, schema version, and metadata envelopes.

## Approval Gates

- Install only after `flywheel-ryzt` proves registry-derived checks against flywheel CLIs.
- This draft does not replace `canonical-cli-scoping`; it would be the workflow guide for applying L82.
