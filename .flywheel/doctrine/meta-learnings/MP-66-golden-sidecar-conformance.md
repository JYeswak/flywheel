# MP-66 — Golden sidecar conformance

**Discovered:** 2026-05-19T06:53Z
**Discovered by:** skillos:2
**Skills exemplifying:** 4+

## Essence

Media and model outputs earn trust through sidecar conformance data, multi-tier thresholds, and health probes; a better-looking result does not replace a golden without measurable agreement.

## Where it applies

TTS regression testing, voice pipelines, video rendering, model sweeps, audio QA, generated script passes, and any subjective output that still needs objective acceptance.

## Adoption signal

The skill emits sidecar metadata, tests independent tiers, probes provider capability before large runs, and blocks golden updates without explicit conformance thresholds.

## Exemplar skills (≥5)

- `~/.claude/skills/testing-tts-conformance/SKILL.md:20` — a render passes only when three independent tiers clear thresholds.
- `~/.claude/skills/testing-tts-conformance/SKILL.md:57` — each cell emits a conformance sidecar.
- `~/.claude/skills/testing-tts-conformance/SKILL.md:65` — never pin a golden just because it scores higher.
- `~/.claude/skills/using-voicebox-multi-engine/SKILL.md:22` — probe before running a full sweep.
- `~/.claude/skills/using-voicebox-multi-engine/SKILL.md:24` — unsupported speed, tempo, and SSML controls must not be assumed.
- `~/.claude/skills/using-voicebox-multi-engine/SKILL.md:186` — binding application is idempotent and verifies health/listings.
- `~/.claude/skills/using-voicebox-multi-engine/SKILL.md:194` — persist rewritten text and rerun lint, voice, grounding, and conformance.
- `~/.claude/skills/zesttube-e2e-smoke/SKILL.md:73` — each stage emits start and end events to `run.jsonl`.

## Adoption recipes

**Recipe 1 — Sidecar required:** every generated media cell writes JSON sidecar data with model, prompt, input hash, thresholds, and measured results.

**Recipe 2 — Independent tiers:** acceptance combines at least three independent checks such as acoustic, transcript, timing, visual, grounding, or event-log evidence.

**Recipe 3 — Golden lock:** golden replacement requires threshold pass, probe output, old/new artifact paths, and an explicit reason.

## Compliance test

```bash
grep -E "(sidecar|threshold|golden|probe|conformance|run.jsonl|health|listing)" SKILL.md || fail
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-79-oracle-strength-testing-ladder.md`
