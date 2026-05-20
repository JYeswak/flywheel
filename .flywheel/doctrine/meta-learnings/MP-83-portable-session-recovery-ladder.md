# MP-83 - Portable session recovery ladder

**Discovered:** 2026-05-19T07:36Z
**Discovered by:** skillos:2
**Skills exemplifying:** 6+

## Essence

Long-running agent work needs a recovery ladder that treats sessions, accounts, panes, transcripts, and dispatch prompts as portable assets with explicit inspection before resumption.

## Where it applies

Cross-provider session conversion, pane respawn recovery, multi-agent research, account switching, mux rescue, memory systems, and any work that can outlive one process.

## Adoption signal

The workflow can list recent sessions, inspect conversion risk, recover from respawn via `/tmp/dispatch_*` or session archaeology, preserve provenance, and re-assert task context after recovery.

## Exemplar skills (>=5)

- `~/.claude/skills/cross-agent-session-resumer/SKILL.md:9` - sessions are portable assets rather than provider lock-in.
- `~/.claude/skills/cross-agent-session-resumer/SKILL.md:15` - pre-flight requires listing and inspecting the source session.
- `~/.claude/skills/cross-agent-session-resumer/SKILL.md:171` - pane respawn means in-flight state is gone.
- `~/.claude/skills/cross-agent-session-resumer/SKILL.md:173` - recovery first checks `/tmp/dispatch_*` and feeds it verbatim if present.
- `~/.claude/skills/brenner/SKILL.md:40` - research sessions are monitored with `session status`.
- `~/.claude/skills/brenner/SKILL.md:57` - sessions compile frequently instead of waiting for the end.
- `~/.claude/skills/caam/SKILL.md:86` - AI CLI OAuth tokens are backed up and restored from tool-specific storage.
- `~/.claude/skills/wezterm/SKILL.md:133` - emergency session rescue has a dedicated procedure before mux restart.
- `~/.claude/skills/agent-memory/SKILL.md:227` - memory without provenance cannot be traced.

## Adoption recipes

**Recipe 1 - Inspect before resume:** list, inspect, and validate the source session before converting or restarting it.

**Recipe 2 - Dispatch prompt as seed:** after respawn, locate the dispatch packet first; if absent, recover from session indexes and then restate bead/task context.

**Recipe 3 - Compile during the run:** for research or long sessions, periodically materialize intermediate state so recovery is not transcript archaeology only.

## Compliance test

```bash
grep -E "(session|resume|inspect|dispatch|respawn|recover|provenance|compile|backup)" SKILL.md || exit 1
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-64-heartbeat-file-resume.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-92-reversible-recovery-ladder.md`
