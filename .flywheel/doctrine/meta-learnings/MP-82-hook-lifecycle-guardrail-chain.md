# MP-82 - Hook lifecycle guardrail chain

**Discovered:** 2026-05-19T07:36Z
**Discovered by:** skillos:2
**Skills exemplifying:** 6+

## Essence

Hooked systems work when each lifecycle event has a narrow purpose, stable I/O, explicit block/feedback semantics, loop prevention, and a receipt or debug path.

## Where it applies

Claude Code hooks, monitoring callbacks, lifecycle repair commands, API envelopes, billing hooks, CI gates, and any automation that runs around a user or agent action.

## Adoption signal

Events are named, blocking behavior is explicit, stdin/stdout schemas are documented, recursive hooks are guarded, mutating repairs are dry-run by default, and every action can be audited.

## Exemplar skills (>=5)

- `~/.claude/skills/cc-hooks/SKILL.md:35` - hook events are tabulated with when they fire and whether they block.
- `~/.claude/skills/cc-hooks/SKILL.md:40` - `UserPromptSubmit` can add context or validate before the prompt proceeds.
- `~/.claude/skills/cc-hooks/SKILL.md:118` - hook input arrives as structured stdin with tool name, input, session id, and cwd.
- `~/.claude/skills/cc-hooks/SKILL.md:136` - Stop hooks must check `stop_hook_active` to avoid infinite loops.
- `~/.claude/skills/agent-monitoring/SKILL.md:191` - monitoring doctor emits stable JSON describing degraded state.
- `~/.claude/skills/agent-monitoring/SKILL.md:200` - repair defaults to dry-run and requires apply scope and audit path.
- `~/.claude/skills/agent-lifecycle/SKILL.md:191` - lifecycle doctor scans state transitions, rollback target presence, and audit-chain integrity.
- `~/.claude/skills/api-design-patterns/SKILL.md:116` - malformed envelopes, absent schema versions, and missing idempotency keys fail closed.

## Adoption recipes

**Recipe 1 - Event table first:** define event name, trigger moment, block behavior, input schema, output schema, and debug command before writing the hook.

**Recipe 2 - Guard recursion:** any hook that can re-enter the same event must check an active flag or equivalent latch.

**Recipe 3 - Dry-run mutation:** hook-triggered repairs preview by default and require explicit scope plus audit receipt for apply.

## Compliance test

```bash
grep -E "(PreToolUse|PostToolUse|Stop|SessionStart|blocks|stdin|schema|dry-run|audit|active)" SKILL.md || exit 1
```

## Meta-Learning Cross-References (2026-05-19)
This flywheel doctrine shard was backfilled during batch-14 to keep MP adoption links navigable.
- Related: `.flywheel/doctrine/meta-learnings/MP-01-sentinel-doctor-surface.md`
- Related: `.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md`
