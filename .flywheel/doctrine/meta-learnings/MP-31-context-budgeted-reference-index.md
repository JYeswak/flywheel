# MP-31 — Context-budgeted reference index

**Discovered:** 2026-05-19T06:27Z
**Skills exemplifying:** 8+

## Essence

Keep the activation surface small and route deep detail through a named reference index; context budget is a first-class design constraint.

## Where it applies

Long skills, API/vendor references, CI recipes, orchestration prompt banks, media provider docs, agent ergonomics libraries.

## Adoption signal

Skill has a concise SKILL.md plus `references/` index, `Extended Reference`, `LATEST.md`, or "read this first" cheat sheet.

## Exemplar skills (≥5)

- `~/.claude/skills/anthropic-cli-patterns/SKILL.md:226` — deep sections are moved to extracted detail to preserve activation budget.
- `~/.claude/skills/api-documentation-generation/SKILL.md:255` — anti-pattern detail lives in references to keep SKILL.md small.
- `~/.claude/skills/apple-silicon-ml-porting/SKILL.md:70` — blocker taxonomy is shifted to extracted detail for context-budget control.
- `~/.claude/skills/cross-platform-builds/SKILL.md:38` — core patterns live in extracted detail.
- `~/.claude/skills/dispatch-tool-contracts/SKILL.md:202` — exact syntax detail is pushed to references.
- `~/.claude/skills/generating-images-multi-provider/SKILL.md:172` — provider breach details live in extracted detail.
- `~/.claude/skills/agent-ergonomics-cli/SKILL.md:25` — starts with a dense cheat sheet for fast activation.
- `~/.claude/skills/gh-actions/SKILL.md:141` — reference index routes CI subdomains to focused files.

## Adoption recipes

**Recipe 1 — Activation split:** keep SKILL.md to trigger, core rules, and top workflow; move long examples to `references/`.

**Recipe 2 — Reference index:** add a table mapping use cases to reference files.

**Recipe 3 — Freshness lane:** if external APIs are involved, pair the index with `LATEST.md` or a drift-probe link.

## Compliance test

```bash
grep -E "(Extended Reference|references/|LATEST.md|context budget|CHEAT-SHEET)" SKILL.md || fail
```


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites earlier MP lessons directly.

- **MP-13 — living documentation:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-13-living-documentation.md` for the canonical pattern.
- **MP-16 — search tool routing doctrine:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-16-search-tool-routing.md` for the canonical pattern.
- **MP-28 — checklist before claim:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-28-checklist-before-claim.md` for the canonical pattern.
