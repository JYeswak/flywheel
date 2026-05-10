---
schema_version: journey-entry/v1
bead_id: flywheel-yy9qi
task_id: flywheel-yy9qi-fe2816
worker_identity: CloudyMill
ts: 2026-05-10T20:39:30Z
mission_fitness: adjacent
commit_sha: 32e7369
linked_l_rules:
  - L107
  - L52
  - L70
  - L120
linked_skills:
  - canonical-cli-scoping
narrative_tags:
  - blocker-discipline-5-bead-arc-closure
  - chain-orchestration-pattern
  - kv-prefix-function-arg-discovery
---

# flywheel-yy9qi — journey entry

This is the keystone of the 5-bead blocker-discipline arc. The previous
4 beads each shipped a primitive; this bead's job is composition. The
operator runs ONE script per tick and the entire doctrine fires.

Most interesting moment: stage independence over coordination. First
design considered parsing tick-cadence's per_blocker JSON output and
dispatching auto-close vs escalator based on each blocker's verdict.
This couples the 3 stages — auto-close needs to know what tick-cadence
said. Rejected. Each scan handles its own filtering: auto-close skips
already-closed; escalator skips PASS via counter-reset semantics
(handled by ukbej). Each stage reads blockers directly from the dir.
Loose coupling. Stage 1 can FAIL (e.g., bin missing) and stages 2+3
still run on the same blockers. The composite envelope records
`stages_failed` so partial-failure modes are visible without
masking.

Second moment: `K=V cmd` env-prefix syntax doesn't propagate through
function args. I had:
```bash
fail_escalator_out="$(run_stage fail-escalator BLOCKER_FAIL_ESCALATOR_THRESHOLD_N=4 ...)"
```
The shell tried to execute `BLOCKER_FAIL_ESCALATOR_THRESHOLD_N=4` as
a command name. Bash's K=V prefix only works when the next positional
arg IS the command. Inside a function's `"$@"`, the K=V token is
just a string. Fix: `export K=V` before the call. Filed as skill
discovery — symmetric with python's `subprocess.run(env={...})`
parameter pattern.

Third moment: counter-reset semantics + 23-assertion test 13. The
ukbej fail-escalator's `reset_counter` only writes when the counter
file already exists. For threshold n=1 (canonical-cli's "every fail
escalates"), the counter file never gets written before escalation
because `process_blocker` increments to 1, hits threshold (1 >= 1),
escalates, then calls `reset_counter` — which does nothing because
the file isn't there. Test 13 first asserted `counter == 0` in the
file. Wrong assertion: file absence is equivalent to counter=0
semantically (next run starts fresh either way). Updated the assertion
to accept BOTH states. Documenting this in evidence pack as a found
edge case in ukbej's reset_counter.

Substrate-hygiene-doctrine-cluster is now a fully-wired triad:
- blocker-discipline (this 5-bead arc): audit + runtime + tick-orch
- canonical-cli-lint (4-bead arc): author-time + lint enforcement
- git-stash-discipline: audit + runtime

The orchestrator can now run the entire blocker-discipline doctrine
in one invocation per tick. Operator agency preserved via
`--skip-stage` for incident response (e.g., re-run only auto-close
+ escalator without bumping the counter again).
