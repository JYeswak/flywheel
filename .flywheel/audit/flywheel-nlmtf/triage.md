# flywheel-nlmtf — Jeff signal triage: github-repos/bun

Bead: `flywheel-nlmtf`
Source: `github-repos`
Detected: 2026-05-15T12:04:32Z
Upstream: https://github.com/Dicklesworthstone/bun

## What The Signal Is

`Dicklesworthstone/bun` is a public fork of `oven-sh/bun`, the JavaScript runtime,
bundler, test runner, and package manager.

GitHub evidence:

- `isFork=true`
- parent repo: `oven-sh/bun`
- default branch: `main`
- latest release on the fork: none
- compare `oven-sh:main...Dicklesworthstone:main`: `status=identical`,
  `ahead_by=0`, `behind_by=0`, `total_commits=0`

That means this is not a new Jeffrey-authored tool or a new substrate surface.
It is an unmodified fork of a large upstream runtime repo.

## Four-Hypothesis Triage

| Hypothesis | Verdict | Reason |
|---|---:|---|
| Mirror for Flywheel reuse | No | No Jeffrey delta exists to mirror. The fork is identical to upstream. |
| Extract doctrine | No | No new operator pattern, safety pattern, or public-story pattern is present. |
| Substrate upgrade | No | Bun itself may be useful per project, but this fork does not add a Jeffrey-specific substrate primitive. |
| Skill upgrade | No | No new workflow, wrapper, CLI contract, receipt shape, or agent pattern was introduced. |

## Disposition

No Flywheel adoption action.

This should be treated as a detector-learning row: `github-repos` should
distinguish a newly observed unmodified fork from a new Jeffrey-authored tool.
The current classifier filed this as `new-tool`, but the compare proof says
there is no new tool delta.

Mechanical follow-through landed in `.flywheel/scripts/daily-jeff-ingest.sh`:
new `github-repos` additions that are unmodified forks now get recorded as
`archived-signal` rows instead of high-actionable `new-tool` rows. Forks with a
nonzero Jeffrey-authored delta still remain evaluable.

## Evidence

- `upstream-repo-metadata.json`
- `upstream-root-listing.json`
- `upstream-compare.json`

## What Was Not Done

- No clone or mirror.
- No installation.
- No Bun runtime recommendation for Flywheel.
- No public reduced-mode dependency.
- No issue filed upstream.

## Acceptance

- Repo identified and inspected.
- Fork/parent status verified.
- Compare status verified as identical.
- Apply-to-Flywheel hypotheses evaluated.
- Disposition recorded as no-action with classifier-tuning lesson.
- Classifier updated so this failure class is not refiled as an actionable
  bead without a Jeffrey-authored delta.
