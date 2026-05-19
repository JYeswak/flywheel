# MP-46 — Media timing signal gates

**Discovered:** 2026-05-19T08:05Z
**Discovered by:** skillos:2
**Skills exemplifying:** 6+

## Essence

Media quality is a timed signal contract: script, visuals, frames, captions, audio, and rendered pixels must agree on measurable clocks before taste review.

## Where it applies

Video analysis, TTS QA, Remotion renders, Zest Feed episode authoring, intro/outro grading, caption timing, and storyboard validation.

## Adoption signal

Skill uses ffprobe/frame extraction, contiguous timing ranges, LUFS/timestamp sidecars, pixel/audio gates, and stale-render rejection.

## Exemplar skills (≥5)

- `~/.claude/skills/ffmpeg-analyse-video/SKILL.md:67` — ffprobe emits metadata as JSON.
- `~/.claude/skills/ffmpeg-analyse-video/SKILL.md:96` — frame timestamps are calculated from sequence and extraction rate.
- `~/.claude/skills/integrating-script-visual-timing/SKILL.md:57` — one source of truth carries script, timing, and visual choice.
- `~/.claude/skills/integrating-script-visual-timing/SKILL.md:59` — `[TIME]` ranges must be contiguous and drift under 200 ms.
- `~/.claude/skills/quality-checking-tts-audio/SKILL.md:25` — sidecar enforces audio composite, hallucination score, LUFS drift, and provenance.
- `~/.claude/skills/remotion-zesttube-traumas/SKILL.md:43` — stinger gate enforces intro/outro caps, disclosure timing, and required fields.
- `~/.claude/skills/remotion-zesttube-traumas/SKILL.md:45` — rendered MP4 still must pass pixel/audio, intro/outro, and multi-axis review layers.
- `~/.claude/skills/grading-intro-outro-by-research-rubric/SKILL.md:48` — storyboard label is not proof that the render contains the intended intro.

## Adoption recipes

**Recipe 1 — Clock unification:** maintain one artifact that binds script ranges, visual refs, scene IDs, and target duration.

**Recipe 2 — Render evidence:** post-render gates inspect actual MP4 pixels/audio, not storyboard labels or intentions.

**Recipe 3 — Threshold receipt:** failure reports include observed value, threshold, artifact path, and rerender command.

## Compliance test

```bash
grep -E "(ffprobe|\\[TIME\\]|LUFS|pixel/audio|intro_outro|frame timestamp|drift)" SKILL.md || fail
```
