---
title: "Plan Convergence Gates — Positive-Practice Transition Skeleton"
type: doctrine
created: 2026-05-11
frontmatter_source: scaffold-doc-frontmatter
---

# Plan Convergence Gates — Positive-Practice Transition Skeleton

Version: `plan-convergence-gates-positive-practice/v1`
Owner: `/flywheel:plan` orchestrator + plan-arc reviewers
Status: canonical, shipped 2026-05-11
Source bead: flywheel-2xdi.141 (memory-without-cross-link wire-in)
Sub-pattern: 1:1 forward-link (default per pmg3c)

## TL;DR

Plan phase transitions (RESEARCH → REFINE → AUDIT → DECOMPOSE → POLISH per
`/flywheel:plan`) MUST use an explicit **convergence gate** with 7 required
fields before moving from design to dispatch or build:

1. Accepted goal
2. Current phase
3. Open gaps
4. Rejected options
5. Evidence paths
6. L112 probe
7. Next owner

If any field is unresolved, **stay in plan-space and refine** rather than
authoring dispatches or substrate patches. Plan-space tokens are 25× cheaper
than code-space; convergence-by-data beats convergence-by-narrative-confidence.

## Canonical memory source

This doctrine summarizes
`feedback_plan_convergence_gates_positive_practice.md` — Disposition APPROVE
from learn-review C4. Read the memory for the original positive-practice
framing (convergence-evidence vs narrative-confidence) and the 7-field gate
list.

## The pattern

### Why convergence gates matter

Plan arcs drift when workers move from review to dispatch on **narrative
confidence** ("this looks ready") instead of **convergence evidence** (the
7 fields are filled). The drift mechanism: workers anchor on the latest
plan-doc revision + their own context-window state; without a structured
gate, "ready" is a vibe-check not a contract.

Per `/flywheel:plan` doctrine: "Plan-space tokens are 25× cheaper than
code-space." A 30-min refinement in plan-space saves 12 hours of code-space
rework. Convergence gates preserve that 25× leverage.

### The 7-field gate (positive-practice skeleton)

Before a plan phase transition (e.g., REFINE → AUDIT, AUDIT → DECOMPOSE):

| # | Field | What it proves |
|---|---|---|
| 1 | **Accepted goal** | The plan knows what it's trying to achieve, in 1-2 sentences |
| 2 | **Current phase** | RESEARCH / REFINE / AUDIT / DECOMPOSE / POLISH (per `/flywheel:plan` 5-phase pipeline) |
| 3 | **Open gaps** | Specific unresolved questions; the next phase will close these |
| 4 | **Rejected options** | What was considered AND ruled out, with why-rejected receipts |
| 5 | **Evidence paths** | File:line citations or command receipts proving the convergence (data, not narrative) |
| 6 | **L112 probe** | A re-runnable verification command an outsider can execute to validate the convergence |
| 7 | **Next owner** | Whose dispatch the next phase requires (orchestrator / specific worker / Joshua-decision) |

### Anti-pattern: narrative-confidence convergence

```
"The plan looks good — let's start dispatching beads."
                ⬇
                ❌ — no L112 probe, no evidence paths, no rejected options table
```

vs. positive-practice:

```
"Convergence gate complete: goal=X, phase=AUDIT done, gaps=[Y1,Y2 resolved
 via Z evidence], rejected=[A: reason, B: reason], evidence=PLAN-AUDIT-r2.md,
 L112: `bash AUDIT-r2-verify.sh`, next-owner=orch-decompose-dispatch."
                ⬇
                ✅ — outsider can re-verify the convergence
```

## Behavioral vs name cross-linking

This doctrine doc gives the memory a **name cross-link** so gap-hunt-probe's
memory-without-cross-link class clears. The discipline IS load-bearing
behaviorally across multiple surfaces:

| Surface | Embedding evidence |
|---|---|
| `.flywheel/rules/L079-L128-plan-convergence-proved-with-data.md` | L128 rule: 6-mechanism discipline (hypothesis-slate, prediction-lock, etc.) — superset of the memory's 7-field gate |
| `.flywheel/rules/L062-L108-meta-rule-cache-is-cache-not-convergence-gate.md` | L108 rule: cache freshness ≠ convergence gate — anti-pattern guardrail |
| `~/.claude/commands/flywheel/plan.md` | 5-phase pipeline (RESEARCH → REFINE → AUDIT → DECOMPOSE → POLISH) with "multi-round convergence + jeff-convergence-audit" doctrinal callouts |
| `~/.claude/skills/jeff-convergence-audit/` | Sister convergence skill (per `/flywheel:plan` 3rd phase) |

But the memory's NAME isn't grep-citable in these surfaces. This doctrine
doc closes the name-grep gap (5th instance of
`TP-with-semantic-embedding-AND-name-grep-blind-spot` this session).

Per substrate-self-improving loop: `flywheel-xbsd8` owns the recurring
class for faqj2 next-tick harvest. No new calibration bead filed; 5th-instance
reinforces the class (data point).

## Sister doctrine

- `feedback_plan_convergence_gates_positive_practice.md` (canonical memory source)
- `.flywheel/rules/L079-L128-plan-convergence-proved-with-data.md` (canonical
  rule; 6-mechanism convergence discipline)
- `.flywheel/rules/L062-L108-meta-rule-cache-is-cache-not-convergence-gate.md`
  (sister rule: cache ≠ convergence gate)
- `~/.claude/commands/flywheel/plan.md` (canonical 5-phase pipeline)
- `~/.claude/skills/jeff-convergence-audit/` (3rd-phase convergence skill)
- `.flywheel/doctrine/forward-link-doctrine-doc-recipe.md` (meta-recipe;
  this bead is the 10th instance of memory-without-cross-link wire-in)
- `flywheel-xbsd8` (meta-class harvest)

## Conformance

A `/flywheel:plan` phase transition proves conformance via:

- Phase transition is preceded by a 7-field convergence gate emit
- Each field has a discrete value (no `<TBD>` / `<pending>` / empty)
- Evidence paths are real files (`test -f` returns rc=0)
- L112 probe is a runnable command an outsider could execute
- Next owner is named (not implicit)
- Rejected options table has at least 1 ruled-out entry with why

The L128 rule's 6-mechanism receipt (hypothesis-slate + prediction-lock +
content-hash + ...) is a SUPERSET — passing L128 satisfies this memory's
7-field gate.

## Below-trauma-class tracking

Disposition was APPROVE from learn-review C4 (origin of memory). The
discipline is now load-bearing in L128 rule. This doctrine doc names the
gate concept positively (vs L128's "proved-with-data" framing). Both
co-exist:

- L128: "convergence requires data" (anti-pattern guardrail)
- This doc: "convergence requires the 7-field skeleton" (positive-practice
  template)

Track via fuckup-log if a plan phase transitions WITHOUT the 7-field gate:
`failure_class=plan_phase_transition_no_convergence_gate`.

## Substrate-self-improving loop (10th instance)

This bead is the 10th instance of memory-without-cross-link auto-injection
post-pmg3c. Sub-pattern distribution after 10 instances:

| Sub-pattern | Instances |
|---|---|
| 1:1 forward-link | 7 (5 pre-pmg3c + 2 post-pmg3c: 2xdi.128 + **2xdi.141 (this)**) |
| CLUSTER-ANCHOR | 1 (2xdi.125) |
| NOT-YET-PROMOTED | 2 (2xdi.117 + 2xdi.129) |

1:1 forward-link remains the dominant sub-pattern (70% of instances). The
auto-injection + recipe + sub-pattern selection continues to function per
design without manual orchestrator intervention.


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-17 — secret emission discipline:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md` for the canonical pattern.
- **MP-29 — production safety guardrails:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-29-production-safety-guardrails.md` for the canonical pattern.
- **MP-30 — human-gated invasiveness:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-30-human-gated-invasiveness.md` for the canonical pattern.
