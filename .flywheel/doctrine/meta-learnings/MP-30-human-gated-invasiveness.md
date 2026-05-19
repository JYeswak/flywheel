# MP-30 — Human-gated invasiveness

**Discovered:** 2026-05-19T06:21Z
**Skills exemplifying:** 6+

## Essence

Recovery ladders and mutation workflows must separate probe/cheap repair from invasive actions, with explicit human approval before the irreversible tier.

## Where it applies

Security recovery, credential rotation, destructive migrations, major upgrades, deploy rollback, agent contact approval, bead/git sync boundaries.

## Adoption signal

Workflow names invasiveness levels and marks the top tier as manual, explicit, approval-required, or non-automatic.

## Exemplar skills (≥5)

- `~/.claude/skills/security-posture/SKILL.md:22` — posture workflow probes first, recovers by ladder, and never auto-rotates.
- `~/.claude/skills/security-posture/SKILL.md:70` — recovery ladders are manual and never auto-escalate.
- `~/.claude/skills/security-posture/SKILL.md:119` — L3 invasive recovery requires Joshua approval.
- `~/.claude/skills/database-modeling/SKILL.md:188` — destructive/data-affecting migrations need dry-run/apply separation and rollback or irreversible-risk note.
- `~/.claude/skills/dependency-management/SKILL.md:341` — major updates require dashboard approval.
- `~/.claude/skills/beads-br/SKILL.md:12` — `br` is non-invasive and never runs git commands.
- `~/.claude/skills/beads-br/SKILL.md:65` — sync is explicit and never automatic.
- `~/.claude/skills/agent-mail/SKILL.md:23` — blocked contact requires request and approval rather than forced messaging.
- `~/.claude/skills/environment-configuration/SKILL.md:238` — deploy-capable token replacement escalates to Joshua, not config drift repair.

## Adoption recipes

**Recipe 1 — Ladder taxonomy:** label actions L0 probe, L1 cheap, L2 moderate, L3 invasive.

**Recipe 2 — Approval gate:** L3 commands require an explicit approval artifact and cannot be run by automatic repair.

**Recipe 3 — Non-invasive default:** default commands inspect, stage, or dry-run; apply/sync/rotate is separate and named.

## Compliance test

```bash
grep -E "(approval required|never auto|manual|invasive|dry-run.*apply|explicit.*automatic)" SKILL.md || fail
```


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-17 — secret emission discipline:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md` for the canonical pattern.
- **MP-29 — production safety guardrails:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-29-production-safety-guardrails.md` for the canonical pattern.
- **MP-30 — human-gated invasiveness:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-30-human-gated-invasiveness.md` for the canonical pattern.
