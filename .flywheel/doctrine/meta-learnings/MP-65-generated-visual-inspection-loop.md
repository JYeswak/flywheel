# MP-65 — Generated visual inspection loop

**Discovered:** 2026-05-19T06:53Z
**Discovered by:** skillos:2
**Skills exemplifying:** 5+

## Essence

Generated visual assets are not accepted at generation time; they are rendered, opened, inspected, refined, and probed through the publishing route that will serve them.

## Where it applies

Open Graph images, social cards, generated thumbnails, share images, video reports, visual QA, screenshot-driven UI checks, and any automated image asset pipeline.

## Adoption signal

The skill requires reading the produced image, iterating against visual defects, verifying the public or framework route, and storing generated outputs as durable files.

## Exemplar skills (≥5)

- `~/.claude/skills/gh-og-share-images/SKILL.md:11` — creation uses iterative vision-guided refinement.
- `~/.claude/skills/gh-og-share-images/SKILL.md:19` — image generation is not fire-and-forget.
- `~/.claude/skills/gh-og-share-images/SKILL.md:40` — read the output image every time.
- `~/.claude/skills/gh-og-share-images/SKILL.md:68` — continue until the result is genuinely good.
- `~/.claude/skills/og-share-images/SKILL.md:21` — Next.js auto-detects metadata image routes.
- `~/.claude/skills/og-share-images/SKILL.md:69` — build verifies dynamic image routes.
- `~/.claude/skills/og-share-images/SKILL.md:70` — curl verifies that the image endpoint returns bytes.
- `~/.claude/skills/nano-banana/SKILL.md:57` — generated images are stored as files or object storage artifacts.

## Adoption recipes

**Recipe 1 — Open the artifact:** after generation, inspect the actual image file or screenshot before declaring success.

**Recipe 2 — Route probe:** verify the serving route with build output, HTTP status, content type, and non-zero bytes.

**Recipe 3 — Refinement receipt:** record prompt, file path, visual defect fixed, and final route probe result.

## Compliance test

```bash
grep -E "(read.*image|screenshot|inspect|refine|curl|content-type|bytes|artifact)" SKILL.md || fail
```
