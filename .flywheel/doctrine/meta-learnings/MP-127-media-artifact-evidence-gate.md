# MP-127 - Media artifact evidence gate

**Discovered:** 2026-05-19T07:56Z
**Discovered by:** skillos:2
**Skills exemplifying:** 4+

## Essence

Media pipelines must verify the actual rendered or edited artifact with frame, audio, OCR, metadata, and visual evidence rather than trusting that the script completed.

## Where it applies

Remotion renders, generated images, local image overlays, captions, video reports, brand-token reviews, publish gates, social images, and any AV artifact with timing or layout constraints.

## Adoption signal

The workflow renders or edits a concrete artifact, captures logs and sidecars, inspects actual frames or image crops, runs technical probes, applies hard gates, and writes a structured publish or block report.

## Exemplar skills (>=5)

- `~/.claude/skills/video-report/SKILL.md:6` - reported video bugs are reproduced by downloading the URL into the example package.
- `~/.claude/skills/video-report/SKILL.md:8` - reproduction uses verbose Remotion render logs.
- `~/.claude/skills/remotion-best-practices/SKILL.md:67` - Remotion animations must be driven by `useCurrentFrame()`.
- `~/.claude/skills/remotion-best-practices/SKILL.md:68` - CSS transitions and animations do not render correctly.
- `~/.claude/skills/reviewing-zest-feed-multi-axis/SKILL.md:10` - final review runs after MP4 render, pre-ship AV check, and intro/outro grading.
- `~/.claude/skills/reviewing-zest-feed-multi-axis/SKILL.md:33` - voice, visual, and technical axes run independently.
- `~/.claude/skills/reviewing-zest-feed-multi-axis/SKILL.md:41` - FTC disclosure must be visible in frames 0-300.
- `~/.claude/skills/reviewing-zest-feed-multi-axis/SKILL.md:81` - failed hard gates cap the composite and force block.
- `~/.claude/skills/image-editor/SKILL.md:65` - visual QA is mandatory after image overlay or composite runs.
- `~/.claude/skills/image-editor/SKILL.md:67` - a successful script run is not proof that the image is correct.

## Adoption recipes

**Recipe 1 - Artifact reproduction:** recreate the artifact from source URL, storyboard, prompt, or input image and retain logs.

**Recipe 2 - Independent probes:** inspect visual frames/crops, audio sidecars, OCR/captions, metadata, and timing as separate axes.

**Recipe 3 - Hard-gate report:** emit a structured `PUBLISH` or `BLOCK` result with failed gate names and owning fix paths.

## Compliance test

```bash
grep -E "(render|artifact|frame|ffprobe|OCR|audio|visual QA|hard gate|PUBLISH|BLOCK|verbose)" SKILL.md || exit 1
```
