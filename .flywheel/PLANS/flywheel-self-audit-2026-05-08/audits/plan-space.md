---
title: "Plan-Space Layer Audit - 2026-05-08"
type: plan
created: 2026-05-07
bead: flywheel-self
frontmatter_source: scaffold-doc-frontmatter
---

# Plan-Space Layer Audit - 2026-05-08

Bead: `flywheel-ivy6g`  
Scope: `/flywheel:plan`, plan-space-convergence, multi-model-triangulation,
dueling-idea-wizards, jeff-convergence-audit, research-triad, idea-wizard, and
the close-gate artifacts that now enforce plan-space readiness.

Socraticode receipt: `socraticode_queries=10`, project
`/Users/josh/Developer/flywheel`, indexed chunks observed at start: `1171`.
Queries covered `hypothesis`, `convergence`, `refinement`, `audit phase`,
`decompose`, `dueling idea wizards`, `jeff convergence audit`,
`idea wizard 30->5->15`, `lie to them`, and Brenner/daxk3 close-gate terms.

## 1. Inventory

| Surface | Kind | Citation | Current role |
|---|---|---|---|
| `/flywheel:plan` active command | command doc | `~/.claude/commands/flywheel/plan.md:1-8` | Canonical five-phase plan pipeline. The dispatch-named `~/.claude/skills/.flywheel/skills/flywheel:plan.md` is absent; active source is this command file. |
| `/flywheel:plan` state machine | command doc | `~/.claude/commands/flywheel/plan.md:40-54` | Defines INTENT -> RESEARCH -> REFINE -> AUDIT -> DECOMPOSE -> POLISH -> READY. |
| Phase 1 research fanout | command doc | `~/.claude/commands/flywheel/plan.md:56-79` | Three-lane problem/ecosystem/implementation research contract. |
| Phase 2 hypothesis slate | command doc | `~/.claude/commands/flywheel/plan.md:80-138` | New Brenner kill-first slate contract: 2-5 hypotheses, `H_alt`, decisive tests, and acceptance-when-killed. |
| Phase 3 audit | command doc | `~/.claude/commands/flywheel/plan.md:175-189` | Embeds `jeff-convergence-audit` Phase 1 and evidence-pack audit pass. |
| Phase 4 decompose | command doc | `~/.claude/commands/flywheel/plan.md:321-330` | Converts audited plan into an 8-15 bead DAG with dep-cycle validation. |
| Phase 5 close gate | command doc | `~/.claude/commands/flywheel/plan.md:332-346` | Requires quality-bar close-gate PASS before ready. |
| STATE schema v5 | command doc | `~/.claude/commands/flywheel/plan.md:362-399` | Stores compliance evidence plus hypothesis slate fields. |
| `plan-space-convergence` | skill | `~/.claude/skills/plan-space-convergence/SKILL.md:1-4`, `~/.claude/skills/plan-space-convergence/SKILL.md:32-39` | Manual pre-`br create` gate for non-trivial beads and clusters. |
| `multi-model-triangulation` | skill | `~/.claude/skills/multi-model-triangulation/SKILL.md:1-7`, `~/.claude/skills/multi-model-triangulation/SKILL.md:93-116` | Cross-model synthesis contract: consensus, divergence, unique insights, recommendation, confidence. |
| `multi-model-triangulation` plan-to-beads gate | skill section | `~/.claude/skills/multi-model-triangulation/SKILL.md:145-156` | r1 PATCH/r2 SHIP cold-read gate before converting complex plans to beads. |
| `dueling-idea-wizards` | skill | `~/.claude/skills/dueling-idea-wizards/SKILL.md:1-17` | NTM-based adversarial idea generation and cross-scoring. |
| `dueling-idea-wizards` cardinality | skill section | `~/.claude/skills/dueling-idea-wizards/SKILL.md:31-42`, `~/.claude/skills/dueling-idea-wizards/SKILL.md:130-139` | Defaults to 30 ideas, top 5, optional expansion to 15. |
| `dueling-idea-wizards` synthesis | skill section | `~/.claude/skills/dueling-idea-wizards/SKILL.md:240-254` | Score matrix, 700+ consensus winners, contested ideas, mutual kills, blind spots. |
| `jeff-convergence-audit` | skill | `~/.claude/skills/jeff-convergence-audit/SKILL.md:1-14` | Convergence audit discipline: check beads N times, implement once. |
| `jeff-convergence-audit` zero-round convergence | skill section | `~/.claude/skills/jeff-convergence-audit/SKILL.md:47-55`, `~/.claude/skills/jeff-convergence-audit/SKILL.md:68-78` | Two consecutive zero-finding rounds define convergence. |
| `research-triad` | skill | `~/.claude/skills/research-triad/SKILL.md:1-12`, `~/.claude/skills/research-triad/SKILL.md:85-88` | External-source triangulation with source id and fetch timestamp. |
| `research-triad` composition | skill section | `~/.claude/skills/research-triad/SKILL.md:171-180` | Feeds multi-model-triangulation, idea-wizard, and dueling-idea-wizards. |
| `idea-wizard` | skill | `~/.claude/skills/idea-wizard/SKILL.md:1-8` | Single-agent generate -> winnow -> bead workflow. |
| `idea-wizard` exact 30->5->15 shape | skill section | `~/.claude/skills/idea-wizard/SKILL.md:10-19`, `~/.claude/skills/idea-wizard/SKILL.md:25-40` | Already matches the upstream 30->5 and next-best-10 expansion pattern. |
| `quality-bar-close-gate.sh` | script | `.flywheel/scripts/quality-bar-close-gate.sh:29-41`, `.flywheel/scripts/quality-bar-close-gate.sh:73-85` | Plan close gate and CLI surface; declares schema v5 hypothesis slate and schema v4 compliance evidence requirements. |
| Hypothesis-slate validator | script section | `.flywheel/scripts/quality-bar-close-gate.sh:449-557`, `.flywheel/scripts/quality-bar-close-gate.sh:646-649` | Enforces schema v5 slate validity before PASS. |
| Phase 2 schema | JSON schema | `templates/flywheel-install/polish-gate/v1/plan-phase2-refine.schema.json:1-12`, `templates/flywheel-install/polish-gate/v1/plan-phase2-refine.schema.json:74-103` | Machine schema for hypotheses, `third_alternative`, and `acceptance_when_killed`. |
| Hypothesis-slate regression test | test | `tests/test_brenner_hypothesis_slate.sh:57-128`, `tests/test_brenner_hypothesis_slate.sh:135-150` | Proves no-slate and one-hypothesis fixtures fail; valid slate passes. |
| agent-flywheel.com local gap analysis | doctrine input | `.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:44-55`, `.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:89-94` | Public benchmark: planning arc, bead conversion, convergence numbers. |
| Brenner deep-dive | research input | `.flywheel/PLANS/jeff-ecosystem-deep-dive-2026-05-01/brenner-2026-05-07/01-RESEARCH-DEEP-DIVE.md:122-137`, `.flywheel/PLANS/jeff-ecosystem-deep-dive-2026-05-01/brenner-2026-05-07/01-RESEARCH-DEEP-DIVE.md:138-168` | Source for daxk3 and next Brenner wire-in proposals. |

Inventory count: 25 rows.

## 2. Load-bearing

Callsite scan command:

```bash
for term in 'flywheel:plan' 'plan-space-convergence' 'multi-model-triangulation' \
  'dueling-idea-wizards' 'jeff-convergence-audit' 'research-triad' 'idea-wizard'; do
  rg -l "$term" /Users/josh/Developer/flywheel ~/.claude/commands ~/.claude/skills \
    --glob '!**/.git/**' --glob '!**/node_modules/**' --glob '!**/.venv/**' \
    --glob '!**/vendor/**' 2>/dev/null | wc -l
done
```

Observed unique-file counts: `/flywheel:plan=100`, `plan-space-convergence=14`,
`multi-model-triangulation=103`, `dueling-idea-wizards=40`,
`jeff-convergence-audit=130`, `research-triad=154`, `idea-wizard=158`.

| Surface | Why load-bearing | Evidence |
|---|---|---|
| `/flywheel:plan` active command | Critical path: it owns the 5-phase planning pipeline and every transition through ready. | `~/.claude/commands/flywheel/plan.md:40-54`, `~/.claude/commands/flywheel/plan.md:338-346`; callsite count 100. |
| `quality-bar-close-gate.sh` | Critical path for Phase 5 ready transition; now enforces compliance packs and hypothesis slate validity. | `.flywheel/scripts/quality-bar-close-gate.sh:73-85`, `.flywheel/scripts/quality-bar-close-gate.sh:646-649`; `git log` shows daxk3 commits `092b303`, `8f86bdb`, `9c90b03`. |
| Phase 2 hypothesis slate schema + test | It is the new plan-space falsification gate; without it, daxk3 becomes prompt-only doctrine. | `templates/flywheel-install/polish-gate/v1/plan-phase2-refine.schema.json:8-12`, `tests/test_brenner_hypothesis_slate.sh:138-150`. |
| `research-triad` | Critical Phase 1 and source-truth layer; `/flywheel:plan` requires skills-first before socraticode/research-triad and lane templates consume research artifacts. | `~/.claude/commands/flywheel/plan.md:62-78`, `~/.claude/skills/research-triad/SKILL.md:85-88`, `~/.claude/skills/research-triad/SKILL.md:171-180`; callsite count 154. |
| `jeff-convergence-audit` | Phase 3 uses this as the audit lens source; convergence means two clean rounds. | `~/.claude/commands/flywheel/plan.md:175-181`, `~/.claude/skills/jeff-convergence-audit/SKILL.md:47-55`; callsite count 130. |
| `multi-model-triangulation` | It is our operational "best-of-all-worlds" synthesis and the r1/r2 SHIP gate before large bead fanout. | `~/.claude/skills/multi-model-triangulation/SKILL.md:93-116`, `~/.claude/skills/multi-model-triangulation/SKILL.md:145-156`; callsite count 103. |
| `idea-wizard` | High-callsite ideation-to-bead workflow and already matches the 30->5->15 benchmark. | `~/.claude/skills/idea-wizard/SKILL.md:10-19`, `~/.claude/skills/idea-wizard/SKILL.md:56-70`; callsite count 158. |
| `dueling-idea-wizards` | Load-bearing for adversarial idea selection; it has real skill outcome history and an open Brenner wire-in path. | `~/.claude/skills/dueling-idea-wizards/SKILL.md:13-25`, `~/.claude/skills/dueling-idea-wizards/SKILL.md:240-254`; callsite count 40. |
| `plan-space-convergence` | Critical even with lower callsite count because it guards non-trivial bead creation before code-space rework. | `~/.claude/skills/plan-space-convergence/SKILL.md:32-39`, `~/.claude/skills/plan-space-convergence/SKILL.md:53-57`; callsite count 14. |

Load-bearing count: 9.

## 3. Vestigial

| Surface | Evidence | Disposition |
|---|---|---|
| `~/.claude/skills/.flywheel/skills/flywheel:plan.md` path named in dispatch | `test -f ~/.claude/skills/.flywheel/skills/flywheel:plan.md` returned missing; active source is `~/.claude/commands/flywheel/plan.md:1-8`. | Sunset as a path reference. Future dispatches should name the active command or install a pointer file. |
| Legacy three-judges/four-lens close-gate fields | L126 allows legacy rows only; close gate now declares schema v4 compliance evidence and schema v5 hypothesis slate requirements in `.flywheel/scripts/quality-bar-close-gate.sh:73-85`. | Keep compatibility code for old plans, but do not use it as a new-plan criterion. |
| `dueling-idea-wizards` CronCreate monitoring block | The skill still recommends `CronCreate`/`CronDelete` monitoring at `~/.claude/skills/dueling-idea-wizards/SKILL.md:368-380`, while current loop doctrine moved to event-driven Monitor for worker callbacks. | Superseded monitoring surface. Replace with NTM robot-activity plus dispatch-log Monitor pattern. |
| Manual copy-paste framing in `multi-model-triangulation` | Skill says "You can't directly call other models" and relies on human pasteback at `~/.claude/skills/multi-model-triangulation/SKILL.md:15-25`, while NTM and multi-agent dispatch now routinely run model-diverse workers. | Retire as default. Keep as fallback for off-fleet models, but add NTM-native route. |
| `plan-space-convergence` lacks Socraticode lookup in steps | The skill's seven steps require plan pass and file:line evidence but no Socraticode search at `~/.claude/skills/plan-space-convergence/SKILL.md:32-39`; the prior proposal explicitly notes no built-in pre-`br create` Socraticode hook in `~/.claude/skills/.flywheel/proposals/socratic-cross-existing-doctrine-2026-04-27.md:24-25`. | Not vestigial as a skill, but incomplete versus current L50 doctrine. Fix as a narrow update bead. |

Vestigial/superseded count: 5.

## 4. Missing per agent-flywheel.com gap analysis

### Gap 1: convergence-score thresholds 0.75 / 0.90

agent-flywheel.com names explicit plan refinement thresholds: `0.75+ ready`,
`0.90+ diminishing returns` (`.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:89-92`).
Our `/flywheel:plan` currently uses 2 consecutive rounds with `<5%` changes for
Phase 2 and Phase 5 (`~/.claude/commands/flywheel/plan.md:80-87`,
`~/.claude/commands/flywheel/plan.md:332-336`). That is useful stability
evidence, but it is not a weighted convergence score and can miss "stable but
wrong" artifacts.

Recommendation: add `plan_convergence_score` to `STATE.json` and close-gate
JSON. Ready at `>=0.75`, diminishing-return at `>=0.90`; retain diff-stability
as one input, not the whole score.

### Gap 2: idea-wizard 30->5->15 shape

agent-flywheel.com asks us to compare the public six-phase idea-wizard shape
(`.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:162-165`).
Our single-agent `idea-wizard` already matches the core cardinality:
Phase 2 says generate `30->5`, Phase 3 says next best 10, and Phase 6 says
repeat 4-5x (`~/.claude/skills/idea-wizard/SKILL.md:10-19`,
`~/.claude/skills/idea-wizard/SKILL.md:25-40`). `dueling-idea-wizards` also
defaults to 30/top-5 and optionally expands to 15
(`~/.claude/skills/dueling-idea-wizards/SKILL.md:31-42`,
`~/.claude/skills/dueling-idea-wizards/SKILL.md:130-139`).

Remaining gap: neither skill makes the human review checkpoint explicit before
beads. Dueling can auto-create beads with `--beads`
(`~/.claude/skills/dueling-idea-wizards/SKILL.md:294-332`), which is too sharp
for contested strategic ideas.

### Gap 3: "lie to them" exhaustive re-review technique

The local gap analysis says the guide names a technique: claim `80+` missed
elements exist to force exhaustive re-review
(`.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:157-160`).
I found no corresponding named step in `/flywheel:plan`, `multi-model-triangulation`,
or `plan-space-convergence`. The closest local analogue is adversarial audit
pressure in `jeff-convergence-audit` and `dueling-idea-wizards`, but those do not
use the deliberate exhaustive-rerun prompt as a plan-space convergence breaker.

Recommendation: add it as an optional Phase 2/Phase 3 "exhaustive miss probe"
only when convergence stalls or r1 returns suspiciously clean. It should be
labeled as adversarial prompt pressure, not a factual claim in durable artifacts.

## 5. Lessons learned (today's evidence)

1. **daxk3 turned Brenner into a gate, not just a good idea.** The active
   `/flywheel:plan` command now requires a kill-first hypothesis slate in Phase 2
   (`~/.claude/commands/flywheel/plan.md:88-138`), the schema encodes it
   (`templates/flywheel-install/polish-gate/v1/plan-phase2-refine.schema.json:1-12`),
   and the close gate fails missing or one-hypothesis fixtures
   (`tests/test_brenner_hypothesis_slate.sh:138-150`). Lesson: plan-space
   improvements compound only when the prompt, schema, and close gate all move.

2. **mqy5l found the right adoption posture: extend plan-space, avoid transport replacement.**
   The Brenner comparison matrix had 3 ADOPT, 6 EXTEND, 2 AVOID, and 2
   already-covered dispositions
   (`.flywheel/PLANS/jeff-ecosystem-deep-dive-2026-05-01/brenner-2026-05-07/01-RESEARCH-DEEP-DIVE.md:3-9`).
   It specifically says `/flywheel:plan` should be extended with hypothesis
   slates, third alternatives, potency controls, and kill criteria
   (`.flywheel/PLANS/jeff-ecosystem-deep-dive-2026-05-01/brenner-2026-05-07/01-RESEARCH-DEEP-DIVE.md:124-137`).
   Lesson: we should harvest Brenner epistemics, not replace NTM/flywheel
   orchestration with Brenner robot transport.

3. **The agent-flywheel.com gap analysis mostly validates our architecture, but
   the numbers matter.** It credits our 5-phase pipeline, plan-space-convergence,
   dueling wizards, multi-model triangulation, jeff-convergence-audit, and
   research-triad as local strengths
   (`.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md:124-130`).
   The concrete missing piece is thresholding: 0.75/0.90 is easier to gate and
   compare than "two rounds felt steady."

4. **Path drift is already visible in the plan layer.** The dispatch named
   `~/.claude/skills/.flywheel/skills/flywheel:plan.md`, but the live surface is
   `~/.claude/commands/flywheel/plan.md`. Lesson: command/skill aliases must be
   structurally discoverable before they become audit inputs; otherwise
   self-audits start by reconciling names.

5. **Idea generation is surprisingly healthy.** The public 30->5->15 shape is
   already present in both `idea-wizard` and `dueling-idea-wizards`. The gap is
   not ideation volume; it is explicit human review and structured deltas before
   bead creation.

## 6. Fix-bead manifest

Recommendations only; no beads filed.

1. **P0 - `[plan-space] add weighted convergence_score to /flywheel:plan close gate`**  
   Scope: `/flywheel:plan` STATE schema, `quality-bar-close-gate.sh`, and one
   fixture test.  
   Acceptance: schema v6 plans expose `plan_convergence_score`; close gate
   reports `convergence_score_ready=yes` at `>=0.75`, reports
   `diminishing_returns=yes` at `>=0.90`, and keeps existing 2-round diff
   stability as an input signal.

2. **P1 - `[plan-space] add exhaustive miss probe to Phase 2/3 refinement`**  
   Scope: `/flywheel:plan`, `multi-model-triangulation`, and
   `jeff-convergence-audit` prompt docs only.  
   Acceptance: when convergence stalls or r1 is suspiciously clean, the plan
   template runs an adversarial "assume 80+ missed elements" re-review, records
   found/missed counts, and labels the premise as prompt pressure rather than
   fact.

3. **P1 - `[plan-space] retire stale aliases and modernize wizard outputs`**  
   Scope: add a pointer or remove references to missing
   `~/.claude/skills/.flywheel/skills/flywheel:plan.md`; update
   `dueling-idea-wizards` monitoring away from `CronCreate`; add structured
   `ADD/EDIT/KILL` output for wizard winners before `--beads`.  
   Acceptance: `rg 'skills/.flywheel/skills/flywheel:plan.md'` has no live
   dispatch references, wizard docs use event-driven/NTM monitoring, and winner
   reports include mergeable deltas plus an explicit human-review checkpoint.

Fix beads proposed: 3.
