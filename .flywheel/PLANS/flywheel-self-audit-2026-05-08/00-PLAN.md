---
title: "Flywheel Self-Audit Plan — 2026-05-08"
type: plan
created: 2026-05-08
bead: flywheel-self
frontmatter_source: scaffold-doc-frontmatter
---

# Flywheel Self-Audit Plan — 2026-05-08

**Trigger:** agent-flywheel.com /complete-guide pulled + bidirectional gap analysis at `.flywheel/research/external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md`. User directive: "turn the flywheel into beads — make sure we're auditing all layers of our flywheel and coming back with lessons learned."

**Goal:** every layer of our flywheel gets one explicit audit bead. Each audit produces a lessons-learned artifact at `.flywheel/PLANS/flywheel-self-audit-2026-05-08/audits/<layer>.md` with: what we have, what's load-bearing, what's vestigial, what's missing per agent-flywheel.com gap analysis, and a 1-3 fix-bead manifest.

## The 7 layers (Three Reasoning Spaces × ops/hygiene/doctrine bisection)

| # | Layer | Scope | Audit bead |
|---|---|---|---|
| 1 | **Plan-space** | /flywheel:plan, plan-space-convergence, multi-model-triangulation, dueling-idea-wizards, jeff-convergence-audit, research-triad, idea-wizard | (audit-1) |
| 2 | **Bead-space** | beads-workflow, plan-space-convergence, bead polish discipline, br/bv tooling, plan→bead conversion contract | (audit-2) |
| 3 | **Code-space** | UBS, multi-pass-bug-hunting, de-slopify, code-reviewer agents, gemini-swarm review, security-review, ui-polish | (audit-3) |
| 4 | **Coordination** | NTM canonical surfaces, Agent Mail, doctrine-broadcast sidechannel, dispatch-log substrate, callback contracts, dispatch-template, close-handler | (audit-4) |
| 5 | **Orchestrator** | /flywheel:tick, /flywheel:dispatch, /flywheel:respawn, /flywheel:status, /flywheel:loop, /loop, peer-orch handoff, callback reap discipline | (audit-5) |
| 6 | **Hygiene** | storage-prune, session-residue-prune, repo-hygiene meta-skill, fuckup-log promotion, watcher-pattern-bank, doctrine-sync, canonical-meta-rules-sync | (audit-6) |
| 7 | **Doctrine** | AGENTS.md (root + canonical + template), L1-L126 rules, MISSION-anchor, Three Reasoning Spaces, 6-Joshua-blocker-classes, mission-lock | (audit-7) |

## Audit contract per layer

Each audit bead writes `audits/<layer>.md` with sections:

1. **Inventory** — every script/skill/doctrine artifact in scope, file:line citations
2. **Load-bearing** — surfaces with ≥3 callsites OR critical path; proven by evidence
3. **Vestigial** — surfaces with 0-2 callsites OR superseded; candidates for sunset
4. **Missing per agent-flywheel.com gap analysis** — items from `external-doctrine/agent-flywheel-com-complete-guide-2026-05-08.md` Tier-1/2/3 that apply to this layer
5. **Lessons learned (today's evidence)** — what shipped today, what broke, what worked
6. **Fix-bead manifest** — 1-3 proposed beads (title, priority, scope, acceptance) — recommendations only, NOT filed

## Process per audit bead

1. socraticode K=10 against `/Users/josh/Developer/flywheel` for the layer's scope keywords
2. Read source-of-truth docs cited in `audits/<layer>.md` Section 1
3. Cross-reference every Tier-1/2/3 gap from agent-flywheel.com analysis
4. Cite today's evidence (commits, callbacks, failures) where relevant
5. Output the 6-section markdown
6. Compliance pack on close per post-x6ok8 contract

## Output

`.flywheel/PLANS/flywheel-self-audit-2026-05-08/audits/{plan-space,bead-space,code-space,coordination,orchestrator,hygiene,doctrine}.md` (7 files)
+ `.flywheel/PLANS/flywheel-self-audit-2026-05-08/01-SYNTHESIS.md` (orchestrator-side synthesis after all 7 land — fix-bead consolidation, deduplication, priority ordering)

## Ordering

7 audits are ORTHOGONAL — no dependencies. Run in 3 waves of ~2-3 panes:
- **Wave 1 (parallel × 3):** plan-space, bead-space, code-space (the Three Reasoning Spaces — most leverage, most independent)
- **Wave 2 (parallel × 3):** coordination, orchestrator, hygiene (substrate triad)
- **Wave 3 (single):** doctrine (synthesizes all 6 prior audits since L-rules touch every layer)

Synthesis bead runs after wave 3 lands.

## Acceptance for the plan as a whole

- 7 layer-audits written with all 6 sections each
- 7 separate commits (one per audit) for clean revert
- Synthesis doc produced with deduplicated fix-bead manifest
- ZERO new fix-beads filed during audit phase (recommendations only — orchestrator files post-synthesis)
- Total expected: ~15-25 fix-beads consolidated from ~21 raw proposals (3 per layer × 7)

## Mission anchor

continuous-orchestrator-uptime-self-sustaining-fleet — a flywheel that doesn't audit itself is just spinning. agent-flywheel.com is the public benchmark; this audit measures our doctrine's depth against it AND surfaces vestigial substrate we've been carrying forward.
