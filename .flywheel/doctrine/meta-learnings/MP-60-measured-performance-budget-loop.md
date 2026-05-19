# MP-60 — Measured performance budget loop

**Discovered:** 2026-05-19T08:39Z
**Discovered by:** skillos:2
**Skills exemplifying:** 5+

## Essence

Performance work starts with budgets and profiles, ranks hotspots by contribution, ships only measurable wins, and re-profiles because bottlenecks move.

## Where it applies

Render pipelines, React apps, visualization canvases, MLOps inference, API latency, Remotion Apple Silicon tuning, and any optimization claim.

## Adoption signal

Skill captures baseline p50/p95/p99 or wall-clock, defines budgets, ranks contribution, gates quality, journals fixes, and reruns the profiler after each change.

## Exemplar skills (≥5)

- `~/.claude/skills/extreme-software-optimization/SKILL.md:4` — optimization is profile-driven with behavior proofs.
- `~/.claude/skills/extreme-software-optimization/SKILL.md:20` — repeat by re-profiling because bottlenecks shift.
- `~/.claude/skills/extreme-software-optimization/SKILL.md:107` — baselines include p50/p95/p99, throughput, and memory.
- `~/.claude/skills/cfs-performance-discipline/SKILL.md:39` — never optimize what cannot be measured.
- `~/.claude/skills/cfs-performance-discipline/SKILL.md:54` — define step budgets and breach detection.
- `~/.claude/skills/cfs-performance-discipline/SKILL.md:92` — full sweep runs baseline, rank, optimize, and journal.
- `~/.claude/skills/remotion-apple-silicon-perf/SKILL.md:82` — concurrency sweet spot is measured, not guessed.
- `~/.claude/skills/rendering-multi-aspect-remotion/SKILL.md:52` — Lambda batch queue starts only after local rendering exceeds a threshold.
- `~/.claude/skills/interactive-visualization-creator/SKILL.md:32` — lazy initialization is mandatory for heavy off-screen content.

## Adoption recipes

**Recipe 1 — Budget first:** define target latency, throughput, memory, render time, or quality thresholds before changing code.

**Recipe 2 — Rank by contribution:** optimize top contributors, not the easiest or most interesting functions.

**Recipe 3 — Re-profile receipt:** every performance claim includes before/after numbers, command, data size, and quality gate result.

## Compliance test

```bash
grep -E "(p50|p95|baseline|budget|profile|re-profile|top-3|before/after)" SKILL.md || fail
```
