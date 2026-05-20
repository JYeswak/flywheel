# MP-92 - Reversible recovery ladder

**Discovered:** 2026-05-19T08:02Z
**Discovered by:** skillos:2
**Skills exemplifying:** 8+

## Essence

Recovery systems should climb from cheap reversible probes to invasive actions, re-probing between every level and requiring approval before irreversible data loss.

## Where it applies

Docker, storage cleanup, cache pruning, APFS snapshots, container orphans, volume repair, service restarts, and any operator flow that can destroy local state.

## Adoption signal

The skill declares a ladder, names what each level preserves, re-probes after each action, routes by failure mode, and marks nuclear steps as approval-only.

## Exemplar skills (>=5)

- `~/.claude/skills/docker-troubleshooting/SKILL.md:37` - recovery requires a re-probe after every action.
- `~/.claude/skills/docker-troubleshooting/SKILL.md:51` - storage-critical states route to storage-health first and never auto-fire the next destructive level.
- `~/.claude/skills/docker-troubleshooting/SKILL.md:123` - auto-climbing the ladder can lose data when a cheaper level would have worked.
- `~/.claude/skills/container-orphan-detector/SKILL.md:12` - duplicate healthy containers are a Tier-0 ambiguity hazard.
- `~/.claude/skills/docker-storage-ops/SKILL.md:13` - storage-health gates Docker pruning.
- `~/.claude/skills/docker-storage-ops/SKILL.md:52` - every reclaim level requires a re-probe and no auto-escalation.
- `~/.claude/skills/dev-cache-janitor/SKILL.md:12` - intelligent prune is preferred over nuclear deletion.
- `~/.claude/skills/apfs-snapshot-ops/SKILL.md:167` - sealed system snapshots must not be deleted.

## Adoption recipes

**Recipe 1 - Preserve column:** every ladder level states which assets, data, or settings survive.

**Recipe 2 - Probe/action/probe:** each recovery step starts from a status code and ends with a fresh status code.

**Recipe 3 - Approval boundary:** the first irreversible step is named, separated, and unreachable by automation.

## Compliance test

```bash
grep -E "(ladder|re-probe|approval|irreversible|preserves|nuclear|gate|NEVER auto)" SKILL.md || exit 1
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-45-reversible-cleanup-bundle.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-83-portable-session-recovery-ladder.md`
