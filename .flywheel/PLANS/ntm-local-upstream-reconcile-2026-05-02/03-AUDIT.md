# AUDIT: NTM Reconcile Plan

## Safety

Irreversible or risky actions:

- Branch renaming is potentially confusing but not data-deleting if the backup branch exists.
- Binary install replaces `~/.local/bin/ntm`, but runbook first copies the old binary to `/tmp`.
- Cherry-pick can conflict, but `git cherry-pick --abort` is the rollback.

Explicitly absent:

- No `git reset --hard`.
- No `git rebase`.
- No `git clean`.
- No `rm -rf`.
- No `git push --force`.
- No push to Jeff.

The plan preserves current state with:

- `git bundle --all`
- tracked diff archive
- untracked tarball
- backup branch
- stash only after archive

## Authority

| Step | Authority |
|---|---|
| Read-only status/log/show/diff | agent-runnable |
| Create plan files in flywheel | agent-runnable |
| Create bundle/archive | Joshua-runnable in runbook |
| Stash dirty work | Joshua-runnable with prompt |
| Fetch origin | Joshua-runnable with prompt |
| Create branches | Joshua-runnable with prompt |
| Cherry-pick local commits | Joshua-runnable with prompt |
| Resolve conflicts | Joshua manual |
| Install candidate binary | Joshua-runnable with prompt |
| Optional main rename | Joshua-only prompt |
| Any push | prohibited unless Joshua creates a separate fork plan |

DCG-sensitive actions:

- `git rebase`: not used.
- `rm -rf`: not used.
- `git push --force`: not used.

## Observability

Joshua verifies success at each phase via:

- `git branch --show-current`
- `git rev-parse HEAD origin/main`
- `git status --short`
- bundle path existence
- archive path existence
- `go build` exit code
- candidate `ntm version`
- `ntm config validate --json | jq '.valid'`
- grep gates for local invariants
- `~/.local/bin/ntm version` after install

The runbook logs all output to `/tmp/ntm-reconcile-<ts>.log`.

## Long-Term Pattern

This scales if repeated as:

1. `git fetch origin`.
2. Create new `vendor/upstream-main-<date>` from `origin/main`.
3. Create new `local/bead-isolation-reconciled-<date>` from vendor.
4. Replay local overlay commits.
5. Build candidate.
6. Install only after verification.

If local overlay grows beyond a handful of commits, graduate to Model C private fork or maintain a patch stack directory.

## Doctrine Impact

Memory update recommended:

- `ntm` daily binary comes from local overlay branch, not Jeff-pristine branch.
- Never push to Jeff.
- Use Model B for future upstream intake.

INCIDENTS row:

- Not needed yet. This is a planned reconciliation, not a fresh trauma.
- If a future agent pushes to Jeff or drops bead-isolation commits during reconcile, promote a new incident.

Skill update:

- Candidate future skill/reference: `dicklesworthstone-stack` or `ntm` local overlay maintenance. Not required before this run.

## Audit Verdict

Model B is the safest converged plan. The only material concern is live divergence being larger than the prompt summary; the runbook guards this by never mutating current `main` until backup and candidate verification exist.
