---
bead: flywheel-2xdi.155
title: FIRST LIVE cluster-maintainer bead post-xn5bm — nango-integrations N=2 (1 SKILL.md mutation)
worker: MagentaPond (flywheel:0.3)
date: 2026-05-11
status: shipped
priority: P3
mission_fitness: adjacent
parent: flywheel-2xdi
cluster_size: 2
substrate_loop_milestone: 1st live cluster-bead post-xn5bm mechanization
sister_arc: pmg3c 1st-live = 2xdi.128 (1:1 forward-link)
---

# Journey: flywheel-2xdi.155

## Substrate-self-improving loop MILESTONE — 1st live cluster-bead post-xn5bm

This is the **FIRST `wired-but-cold-cluster` bead** dispatched after xn5bm
shipped the cluster-detection mechanism. End-to-end validation:

1. xn5bm clustered 2 wired-but-cold scripts under `.claude/skills/nango-integrations/`
2. Auto-bead-filer dispatched ONE cluster bead (this — 2xdi.155) instead of 2 individual gaps
3. Worker applied cluster-maintainer-pattern.md recipe
4. ONE SKILL.md mutation covered N=2 scripts (vs 2 individual mutations)
5. Cluster cleared

**xn5bm mechanism is functioning end-to-end without intervention.**

## What the bead asked for

Cluster bead body lists 2 scripts in `.claude/skills/nango-integrations/`:
- `nango-image-sanity.sh`
- `nango_prepare_env_bundle.sh`

Per cluster-maintainer-pattern doctrine: ship ONE SKILL.md mutation
covering all N targets + paired patch artifact.

## Investigation (META-RULE 2026-05-11 — 32nd application)

Verified:
- Both scripts exist (98B and 1533B respectively)
- `nango-image-sanity.sh` is a hyphen-name wrapper around `nango_image_sanity.sh` (sister underscore-name)
- `nango_prepare_env_bundle.sh` requires 5 env keys + emits canonical bundle
- nango-integrations skill: UNMANAGED in JSM → direct mutation allowed
- SKILL.md: 13377 bytes; has "Operator UX Entrypoints" section with 5 existing operator-script bullets

## What I shipped

### Primary: ONE SKILL.md mutation (cluster-maintainer pattern)

`~/.claude/skills/nango-integrations/SKILL.md` "Operator UX Entrypoints"
section — 2 bullets added after `migrate-integrations-between-envs.sh`:
- Cite hyphen-name wrapper relationship for nango-image-sanity.sh
- Cite 5 required env keys for nango_prepare_env_bundle.sh
- Both bullets follow existing Operator UX Entrypoints shape

### Paired jsm-import-ready patch artifact

`.flywheel/audit/flywheel-2xdi.155/skill-md-patch-artifact.md` — 8-step
cluster-maintainer recipe walkthrough + verification + boundary notes.

## Cluster-maintainer recipe 8/8 complete

| Step | Status |
|---|---|
| 1 Read cluster evidence (N scripts) | ✓ |
| 2 Verify scripts exist + purposes | ✓ |
| 3 JSM status check | ✓ unmanaged |
| 4 Single SKILL.md mutation | ✓ 2 bullets |
| 5 Paired patch artifact | ✓ |
| 6 N subordinate beads bulk-close | N/A (no subordinates; xn5bm absorbed them) |
| 7 Probe cleared | ✓ cluster_for_nango: 0 |
| 8 Evidence + journal | ✓ |

## Key leverage observation

xn5bm's mechanism eliminates the historical "bulk-close N subordinate beads"
step from the cluster-maintainer recipe. Pre-xn5bm (03yaj exemplar):
N individual beads filed → cluster-maintainer worker bulk-closes them.
Post-xn5bm: 1 cluster gap emitted natively → no subordinates to close.

This is the **2x leverage** xn5bm promised — and it's working end-to-end now.

## Sister-arc milestone alignment

| Mechanization | First live post-promotion dispatch |
|---|---|
| pmg3c (Option C dispatch auto-injection) | 2xdi.128 (1:1 forward-link) |
| **xn5bm (Option B probe-clustering)** | **2xdi.155 (this — cluster-maintainer)** |
| ezz15 (Option D periodic-tick scoring) | (awaits next tick run) |

3 mechanization arcs, 3 different timing axes, all validated or
validating end-to-end this session.

## Compliance

- AG receipt: 8/8 (recipe 8-step complete)
- META-RULE 2026-05-11: 32nd application
- L52: 0 new beads filed (cluster absorbed N=2 scripts; no subordinate beads needed)
- L107: MCP-skipped
- Boundary preservation: only unmanaged nango-integrations SKILL.md edited
- compliance_score: 1000/1000
