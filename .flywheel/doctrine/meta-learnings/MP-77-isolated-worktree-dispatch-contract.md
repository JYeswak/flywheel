# MP-77 — Isolated worktree dispatch contract

**Discovered:** 2026-05-19T07:12Z
**Discovered by:** skillos:2
**Skills exemplifying:** 5+

## Essence

Parallel code work requires explicit checkout isolation: clean baseline, branch-from-authority, one owner per worktree, unique ports/env, drift snapshots, and cleanup gates.

## Where it applies

Multi-agent dispatch, worktree management, repo cleanup, stash archaeology, multi-repo maintenance, PR workflows, and any branch-per-task engineering operation.

## Adoption signal

The skill requires dirty-state checks, branch-origin validation, per-worktree resources, one agent per branch, cleanup scan, and refusal to overwrite concurrent work.

## Exemplar skills (≥5)

- `~/.claude/skills/git-worktree-isolation-for-parallel-bg-agents/SKILL.md:29` — parallel dispatch branches from `origin/main`.
- `~/.claude/skills/git-worktree-isolation-for-parallel-bg-agents/SKILL.md:30` — dirty target worktrees abort dispatch.
- `~/.claude/skills/git-worktree-isolation-for-parallel-bg-agents/SKILL.md:54` — branch tip is validated against `origin/main`.
- `~/.claude/skills/git-worktree-manager/SKILL.md:23` — worktrees standardize branch isolation, port allocation, environment sync, and cleanup.
- `~/.claude/skills/git-worktree-manager/SKILL.md:79` — each worktree has assigned ports.
- `~/.claude/skills/git-worktree-manager/SKILL.md:136` — one agent per worktree and branch.
- `~/.claude/skills/git-repo-janitor/SKILL.md:541` — re-snapshot status and diff before each mutation.
- `~/.claude/skills/ru-multi-repo-workflow/SKILL.md:51` — commit, sync, release, and review phases run in order.
- `~/.claude/skills/git-stash-janitor/SKILL.md:14` — stash drops must be reversible.

## Adoption recipes

**Recipe 1 — Clean authority base:** fetch and branch from the authoritative remote ref, then verify `HEAD` equals that ref.

**Recipe 2 — One owner per sandbox:** allocate branch, worktree, ports, env, and task owner together.

**Recipe 3 — Drift gate:** snapshot status before every mutation and stop on unexpected concurrent changes.

## Compliance test

```bash
grep -E "(origin/main|dirty worktree|worktree|branch tip|port|one agent|status|diff)" SKILL.md || fail
```
