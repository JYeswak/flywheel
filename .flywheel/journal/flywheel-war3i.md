---
bead_id: flywheel-war3i
task_id: flywheel-war3i-f9ceb2
worker_identity: MistyCliff
ts: 2026-05-10T15:48:25Z
mission_fitness: adjacent
commit_sha: pending
linked_incidents: []
linked_l_rules: []
linked_skills:
  - canonical-cli-scoping
narrative_tags:
  - wave-2-cleaner-than-wave-1
  - bash-heredoc-vs-python-fstring-trap
  - cumulative-16-of-21-dispatch-lane
---

Wave 2 was faster (~2min) and cleaner (8/8 lint vs 7/8) than wave 1.
The scaffolder v3 from the pilot is mature; no in-flight revisions
needed for this wave. The targets in this wave all use `set -euo
pipefail` from the start so no L5 variances surfaced — the dispatch-
and-log L5 variance was specific to that script's command-
substitution-rc-capture pattern, not endemic.

The interesting bug this wave was a TYPING bug in MY orchestration
code, not the substrate. My Python heredoc that injects 2 per-surface
test assertions had a `${schema_prefix}` reference that I expected to
be expanded by Python (as part of an f-string-style template). But
the heredoc was `<<PY` (unquoted) which is bash-default-interpolated
— so `${schema_prefix}` got expanded by BASH first, BEFORE Python saw
it. Wave 1 worked because I had also defined `schema_prefix="$t"` as
a bash variable; wave 2 I forgot to do that, and the bash
interpolation of an undefined `${schema_prefix}` collapsed to empty.

The result: 8 scaffolded tests with `^/v[0-9]+$` regexes (missing the
surface prefix) — all 8 failed Test 14. Caught by the test runner
itself; root cause and fix took <30s once I read one of the
generated test files. The repair: a follow-up Python script using
`os.environ["schema_prefix"]` (so the export was bash→env→python,
unambiguous) and a regex sub that found-and-replaced the broken
pattern.

This is the canonical "lean on tests as the contract" pattern. The
test runner FAILED, I read the failure, traced to the regex, fixed
the injection logic, re-ran. Total cost: 30 seconds. If the tests
hadn't been there, the broken regex would have shipped silently.

The cumulative dispatch lane numbers are interesting:
- 16 of 21 surfaces shipped (waves 1 + 2)
- 15 of 16 lint clean (1 documented variance)
- 16 of 16 canonical-cli 13/13
- 16 of 16 tests 15/15
- ~5 minutes total wall-clock vs ~10-16 hours estimated

Wave 3 (jloib.1.3, 5 surfaces tail) will ship in ~1.5 minutes if the
pattern holds. After that, the dispatch lane is 100% canonical-cli
shipped (with TODO markers as the deferred substance fill-in queue).
That unblocks the recovery lane (jloib.2) and agent-mail lane
(jloib.3) — both follow the same scaffolder pattern.

The TODO marker accumulating is real — 18 markers/surface × 16
surfaces = 288 substance markers in the queue. That's the scaffolder's
honest signal of "where to add per-surface depth". The next bead
class should be a per-surface fill-in dispatch that actually writes
the substantive cmd_doctor probes etc. for each script's domain.
That's a different kind of work — domain-knowledge-bound rather than
boilerplate-bound — and probably not dispatched as a single bead but
as one bead per surface (or per group of 3-4 related surfaces).
