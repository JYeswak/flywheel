## L145 — ORCH-HANDSHAKES-NEVER-GATE-ON-JOSHUA

---
id: L145
title: Orch handshakes never gate on Joshua
status: long_term
shipped: 2026-05-08
review_due: 2026-11-08
trauma_class: phantom-joshua-blocker
---

Intra-fleet orchestrator handshakes are flywheel-owned coordination, not a
true Joshua blocker. Agent Mail contact approvals, fleet-mail trust grants,
peer-orch trust, and similar coordination primitives MUST use auto-trust,
file-based sidechannels, or flywheel-owned repair paths. Do not write Joshua
approval as a fallback for an orchestrator-to-orchestrator handshake.

**How to apply:**
- Spawn-time setup should auto-trust fleet-spawned orchestrators where the
  trust domain is already flywheel-owned.
- When Agent Mail policy blocks a peer handshake, route to the file-based
  sidechannel or the flywheel-owned identity/contact repair path.
- The Stop hook
  `~/.claude/hooks/flywheel-orch-handshakes-never-gate-on-joshua-gate.sh`
  warns on text that pairs intra-fleet handshake language with Joshua approval.
- `.flywheel/scripts/memory-rule-gate-parity-detector.sh` must continue to mark
  `feedback_orch_handshakes_never_gate_on_joshua.md` as wired.

**Forbidden outputs:**
- "Ask Joshua to approve the Agent Mail contact request" for two fleet
  orchestrators.
- Listing Joshua approval as fallback Option C for peer-orch trust.
- Treating a cross-orch handshake as a `true_josh_blocker` when a flywheel-owned
  sidechannel or repair path exists.

**Evidence:** bead `flywheel-wire-orch-handshakes-never-gate-on-josh-9f44eb70`;
memory
`feedback_orch_handshakes_never_gate_on_joshua.md`; gate
`.flywheel/scripts/orch-handshakes-never-gate-on-joshua-gate.sh`; hook
`~/.claude/hooks/flywheel-orch-handshakes-never-gate-on-joshua-gate.sh`; test
`.flywheel/tests/test-orch-handshakes-never-gate-on-joshua.sh`; INCIDENTS entry
`orch-handshakes-never-gate-on-joshua`.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.

**Cross-references:** L48, L58, L75, L76, L101, L130, and L135.

