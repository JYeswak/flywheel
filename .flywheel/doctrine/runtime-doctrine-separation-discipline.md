# Runtime Doctrine Separation Discipline

Source bead: `flywheel-8ont6`
Paired primitive: `flywheel-ge03h`
Mobile-eats evidence: `/Users/josh/Developer/mobile-eats/.repo_janitor_workspace/JANITOR-FINAL-REPORT.md`

## Why This Matters

`flywheel-ge03h` measures tracked substrate bloat in `.flywheel/runtime`, `.flywheel/state`, and `.flywheel/evidence`. That metric is only structurally meaningful if runtime state is not supposed to live in Git. This discipline turns that from a warning into a migration path: runtime moves under `~/.local/state/flywheel/<repo>/`, while versioned doctrine stays in the repo.

Mobile-eats is the calibration case. Its janitor report showed `.flywheel/` at 1417 tracked files and about 64 MB after all other hygiene cleanup was done. That was intentionally deferred because it needed fleet-level taxonomy rather than repo-local deletion.

## Taxonomy

| Subdir | Class | Action |
|---|---|---|
| `.flywheel/doctrine/` | DOCTRINE | Keep tracked |
| `.flywheel/specs/` | DOCTRINE | Keep tracked |
| `.flywheel/scripts/` | DOCTRINE | Keep tracked |
| `.flywheel/dispatches/` | DOCTRINE | Keep tracked |
| `.flywheel/handoffs/` | DOCTRINE | Keep tracked |
| `.flywheel/audits/` | MIXED/EVIDENCE | Operator review; keep small evidence, rotate large snapshots |
| `.flywheel/runtime/` | RUNTIME | Migrate to `~/.local/state/flywheel/<repo>/runtime/`, gitignore, symlink |
| `.flywheel/state/` | RUNTIME | Migrate to `~/.local/state/flywheel/<repo>/state/`, gitignore, symlink |
| `.flywheel/evidence/` | RUNTIME | Migrate to `~/.local/state/flywheel/<repo>/evidence/`, gitignore, symlink |
| `.flywheel/validation/` | MIXED | Per-file review; validators stay tracked, snapshots rotate |
| `.flywheel/private/` | SECRETS | Never track; tracked file is an incident |
| `.flywheel/brand-candidates/` | MIXED | Per-file review |

## Migration Recipe

Use `.flywheel/scripts/runtime-doctrine-separation-migrate.sh` per repo.

Default mode is dry-run:

```bash
.flywheel/scripts/runtime-doctrine-separation-migrate.sh --repo "$PWD" --dry-run --json
```

Apply mode is Joshua-gated for real repos. It exists for synthetic fixtures and supervised operator use:

```bash
.flywheel/scripts/runtime-doctrine-separation-migrate.sh --repo "$PWD" --apply --json
```

Apply mode refuses to mutate when `.flywheel/private/` has any tracked file. For runtime classes it creates a pre-migration tarball under `~/.local/state/flywheel/<repo>/`, copies contents preserving mtimes, runs cached-untrack with `git rm --cached -r --ignore-unmatch` and no force flag, adds idempotent `.gitignore` entries, and replaces the in-repo runtime path with a symlink to local state.

Mixed classes are report-only. The operator decides whether a file is durable evidence, a live validator, a snapshot, or disposable runtime.

## Fleet Rollout

Use `.flywheel/scripts/runtime-doctrine-separation-fleet-rollout.sh` for the five flywheel-managed repos:

- `/Users/josh/Developer/flywheel`
- `/Users/josh/Developer/skillos`
- `/Users/josh/Developer/zesttube`
- `/Users/josh/Developer/mobile-eats`
- `/Users/josh/Developer/clutterfreespaces`

The fleet wrapper writes a markdown report under `.flywheel/audits/runtime-doctrine-separation-fleet-dry-run-<ts>.md`. It refuses `--apply` unless `--joshua-gated-apply` is provided, and agents still must not run fleet apply without direct approval.

## Safety Bar

- Real fleet work stays dry-run until Joshua approves apply.
- Secrets incidents stop migration before runtime mutation.
- Cached-untrack uses no force flag.
- Backup tarball is created before any synthetic or approved apply migration.
- Re-running an already migrated repo produces no runtime migration and does not duplicate `.gitignore` rules.
