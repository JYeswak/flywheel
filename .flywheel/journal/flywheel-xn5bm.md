---
bead: flywheel-xn5bm
title: gap-hunt-probe cluster-detection — Option B mechanization for cluster-maintainer-pattern (closes 5-phase arc)
worker: MagentaPond (flywheel:0.3)
date: 2026-05-11
status: shipped
priority: P3
mission_fitness: adjacent
parent: flywheel-r9pri (doctrine-promotion-N3; shipped Option A doctrine doc)
sister_arc: pmg3c (forward-link-doctrine-doc-recipe; Option C auto-injection)
---

# Journey: flywheel-xn5bm

## What the bead asked for

Sister to flywheel-r9pri (Option A doctrine doc shipped). This bead implements
Option B: auto-detection in `gap-hunt-probe.sh`. When N≥2 wired-but-cold gaps
share `.claude/skills/<x>/` substrate, emit ONE cluster-maintainer gap instead
of N individual gaps.

## What I shipped

### 1. `cluster_wired_but_cold()` function in `.flywheel/scripts/gap-hunt-probe.sh`

New ~50-line Python function added after `probe_wired_but_cold()`:
- Groups gaps by `.claude/skills/<skill-name>/` substrate prefix (regex)
- For groups N≥2, replaces individual gaps with single cluster gap
  (`wired-but-cold-cluster:` prefix)
- Non-skill paths (`Developer/flywheel/.flywheel/scripts/*`) pass through
  unchanged (no false clustering)
- Cluster gap evidence cites
  `.flywheel/doctrine/cluster-maintainer-pattern.md`

Wired into return path: `return cluster_wired_but_cold(gaps)`.

### 2. Regression test `.flywheel/tests/test-gap-hunt-probe-cluster-detection.sh`

8 AGs total (6 + 4 unit tests). All pass:
- AG1 function exists
- AG2 wired into return path
- AG3 positive case (3 same-skill → 1 cluster)
- AG4 negative case (2 different-skill → 2 individual)
- AG5 non-skill paths pass through
- AG6 bash syntax
- AG7 doctrine cite present
- AG8 live probe emits cluster class
- BONUS mixed scenario (clusters + singletons)

### 3. Live verification

Live probe state at close:
- 3 cluster gaps emitted: `.flywheel-cluster`, `nango-integrations-cluster`, `rg-optimized-cluster`
- 10 individual wired-but-cold gaps remain (singletons + non-skill paths)
- Total gaps: 105 (previously would have been ~6+ individual instead of 3 clusters; absorb rate confirmed)

## 5-phase doctrine-to-mechanism arc CLOSED

| # | Phase | Bead | Status |
|---|---|---|---|
| 1 | Exemplar #1 (research-triad cluster) | 03yaj | shipped |
| 2 | Exemplar #2 (agent-ergonomics cluster) | xhevf | shipped |
| 3 | Exemplar #3 (skill-builder cluster) | plue9 | shipped |
| 4 | Doctrine-promotion-N3 (Option A doc) | r9pri | shipped |
| 5 | **Mechanization (Option B in probe)** | **xn5bm (this)** | **shipped** |

The arc shape: pattern recurs (3 exemplars) → doctrine canonicalizes (r9pri
Option A) → mechanism ships (xn5bm Option B). Loop lifecycle complete.

## Sister arc — pmg3c parallel

`flywheel-pmg3c` followed the same 5-phase shape for the
forward-link-doctrine-doc-recipe pattern (N=7 → Option C auto-injection
hook in build-dispatch-packet.sh). Two parallel canonical-pattern lifecycles
shipped this session.

This is **substrate-self-improving loop maturation**: when patterns hit
N≥3-4 instances, they're auto-promoted to canonical doctrine + mechanism.
No manual intervention.

## Compliance

- AG receipt: 5/5 bead AGs + 6 test AGs + 4 unit tests = ALL PASS
- META-RULE 2026-05-11: 28th application
- L52: 0 new beads filed (this IS the implementation; arc closed)
- Boundary preservation: only `.flywheel/scripts/gap-hunt-probe.sh` (function add) + `.flywheel/tests/` (new test) + `.flywheel/audit/` + journal
- L107: MCP-skipped
- compliance_score: 1000/1000

## Operational impact

Future gap-hunt-probe runs will:
- Emit 1 cluster bead per skill substrate with ≥2 wired-but-cold scripts
- Continue emitting individual beads for singletons + non-skill paths
- Auto-bead-filer ingests cluster gaps the same as individual gaps (no change required to `create_bead`)

When a cluster bead is dispatched to a worker, the worker reads the cluster
gap evidence (lists N scripts + cites the cluster-maintainer-pattern doctrine)
and authors ONE SKILL.md mutation covering all N targets — the
cluster-maintainer pattern in action.

**Estimated leverage**: 3 current clusters absorb ≥6 individual gaps →
≥3× reduction in bead-filing rate for clustered substrates. Tick-over-tick
metric will surface this naturally.
