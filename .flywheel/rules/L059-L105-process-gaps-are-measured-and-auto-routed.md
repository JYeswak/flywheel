## L105 — PROCESS-GAPS-ARE-MEASURED-AND-AUTO-ROUTED

---
id: L105
title: Process gaps are measured and auto routed
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: process-gap-drift
---

Fuckup classes repeating at least 2x in 24h, doctor errors sticky across at
least 3 ticks, 3-surface drift above 5 rules, unpromoted candidates older than
24h, closed-bead audit gaps, identity drift, and watcher coverage holes are
auto-flagged as process gaps. Top-3 gaps auto-route to fix-beads via
`fleet-process-gap-detector.sh --apply`. Joshua sees one `Fleet process` line,
not a wall of symptoms. Fix the gate, not the leak.

**How to apply:**
- `.flywheel/scripts/fleet-process-gap-detector.sh --json` emits
  `fleet-process-gap-detector/v1` with `open_gap_count`, `top_gaps`,
  `stuck_class_count`, and `process_health_score`.
- `--apply --dry-run` produces the top-3 bead-create plan; actual apply uses
  stable class markers so the same process class does not file duplicate
  fix-beads on every tick.
- `flywheel-loop doctor --json` exposes `fleet_process_gap_detector`,
  `fleet_process_open_gap_count`, `fleet_process_stuck_class_count`,
  `fleet_process_health_score`, and `fleet_process_top_gap_class`.
- `/flywheel:status` renders
  `Fleet process: health=<score> | open-gaps=<N> | top: <class>` after the
  Fleet comms line.

**Forbidden outputs:**
- Reporting recurring process failures as a prose list without a top-class,
  score, and fix-bead route.
- Filing duplicate process fix-beads for the same class and marker.
- Treating the process gap as an individual-agent failure; this is a gate,
  routing, or information-flow leak.
- Adding new manual gates instead of measuring the recurring class and routing
  it to a structural fix.

**Donella read:** #4 self-organization routes recurring classes to fix-beads,
#6 information flows surface the process leak before Joshua does, and #11
parameters stay secondary to changing the gate that produced the leak.

**Evidence:** probe `.flywheel/scripts/fleet-process-gap-detector.sh`; tests
`tests/fleet-process-gap-detector.sh`; doctor fields in
`~/.claude/skills/.flywheel/bin/flywheel-loop`; status surface
`~/.claude/commands/flywheel/status.md`.

**Cross-references:** L50 (Socraticode preflight), L51 (file reservations),
L56 (promotion ladder), L61 (ecosystem wire-in), L96 (3-surface diff), L98
(architecture health measured, not individuals), L101 (continuous fleet
productivity), and L103 (fleet conformance score).

