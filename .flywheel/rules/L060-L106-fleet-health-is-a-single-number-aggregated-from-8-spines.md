## L106 — FLEET-HEALTH-IS-A-SINGLE-NUMBER-AGGREGATED-FROM-8-SPINES

---
id: L106
title: Fleet health is a single number aggregated from 8 spines
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: dashboard-sprawl-without-strategic-health
---

Fleet health is one composite number: productivity 10% + conformance 15% +
comms 10% + process gaps 15% + architecture 15% + identity 10% + L-rule lag
15% + watcher coverage 10%. Thresholds are >=85 green, 60-84 yellow, and <60
red. `/flywheel:fleet-observatory` is the strategic command-center view;
`/flywheel:status` remains tactical. Joshua sees one number when stepping back,
not 25 fields.

**How to apply:**
- `.flywheel/scripts/fleet-observatory-aggregate.sh --json` reads
  `flywheel-loop doctor --json` once, caches doctor JSON for 60 seconds, and
  emits `fleet_overall_health_score`, per-spine traffic lights, worst spine,
  worst session, top process gaps, and recommended action.
- `flywheel-loop doctor --json` exposes `fleet_observatory_health_score` as
  the lightweight composite field for automation.
- `/flywheel:fleet-observatory` renders the strategic one-screen dashboard;
  use `/flywheel:status` for tactical pane/bead/callback work.

**Forbidden outputs:**
- Showing Joshua 25 raw doctor fields when the strategic ask is fleet health.
- Treating the composite as an individual-agent ranking. This is system-level
  observability, not agent-shaming.
- Re-running every expensive spine separately inside the dashboard instead of
  reading doctor once and using the 60-second cache.

**Evidence:** aggregate `.flywheel/scripts/fleet-observatory-aggregate.sh`;
tests `tests/fleet-observatory-aggregate.sh`; command surface
`~/.claude/commands/flywheel/fleet-observatory.md`; doctor field in
`~/.claude/skills/.flywheel/bin/flywheel-loop`.

**Cross-references:** L61 (ecosystem wire-in), L98 (architecture health
measured structurally), L101 (continuous productivity), L103 (conformance
score), L104 (comms measured), and L105 (process gaps measured).

