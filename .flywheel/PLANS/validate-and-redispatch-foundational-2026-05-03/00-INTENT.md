---
title: "INTENT — validate-everything-we-build as foundational flywheel primitive"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# INTENT — validate-everything-we-build as foundational flywheel primitive

Captured: 2026-05-03T22:19Z (initial scope: validate-and-redispatch worker callbacks)
Expanded: 2026-05-03T22:25Z (Joshua broadened: every flywheel surface must be subject to this)
Source: Joshua direct prompts this session

## Verbatim prompts
> [22:19Z] "this process of validate and redispatch needs foundationally baked into our flywheel - /flywheel:plan"

> [22:25Z] "every surface in our flywheel need to be validated against this idea - are we validating everything we build? are we documenting it? are we surfacing all skill and issue findings throughout? that is the point of the flywheel"

## Three audit questions (the new framing)
For EVERY surface, commit, skill, bead, doctrine file, hook, probe, CLI, MCP server, memory note, README, and agent in the flywheel ecosystem:

1. **Are we validating everything we build?**
   - Probe artifacts exist at claimed paths
   - Smoke tests run and pass
   - End-to-end proof, not just unit tests
   - Validation is mechanical (gated), not memory-driven (rule someone has to remember)

2. **Are we documenting it?**
   - AGENTS.md L-rule landing for doctrine
   - INCIDENTS.md trauma class for repeated failure modes
   - Memory note for cross-session lessons
   - README update for user-facing surfaces
   - Skill SKILL.md for repeatable patterns
   - L61 ecosystem-wire-in cited and applied

3. **Are we surfacing all skill+issue findings throughout?**
   - skills library updated (skill-builder skill applied)
   - fuckup-log row → INCIDENTS.md promotion via L56 ladder
   - Bead filed for any unwired/undocumented gap
   - Doctor signal added if signal class is recurring
   - /flywheel:learn ingests it
   - Cross-orch propagation if fleet-wide

## Surrounding context (this session)
1. Earlier in session: 3× fleet death from clean codex exits → flywheel-delp filed
2. dcg v0.5.0 → v0.5.1 upgraded after Joshua surfaced Jeff's note (watchtower failure)
3. Substrate audit revealed josh-request-capture documented but partially-wired (3 OPEN beads with claimed-shipped artifacts at canonical paths that don't exist)
4. Joshua flagged: orchestrators must validate worker DONE callbacks AND open new beads for unfulfilled work BEFORE summarizing — I (orch) had skipped this step on the p4 audit callback
5. Fuckup logged: `orchestrator-skipped-callback-validation` severity=high 2026-05-03T22:15:35Z
6. Doctrine bead `flywheel-1z65` filed (P1) capturing the rule
7. Joshua: this needs to be foundational, not a one-off rule → `/flywheel:plan`

## Core proposition
Every worker DONE callback MUST flow through orchestrator validation before any "summarize to Joshua" or "what next" step. Validation is not optional, not memory-driven; it is mechanical, doctor-gated, dispatch-template-injected, and a tick-phase in its own right.

## Components in scope
1. **Mechanical gate** — dispatch-template auto-injects validation block at end of every dispatch packet; orchestrator can't skip it without the gate firing
2. **Doctor signal** — `callbacks_unvalidated_count` ≥ 1 → status=fail; `callbacks_validated_with_failures_count` surfaces the auto-opened fix-beads
3. **Tick phase** — VALIDATE phase between DISPATCH and INTEGRATE; runs validation on all in-flight callbacks before any new dispatch
4. **Auto-open fix-beads** — when validation finds unfulfilled gates, auto-create bead with worker evidence as starting context, blocked-by parent bead
5. **Auto-reopen falsely-closed beads** — when audits find "shipped" beads with missing artifacts, auto-reopen with audit reference
6. **L-rule landing** — promote flywheel-1z65 doctrine to canonical L-rule with companion citations (L52, L53, L60, L61)
7. **/flywheel:learn integration** — every worker callback ingested produces validation receipts BEFORE LEARN tick advances
8. **Memory wire-in** — feedback_orchestrator_validates_callbacks.md indexed (already done)
9. **Codex parity** — validation must work whether worker is Claude or Codex (related to flywheel-2p25 parity epic)

## Existing artifacts
- `flywheel-1z65` — meta-doctrine bead (P1, blocks flywheel-2p25 parity epic)
- `feedback_orchestrator_validates_callbacks.md` — META-RULE memory note (just landed)
- `feedback_substrate_watchtower_must_be_wired.md` — companion (documented ≠ wired)
- `feedback_orchestrator_must_dispatch.md` — companion (orch decides without asking)
- `feedback_data_guides_decisions_not_human_judgment.md` — companion (no meat-puppet gates)
- Trauma class `orchestrator-skipped-callback-validation` in fuckup-log.jsonl

## Why /flywheel:plan and not just a bead
This is foundational doctrine touching:
- Tick phase semantics (new VALIDATE phase)
- Doctor signal taxonomy
- Dispatch template structure
- Bead auto-creation rules
- L-rule promotion path
- Skill ecosystem (probably needs new skill or extension to dispatch-tool-contracts)

A single bead can't carry that. Plan-space cost (12-20 dispatches) is justified.

## Out of scope (explicitly)
- Implementing the validation primitive (that's Phase 4-5 → bead → /flywheel:dispatch)
- Backporting validation to closed beads (only forward, like schema v2)
- Changing the existing dispatch-template schema (validation block is APPENDED, not restructure)
- Tooling Joshua's pane state probe (separate concern)

## Success criteria for the plan itself
- 5/5 phases complete (or audit-paused for Joshua-disposes)
- 8-15 polished beads, DAG validated, every component above has ≥1 mitigating bead
- Mechanical gate is implementable from polished beads alone (no plan-stage handwave)
