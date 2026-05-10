---
bead_id: flywheel-ws02m
task_id: flywheel-ws02m-a69359
worker_identity: MistyCliff
ts: 2026-05-10T15:04:00Z
mission_fitness: adjacent
commit_sha: pending
linked_incidents: []
linked_l_rules: []
linked_skills:
  - canonical-cli-scoping
narrative_tags:
  - top-injection-vs-main-wrap
  - scaffolder-as-70-percent-solution
  - dogfood-revert-discipline
  - inline-arg-parser-vs-main-function
---

The load-bearing decision was rejecting the spec's "comment out the
final `main "$@"` line" strategy. Real P0 targets like
`callback-fix-bead-opener.sh` don't have a `main` function — they have
a top-level `while [[ $# -gt 0 ]]; do case "$1" in` arg loop that runs
to completion. The scaffolder's first attempt appended a canonical
block at the bottom; the original arg loop ate every flag before the
new dispatcher ran, and 11/13 surface tests failed.

Top-injection + early-dispatch is the correct shape: inject right
after the shebang and `set -*` lines, define all canonical functions,
then run an intercept that ONLY fires for canonical args
(`doctor|health|repair|validate|audit|why|quickstart|completion` or
`--info|--schema|--examples`). Everything else falls through to the
target's original parser unchanged. This works for both the
`main "$@"` shape AND the inline-arg-loop shape. The spec assumed a
structure the real corpus doesn't always have.

The macOS `/var` -> `/private/var` symlink was the second trap.
`pwd -P` resolves it, but the env-override `SCAFFOLD_REPO_ROOT` doesn't
get realpath'd unless explicitly normalized. Without normalization,
the `target_rel="${target_abs#$REPO_ROOT/}"` strip fails because
`target_abs` starts with `/private/var/...` while `REPO_ROOT` is the
test's `/var/...` form. Fix: realpath REPO_ROOT through `pwd -P` early
in the scaffolder. Same trap I'd seen in flywheel-aic04
(case-insensitive APFS); same pattern (paths-from-different-sources
must be normalized through the same canonicalization).

The dogfood-revert discipline is worth flagging. I scaffolded the real
`callback-fix-bead-opener.sh`, ran the canonical surface tests
(13/13 PASS), then realized the scaffolded version has 18 unfilled
TODO markers and shipping it half-done would be a bad surface. So I
reverted the live tree (cp from backup) and preserved the dogfood
output as audit evidence (`dogfood-diff.patch` + `dogfood-test-scaffold.sh`
+ `dogfood-receipt-snapshot.jsonl`). The bead's deliverable is the
SCAFFOLDER + evidence that it works; the operator-fillin step is a
separate dispatch.

There was one production-pollution incident: my backwards-compat probe
ran the scaffolded target with `--task-id … --reason …` (the legacy
flags that fall through to the original logic), which CREATED A REAL
BEAD `flywheel-k9p92` in the production beads.db because the original
script's job is to file fix-beads. Closed it immediately with a
"test fixture" reason. Lesson: dogfood verification of scaffolded
targets must use canonical subcommands ONLY (which return JSON
envelopes with no side effects), never invoke the target's primary
mode.

The 70% / 30% framing in the doctrine is the right way to set
expectations. The scaffolder ships boilerplate; the operator fills
domain-specific doctor/health/repair/validate/why logic. The dogfood
target's 18 TODO markers ARE the 30%. Filling them is a separate
~30min unit of work per target — exactly the spec's design target.

The e2e test went 19/20 on first run, with Test 20 (--allow-uninventoried)
failing because the test setup re-used a target that Test 17 had
already scaffolded. Adding a fresh non-scaffolded fixture for Test 20
fixed it cleanly. Worth noting because state-leakage between tests
in a sequential e2e is a recurring pattern — each test should set up
its own fresh fixture rather than depending on a prior test's leftovers.
