# Repo Trajectory Story Pack

Schema: `zeststream.repo_git_story_pack.v0`
Status: `candidate-shared-foundation`

This pack turns a repository's git history into an owner-readable story. It is
for public pages, case-study drafts, launch reviews, and Next.js project
foundations where the copy needs to show proof instead of selling a dream.

The failure it prevents is familiar: a project gets a good-looking page, but the
story only reflects the last build session. The real trust signal is the path:
where the work started, what broke, what changed, what got blocked, and which
lessons became reusable.

## Contract

Every repo-facing public story must have two layers:

| Layer | Audience | Job |
|---|---|---|
| Generated trajectory | Reviewer, operator | Extract sanitized chapters from git history with commit evidence. |
| Designed story surface | SMB owner, buyer | Translate the trajectory into plain language, visual rhythm, and CTA flow. |

The generated layer is produced with:

```bash
python3 scripts/extract_git_story.py \
  --repo-label Flywheel \
  --write-json docs/evidence/flywheel-trajectory.json \
  --write-md docs/stories/flywheel-trajectory.md
```

For another repo, run the same script with that repo as `--repo` and write the
artifacts into that repo's evidence/story folders.

```bash
python3 /path/to/flywheel/scripts/extract_git_story.py \
  --repo /path/to/repo \
  --repo-label "Public Product Name" \
  --write-json docs/evidence/repo-trajectory.json \
  --write-md docs/stories/repo-trajectory.md
```

## Story Chapters

The extractor groups commits into five public chapters:

| Chapter | Owner-facing meaning |
|---|---|
| Foundation | The team mapped the work before promising automation. |
| Proof loop | Activity turned into tests, receipts, blockers, and replayable checks. |
| Friction | Red evidence exposed what was not ready instead of hiding it. |
| Reuse | Lessons moved into scripts, runbooks, docs, packages, or shared design grammar. |
| Story | The final surface translates the machinery into a buying journey. |

These chapters are deliberately not raw commit counts. Counts are useful to
reviewers, but owners need movement: start, friction, control, reuse, outcome.

## Copy Rule

Use this line as the editorial filter:

> Show the proof, do not sell the dream.

Good public copy says:

- what changed in the workflow;
- what risk was controlled;
- what evidence exists;
- what stayed blocked;
- what lesson carries into the next project.

Weak copy says:

- AI will transform everything;
- the system is powerful because it has many commits;
- the work is complete because the page looks finished;
- the owner should trust hidden machinery.

## Visual Rule

The trajectory should appear as a living system, not a changelog pasted into a
landing page.

Required visual primitives:

| Primitive | Purpose |
|---|---|
| `TrajectoryRail` | Shows origin, friction, proof, reuse, and current arc as one connected path. |
| `FrictionBand` | Makes blocked or red evidence visible without turning it into failure theater. |
| `LessonLedger` | Shows how lessons become reusable checks, copy, components, or runbooks. |
| `ProofDrawer` | Lets reviewers inspect generated artifacts after the owner story lands. |

For Next.js projects, these should live in the shared design foundation beside
`OperatingRoomHero`, `WorkflowMap`, `SliceWorkbench`, `ProofRail`, and
`YuzuMethodRail`.

## Acceptance Gate

A repo trajectory story is acceptable when:

1. `scripts/extract_git_story.py --json` emits `zeststream.repo_git_story.v0`.
2. Generated JSON and Markdown contain no private paths, client names, or
   unsupported claims.
3. The public page includes the trajectory as a buyer journey, not a developer
   changelog.
4. The page links to the generated story artifact for reviewers.
5. Any claim based on runtime support, release status, or public availability
   still points to its own proof receipt.

Flywheel's current generated artifacts:

- `docs/evidence/flywheel-trajectory.json`
- `docs/stories/flywheel-trajectory.md`
