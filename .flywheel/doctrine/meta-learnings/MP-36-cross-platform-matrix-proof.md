# MP-36 — Cross-platform matrix proof

**Discovered:** 2026-05-19T06:27Z
**Skills exemplifying:** 5+

## Essence

Portability claims require a platform/architecture matrix and smoke proof on each supported lane; README portability is not evidence.

## Where it applies

CI, multi-arch binaries, Apple Silicon ports, CUDA-to-MPS shims, GitHub Actions release builds, platform-specific dependencies.

## Adoption signal

Workflow declares OS/arch matrix, target triples or backend lanes, per-platform smoke tests, and cache/build keys that include platform.

## Exemplar skills (≥5)

- `~/.claude/skills/cross-platform-builds/SKILL.md:22` — skill covers Linux, macOS, Windows and multiple architectures.
- `~/.claude/skills/cross-platform-builds/SKILL.md:31` — CI matrix builds are explicit activation.
- `~/.claude/skills/gh-actions/SKILL.md:64` — GitHub Actions matrix is first-class.
- `~/.claude/skills/gh-actions/SKILL.md:66` — Linux x64 lane is named.
- `~/.claude/skills/gh-actions/SKILL.md:70` — Apple Silicon lane is named.
- `~/.claude/skills/gh-actions/SKILL.md:74` — Windows lane is named.
- `~/.claude/skills/apple-silicon-ml-porting/SKILL.md:13` — CUDA-era READMEs are assumed non-portable until proven.
- `~/.claude/skills/cuda-to-mps-adapter-pattern/SKILL.md:213` — MPS adapter has an explicit smoke test.

## Adoption recipes

**Recipe 1 — Matrix artifact:** every release-capable repo records supported OS/arch lanes.

**Recipe 2 — Smoke per lane:** one smoke test per lane must pass before portability is claimed.

**Recipe 3 — Platform cache key:** CI cache keys include OS and arch to avoid cross-lane contamination.

## Compliance test

```bash
grep -E "(matrix|arm64|x64|macOS|Windows|Linux|platform smoke|MPS)" SKILL.md || fail
```


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites earlier MP lessons directly.

- **MP-23 — replayable mutation contract:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-23-replayable-mutation-contract.md` for the canonical pattern.
- **MP-24 — boundary validation fail-closed:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-24-boundary-validation-fail-closed.md` for the canonical pattern.
- **MP-28 — checklist before claim:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-28-checklist-before-claim.md` for the canonical pattern.
