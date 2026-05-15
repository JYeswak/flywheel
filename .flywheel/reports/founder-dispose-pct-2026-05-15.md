# founder_dispose_pct weekly report — 2026-05-15

**Goal anchor:** P7 of `~/Desktop/zeststream-goals/flywheel/substrate-compounding-v2-20260515.txt`
**Mission anchor:** continuous-orchestrator-uptime-self-sustaining-fleet
**Period:** 7d
**Generated:** 2026-05-15T14:56:02Z
**Source:** `.flywheel/scripts/architecture-health-rollup.sh --period 7d`

## Headline

```
Architecture Health: red | leverage_trend=+3718%/30d | rework_ratio=3.72 | founder_dispose_pct=0%
```

## Fleet metrics (7d)

| Metric | Value | Direction | Status |
|---|---|---|---|
| coordination | 0.0051 | (track over time) | — |
| drift_authoring | 1.8783 | (track over time) | — |
| faithfulness | 0 | (track over time) | — |
| founder_dispose_pct | 0.0 | (track over time) | — |
| leverage | 6.9948 | (track over time) | — |
| leverage_trend_30d_pct | 3718.12 | (track over time) | — |
| reliability | 0.0 | (track over time) | — |
| reuse | 0.0 | (track over time) | — |
| rework_ratio | 3.724 | (track over time) | — |

**Agent-shaming detected:** false
**Architecture health status:** red

## Trend interpretation

`founder_dispose_pct = 0.0%` is mission-aligned (target: trending down quarterly).
Zero dispatches/callbacks in the 7d window mention "founder" or "joshua-dispose" —
the agents are operating without founder-in-loop on routine decisions. Good.

`rework_ratio = 3.724` is RED
(green threshold <0.3, yellow <1.0, red >1.0). The 7d window shows 3.7× more rework
events than first-pass closures. This is the routing-to-arch-change-beads signal
the mission anchor names.

`leverage_trend_30d_pct = 3718.12%`
is up sharply — the substrate IS compounding (this is the positive R1 signal
flywheel + skillos are designed to produce).

## Source counts (this period)

- callbacks: 4
- closed_beads: 1412
- dispatches: 192
- fuckup_rows: 715
- identity_vectors: 11
- incident_commits: 49
- validation_fail: 0
- validation_pass: 0
- validation_receipts: 0
- validation_unknown: 0

## Routing decision

Per goal CONTRACT and mission anchor: *route bad trends to architecture-change
beads, not individual-agent performance reviews.*

- agent_shaming forbidden ✓
- arch-change bead filed: `flywheel-arch-rework-ratio-3-72-red-2026-05-15` (P0)

The bead's scope: investigate the 3.7× rework_ratio and propose architectural
changes (probe, doctrine, dispatch-template) — not flag individual workers.

## Next-week comparison

Re-run this report next 2026-05-22 and compare:

- Did rework_ratio drop?
- Did founder_dispose_pct stay at 0%?
- Did leverage_trend continue compounding?

Track week-over-week in `.flywheel/reports/founder-dispose-pct-*.md` directory.
