# MP-91 - Progress-counter forced-motion loop

**Discovered:** 2026-05-19T08:02Z
**Discovered by:** skillos:2
**Skills exemplifying:** 7+

## Essence

Loops that can repeatedly report "nothing to do" need explicit zero-value counters, stale-state probes, and forced next actions after a threshold.

## Where it applies

Cron orchestrators, agent dispatch loops, retry systems, batch processors, blocker re-evaluation, long-running simulations, and any workflow where HOLD can disguise drift.

## Adoption signal

The loop records productive events per tick, increments repeated no-op or stall counters, defines a threshold that changes behavior, and writes an append-only receipt proving whether the tick moved the system.

## Exemplar skills (>=5)

- `~/.claude/skills/accretive-cron-orchestration/SKILL.md:30` - names the failure class: repeated HOLD ticks with zero dispatches and zero reaps.
- `~/.claude/skills/accretive-cron-orchestration/SKILL.md:55` - tick state increments counters in `.ecosystem/cron_stocks.json`.
- `~/.claude/skills/accretive-cron-orchestration/SKILL.md:77` - two consecutive zero-value ticks force DEGRADED state and forbid another HOLD.
- `~/.claude/skills/accretive-cron-orchestration/SKILL.md:91` - a pure HOLD with no productive event is graded F.
- `~/.claude/skills/deterministic-tick-simulation/SKILL.md:23` - blocker-discipline AC-tests require deterministic tick re-evaluation.
- `~/.claude/skills/deterministic-tick-simulation/SKILL.md:63` - replay logs carry per-tick state hashes.
- `~/.claude/skills/etl-pipeline/SKILL.md:204` - silent success that drops records is caught by reconciliation every run.
- `~/.claude/skills/distributed-systems/SKILL.md:159` - cron is rejected for multi-step workflows because it lacks retry, state, and visibility.

## Adoption recipes

**Recipe 1 - No-op budget:** define how many consecutive zero-value ticks are allowed before the loop must change mode.

**Recipe 2 - Productive-event ledger:** record dispatches, completions, repairs, row counts, or state hashes per tick; never rely on prose status.

**Recipe 3 - Forced next action:** after threshold, require a probe, recovery step, redispatch, or bead creation instead of another HOLD.

## Compliance test

```bash
grep -E "(zero|no-op|HOLD|counter|tick|productive|DEGRADED|reconciliation|state hash)" SKILL.md || exit 1
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-63-phase-tick-bounded-action.md`
