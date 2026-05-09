## L117 — PEER-ORCH-FREEZE-MONITOR-IS-A-DRIVER

---
id: L117
title: Peer orchestrator freeze monitor is a driver
status: long_term
shipped: 2026-05-05
review_due: 2026-11-05
trauma_class: peer-orch-freeze-without-monitor
---

Peer orchestrator liveness is not proven by a pane being open. A peer
orchestrator freeze monitor must scan current topology, ignore the flywheel
orchestrator's own pane, reuse mk303 stuck classification for peer orch panes,
and call the L115 permit gate before any recovery action.

Auto-respawn is disabled by default. Recovery may mutate only when the monitor
is run with `--apply`, `PEER_ORCH_AUTO_RESPAWN=1` is present, and
`.flywheel/scripts/peer-orch-respawn-permit.sh` returns `decision=permit`.
`flywheel:1` self-recovery remains forbidden.

**Doctor contract:** `flywheel-loop doctor --scope peer-orch-monitor --json`
MUST expose `monitor_last_fire_ts`, `mttr_p95_seconds`,
`false_recovery_count_24h`, `permit_gate_refusals_24h`, `recoveries_24h`, and
`monitor_alive`.

**Forbidden outputs:**

- Claiming peer orchestrators are healthy because topology or panes exist.
- Respawning a peer orchestrator without an L115 permit/refuse decision.
- Treating a disabled plist or script presence as proof that monitoring fired.
- Reporting recovery clean when `false_recovery_count_24h > 0`.

**Evidence:** bead `flywheel-3e5c7`; monitor
`.flywheel/scripts/peer-orch-freeze-monitor.sh`; fixture
`tests/peer-orch-freeze-monitor.sh`; manifest
`.flywheel/scripts/tick-driver-manifest.json`; disabled plist
`.flywheel/launchd/ai.zeststream.peer-orch-freeze-monitor.plist`.

**Cross-references:** L57, L110, L111, L115, L116, and pbt55
`tick-hook-firing-verifier.sh`.

