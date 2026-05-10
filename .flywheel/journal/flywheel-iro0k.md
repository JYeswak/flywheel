---
bead_id: flywheel-iro0k
task_id: flywheel-iro0k-2117da
worker_identity: MistyCliff
ts: 2026-05-10T19:50:00Z
mission_fitness: direct
commit_sha: pending
narrative_tags:
  - cross-pane-git-discipline-doctrine-wire-in
  - 141-live-race-violations-surfaced-on-flywheel
  - L120-close-gate-extension
---

Doctrine wire-in for cross-pane-git-discipline.md (ratified bilaterally
2026-05-10T21:35Z, 6h default-accept window). Two new canonical-cli
surfaces shipped per the doctrine's wire-in mandate:

1. **`cross-pane-git-probe.sh`** — orchestrator per-tick probe trio.
   Implements all 3 doctrine probes: active-worktree census + stale-
   worktree garbage + concurrent-commit window (5-sec).

2. **`worker-head-verify.sh`** — close-gate HEAD-verify post-commit.
   Implements doctrine worker rule #3: verify HEAD points at expected
   branch + matches expected parent SHA before `br close`. Extends
   L120 br-close-executed gate.

**Headline finding** (the dispatch's "lucky not disciplined" framing
proven empirically): running cross-pane-git-probe.sh against the live
flywheel repo surfaced **141 concurrent-commit-window violations** in
the recent reflog. This is exactly the Class B race the doctrine names
— 3+ codex panes have been making commits within seconds of each other
in the shared `.git` directory, and we've been LUCKY that none of them
produced visible corruption. The probe surfaces it; the doctrine says
this should never have been invisible. Now it isn't.

Pattern continuity: matches the wgitr+wave-2 chain surface shape (full
canonical-cli wrapper + doctor 9-10 named probes + integration tests
with isolated-TMP discipline). Distinguishing wrinkle: these are net-
NEW files, not scaffolded surfaces. The pattern transfers cleanly
either way — same doctor/health/repair/validate/audit/why structure,
same per-surface --schema + topic_help, same emit/audit-log discipline.

Worker close-gate is the more operationally interesting addition: it
turns L120 from "did br close exit 0" into "did br close exit 0 AND is
HEAD on the right branch with the expected parent". The exit-code
contract (1=branch_mismatch, 2=parent_mismatch, 3=substrate_failure)
gives orchestrators a clear escalation signal. Workers should add a
call to this script BETWEEN `git commit` and `br close` per the
doctrine.

mission_fitness=DIRECT because the failure mode this prevents is
exactly the kind that silently corrupts orch substrate. Without these
probes, the 141 violations would remain invisible until the first
visible corruption event (likely an entangled commit with WRONG files,
matching the skillos trauma class instances 1-4).
