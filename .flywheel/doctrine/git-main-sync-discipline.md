# Git Main Sync Discipline

Local `main` and `master` branches drift behind `origin/*` during auto-merge
work. That turns routine pushes and callback commits into avoidable
non-fast-forward stalls.

The repo-local primitive is `.flywheel/scripts/git-main-sync.sh`:

- `main` / `master`: fetch all remotes with prune, then `pull --rebase
  --autostash` from `origin/<branch>`.
- Dirty `main` / `master`: same path; `rebase.autoStash` keeps local tracked
  edits out of the rebase path.
- `review/*`, `arc/*`, and `feat/*`: fetch-only by default. Rebase against
  `origin/main` only when `--rebase-feature` is explicitly supplied.
- Detached HEAD or active merge/rebase recovery: skip with
  `reason=conflict-recovery-in-progress`.

Recommended one-time operator defaults:

```bash
git config --global pull.rebase true
git config --global rebase.autoStash true
```

The launchd installer is Joshua-gated for apply mode. Dry-run is safe for
validation; fleet rollout must not start cadence until explicitly approved.

