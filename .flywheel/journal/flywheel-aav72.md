---
bead_id: flywheel-aav72
task_id: flywheel-aav72-ffff01
worker_identity: MistyCliff
ts: 2026-05-10T16:03:24Z
mission_fitness: adjacent
commit_sha: pending
linked_incidents: []
linked_l_rules: []
linked_skills:
  - canonical-cli-scoping
narrative_tags:
  - first-cross-repo-wave
  - peer-worker-concurrency-interference
  - 4473-line-binary-scaffold
---

This was the first wave to span repo boundaries — 5 targets in the
flywheel repo + 3 targets in `~/.claude` (the dispatcher binary
`flywheel` at 4473 lines, the `auto-respawn-detector.sh` daemon, and
the shared `inject-skill-auto-routes.sh` command). The scaffolder
handled cross-repo paths cleanly at the scaffold step itself, but
the test-scaffold emission had a path bug that surfaced 3 broken
tests (out of 8): `SCRIPT="$ROOT/$target_rel"` produced
`$ROOT//Users/...` (double slash) when target_rel was an absolute
path because the REPO_ROOT-strip didn't reduce it.

Surgical sed fix to the 3 broken test scaffolds. The proper fix
belongs in the scaffolder itself: emit `SCRIPT="$target_abs"`
directly when target is outside REPO_ROOT. Filed as proposed
scaffolder revision.

The 4473-line `flywheel` dispatcher binary is the largest target
the scaffolder has handled. Adding 239 lines to a 4473-line file is
trivial mechanically, but worth noting because the canonical-cli
surface now sits ABOVE the dispatcher's main routing logic. The
early-dispatch intercept catches canonical subcommands before the
dispatcher's own subcommand routing runs — backward-compat preserved.

The peer-worker concurrency interference was the load-bearing
discovery. While I was scaffolding wave 2.2 at 16:00:49-16:03:24Z, a
peer worker (or orchestrator) was scaffolding `~/.claude/skills/.flywheel/bin/flywheel-*`
sub-scripts in parallel at 16:03:18-20Z. My wildcard `mv .bak.scaffold-*`
picked up THEIR backups along with mine. Recognized the timestamp
delta (160050-51Z mine vs 160318-20Z theirs), restored their
backups, kept mine archived.

This surfaces a real scaffolder design issue: backup file naming
`<file>.bak.scaffold-<UTC>` collides across concurrent workers
because the UTC stamp is the only disambiguator. If two workers
scaffold related files at near-the-same UTC second, their backups
might overwrite. Fix: include worker_id or task_id in backup name
(e.g., `<file>.bak.scaffold-<UTC>-<worker_or_task>`). Filed as
proposed scaffolder revision.

The "orphan: orig gone" backups in /tmp came from MY wildcard
picking up `.flywheel/scripts/*.bak.scaffold-*` files where the
original .sh had already been pulled in for scaffolding by THIS
bead, leaving the backup briefly. They're correctly archived now.

L4 fix on `worker-auto-respawn-watchdog.sh` was the canonical
short-circuit-in-helper trap: `[[ ]] && X || Y` rewritten as
`if/then/else/fi`. Same pattern the canonical-cli-helpers.sh comment
warned about (rule 5: "Conditional returns use if/then/elif/fi,
NEVER `[[ ]] && X || Y`"). The original target predated the
helper-lib doctrine; the fix brings it into compliance.

Cumulative state: 32 P0 surfaces canonical-cli passing across waves
1.1, 1.2, 1.3, and 2.2 — all shipped today. The recovery lane has
37 total surfaces; wave 2.1 was concurrent in another pane (per
parent dependency note "jh5bb in flight"); wave 2.2 is the second
sub-wave. Remaining recovery surfaces will ship in 2-3 more sub-waves
at this pace.
