---
bead: flywheel-38u3d
title: Nextra docs scaffold — DECLINED + decomposed into 4-phase chain
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: shipped (declined; sub-beads queued)
priority: P2
mission_fitness: drift
disposition: DECLINED with decomposition
sub_beads: mv2th (P2 P1) + ti46c (P2 P2) + sjr9e (P3 P3) + ll107 (P3 P4)
---

# Journey: flywheel-38u3d

## What the bead asked for

Build `flywheel docs init` + scaffold Nextra 4 sites across 6 repos
(flywheel/alps/mobile-eats/blackfoot/terratitle/vrtx). 7 acceptance
gates. Bead body explicitly suggested 4-phase decomposition.

## Investigation (N=37 bead-hypothesis META-rule)

Substrate probe:
- `documentation-website-for-software-project` is **Jeffrey's Premium
  Skill** → Class 3 (Jeff-substrate, READ-ONLY consumer per 3-class
  taxonomy)
- `scripts/scaffold-nextra.sh` exists in Jeff-skill (consumer-class
  invocation allowed)
- `references/PROJECT-TYPES.md` exists in Jeff-skill (read-class)
- `~/.claude/skills/.flywheel/bin/flywheel` is Class 1 (Joshua-unmanaged);
  adding subcommand = direct mutation + paired patch
- Phase 1 alone (cmd + detection) is 1-2 hours; exceeds session-tick budget

Verdict: DECLINE + decompose, honoring bead-body's explicit instruction.

## What I shipped

4 sub-beads with concrete phase scopes + dependency chain:
- **flywheel-mv2th** (P2 Phase 1): docs init subcommand + project-type detection
- **flywheel-ti46c** (P2 Phase 2): dogfood on flywheel repo
- **flywheel-sjr9e** (P3 Phase 3): alps + mobile-eats
- **flywheel-ll107** (P3 Phase 4): blackfoot + terratitle + vrtx (deferred)

Dependency chain: mv2th → ti46c (blocks) → sjr9e (blocks) → ll107 (blocks).

Each sub-bead cites parent + relevant doctrine docs +
cross-repo-mutator class for its target substrate(s).

## Verification

- 4 sub-beads exist
- Dependency chain wired via br dep add
- Parent bead's 7 gates distributed across sub-beads (1 in mv2th, 4 in
  ti46c, 1 in sjr9e, 1 in ll107)

## L112 probe

    br dep tree flywheel-38u3d 2>&1 | grep -E "mv2th|ti46c|sjr9e|ll107" | wc -l | tr -d ' '

Expected: positive integer ≥ 4 (all 4 sub-beads in dependency tree).

## Pattern note — first DECLINE-with-decomposition this session

Sister to kwjja Option D decision (chose cheapest mechanization) and
r9pri Option A (doctrine doc + follow-up bead). The decline-with-
decomposition pattern is a different shape: rather than
ship-cheapest, the worker DECLINES + files the natural-unit
decomposition.

This is the canonical action when:
1. Bead body explicitly says decompose
2. Phase 1 alone exceeds session-tick budget
3. Decomposition mechanizes future tick efficiency (orch dispatches
   sub-beads at appropriate priority)

Filed `pattern-emerged-decline-with-decomposition-when-bead-body-says-
decompose-bead-hypothesis-N37-instance`.

## Cluster shape note

This bead doesn't add a new fix shape; it's a disposition class
(decline + decompose). The 25 fix shapes in the 2xdi/kwjja/r9pri arc
remain at 25. But this bead demonstrates that the worker discipline
extends beyond the recipe set to disposition decisions.

The decline callback shape (`DECLINED <task_id> reason=scope-mismatch
br_close_executed=not_applicable`) is the canonical signal for orch
to handle the decomposition fan-out.
