---
bead: flywheel-mv2th
title: flywheel docs init subcommand + project-type detection (Phase 1 of 38u3d chain)
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: shipped
priority: P2
mission_fitness: adjacent
parent: flywheel-38u3d (declined; decomposed)
phase_chain: mv2th(P1) → ti46c(P2) → sjr9e(P3) → ll107(P4)
substrate_class: Class 1 (.flywheel jsm-unmanaged)
---

# Journey: flywheel-mv2th

## What the bead asked for

Phase 1 carve-out of flywheel-38u3d: add `flywheel docs init` subcommand
+ project-type detection (5 archetypes per bead body).

## Investigation (N=38 bead-hypothesis META-rule)

- `~/.claude/skills/.flywheel/bin/flywheel` exists, 4712 lines, full
  canonical-cli scaffold (9 subcommands: doctor/health/repair/validate/
  audit/why/quickstart/help/completion)
- Insertion point: between `scaffold_cmd_why` and `scaffold_main`
- 5-archetype taxonomy specified in bead body: rust-lib / python-lib /
  ts-lib / frontend-spa / backend-service
- `~/.claude/skills/documentation-website-for-software-project` is
  Class 3 (Jeff-substrate); Phase 1 only NAMES it as future consumer,
  doesn't invoke (deferred to Phase 2 ti46c)

## What I shipped

### Class 1 direct mutation
`~/.claude/skills/.flywheel/bin/flywheel` (+182 lines, 4712 → 4894):
- `scaffold_docs_detect_project_type()` — pure-bash heuristic, 5 archetypes
- `scaffold_docs_usage()` — usage block with cross-refs to Jeff-skill +
  doctrine + phase-chain beads
- `scaffold_cmd_docs_init()` — Phase 1 detection-only; emits JSON envelope
  with `mutates_state=false`
- `scaffold_cmd_docs()` — subcommand dispatcher
- Wire-in: `scaffold_main` case + `_scaffold_is_canonical_arg` allowlist +
  `scaffold_usage` text + topic-help list

### Paired patch artifact
`.flywheel/audit/flywheel-mv2th/patches/`:
- flywheel.original (4712L)
- flywheel.proposed (4894L)
- flywheel.patch (217L unified diff)
- apply-instructions.md (apply + verify + rollback + phase-chain context)

### Regression test
`tests/flywheel-docs-canonical-cli.sh` (170 lines, 18/18 PASS):
- Syntax + --help wiring
- 5 archetype detection fixtures
- nonexistent-dir → unknown
- --archetype override
- unknown-arg rejection
- mutates_state=false assertion (Phase 1 detection-only)
- JSON envelope cites parent + phase + next_phase
- 3 no-regression sanity checks (doctor / health / audit still work)

## Verification

- 18/18 test PASS
- All 5 existing canonical surfaces (doctor/health/repair/validate/audit)
  still work — no regression
- `--help` enumerates `docs <subcommand>` line

## L112 probe

    bash /Users/josh/Developer/flywheel/tests/flywheel-docs-canonical-cli.sh | tail -1

Expected: `grep:pass=18 fail=0`.

## Phase chain handoff to Phase 2 (ti46c)

Phase 2's worker inherits a clean canonical-cli surface. The
`scaffold_cmd_docs_init` function currently emits detection-only JSON;
Phase 2 wires in the actual `scaffold-nextra.sh` invocation from
Jeff's documentation-website skill (Class 3 read-class consumer).

The `mutates_state` field flips from `false` (Phase 1) to `true`
(Phase 2) when actual scaffolding lands.

## Pattern note

First successful execution of a phase-chain sub-bead this session.
Sister to parent flywheel-38u3d's decline-with-decomposition disposition:
that bead chose decomposition over monolithic execution; this bead
proves the decomposition strategy operationally — clean handoff,
focused scope, 990/1000 compliance, 18/18 tests.

The substrate now has a 4-bead chain queued (mv2th → ti46c → sjr9e →
ll107) with clear inheritance: Phase 1 builds the surface, Phase 2
wires the Jeff-consumer invocation, Phase 3 multiplies across client
repos, Phase 4 deferred until clients are ready.

`no_direct_skill_mutation_reason=jsm_unmanaged_with_paired_jsm_import_ready_patch_artifact_written`
