# MP-61 — Agent-first operator surface

**Discovered:** 2026-05-19T06:53Z
**Discovered by:** skillos:2
**Skills exemplifying:** 7+

## Essence

Tools meant for humans and agents expose the same capability through a predictable CLI contract: JSON output, robot docs, non-interactive modes, capability discovery, and terminal-safe fallbacks.

## Where it applies

CLIs, TUIs, local developer tools, orchestration helpers, model-provider probes, and any operator surface that agents must call without relying on human intuition.

## Adoption signal

The skill documents machine-readable command surfaces, capability discovery, terminal cleanup, plain-text fallback behavior, and an explicit first-command path an agent can infer.

## Exemplar skills (≥5)

- `~/.claude/skills/agent-ergonomics-and-intuitiveness-maximization-for-cli-tools/SKILL.md:27` — the first thing an agent instinctively tries should work.
- `~/.claude/skills/agent-ergonomics-and-intuitiveness-maximization-for-cli-tools/SKILL.md:40` — add robot flags, capabilities JSON, and robot docs.
- `~/.claude/skills/agent-ergonomics-and-intuitiveness-maximization-for-cli-tools/SKILL.md:1285` — capabilities, robot docs, and robot modes are late-stage release gates.
- `~/.claude/skills/cfs-cli-discipline/SKILL.md:48` — every subcommand exposes JSON and robot modes.
- `~/.claude/skills/cfs-cli-discipline/SKILL.md:75` — day-one ergonomics review surfaces missing agent affordances.
- `~/.claude/skills/tui-glamorous/SKILL.md:255` — Ctrl-C restores terminal state.
- `~/.claude/skills/tui-glamorous/SKILL.md:256` — piped input or output falls back to plain text.
- `~/.claude/skills/tui-inspector/SKILL.md:227` — doctor output precedes TUI inspection.

## Adoption recipes

**Recipe 1 — First-command contract:** publish the exact first command an agent should run and make it succeed without hidden setup.

**Recipe 2 — Robot surface:** add `--json`, `--robot`, `capabilities --json`, and a short robot-docs command for every operational CLI.

**Recipe 3 — Terminal escape hatch:** TUIs must degrade to plain text for pipes, restore terminal state on interrupt, and expose the same data through non-TTY mode.

## Compliance test

```bash
grep -E "(--json|--robot|capabilities|robot-docs|non-TTY|plain text|Ctrl-C|doctor)" SKILL.md || fail
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-03-agent-ergonomics-rubric.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-58-agent-tool-theory-of-mind.md`
