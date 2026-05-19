---
title: Goal Contract No Writable Escape
source_beads:
  - flywheel-2xdi.177
  - flywheel-2xdi.178
canonical_memory:
  - feedback_forever_goals_must_not_hardcode_changing_lists.md
  - feedback_or_explanation_escape_is_goodhart_at_goal_layer.md
---

# Goal Contract No Writable Escape

A forever goal must be evaluated against live operating facts, not against a
document the operator can write during the same session. If the goal can be
satisfied by editing the goal, filing an explanation, or hardcoding today's
fleet list, the goal is no longer a control loop. It has become a checkbox.

## Canonical Memory Sources

Read these two source memories before editing `/goal` contracts or goal-build
validators:

- `~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_forever_goals_must_not_hardcode_changing_lists.md`
- `~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_or_explanation_escape_is_goodhart_at_goal_layer.md`

They describe two shapes of the same failure:

- Hardcoded changing lists make the goal stale as soon as the fleet changes.
- "OR explanation filed" clauses let the operator satisfy an outcome bar by
  writing a document.

## Operating Rule

Forever-goal text must reference canonical registries and live receipts:

- Use "active commercial engagements per the canonical registry," not a
  comma-separated list of client names.
- Use "at least one real event occurred," not "or explanation filed."
- Use receipts, ledgers, counters, and validator output as proof surfaces.
- Treat writable prose as context, never as satisfaction of the hard bar.

## Validator Duty

The goal-build validator should reject these shapes at authoring time:

- Three or more proper nouns in a comma-separated changing list.
- OR branches that point to explanation, note, filing, document, or report.
- Temporal hedges such as "for now," "as a first step," or "future work."

If a future goal needs an OR clause, both branches must be live observable
events. The branch cannot be a document that exists because the operator wrote
it after seeing the gate.

This doctrine file is the name cross-link for both source memories. The
behavioral receiver is the `/goal` authoring gate and the goal-build validator.


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-17 — secret emission discipline:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md` for the canonical pattern.
- **MP-29 — production safety guardrails:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-29-production-safety-guardrails.md` for the canonical pattern.
- **MP-30 — human-gated invasiveness:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-30-human-gated-invasiveness.md` for the canonical pattern.
