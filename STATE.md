# Flywheel Repo State

status: ready
repo: repo-local

Current status: public publication lane is locally verified but not complete.

Active focus:

- Keep public mission, goal, and state files free of private operator paths.
- Preserve strict blocker truth for public GitHub, release assets, hosted
  workflow runs, and final signoff.
- Keep repo-local decisions grounded in checked-in docs, scripts, tests,
  receipts, and public export evidence.

Next safe action: run `python3 scripts/publication_readiness.py --json` and
continue closing only the blockers it reports.
