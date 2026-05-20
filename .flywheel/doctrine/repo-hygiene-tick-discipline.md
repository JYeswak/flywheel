# Repo Hygiene Tick Discipline

Source bead: `flywheel-ge03h`
Related bead: `flywheel-8ont6`
Source evidence: `/Users/josh/Developer/mobile-eats/.repo_janitor_workspace/JANITOR-FINAL-REPORT.md` and `/Users/josh/Developer/mobile-eats/.flywheel/scripts/repo-hygiene-doctor.sh`

## Contract

Every tick measures repository hygiene before cleanup becomes a project-level incident. The canonical primitive is `.flywheel/scripts/repo-hygiene-doctor.sh`, wired through `.flywheel/scripts/tick-driver-manifest.json` as `repo-hygiene-doctor`.

The tick writes one JSON envelope per repo to `~/.local/state/flywheel/repo-hygiene-tick.jsonl`:

```json
{"repo":"<absolute path>","ts":"<ISO8601>","metrics":{},"alerts":[]}
```

The probe is read-only unless `--auto-bead` is enabled. In tick-driver mode the current manifest runs with `--auto-bead`, so P0/P1/P2 alerts become repo-local beads while every measured repo still writes a ledger row.

## Trauma Classes

- `worktree-orphan`: `git worktree list --porcelain` count exceeds threshold.
- `stash-buildup`: `git stash list` count exceeds threshold.
- `branch-debt`: local-only branches already merged to `main` exceed threshold.
- `main-FF-divergence`: local `main` is behind `origin/main` beyond threshold.
- `tracked-substrate-bloat`: tracked `.flywheel/runtime`, `.flywheel/state`, or `.flywheel/evidence` payload size exceeds threshold.

## Thresholds

Defaults live in `.flywheel/hygiene-thresholds.yaml`. Values are strict greater-than thresholds, so `worktree_count_p2: 5` means `current > 5` files a P2 alert.

Repo-local overrides may be added at `<repo>/.flywheel/hygiene-thresholds.yaml`. Use repo name keys under `repos:` for narrow exceptions, not global threshold inflation. Mobile-eats is the calibration case: the janitor run proved worktree, stash, branch, and main drift cleanup while tracked `.flywheel/` substrate bloat remained deliberately deferred to `flywheel-8ont6`.

## Auto-Bead Filing

When run without `--dry-run`, P0/P1/P2 alerts create repo-local beads titled:

```text
hygiene-tick: <class> exceeds threshold (current=<X> threshold=<Y>) at <repo>
```

Descriptions include the full metrics envelope and remediation hint. The filer dedupes against open beads for the same class and repo created within 24 hours.

`.flywheel/hygiene-tick.disabled` is the repo-local opt-out marker. Disabled repos emit `status=skipped`, no metrics, no alerts, and no bead actions.
