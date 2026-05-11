---
bead: flywheel-2xdi.66
title: gap-hunt-probe corpus extension — skill-tree markdown (references/**/README.md)
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: shipped
priority: P3
mission_fitness: adjacent
parent: flywheel-2xdi
sister_exemplars: flywheel-2xdi.47, flywheel-2xdi.49, flywheel-2xdi.64
discovered_gap: flywheel-f1s2x (vacuous .gaps filter in sister tests)
---

# Journey: flywheel-2xdi.66

## What the bead claimed

Auto-filed by gap-hunt-probe: `cluster-recommendations.sh` is wired-but-cold;
script not referenced by recent flywheel jsonl ledgers in last 30d.

## What I found (Bayesian posterior, N=10 this session)

The script IS wired. Documented in
`~/.claude/skills/agent-ergonomics-and-agent-intuitiveness-maximization-for-cli-tools/references/calibration-fixtures/README.md:51`
as a stable use-case invocation path:

> Regression test for clusterer: when re-running scripts/cluster-recommendations.sh
> against bv-dogfood-2026-05-07.recommendations.jsonl, the default threshold (3)
> should produce 3 clusters.

The probe's `skill_md_corpus()` only scanned `SKILL.md` files at skill roots,
not tree-internal docs. Same META-rule shape as 2xdi.47, .49, .64.

## Fix

`.flywheel/scripts/gap-hunt-probe.sh` — `skill_md_corpus()`:

1. Glob `SKILL.md` → `*.md`
2. Per-file cap (4 KB) prevents single-file budget exhaustion (e.g., 350KB
   `.flywheel/CHANGELOG.md` was consuming the whole 1.5MB budget)
3. File count cap 1000 → 6000
4. Overall budget 1.5MB → 32MB

The cache key + function name stay the same; semantic intent unchanged
(skill-tree markdown = wiring evidence).

## Sub-discovery: vacuous test filter (flywheel-f1s2x)

During verification I noticed that prior sister tests (2xdi.47, .49, .64)
use `jq '.gaps // []'` filters on the probe's JSON output. BUT the JSON
output has no top-level `.gaps` field — real gap state lives in
`.gap_ids[]` and `.gap_class_distribution`. So those filters always
evaluate to `[]` and the assertions pass vacuously.

Filed as P2 bug `flywheel-f1s2x` with the three test files named, plus
acceptance criteria. The new test for this bead
(`tests/gap-hunt-probe-skill-tree-md-corpus.sh`) uses the REAL filter
(`.gap_ids[]`) and passes legitimately (6/6).

## Verification

- Live probe → cluster-recommendations.sh, archetype-calibrate.sh,
  protected-session-recovery.sh all unflagged
- New test 6/6 PASS (with REAL probe field filter)
- Sister 47 (4/4), 49 (5/5), 64 (5/5) — still green (vacuous, but at least
  don't regress)

## L112 probe

    bash .flywheel/scripts/gap-hunt-probe.sh --json \
      | jq '[.gap_ids[] | select(test("cluster-recommendations"))] | length'

Expected: `literal:0`.

## Pattern reinforcement (4th in cluster)

The 2xdi-class beads continue to surface real probe corpus blind spots:
- 2xdi.47 — for-loop module list (`for m in mod_a mod_b; do source ...; done`)
- 2xdi.49 — SKILL.md "also available at" entry points
- 2xdi.64 — direct-exec wrappers (`run/exec/bash/sh path/to/x.sh`)
- 2xdi.66 — skill-tree non-SKILL.md docs (`references/**/README.md`)

Each fix is probe-side, not script-side. Each closes a class of similar
beads. When the next 2xdi appears: investigate documented invocation paths
first, default suspicion goes to corpus, not dead code.
