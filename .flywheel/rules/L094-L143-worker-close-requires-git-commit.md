## L143 — WORKER-CLOSE-REQUIRES-GIT-COMMIT

---
id: L143
title: Worker close requires git commit
status: long_term
shipped: 2026-05-08
review_due: 2026-11-08
trauma_class: worker-closes-bead-without-git-commit
---

Workers MUST emit `git_committed=<yes|no_changes|skipped>` alongside
`br_close_executed=yes` in every DONE callback. `skipped` is a workflow
violation and a fuckup-log promotion candidate. Close-handler refuses close when
any declared file-scope path is dirty or when `git_committed=yes` lacks a commit
reachable from `HEAD` after dispatch start.

**How to apply:**
- Dispatch templates require the `git_committed` field in DONE callbacks.
- Close-handler parses declared file scope from the dispatch packet and bead
  body, runs `git status --porcelain -- <declared-scope-paths>`, and refuses
  dirty scope with reason
  `declared scope has uncommitted changes — commit before close`.
- `git_committed=yes` requires a declared-scope commit in `HEAD` after
  `ntm_context_repo_rev` or the dispatch-log repo revision.
- `git_committed=no_changes` requires a clean declared scope and no accepted
  file mutation claim.

**Forbidden outputs:**
- DONE callback with `br_close_executed=yes` and no `git_committed`.
- Closing a bead while declared implementation files remain dirty.
- Using `git_committed=skipped` except as an explicit violation receipt.
- Auto-fixing historical beads; this rule is forward-only.

**Evidence:** bead `flywheel-23dsl`; peer finding from mobile-eats handoff
2026-05-07T23:05Z; command docs
`~/.claude/commands/flywheel/_shared/dispatch-template.md` and
`~/.claude/commands/flywheel/_shared/close-handler.md`; regression
`tests/test_worker_close_requires_git_commit.sh`.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

**Cross-references:** L120, L126, L137.

