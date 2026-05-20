# Review Branch Merge-Back Discipline

Bead: `flywheel-r3gz8`

Long-lived review branches must not drift for days while `main` keeps moving.
The daily merge-back cadence rebases the named review branch on `main`, pushes
with `--force-with-lease`, and records a machine-readable receipt.

Canonical command:

```bash
.flywheel/scripts/review-branch-mergeback.sh run \
  --repo /Users/josh/Developer/flywheel \
  --branch review/flywheel-2.0-private-20260513 \
  --base main \
  --apply \
  --push \
  --conflict-action issue \
  --json
```

Operator boundaries:

- Dirty worktrees, detached HEAD, and merge/rebase recovery states are skipped.
- Dry-run never fetches, switches branches, rebases, pushes, or files follow-up
  issues.
- Apply mode restores the original branch after a clean rebase or after aborting
  a conflict.
- Conflict follow-up is filed through GitHub Issues because unresolved conflict
  content cannot be opened as a valid PR without a human or worker resolution
  branch.
- `review-branch-mergeback-fleet-rollout.sh` defaults to the known Flywheel
  review branch. SkillOS bankruptcy classification should add explicit branch
  specs after the 48-branch triage is complete.

Launchd installer:

```bash
.flywheel/scripts/install-review-branch-mergeback-launchd.sh \
  --repo /Users/josh/Developer/flywheel \
  --branch review/flywheel-2.0-private-20260513 \
  --dry-run \
  --json
```

Fleet rollout remains Joshua-gated:

```bash
.flywheel/scripts/review-branch-mergeback-fleet-rollout.sh --dry-run --json
```
