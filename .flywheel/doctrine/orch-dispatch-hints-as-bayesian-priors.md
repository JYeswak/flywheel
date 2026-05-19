---
title: "Orch Dispatch Hints Are Bayesian Priors, Not Directives"
type: doctrine
created: 2026-05-11
frontmatter_source: scaffold-doc-frontmatter
---

# Orch Dispatch Hints Are Bayesian Priors, Not Directives

Version: `orch-dispatch-hints-as-bayesian-priors/v1`
Owner: orchestrator (dispatch author) + workers (consumer)
Status: canonical, shipped 2026-05-11
Source bead: flywheel-2xdi.139 (memory-without-cross-link wire-in)

## TL;DR

When orch (flywheel:1) adds expected-disposition annotations to dispatch
packets ("expect resolved-upstream", "likely moot", "should be genuine-gap"),
these function as **Bayesian priors that workers verify empirically** — NOT
conclusions to execute against. Two consecutive 2026-05-11 instances where
the orch hint was wrong proved this.

## Canonical memory source

This doctrine summarizes
`feedback_orch_dispatch_hint_discipline.md` — the META-rule memory
(N=2 consecutive wrong) documenting the discipline. Read the memory
for the full empirical evidence and triple-recursive worker extension.

## The rule (formal)

For any dispatch packet with an orch-authored expected-disposition annotation:

1. The annotation is a **prior** — orchestrator's projection given the
   information available at dispatch authoring time.
2. The worker's job is to **probe empirical state** and ship the disposition
   the evidence supports, even when it conflicts with the prior.
3. When worker's empirical disposition differs from the orch hint, that's
   data (catches orchestrator drift), not a worker error.

## Empirical evidence (N=2 consecutive wrong, 2026-05-11)

| # | Bead | Orch hint | Empirical truth | Outcome |
|---|---|---|---|---|
| 1 | flywheel-2xdi.106 | "Expect resolved-upstream per 2m2cs pattern" | 4-form name-match all False — gap was real | CloudyMill shipped root-cause fix (command_text tests/ corpus extension); 15-for-1 leverage (18 silos → 3 remaining) |
| 2 | flywheel-2xdi.108 | "Expect genuine-gap class (not auto-cleared)" | Bead WAS auto-cleared by 2xdi.106's commit `8b9f8b3` | Moot-by-parallel-fix; SD `moot-by-parallel-fix-N4-mechanization-trigger` |

N=2 consecutive wrong predictions from orch within a single session. The data
says: orch hints are good Bayesian priors but they're not authoritative.

## Orch discipline (dispatch authors)

1. **Default to no projection hint.** A standard dispatch packet (bead body +
   memory hits + skill auto-routes + relevant precedent) is sufficient. Most
   dispatches don't need a projected disposition.
2. **When hint adds value**: cite *specific empirical evidence* (commit SHA,
   probe output, fix shape) — NOT abstract "expected disposition".
3. **Frame as prior, not directive**:
   - Good: "potentially resolved by commit X — verify before closing"
   - Bad: "expect resolved-upstream close"
4. **Accept correction**: when a worker ships a disposition different from
   your hint, the pattern is `orch-hint-as-Bayesian-prior`. Worker discipline
   beats orch projection. This is **expected behavior**, not an exception.

## Worker discipline (triple-recursive META-RULE extension)

Extends `feedback_bead_hypothesis_starting_point_not_conclusion` (the
N=28-instance master rule) with two additional signal classes to verify
before action:

1. **Bead body hypothesis** (original — N=14+ instances of being WRONG)
2. **Parent bead evidence** (per `flywheel-2xdi.60.1` nq5ns refinement)
3. **Orch dispatch hints** (this doctrine — N=2 instances of being WRONG)

All three signal classes get empirically probed before action. Workers trust
nothing upstream until verified.

## Why this matters

The substrate-self-improving property requires that **no single signal
source is privileged**. If orch hints were authoritative, the orchestrator
would be a single point of failure for substrate health. By treating orch
hints as priors:

- Workers' verification discipline catches orchestrator drift
- The orchestrator learns via callback evidence (this very doctrine doc IS the learning)
- Convergence happens at the substrate level, not via any single component

Donella systems-thinking lens: the **paradigm** that "orchestrator is authoritative" creates a single-point-of-failure trauma class. The **paradigm** that "empirical state is authoritative; orch is a fast-source of priors" creates a self-correcting substrate.

## Trauma class

META-EXTRACTION-DRIFT — "downstream signal masking upstream gap". The orch
hint is a downstream signal (orch's projection); empirical state is upstream
(the actual codebase / bead state / probe output). Worker's job: probe
upstream, IGNORE downstream-when-conflicting.

## Anti-patterns

| Anti-pattern | Why it fails |
|---|---|
| Adding "expected resolved-upstream" or "likely moot" annotations to dispatch packets. | Shortcuts worker investigation; risks shipping symptom-fixes instead of root-cause-fixes when the hint is wrong. Two consecutive demonstrations 2026-05-11. |
| Worker closes bead based solely on orch hint without empirical probe. | Violates bead-hypothesis META-rule + triple-recursive extension; ships untested closes. |
| Orch responds to worker's empirically-driven correction as if worker is wrong. | Creates upstream pressure that makes future workers less likely to probe empirically; degrades the self-correcting property. |
| Citing "orch hint says X" as load-bearing evidence in callback envelope. | Hints aren't evidence — empirical probe output is. Cite the probe, not the hint. |

## Conformance

A dispatch packet proves orch-discipline conformance via:
- No expected-disposition annotation present, OR
- Annotation cites specific empirical evidence + uses prior-not-directive language
- Annotation includes "verify before closing" guidance

A worker callback proves worker-discipline conformance via:
- Empirical probe output in evidence (regardless of orch hint)
- Disposition matches probe output, not the hint
- If hint was wrong, explicitly notes "orch-hint-as-Bayesian-prior" pattern

## Sister doctrine + memory

- `feedback_orch_dispatch_hint_discipline` (above-cited canonical memory)
- `feedback_bead_hypothesis_starting_point_not_conclusion` — N=28+ master rule; this is its triple-recursive extension
- `feedback_data_decides_not_human_meatpuppet` — same family: trust empirical state over claims
- `project_self_sustaining_company_paradigm_2026_05_04` — architecture-health > individuals (including the orchestrator)

## Lifecycle

This is a HARD RULE for both orch + workers. The 2 wrong-prediction instances
from 2026-05-11 are below the trauma-class-promotion threshold (4 instances)
but at-or-above the doctrine-codification threshold. The doctrine doc
sanctions worker correction as expected behavior; orchestrator learns from
callback evidence.

When a 3rd instance occurs (orch hint wrong again), promote to trauma class
and add a dispatch-template warning block. Until then, this doctrine doc
is the discipline anchor.


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-17 — secret emission discipline:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md` for the canonical pattern.
- **MP-29 — production safety guardrails:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-29-production-safety-guardrails.md` for the canonical pattern.
- **MP-30 — human-gated invasiveness:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-30-human-gated-invasiveness.md` for the canonical pattern.
