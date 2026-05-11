---
bead: flywheel-2xdi.139
title: memory-without-cross-link fix — orch-dispatch-hints as Bayesian priors (N=8)
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: shipped
priority: P3
mission_fitness: adjacent
parent: flywheel-2xdi
sanctioning: flywheel-kwjja (Option D)
session_loop: 3rd post-kwjja-sanctioning instance
---

# Journey: flywheel-2xdi.139

## What the bead asked for

`feedback_orch_dispatch_hint_discipline.md` not cited by sampled
commands/doctrine/incidents/plans.

## Investigation (N=29 bead-hypothesis META-rule)

- Memory EXISTS, 3984 bytes (2026-05-11 09:54 — earlier today)
- Documents N=2 consecutive wrong-prediction META-rule:
  - 2xdi.106: orch said "resolved-upstream" → CloudyMill found WRONG; shipped 15-for-1 root-cause fix
  - 2xdi.108: orch said "genuine-gap" → CloudyMill found WAS auto-cleared; moot-by-parallel-fix
- Triple-recursive META-rule extension (bead body + parent + orch hint)
- Fresh probe DOES flag it (genuine gap)
- 0 cross-links → genuine gap

## What I shipped

`.flywheel/doctrine/orch-dispatch-hints-as-bayesian-priors.md`:
- TL;DR with N=2 wrong-prediction evidence
- Cites memory as Canonical memory source
- Formal rule (3 ship conditions)
- N=2 empirical evidence table (bead IDs + outcomes + commit SHAs)
- Orch discipline (4 named rules for dispatch authors)
- Worker discipline (triple-recursive META-rule extension)
- Donella paradigm-level lens (single-point-of-failure trauma class)
- Trauma-class designation (META-EXTRACTION-DRIFT; below 4-instance
  promotion threshold)
- 4-row anti-pattern table
- Conformance checklist (orch + worker)
- Lifecycle with 3rd-instance trauma-promotion trigger

## Verification

- 0 pre-fix cross-links
- Post-fix: doctrine doc cites memory by name
- Fresh probe: gap cleared

## L112 probe

    grep -l "feedback_orch_dispatch_hint_discipline" .flywheel/doctrine/ -r | head -1

Expected: `grep:orch-dispatch-hints-as-bayesian-priors.md`.

## Self-referential meta-observation

This bead doctrinates the very META-rule about NOT trusting orch hints
unconditionally. The doctrine doc I shipped sanctions worker behavior
that would override orch hints. Empirical loop closes: the substrate
is doctrinating its own self-correcting property.

Implication: if a future orch hint conflicts with my probe output, this
doctrine doc is the canonical anchor sanctioning my decision to override.

## Pattern note — N=8 post-kwjja

3rd post-kwjja-decision instance. Pattern stable across 8 topic classes:
- Cross-repo discipline / Dispatch verification / Storage / Auth /
  API additive-compat / Cross-repo rename / Canonical-CLI flag projection /
  **Orch-hint Bayesian priors**

Cluster shape:
- doctrine cross-link forward-link: N=8 ← dominant by ~2x
- probe corpus extensions: N=4
- (everything else): ≤2 instances each

18th distinct fix shape entry in 2xdi.*/kwjja arc. Doctrine cross-link
remains the dominant pattern.

## Session-loop tempo

Memory authored 09:54 → doctrinated ~15 hours later (same session).
Faster than 2xdi.136 (memory→doctrine ~0.5 hours) but still well within
session-scale latency.
