---
name: git-repo-discipline
type: doctrine
created: 2026-05-14
status: active
authority: joshua-direct-ask-<timestamp>
cluster: substrate-hygiene-doctrine-cluster
sisters:
  - git-stash-discipline.md
  - blocker-discipline.md
---

# Git Repo Discipline (Fleet-Wide)

## Substrate-hygiene doctrine cluster

This doctrine is part of the substrate-hygiene doctrine cluster alongside
`git-stash-discipline.md` and `blocker-discipline.md`.

- **git-repo-discipline.md** (this doctrine): dirty working trees are
  operational debt; every dirty file needs a responsible disposition.
- **git-stash-discipline.md**: stash is 24h scratch, not durable storage.
- **blocker-discipline.md**: blockers are live claims, not stale text.

The shared failure mode is the same: the loop reports the problem, then lets it
sit. Reporting dirt is not enough. Flywheel must route dirty state to commit,
restore, `.gitignore`, bead, or `/git-repo-janitor` triage.

## Mandate

Every flywheel-installed repo probes working-tree dirt on tick, dispatch, close,
and daily report. A dirty tree is not automatically bad, but it is never
ambient. It must be classified and moved toward one of these dispositions:

- **commit** owner-scoped work in a focused commit;
- **restore** generated/runtime noise that should not persist;
- **file a bead** for out-of-scope discoveries;
- **gitignore** recurring untracked artifacts after shadowing audit;
- **run `/git-repo-janitor`** when the repo has enough unclassified artifacts
  that manual cleanup is unsafe or expensive.

## Paradigm - dirty state is a queue, not weather

A dirty repo is a queue of unresolved decisions. The loop must not normalize
that queue as background weather.

`git status --short` tells us that a queue exists. It does not tell us how to
resolve it. The responsible handler is:

1. identify whether each row is source work, runtime noise, generated evidence,
   public artifact, or unknown;
2. preserve or route source work;
3. restore noise;
4. prevent recurrence with `.gitignore` or generator placement;
5. use `/git-repo-janitor` when the candidate set is large enough to need
   bundle-backed triage.

## Thresholds

`.flywheel/scripts/repo-discipline-check.sh` is the mechanical probe.

| Class | Predicate | Required action |
|---|---|---|
| `clean` | tracked=0 and untracked=0 | no action |
| `notable` | dirty total >0 but below janitor thresholds | close the queue before worker close; commit, restore, or bead |
| `janitor_triage_class` | untracked >=5 or dirty total >=10 | file/route cleanup work and run `/git-repo-janitor` in `triage-only` before more unrelated dispatch |
| `halt` | untracked >=20 or tracked >=100 or dirty total >=100 | halt new dispatch in that lane until a cleanup plan or cleanup commit lands |

These thresholds are intentionally lower for untracked files. Untracked files
are unclassified substrate by definition; five is already enough to need a
plan.

## Worker responsibilities

1. Workers must not close a bead while their own changes remain unstaged,
   uncommitted, or unexplained.
2. Workers must not hide unrelated dirt by stashing it. Use
   `git-stash-discipline.md` for the stash path and this doctrine for
   working-tree dirt.
3. Generated noise observed during a task must be restored, ignored, or filed
   as a generator-placement bead before close.
4. If the worker inherited dirt, the callback names it as inherited and leaves
   it unstaged. The orchestrator still routes the repo-level cleanup queue.

## Orchestrator responsibilities

1. Dispatch gate runs `repo-discipline-check.sh` before assigning new work.
2. Daily report includes the repo-discipline class and required action.
3. `janitor_triage_class` opens or reuses a cleanup bead and routes
   `/git-repo-janitor` in `triage-only` mode unless the dirt is already owned by
   an active cleanup branch.
4. `halt` refuses new unrelated dispatch until a cleanup plan, cleanup commit,
   or explicit skip receipt exists.
5. The orchestrator never runs destructive cleanup directly. `/git-repo-janitor`
   owns backup refs, recovery bundles, reference greps, secret scan, and
   authorization gates.

## Cross-references

- `~/.claude/skills/git-repo-janitor/SKILL.md` - bundle-backed dirty repo
  triage, move, delete, and `.gitignore` flow.
- `.flywheel/doctrine/git-stash-discipline.md` - stash accumulation sister
  doctrine.
- `.flywheel/doctrine/dispatch-author-skill-routing-contract.md` - routes
  dirty-tree language to `git-repo-janitor`.
- `.flywheel/scripts/repo-discipline-check.sh` - read-only probe and
  threshold classifier.
