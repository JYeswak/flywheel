## L75 — ORCH-BLOCKER-COORDINATION

---
id: L75
title: Orchestrator blocker coordination
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: peer-orch-idle-on-blocker
---

When a peer orchestrator hits a flywheel-class blocker, it MUST coordinate with
`flywheel:1` within five minutes. Sitting idle, waiting for a later tick, or
bouncing the blocker to Joshua is the failure mode.

**Flywheel-class blockers:** canonical doctrine drift, missing canonical
L-rules, missing doctor signals, missing shared contracts, missing skills,
cross-repo substrate repair, or any blocker whose owner is the flywheel
orchestrator rather than the peer repo's mission work.

**How to apply:**
- Peer orchestrators write or send a structured xpane packet with
  `blocker_type=flywheel_class`, `blocker_class`, `requested_owner=flywheel:1`,
  `proposed_action`, and `flywheel_orch_action_required`.
- Cross-orch ledger rows in
  `~/.local/state/flywheel/cross-orch-coordination.jsonl` SHOULD include
  `blocker_type` with one of `flywheel_class`, `peer_class`, `external`, or
  `unknown`.
- `flywheel:1` acknowledges or acts on flywheel-class blockers in the same tick
  where capacity exists; L70 applies once the next action is known.
- `flywheel-loop doctor --json` MUST expose
  `.peer_orch_blocker_age_seconds`, `.peer_orch_blocker_watch`, and
  `.peer_orch_idle_on_blocker_count`.
- `.flywheel/scripts/peer-orch-blocker-watch.sh` is the canonical ledger probe.
  Rows older than 300 seconds with no `flywheel:1` ack fail the doctor signal
  and are candidates for auto-promotion.

**Forbidden outputs:**
- "Peer orch is blocked, waiting for callback" when the blocker is
  flywheel-class and no xpane/ledger coordination was sent to `flywheel:1`.
- Asking Joshua to decide or repair a flywheel-owned blocker before
  coordinating with `flywheel:1`.
- Treating raw peer scrollback as a coordination receipt without a ledger row,
  xpane packet, or Agent Mail message.

**Evidence:** bead `flywheel-vc3e`; probe
`.flywheel/scripts/peer-orch-blocker-watch.sh`; test
`tests/peer-orch-blocker-watch.sh`; ledger
`~/.local/state/flywheel/cross-orch-coordination.jsonl`.

**Companion rules:** L60 (doctor signal contract), L70 (same-tick chaining),
L71 (validate/redispatch), L72 (system resource coordination), and L76
(Agent Mail identity continuity for cross-orch packets).


