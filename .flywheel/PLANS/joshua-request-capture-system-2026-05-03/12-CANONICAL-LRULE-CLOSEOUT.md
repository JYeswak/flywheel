---
title: "josh-req-12 canonical L-rule closeout"
type: plan
created: 2026-05-08
frontmatter_source: scaffold-doc-frontmatter
---

# josh-req-12 canonical L-rule closeout

Task: `flywheel-flmn-6fe627`
Parent bead: `flywheel-flmn`
Prerequisite bead satisfied in this pass: `flywheel-7elw`

## Status

The prerequisite layer-2 INCIDENTS entry was added to
`/Users/josh/.claude/skills/.flywheel/INCIDENTS.md` under trauma class
`joshua-request-forgotten`.

The layer-3 canonical L-rule was added to `.flywheel/AGENTS-CANONICAL.md` as
`L144 — JOSHUA-REQUEST-CAPTURE-MANDATORY`. `L143` was already occupied by
`WORKER-CLOSE-REQUIRES-GIT-COMMIT` from `flywheel-23dsl`, so this promotion
used the next available id.

## Incident Evidence Landed

The INCIDENTS entry includes:

- trauma_class: `joshua-request-forgotten`
- Forever-Rule: every Joshua message in flywheel-managed orchestrator sessions
  must be captured through prompt-submit substrate
- Cost citation: 2026-05-03 Jeff-corpus Socraticode indexing ask forgotten for
  roughly five hours
- Mechanism: UserPromptSubmit hook reads stdin JSON `.prompt`, scrubs before
  truncation, writes MISSION.md `## Joshua Requests`, mirrors JSONL, exits
  fail-open for user input
- L56 placement: layer-2 INCIDENTS promotion, with layer-3 canonical promotion
  target named as `JOSHUA-REQUEST-CAPTURE-MANDATORY`

## Canonical Rule Landed

```markdown
## L144 — JOSHUA-REQUEST-CAPTURE-MANDATORY

---
id: L144
title: Joshua request capture mandatory
status: long_term
shipped: 2026-05-08
review_due: 2026-11-08
trauma_class: joshua-request-forgotten
---

Every Joshua message in a flywheel-managed orchestrator session MUST enter the
request substrate at prompt time. The canonical path is UserPromptSubmit reading
stdin JSON `.prompt`, scrubbing secrets before truncation, appending to the
repo MISSION.md `## Joshua Requests` section, and mirroring a schema-versioned
row to `~/.local/state/flywheel/josh-requests.jsonl`.

The hook is passive and fail-open for user input, but missing capture is a
substrate failure. Orchestrators may interpret and prioritize captured requests,
but they may not rely on scrollback, memory, or "I'll remember" as the system of
record. Tick selection must surface open/stale Joshua requests before lower
priority autonomous work, and closure requires typed evidence.

Forbidden:
- Treating a Joshua request as complete without a captured row and typed closure
  evidence.
- Building dispatch plans from memory when `josh-requests` or MISSION substrate
  has not been checked.
- Designing capture around env-only prompt sources when stdin JSON `.prompt` is
  the verified hook contract.

Evidence:
- INCIDENTS:
  `/Users/josh/.claude/skills/.flywheel/INCIDENTS.md#2026-05-08-rule-promotion-joshua-requests-must-enter-substrate-at-prompt-time-joshua-request-forgotten`
- Plan:
  `.flywheel/plans/joshua-request-capture-system-2026-05-03/00-PLAN.md`
- Polish findings:
  `.flywheel/plans/joshua-request-capture-system-2026-05-03/05-POLISH-r1.md`
- Beads: `flywheel-7elw`, `flywheel-flmn`

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

Cross-references: L56, L61, L62, L70, L71, L80, L120, and L137.
```

## Validation

```bash
rg -n "joshua-request-forgotten|JOSHUA-REQUEST-CAPTURE-MANDATORY|UserPromptSubmit" \
  /Users/josh/.claude/skills/.flywheel/INCIDENTS.md \
  .flywheel/AGENTS-CANONICAL.md \
  .flywheel/plans/joshua-request-capture-system-2026-05-03/12-CANONICAL-LRULE-CLOSEOUT.md
```

Result: PASS.

## Three-Q Receipt

- Q1 What changed? The missing L56 layer-2 INCIDENTS entry was landed and the
  canonical L144 rule was added to `.flywheel/AGENTS-CANONICAL.md`.
- Q2 How was it validated? Targeted `rg` confirmed the incident, canonical
  rule, trauma class, and UserPromptSubmit mechanism.
- Q3 What remains? Root/template propagation is outside this dispatched
  surface; this bead's named canonical surface is complete.
