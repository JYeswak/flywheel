# NTM Local-Upstream Reconcile: Intent

Date: 2026-05-02

Task: `ntm_reconcile_plan_2026_05_02`

Mode: plan-space only. This plan does not execute git operations in `/Users/josh/Developer/ntm`.

## Problem Statement

`/Users/josh/Developer/ntm` is operational substrate: it is the `ntm` binary Joshua uses daily to manage agent sessions. It also lives in Jeff Emanuel's upstream repository. Joshua has local commits that protect ZestStream's bead isolation and checkpoint isolation work, while Jeff has upstream commits that fix live bugs, including #111 coordinator config loading.

The reconciliation problem is not "ship a feature." It is to preserve daily substrate stability while making future upstream intake routine and auditable.

Hard constraints:

- Never push directly to `Dicklesworthstone/ntm`.
- Do not erase local bead-isolation work.
- Do not let stale upstream miss critical fixes.
- Do not turn `main` into an unreviewable mixture of vendor and local state without a durable pattern.

Live caveat discovered during read-only research: the dispatch context says the local branch has 5 local commits and origin/main is 3 commits ahead. The repository currently reports `main [origin/main: ahead 63, behind 521]`. The named 5 local commits and named 3 upstream commits are real, but the branch ancestry is more divergent than the prompt summary. This plan therefore includes an ancestry preflight and uses branch-preserving operations rather than blind merge/rebase.

## Mission Anchor

This is operational substrate. Correct priorities:

1. Preserve the working `ntm` binary path.
2. Preserve local bead-isolation safety.
3. Pull Jeff's upstream fixes without pushing to Jeff.
4. Make the next reconcile cheaper than this one.

Speed is secondary. Clarity and rollback are the product.

## Out Of Scope

- Rewriting bead-isolation commits.
- Refactoring local commits during reconciliation.
- Fixing Jeff's remaining schema-loader drift locally.
- Filing issues automatically.
- Pushing to Jeff's repo.
- Running destructive git operations by agents.

## Trauma Classes In Scope

1. `bead-isolation-drift`: local safety patches can be accidentally dropped when upstream moves.
2. `push-to-jeff-prohibition`: this is Jeff's repo; our local fixes are not upstream PRs unless Joshua separately chooses fork/issue workflow.
3. `daily-binary-stability` / daily-binary stability: the binary in `~/.local/bin/ntm` must remain usable even if reconciliation conflicts.

## Reconciliation Models

### Model A: Single-Branch Merge

Shape:

- Keep working on local `main`.
- Periodically merge or rebase upstream into local `main`.
- Build daily binary from local `main`.

Pros:

- Simple mental model: one branch.
- Lowest command overhead.
- No separate branch naming discipline.

Cons:

- `main` stops communicating whether it is Jeff-pristine or local-mutated.
- Conflicts recur in the same branch that daily binary depends on.
- Easy to forget "never push to Jeff" because the branch name matches upstream.
- Harder to cleanly file upstream issues without local patch noise.

Tradeoff: acceptable for one-off personal forks, weak for operational substrate with explicit no-push doctrine.

### Model B: Vendor Branch

Shape:

- Keep an upstream-pristine branch that tracks Jeff's `origin/main`.
- Keep local commits on `local/bead-isolation`.
- Build daily binary from `local/bead-isolation`.
- Reconcile by cherry-picking/replaying local commits onto a fresh upstream base.

Pros:

- Clean separation between vendor state and local operational overlay.
- Never needs push to Jeff.
- Local safety invariants are explicit.
- Future upstream intake becomes: update vendor branch, replay local overlay, build, verify.
- GitHub issue evidence can cite local commits without pretending they should be merged upstream.

Cons:

- Requires branch naming discipline.
- Requires an explicit install provenance so daily binary is known to come from local branch.
- Cherry-pick conflicts may recur if upstream edits the same surfaces.

Tradeoff: best fit for operational substrate with local policy patches.

### Model C: Private Fork

Shape:

- Push local branch to `jyeswak/ntm`.
- Treat Joshua's fork as the daily remote.
- Periodically sync from `Dicklesworthstone/ntm`.
- Still never push to Jeff.

Pros:

- Off-machine backup of local commits.
- Easier multi-machine setup.
- Enables PR-like review against private/public fork if Joshua wants it.

Cons:

- Adds remote governance overhead.
- Can blur no-push-to-Jeff discipline unless remotes are named very clearly.
- Requires credential/visibility choices.
- More process than needed for local-only substrate patches.

Tradeoff: useful later if local overlay grows or needs another machine; premature for today's reconcile.

## Chosen Model

Recommend Model B.

Reason: It directly addresses all three trauma classes. It preserves bead-isolation work as a named local overlay, keeps Jeff's upstream state inspectable, and lets the daily binary be rebuilt from a verified local branch. It avoids pushing to Jeff and avoids private-fork overhead.

## Success Definition

Reconciliation is successful when:

- A backup bundle and dirty-work archive exist.
- Jeff's upstream state is available on an upstream-pristine branch.
- A local reconciled branch exists with the five named local commits replayed.
- The branch builds.
- The candidate binary reports useful version/commit provenance.
- `ntm config validate --json` no longer rejects `[coordinator]`.
- Bead-isolation invariants still hold:
  - `RunBd` sets `BEADS_STRICT_LOCAL=1`.
  - `RunBrReal` is absent.
  - `source_repo` is preserved in BV/spawn recovery surfaces.
  - runtime handoff and checkpoint storage remain scoped by working directory/project slug.
- The installed binary is changed only after candidate validation.

## Non-Goals For Joshua's Run

- Do not clean arbitrary untracked files.
- Do not use `git reset --hard`.
- Do not use `git rebase`.
- Do not `git push --force`.
- Do not delete lock files or scratch files without separate confirmation.
