# MP-64 — Heartbeat file resume

**Discovered:** 2026-05-19T06:53Z
**Discovered by:** skillos:2
**Skills exemplifying:** 4+

## Essence

Long work survives compaction, pane loss, and worker turnover by writing progress, ownership, next action, and evidence to disk instead of trusting conversational memory.

## Where it applies

Long-horizon pipelines, repeated skill application, worker orchestration, multi-pass audits, batch generation, and any task that spans multiple context windows.

## Adoption signal

The skill defines a project-local state or progress file, updates it after each meaningful step, uses it as the resume source, and stores worker results on disk.

## Exemplar skills (≥5)

- `~/.claude/skills/long-horizon-pipeline-ops/SKILL.md:34` — `STATE.md` acts as the pipeline heartbeat file.
- `~/.claude/skills/long-horizon-pipeline-ops/SKILL.md:66` — ownership is declared at the top of the heartbeat.
- `~/.claude/skills/long-horizon-pipeline-ops/SKILL.md:96` — kick, schedule wakeup, report, and continue form the operating loop.
- `~/.claude/skills/long-horizon-pipeline-ops/SKILL.md:144` — agents write results to disk instead of returning them only to context.
- `~/.claude/skills/repeatedly-apply-skill/SKILL.md:57` — repeated work writes `.skill-loop-progress.md`.
- `~/.claude/skills/repeatedly-apply-skill/SKILL.md:170` — after compaction, read the progress file and continue.
- `~/.claude/skills/worker-orchestration/SKILL.md:223` — worker output is captured for later coordination.
- `~/.claude/skills/multi-pass-bug-hunting/SKILL.md:89` — each pass records findings so later passes do not restart discovery.

## Adoption recipes

**Recipe 1 — Heartbeat path:** name the exact state file before starting long work and treat it as the resume source.

**Recipe 2 — Ownership header:** record owner, current phase, last completed step, next action, and evidence directory at the top.

**Recipe 3 — Disk-first callback:** worker outputs, summaries, and receipts are written to files before orchestration messages reference them.

## Compliance test

```bash
grep -E "(STATE.md|progress|heartbeat|resume|owner|next action|write.*disk|compaction)" SKILL.md || fail
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-83-portable-session-recovery-ladder.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-92-reversible-recovery-ladder.md`
