---
bead: flywheel-f1s2x
title: vacuous-filter fix — sister 2xdi regression tests use REAL .gap_ids
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: shipped
priority: P2
mission_fitness: adjacent
parent: flywheel-2xdi
discovered_during: flywheel-2xdi.66
---

# Journey: flywheel-f1s2x

## What the bead claimed

Three sister regression tests filter on `.gaps // []` against probe JSON
that has no `.gaps` field. All per-script-name assertions pass vacuously.

## What I shipped

Switched the per-script filters to `.gap_ids` (the real field), which is a
flat array of strings encoded as `<class>:<stable-id>`. Decoded with
`startswith("wired-but-cold:") and contains("<script>")`.

Also dropped the "0 wired-but-cold total" assertions — those were also
vacuously true and assert something that isn't actually true (the real
cluster has many remaining cold candidates unrelated to each test's
specific fix). Per-script targeting IS the meaningful check.

## Verification

- 4/4 for-loop-source-corpus (REAL filter)
- 4/4 skill-md-corpus (REAL filter)
- 4/4 exec-sh-corpus (REAL filter)
- 6/6 skill-tree-md-corpus (already real; comment cross-ref added)

All four per-script targets (reconcile, protected-session-recovery,
archetype-calibrate, cluster-recommendations) confirmed unflagged under
the real filter. Sister fixes ARE legitimate — they were tested vacuously
but the probe code itself is correct.

## L112 probe

    grep -l "gaps // \[\]" tests/gap-hunt-probe-{for-loop-source,skill-md,exec-sh}-corpus.sh 2>/dev/null | wc -l | tr -d ' '

Expected: `literal:0` (none of those three files still match).

## Meta-pattern: vacuous-filter class

`jq '.field // [] | ...'` is silently resilient — the fallback hides missing
fields. Useful for resilience, dangerous for verification tests. Reflex
going forward: every new probe test must `jq '.field'` (no fallback) at
least once to confirm the field exists in real output, before using
fallback-style filters in subsequent assertions.

Not yet 3-strike, so not a skill. If a 3rd instance appears, promote.
