## L104 — FLEET-COMMS-MEASURED-NOT-ASSUMED

---
id: L104
title: Fleet comms measured not assumed
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: assumed-open-fleet-comms
---

Open communication lines across the fleet MUST be measured by substrate signals,
not inferred from active loop markers, recent commits, or a single liveness
classifier.

**How to apply:**
- `.flywheel/scripts/fleet-comms-health-probe.sh --fleet --json` scores each
  active session across Agent Mail token freshness, last cross-orch packet age,
  unread escalations, productivity escalation backlog, identity-registry
  liveness, and multi-frame liveness classifier agreement.
- `flywheel-loop doctor --json` exposes `fleet_comms_health`,
  `fleet_comms_silent_session_count`, `fleet_comms_token_stale_count`,
  `fleet_comms_escalation_unread_count`, `fleet_comms_min_score`, and
  `fleet_comms_worst_session`.
- `/flywheel:status` renders one compact line after Fleet conformance:
  `Fleet comms: <healthy>/<total> healthy | silent=<N> | stale-tokens=<N> | unread-esc=<N>`.
- Silent sessions are sessions with no cross-orchestrator packet for more than
  24 hours; they get `COMMS_HEALTH_PING` packets through `--apply`.
- Agent Mail tokens are checked by mtime only. The probe never reads or prints
  raw bearer material.
- Broadcast-script liveness is cross-checked against multi-frame activity. A
  broadcast classifier that says dead while multi-frame activity is alive logs
  `false_positive_classifier`; never trust one liveness source for comms.

**Forbidden outputs:**
- Reporting fleet comms healthy without token freshness, cross-orch packet age,
  unread escalation, identity-registry, and multi-frame classifier evidence.
- Treating `active=true`, doctor receipts, or pane process existence as proof
  that cross-orch communication is open.
- Sending Joshua notifications for routine silence; notify only for true
  substrate corruption such as token expiry beyond the recovery window.
- Publishing per-agent comms rankings or blame labels. This is a session and
  substrate observatory.

**Evidence:** probe `.flywheel/scripts/fleet-comms-health-probe.sh`; tests
`tests/fleet-comms-health-probe.sh`; doctor fields in
`~/.claude/skills/.flywheel/bin/flywheel-loop`; status surface
`~/.claude/commands/flywheel/status.md`.

**Cross-references:** L57 (loop marker is not driver), L75 (peer orchestrator
blocker coordination), L76 (AgentMail identity canonical), L91 (dispatch
delivery receipt), L98 (architecture health measured structurally), L101
(continuous fleet productivity), and L103 (fleet conformance score).

