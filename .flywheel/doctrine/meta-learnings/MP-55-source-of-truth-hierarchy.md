# MP-55 — Source-of-truth hierarchy

**Discovered:** 2026-05-19T08:39Z
**Discovered by:** skillos:2
**Skills exemplifying:** 5+

## Essence

Recovery starts by naming the authoritative layer and demoting caches, mirrors, pane titles, and proxy metrics; a plausible tool result is not truth until the hierarchy confirms it.

## Where it applies

State recovery, frontend state, SQLite/JSONL CLIs, substrate bleed, Agent Mail reservation cleanup, cache invalidation, and incident triage.

## Adoption signal

Skill declares canonical source, alternate sources, cache/rebuild relationships, secondary verifier, disagreement policy, and recovery commands.

## Exemplar skills (≥5)

- `~/.claude/skills/state-truth-recovery/SKILL.md:18` — jsonl/git HEAD can be authoritative while SQLite is a rebuildable cache.
- `~/.claude/skills/state-truth-recovery/SKILL.md:30` — name the canonical layer before recovery.
- `~/.claude/skills/state-truth-recovery/SKILL.md:39` — recovery claims cite authoritative artifact plus secondary verifier.
- `~/.claude/skills/substrate-bleed-triage/SKILL.md:43` — state expected canonical substrate and observed alternate substrate.
- `~/.claude/skills/substrate-bleed-triage/SKILL.md:56` — never trust a single truth source at a substrate boundary.
- `~/.claude/skills/rust-cli-with-sqlite/SKILL.md:87` — SQLite is source of truth and JSONL is periodic export.
- `~/.claude/skills/state-management/SKILL.md:18` — server state has the server as source of truth.
- `~/.claude/skills/state-management/SKILL.md:85` — URL can be the source of truth for shareable state.

## Adoption recipes

**Recipe 1 — Truth ladder:** list canonical source, cache, mirror, display surface, and diagnostic surface in order.

**Recipe 2 — Disagreement receipt:** if sources disagree, record the disagreement and choose the conservative source.

**Recipe 3 — Rebuild command:** every cache source has a documented rebuild/import/export command and validation probe.

## Compliance test

```bash
grep -E "(source of truth|canonical layer|secondary verifier|cache|mirror|disagreement)" SKILL.md || fail
```
