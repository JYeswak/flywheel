# MP-34 — Canonical-owner runtime proof

**Discovered:** 2026-05-19T06:27Z
**Skills exemplifying:** 6+

## Essence

Name the single owner of every live surface and prove the runtime state, not just the repo state, before dispatching dependent work.

## Where it applies

Launchd jobs, OAuth/Nango connections, cross-orch handoffs, agent swarms, GitHub cloud agents, session memory, live publishing.

## Adoption signal

Artifact names owner, non-owners/consumers, runtime inventory command, and blocked receipt path when owner custody is missing.

## Exemplar skills (≥5)

- `~/.claude/skills/canonical-owner-runtime-state/SKILL.md:18` — winning pattern is explicit ownership plus runtime proof.
- `~/.claude/skills/canonical-owner-runtime-state/SKILL.md:36` — every table/env/role/config surface gets one canonical owner and listed consumers.
- `~/.claude/skills/canonical-owner-runtime-state/SKILL.md:48` — live action must enumerate owner-custody inventory and halt if absent.
- `~/.claude/skills/cross-orch-handoff/SKILL.md:67` — handoffs include a phase plan with unambiguous owner rows.
- `~/.claude/skills/agent-fungibility-philosophy/SKILL.md:52` — beads are marked so status is visible to all agents.
- `~/.claude/skills/gh-coding-agent/SKILL.md:35` — cloud-agent runtime sessions are listed through the GitHub API.
- `~/.claude/skills/cass-memory/SKILL.md:92` — session summaries preserve runtime decisions and accomplishments.

## Adoption recipes

**Recipe 1 — Owner table:** every live dependency has `owner`, `consumers`, `runtime_probe`, and `missing_owner_blocker`.

**Recipe 2 — Runtime proof gate:** dispatch cannot proceed until the installed runtime surface is probed.

**Recipe 3 — Blocked receipt:** missing owner custody emits a receipt and next action rather than attempting a live call.

## Compliance test

```bash
grep -E "(canonical owner|runtime proof|owner-custody|owner.*consumer|runtime inventory)" SKILL.md || fail
```


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites earlier MP lessons directly.

- **MP-23 — replayable mutation contract:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-23-replayable-mutation-contract.md` for the canonical pattern.
- **MP-24 — boundary validation fail-closed:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-24-boundary-validation-fail-closed.md` for the canonical pattern.
- **MP-28 — checklist before claim:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-28-checklist-before-claim.md` for the canonical pattern.
