# MP-59 — Generated docs publish asset

**Discovered:** 2026-05-19T08:39Z
**Discovered by:** skillos:2
**Skills exemplifying:** 6+

## Essence

Documentation that ships is an artifact pipeline: it has source files, generated assets, compile checks, schema alignment, and freshness rules, not just prose near the code.

## Where it applies

MDX docs, README/API docs, Zest Feed client registries, TTS conventions, episode production handoffs, review JSONs, and social preview cards.

## Adoption signal

Skill names source docs, generated outputs, build/render commands, schema consumers, freshness checks, and the rule that wrong docs block completion.

## Exemplar skills (≥5)

- `~/.claude/skills/writing-docs/SKILL.md:8` — documentation lives in a specific MDX source tree.
- `~/.claude/skills/writing-docs/SKILL.md:15` — docs changes generate social preview cards.
- `~/.claude/skills/writing-docs/SKILL.md:199` — docs compile is verified with a build command.
- `~/.claude/skills/living-documentation/SKILL.md:13` — documentation is part of the feature.
- `~/.claude/skills/living-documentation/SKILL.md:91` — wrong docs mean the feature is incomplete.
- `~/.claude/skills/zest-feed-content-client-onboarding/SKILL.md:111` — client YAML must satisfy the loader schema.
- `~/.claude/skills/writing-qwen-tts-scripts/SKILL.md:217` — the authoritative source document governs skill updates.
- `~/.claude/skills/producing-zest-feed-episodes/SKILL.md:40` — publish handoff carries final MP4 plus metadata to n8n.

## Adoption recipes

**Recipe 1 — Source/output map:** list source doc, generated assets, consumers, and verification commands together.

**Recipe 2 — Schema alignment:** if docs or registries feed code, validate against the consumer schema before completion.

**Recipe 3 — Freshness gate:** feature closeout checks docs updated, generated assets refreshed, and build/render commands passed.

## Compliance test

```bash
grep -E "(generated|build-docs|source document|schema|preview cards|docs.*feature)" SKILL.md || fail
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-13-living-documentation.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-54-template-publish-gate.md`
