# MP-63 — Phase-tick bounded action

**Discovered:** 2026-05-19T06:53Z
**Discovered by:** skillos:2
**Skills exemplifying:** 5+

## Essence

Loops stay accretive when each tick declares its phase, class, owner, one bounded action, evidence target, and callback shape before workers touch files.

## Where it applies

Flywheel loop ticks, NTM dispatches, worker orchestration, recurring automation, multi-pane repairs, and any long-running agent system that can otherwise drift into no-op motion.

## Adoption signal

The skill names the current phase, dispatch class, next bounded action, callback contract, and close-of-tick evidence rather than only describing broad intent.

## Exemplar skills (≥5)

- `~/.claude/skills/flywheel-end-to-end/SKILL.md:166` — portable loop mode chooses one bounded action per tick.
- `~/.claude/skills/flywheel-end-to-end/SKILL.md:175` — phase priority determines what happens next.
- `~/.claude/skills/flywheel-end-to-end/SKILL.md:200` — each phase maps to a concrete class of work.
- `~/.claude/skills/flywheel-end-to-end/SKILL.md:271` — dispatch packets state phase and tick class.
- `~/.claude/skills/flywheel-end-to-end/SKILL.md:576` — workers report done, warn, blocked, or failed.
- `~/.claude/skills/worker-orchestration/SKILL.md:28` — orchestration is mostly planning with a smaller execution slice.
- `~/.claude/skills/worker-orchestration/SKILL.md:52` — unblocked bead count drives worker utilization.
- `~/.claude/skills/tick-protocol-init/SKILL.md:43` — close-of-tick ritual is mandatory after scheduled cycles.

## Adoption recipes

**Recipe 1 — Phase label:** every loop packet includes phase, tick class, owner, and whether it is discovery, repair, validation, or closure.

**Recipe 2 — Single bounded action:** the tick chooses one safe local action and states the artifact it will leave behind.

**Recipe 3 — Callback enum:** worker callbacks use stable states such as `done`, `warn`, `blocked`, and `failed` with evidence paths.

## Compliance test

```bash
grep -E "(phase|tick_class|bounded action|callback|done|blocked|worker|evidence)" SKILL.md || fail
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-91-progress-counter-forced-motion-loop.md`
