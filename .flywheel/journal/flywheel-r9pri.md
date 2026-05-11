---
bead: flywheel-r9pri
title: cluster-maintainer-pattern N=3 doctrine-promotion (Option A) + Option B follow-up
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: shipped
priority: P2
mission_fitness: adjacent
parent: flywheel-2xdi (gap-hunter parent)
sister_promotion: flywheel-kwjja (Option D for memory-without-cross-link), flywheel-pmg3c (N=4 forward-link auto-injector)
followup: flywheel-xn5bm (Option B: probe cluster-detection)
---

# Journey: flywheel-r9pri

## What the bead asked for

N=3 doctrine-promotion for the cluster-maintainer pattern. 3 options:
- A: doctrine doc only
- B: doctrine + cluster-detection in gap-hunt-probe
- C: doctrine + cluster auto-suggestion in build-dispatch-packet

## Decision: A primary + B follow-up

Per kwjja Option D precedent (cheapest mechanization that moves
substrate forward):
- A is cheap (~15min, sanctioned recipe shape) and immediately useful
- B has structural value but adds probe complexity + regression tests
- C is middle-ground but lower value than B

Two-step rollout: A now, B filed as `flywheel-xn5bm` (P3 enhancement).

## Investigation (N=30 bead-hypothesis META-rule)

Verified all 3 N=3 precedents shipped + closed this session:
- 03yaj (research-triad, 31/31 coverage, 4 sub-beads closed)
- xhevf (agent-ergonomics-cli-max, patch-only artifact)
- plue9 (skill-builder, 10/10 coverage, 2 sub-beads closed)

Pattern is empirically stable across 3 distinct skills + 3 substrate classes (jsm-unmanaged Joshua-domain twice, jsm-managed Skillos-substrate once).

## What I shipped

### Primary: doctrine doc

`.flywheel/doctrine/cluster-maintainer-pattern.md`:
- TL;DR with kwjja Option D precedent cite
- N=3 promotion table with substrate classification + coverage delta + sub-beads closed
- 4-step canonical recipe (file cluster bead / dispatch / paired patch / auto-close subordinates)
- Per-substrate-class branches (3 cases: jsm-unmanaged / jsm-managed / Jeff Premium AUDIT-ONLY)
- Empirical comparison table (N individual vs 1 cluster)
- Anti-pattern guard (cite `feedback_decompose_by_natural_unit_not_bundle`)
- Sister doctrine + memory cross-refs
- Auto-detection (Option B) noted as future enhancement filed
- Conformance checklist
- Lifecycle (N=5 promote to skill)

### Follow-up: Option B mechanization bead

`flywheel-xn5bm` (P3 feature):
- Implementation shape (group gaps by skill-substrate; emit cluster gap)
- 5 acceptance gates including 2 regression tests
- Cites doctrine + kwjja precedent

## Verification

- Doctrine doc exists; cites all 3 N=3 exemplars
- `flywheel-xn5bm` filed P3 with concrete acceptance
- `br dep add` links xn5bm → r9pri

## L112 probe

    test -f .flywheel/doctrine/cluster-maintainer-pattern.md \
      && grep -c "03yaj\|xhevf\|plue9" .flywheel/doctrine/cluster-maintainer-pattern.md

Expected: positive integer (all 3 exemplars cited).

## Pattern reinforcement — 19th fix shape entry; substrate self-correcting layers codified

The doctrine layer of the 2xdi/kwjja arc now contains:
- `.flywheel/doctrine/orch-dispatch-hints-as-bayesian-priors.md` (2xdi.139)
- `.flywheel/doctrine/cluster-maintainer-pattern.md` (this bead)
- (plus the 8 forward-link doctrine docs from the doctrine cross-link recipe)
- (plus the in-probe Option D decision from kwjja)

Three layers of self-correcting substrate now codified:
1. **Worker discipline** (bead-hypothesis META-rule N=30+)
2. **Recipe sanctioning** (kwjja for memory-without-cross-link; r9pri for cluster-maintainer)
3. **Auto-detection mechanization** (filed as future enhancements: xn5bm here, future-pmg3c-style mechanization for forward-link recipe)

The substrate is now consciously building its own meta-layer: recipes ship as doctrine docs; doctrine docs sanction future workers; mechanization beads file follow-ups for the auto-detection step.

## Hint-productivity observation

The orch's dispatch packet body cited kwjja Option D precedent explicitly + pmg3c as sister at N=4. That made the cost-benefit analysis essentially pre-computed — Option A was the data-driven answer. Orch's hint-productivity from r9pri's perspective: high (decided in 1 step rather than requiring AskUserQuestion).
