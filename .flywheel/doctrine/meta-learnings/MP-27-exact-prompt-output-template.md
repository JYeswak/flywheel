# MP-27 — Exact-prompt output template

**Discovered:** 2026-05-19T06:21Z
**Skills exemplifying:** 7+

## Essence

For repeatable agent work, ship the invocation prompt and the expected output template together; otherwise every run re-invents the contract.

## Where it applies

Audits, archaeology, handoffs, agent-mail session bootstraps, bead conversion, security ladders, compliance reports.

## Adoption signal

Skill has `THE EXACT PROMPT`, `Output Template`, or equivalent machine-fillable artifact contract.

## Exemplar skills (≥5)

- `~/.claude/skills/agent-mail/SKILL.md:28` — session bootstrap is provided as an exact prompt.
- `~/.claude/skills/beads-workflow/SKILL.md:38` — plan-to-beads conversion includes an exact prompt.
- `~/.claude/skills/beads-workflow/SKILL.md:61` — bead polishing has a standard exact prompt.
- `~/.claude/skills/codebase-archaeology/SKILL.md:20` — archaeology provides an exact prompt.
- `~/.claude/skills/codebase-archaeology/SKILL.md:172` — archaeology also defines an output template.
- `~/.claude/skills/codebase-audit/SKILL.md:25` — codebase audit has an exact prompt.
- `~/.claude/skills/codebase-audit/SKILL.md:67` — codebase audit defines its report template.
- `~/.claude/skills/security-posture/SKILL.md:77` — exit-code-to-ladder mapping is an exact prompt.

## Adoption recipes

**Recipe 1 — Prompt/template pair:** every repeatable workflow includes both invocation text and expected output fields.

**Recipe 2 — Template lint:** CI checks required headings or JSON fields before accepting an agent-produced artifact.

**Recipe 3 — Callback reuse:** handoff/callback packets embed the template path instead of relying on prose instructions.

## Compliance test

```bash
grep -E "(THE EXACT PROMPT|Output Template|Report Template|callback.*schema)" SKILL.md || fail
```


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-04 — receipt-and-callback envelope contract:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-04-receipt-callback-envelope.md` for the canonical pattern.
- **MP-20 — cross-orch handoff:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-20-cross-orch-handoff.md` for the canonical pattern.
- **MP-23 — replayable mutation contract:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-23-replayable-mutation-contract.md` for the canonical pattern.
