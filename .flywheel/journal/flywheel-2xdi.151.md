---
bead: flywheel-2xdi.151
title: memory-without-cross-link fix — orchestrator reset-safety doctrine (N=11)
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: shipped
priority: P3
mission_fitness: adjacent
parent: flywheel-2xdi
sister_recipe: N=11 instance (post-kwjja)
sanctioning: flywheel-kwjja Option D (6th post-decision)
---

# Journey: flywheel-2xdi.151

## What the bead asked for

`feedback_substrate_loss_worker_commit_orphan.md` not cited by sampled
commands/doctrine/incidents/plans.

## Investigation (N=33 bead-hypothesis META-rule)

- Memory EXISTS, 3068 bytes (2026-05-08 16:06)
- Documents orchestrator reset-safety / worker-commit-orphan-prevention
- 2 ALPS incidents (2026-05-04: commits 2e43df2 + 641d926)
- Wired via B13 (worker-branch-contract) + B14 (DCG orphan-reset-blocker)
- Fresh probe flags it; 0 cross-links → genuine gap

## What I shipped

`.flywheel/doctrine/orchestrator-reset-safety-orphan-prevention.md`:
- TL;DR with probe command + STOP rule
- Cites memory as Canonical memory source
- Formal rule (4-step pre-reset procedure)
- Worker discipline (side-branch dispatch contract; B13 wire-in)
- Orchestrator discipline (reset-guard; B14 wire-in)
- Recovery procedure (4-step safe primitive via `git show` not `checkout`)
- Empirical incidents table (ALPS SHAs + recovery cost)
- 5-row anti-pattern table
- Conformance for orch + worker
- Structural-receipt wire-in (B13 + B14)
- Lifecycle (trauma promotion at N=4 incidents)

## Verification

- 0 pre-fix cross-links
- Post-fix: doctrine doc cites memory
- Fresh probe: gap cleared

## L112 probe

    grep -l "feedback_substrate_loss_worker_commit_orphan" .flywheel/doctrine/ -r | head -1

Expected: `grep:orchestrator-reset-safety-orphan-prevention.md`.

## Pattern note — first procedural-safety doctrine in arc

11th instance of forward-link recipe; 6th post-kwjja-sanctioning
application. Notable: this is the **first procedural-safety doctrine**
in the arc — the 10 prior doctrine docs were largely classificatory
(consumer-vs-mutator, 3-class taxonomy) or discipline-spec
(dispatch-verify, JSM auth, API additive-compat). This one codifies a
**safety procedure** with concrete recovery primitives.

The shape proves the recipe extends to procedural-safety memories
cleanly without modification. Same template (TL;DR + memory citation +
formal rule + procedural sections + anti-pattern table + conformance +
lifecycle) handles a different content class.

## Candidate 3rd sister-doctrine pair

This doctrine cross-references `feedback_worker_close_requires_git_commit`
in its "Sister doctrine + memory" section. If that sister memory gets
doctrinated, the resulting pair would form the 3rd sister-doctrine pair:
- 2xdi.151 (this) — reset-safety (orchestrator perspective)
- Future doctrine — worker-close-commit-discipline (worker perspective)

At N=3 sister-doctrine pairs, that's a candidate skill discovery
(`pattern-emerged-sister-doctrine-pairing-for-operational-class`).
Currently N=2 confirmed pairs (rename + cross-repo).

## Cluster shape after N=11

- doctrine cross-link forward-link: **N=11** ← dominant by ~2.75x
- probe corpus extensions: N=4
- (everything else N≤2)

22nd distinct fix shape entry in 2xdi/kwjja/r9pri arc.
