---
bead_id: flywheel-u1zwc
task_id: flywheel-u1zwc-2016a3
worker_identity: MistyCliff
ts: 2026-05-10T16:21:00Z
mission_fitness: adjacent
commit_sha: 4003f1bd16161382775593fe22e02b520d8dff0f
linked_incidents: []
linked_l_rules:
  - L52
  - L70
  - L107
  - L120
linked_skills:
  - canonical-cli-scoping
narrative_tags:
  - first-wave-with-e4lfb-shebang-guard
  - python-target-correctly-refused
  - cross-repo-test-path-bug-still-present
---

Wave 4 was the first wave to land after the e4lfb shebang guard
(commit ec7308f) shipped the same morning. The pre-flight named
flywheel-readme as a python3 target, but waves 1-3 of jloib.2.x
ran before the guard existed; without it, this wave would have
silently corrupted a 993-line python script with appended bash
boilerplate (the exact failure mode that motivated e4lfb). The
guard refused with a structured envelope (`status=refused
reason=non_bash_shebang interpreter=python3 suggested_extension=py`)
and exit 66, and inventory was stamped `refused_python_shebang`
rather than fabricated `passing`.

The L52 receipt for the python gap is filed as flywheel-oozt3
(scaffold-canonical-cli-py — python-aware sibling). That bead
inherits the e4lfb refusal envelope as its acceptance contract:
when the python sibling exists, every refused row in the inventory
should re-stamp clean.

Three pre-existing bash surfaces (lock-repair, refresh-source,
skillos-relay) carried L2/L4 control-flow patterns that the
canonical-cli linter caught after the scaffold landed. The
violations were in original code regions, not scaffolder
boilerplate — the scaffolder did its job and surfaced underlying
debt. Six surgical fixes (trailing `done`/`return 0`,
`[[ ]] && a || b` → if/then/else) brought all 7 bash surfaces lint
clean. The pattern is the same as aav72's L4 fix on
worker-auto-respawn-watchdog.sh.

The cross-repo test SCRIPT path bug (`$ROOT//Users/josh/.claude/...`)
is still present in the scaffolder — same surgical sed fix as aav72.
Bug remains documented under aav72's followup
`scaffolder-cross-repo-test-path-bug`; not re-filing.

The 3 pre-existing bespoke test files (lock-repair, refresh-source,
skillos-relay) were preserved untouched by the scaffolder
(`test_scaffolded:false`) — those are richer per-surface tests with
real fixtures, not the canonical-cli 13/13 template. The 4 new
templates (install-hooks, outcome, render-latest, source-monitor)
all hit 13/13 PASS after the SCRIPT path fix.

Cumulative lane progress: 40 P0 surfaces canonical-cli passing
across waves 1.1+1.2+1.3+2.2+2.4 plus 1 documented refused row.
