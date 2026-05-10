---
title: "REFINE r2: Red-Team Review And Refinement"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# REFINE r2: Red-Team Review And Refinement

This is a self-review of `02-REFINE-r1.md`.

## Risk 1: Prompt Understates Divergence

Problem:

- Dispatch says 5 local vs 3 upstream.
- Live `git branch -vv` says ahead 63 / behind 521.

Impact:

- Cherry-picking onto current `origin/main` may hit conflicts not visible in the named-commit overlap matrix.

Refinement:

- Runbook must compute `git rev-list --left-right --count HEAD...origin/main`.
- If behind count is much greater than 3, script warns but can proceed because Model B is designed for full upstream intake.
- Conflict playbook must mention full-origin overlap, especially checkpoint, state migrations, spawn, and BV.

## Risk 2: Dirty Working Tree Contains Real Work

Problem:

- Untracked `internal/tmux/frankenterm.go` is likely real code.
- Several scripts look like local operational substrate.
- `.flywheel/` files are local doctrine placeholders.

Impact:

- A sloppy clean/stash could hide or lose work.

Refinement:

- Before stashing, archive untracked files to `/tmp/ntm-pre-reconcile-<ts>.untracked.tgz`.
- Never use `git clean`.
- Re-apply dirty surfaces only after binary reconciliation succeeds, and preferably as separate local commits/branches.

## Risk 3: Migration Number Collision

Problem:

- Local commit adds `internal/state/migrations/007_runtime_handoff_working_dir.sql`.
- Upstream may now contain later migrations or a different 007 due to 521 behind.

Impact:

- Cherry-pick may apply but migration ordering may be wrong.

Refinement:

- After cherry-pick, list migrations:

  ```bash
  ls internal/state/migrations
  ```

- If `007` already exists upstream or sequence has advanced, rename local migration to next unused number and update references/tests before building.

## Risk 4: Main-Branch Rewrite Anxiety

Problem:

- Model B ideally makes `main` upstream-pristine, but moving local `main` is high-stress.

Impact:

- Joshua may not want the script to alter `main` on first pass.

Refinement:

- Make `main` rename optional and late.
- The core deliverable is `local/bead-isolation-reconciled-<ts>` plus installed binary.
- Full Model B branch shape can be completed after validation.

## Risk 5: Binary Provenance Could Still Show "dev"

Problem:

- Makefile only sets Version.
- GoReleaser sets Version, Commit, Date, BuiltBy.

Impact:

- A manual build may show incomplete provenance.

Refinement:

- Runbook uses explicit ldflags for all four fields:
  - Version
  - Commit
  - Date
  - BuiltBy

## Risk 6: Upstream Health Fixes Need Behavioral Validation

Problem:

- Build success does not prove `ntm health --json --watch` stays alive.

Impact:

- A dashboard process could still terminate on transient errors.

Refinement:

- Minimum plan gate: run upstream health tests if present.
- Manual smoke can start `ntm health <session> --json --watch` briefly and interrupt after confirming it streams. The runbook keeps this as optional because it touches live session behavior.

## Risk 7: The Local Overlay Might Be Too Broad

Problem:

- The current branch is ahead by 63, not only the named 5.

Impact:

- Replaying only the named five commits may drop other local fixes Joshua depends on.

Refinement:

- The plan explicitly targets the five commits from the dispatch because those are the bead-isolation scope.
- Runbook preserves the full current branch as `backup/pre-reconcile-main-<ts>` and bundle.
- After the first reconciled build, Joshua can decide whether other local commits should be replayed as separate overlays.

## R2 Converged Plan

Proceed with Model B, but treat it as a two-stage implementation:

1. Stage 1: create and validate a new local overlay branch from current `origin/main` plus the five named safety commits.
2. Stage 2: after validation, optionally rename current `main` aside and recreate `main` from `origin/main`.

This preserves all work, gets latest upstream into a candidate binary, and avoids destructive main-branch manipulation until after proof.

## Revised Acceptance Gates

- Backup bundle exists.
- Dirty archive exists.
- `backup/pre-reconcile-main-<ts>` exists.
- `local/bead-isolation-reconciled-<ts>` exists.
- Candidate binary builds.
- Coordinator config #111 behavior validates.
- Bead-isolation grep gates pass.
- Installed binary is only replaced after candidate succeeds.
- No push to Jeff occurs.
- No `git reset --hard`, `git rebase`, `git clean`, `rm -rf`, or force push appears in the runbook.

## Ship Readiness

Ship-ready for Joshua review: yes.

Reason: the plan includes safe preflight, branch preservation, conflict handling, rollback, and a manual runbook. The live divergence increases risk, but the branch model directly handles that risk.
