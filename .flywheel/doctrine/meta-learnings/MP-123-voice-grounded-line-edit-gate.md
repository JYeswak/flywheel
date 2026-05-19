# MP-123 - Voice-grounded line-edit gate

**Discovered:** 2026-05-19T07:56Z
**Discovered by:** skillos:2
**Skills exemplifying:** 4+

## Essence

Public prose needs source context, brand constraints, grounded claims, and a manual line-edit pass that removes formulaic AI tells without flattening the voice.

## Where it applies

Landing pages, email drafts, support replies, social posts, brand copy, documentation, executive notes, public reports, and any prose that represents ZestStream or a client.

## Adoption signal

The workflow gathers audience and surface context, writes for specificity, grounds factual claims, runs voice rules, strips filler and formulaic constructions manually, and scores the result before release.

## Exemplar skills (>=5)

- `~/.claude/skills/de-slopify/SKILL.md:13` - AI-tell removal cannot be solved with regex alone.
- `~/.claude/skills/de-slopify/SKILL.md:17` - the exact prompt requires systematic manual review.
- `~/.claude/skills/de-slopify/SKILL.md:46` - the skill names concrete patterns to eliminate.
- `~/.claude/skills/de-slopify/SKILL.md:127` - manual review is required for context, tone, and judgment.
- `~/.claude/skills/stop-slop/SKILL.md:12` - slop removal cuts filler and breaks formulaic structures.
- `~/.claude/skills/stop-slop/SKILL.md:48` - the checklist requires no filler, varied sentence lengths, and a minimum score.
- `~/.claude/skills/copywriting/SKILL.md:41` - clarity beats cleverness; copy should use benefits and specificity.
- `~/.claude/skills/zeststream-brand-voice/SKILL.md:12` - voice work loads canon, identifies audience, rejects banned words, and grounds claims.
- `~/.claude/skills/zeststream-brand-voice/SKILL.md:113` - scoring and grounding gates decide release readiness.

## Adoption recipes

**Recipe 1 - Context intake:** record surface, audience, desired action, proof points, and banned claims before drafting.

**Recipe 2 - Grounding pass:** mark every factual claim as sourced, inferred, or removed.

**Recipe 3 - Human-line pass:** read every sentence for filler, formula, rhythm, specificity, and brand fit; do not rely on global replacements.

## Compliance test

```bash
grep -E "(audience|claim|ground|voice|filler|manual review|score|specific|banned|proof)" SKILL.md || exit 1
```
