# Journey: flywheel-j3dbv

Sibling phantom of 0u9ch (created 2 min earlier). Same shape: `flywheel-test` bead, `dispatch_file_missing` reason, `foo`/`""` expected/actual. Only difference: task_id is `test-1` (vs 0u9ch's `t-1`).

The 0u9ch fix patched ONE known polluter (test line 40). j3dbv with task_id=`test-1` came from somewhere else I couldn't locate (manual probe? untracked test?). N=2 of this phantom class → ship Path B (defensive guard at opener level).

First attempt: single-axis guard (refuse on sentinel bead names alone). Broke 3 regression tests (`flywheel-x` is canonically used in `tests/callback-fix-bead-opener-canonical-cli.sh` with proper REPO isolation).

Refined to two-axis guard: refuse when (prod-REPO == REPO_DEFAULT) AND (bead matches sentinel). Properly-isolated tests with `--repo /tmp/*` bypass automatically. All regression tests pass; phantom pollution refused.

8th instance of bead-hypothesis-is-prior-not-posterior META-rule. Defense-in-depth pair with 0u9ch fix.
