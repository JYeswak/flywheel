# L160 — AGENTIC-LOOP-HALT-VIA-POSTTOOLUSE-HOOK-WHEN-LEAK-DETECTED

---
id: L160
title: Agentic loops must halt when a protection hook detects a leak
status: long_term
shipped: 2026-05-15
review_due: 2026-11-15
trauma_class: leak-detected-but-agent-loop-continued
source_owner: skillos
source_locator: /Users/josh/Developer/skillos/.flywheel/doctrine/cli-version-flag-mismatch-output-format-switch.md
ratification: .flywheel/handoffs/20260512T040500Z-from-flywheel-1-to-skillos-1-L158-L159-RATIFICATION.md
---

When a PostToolUse, shell, or equivalent protection hook detects a credential
or irreversible-breach-class leak, the agentic loop must halt. Continuing with
the next tool call is non-compliant unless a human operator has made the
continuation decision after the mitigation path is understood.

The hook firing is not a nuisance event. It is evidence that the protection
system worked and that the next system action is containment, rotation, audit,
and an explicit continuation decision.

## Flywheel application

Flywheel-owned loop surfaces must preserve hook failures as stop signals. They
may summarize and route the evidence, but they may not auto-clear the stop by
respawning the pane, flushing local state, or retrying the same workflow with a
slightly different command.

## SkillOS source

SkillOS owns the canonical leak-class incident doctrine. This Flywheel sister
rule cites the source doctrine and makes the loop-control consequence explicit
for Flywheel workers.

- SkillOS canonical:
  `/Users/josh/Developer/skillos/.flywheel/doctrine/cli-version-flag-mismatch-output-format-switch.md`
- Flywheel ratification:
  `.flywheel/handoffs/20260512T040500Z-from-flywheel-1-to-skillos-1-L158-L159-RATIFICATION.md`

