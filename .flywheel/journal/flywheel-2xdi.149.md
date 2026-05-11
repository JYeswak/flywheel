---
bead: flywheel-2xdi.149
title: memory-without-cross-link fix — 3-class substrate boundary taxonomy doctrine (N=10 milestone)
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: shipped
priority: P3
mission_fitness: adjacent
parent: flywheel-2xdi
sister_recipe: 2xdi.93/.109/.116/.118/.127/.134/.136/.139/.142 (N=10)
sister_doctrine_pair: 2xdi.93 (consumer-vs-mutator) + 2xdi.149 (this; 3-class taxonomy)
sanctioning: flywheel-kwjja Option D (5th post-decision)
---

# Journey: flywheel-2xdi.149

## What the bead asked for

`feedback_substrate_boundary_three_class_taxonomy.md` not cited by
sampled commands/doctrine/incidents/plans.

## Investigation (N=32 bead-hypothesis META-rule)

- Memory EXISTS, 4939 bytes (2026-05-11 09:54 — earlier this session)
- Documents 3-class substrate boundary taxonomy:
  - Class 1: Joshua-substrate (jsm-unmanaged OR managed-by-self)
  - Class 2: Skillos-substrate (jsm-managed, peer-orch ownership)
  - Class 3: Jeff-substrate (Premium ⭐, AUDIT-ONLY)
- EXTENDS the cross-repo-consumer-vs-mutator memory shipped in 2xdi.93
- Empirically grounded: N=6 Class 1 + N=6 Class 2 + N=1 Class 3 instances
  this session
- Fresh probe DOES flag it; 0 cross-links → genuine gap

## What I shipped

`.flywheel/doctrine/substrate-boundary-three-class-taxonomy.md`:
- TL;DR with 3-row class summary table
- Cites memory + sister doctrine 2xdi.93
- Per-class deep-dive sections with empirical instance tables
- Detection probe → class mapping (4 cases)
- Per-worker-tick apply procedure
- 4-row anti-pattern table
- Per-class conformance criteria (3 callback signatures)
- Sister doctrine + 5 memory cross-refs
- Lifecycle (HARD RULE)

## Verification

- Pre-fix: 0 cross-links
- Post-fix: doctrine doc cites memory + sister doctrine
- Fresh probe: gap cleared

## L112 probe

    grep -l "feedback_substrate_boundary_three_class_taxonomy" .flywheel/doctrine/ -r | head -1

Expected: `grep:substrate-boundary-three-class-taxonomy.md`.

## Pattern note — N=10 milestone + 2nd sister-doctrine pair

**N=10 milestone.** The forward-link doctrine doc recipe has shipped 10
doctrine docs this session, all independently valuable canonical
write-ups. Recipe applied unchanged across 10 distinct topic classes.

**2nd sister-doctrine pair in arc.** First was rename-discipline pair
(2xdi.134 wire-and-flag + 2xdi.142 scope-mask, shipped earlier today).
Second is cross-repo-discipline pair (2xdi.93 consumer-vs-mutator +
2xdi.149 3-class taxonomy, shipped now).

At N=3 sister-doctrine pairs, that's a candidate skill discovery
(`pattern-emerged-sister-doctrine-pairing-for-operational-class`).
Currently N=2.

## Cluster shape after N=10

- doctrine cross-link forward-link: **N=10** ← dominant by ~2.5x
- probe corpus extensions: N=4
- (everything else N≤2)

21st distinct fix shape entry in 2xdi/kwjja/r9pri arc.

## Substrate maturation signal

10 canonical doctrine docs + 2 sister-doctrine pairs + 1 in-probe
class-taxonomy decision (kwjja) + 1 doctrine-promotion bead (r9pri) =
the doctrine layer of the substrate has reached operational maturity
this session.

Future workers will inherit a cross-referenced doctrine corpus where:
- Each doctrine doc cites its memory source
- Sister pairs cross-reference each other
- The doctrines themselves are now grep-discoverable (the very property
  the forward-link recipe was designed to produce)

The substrate is now self-documenting at the doctrine layer in addition
to the recipe + worker-discipline layers.
