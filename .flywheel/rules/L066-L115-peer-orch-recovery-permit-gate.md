## L115 — PEER-ORCH-RECOVERY-PERMIT-GATE

---
id: L115
title: Peer orch recovery permit gate
status: long_term
shipped: 2026-05-05
review_due: 2026-11-05
trauma_class: peer-orch-recovery-false-ownership-refusal
---

`flywheel:1` owns recovery of frozen, deaf, or stuck peer orchestrator panes.
Peer orchestrators such as `skillos:1`, `mobile-eats:1`, and similar fleet
orchestrator panes are not untouchable when they are dead; recovering them is
flywheel repo work. The self-respawn boundary remains hard: `flywheel:1` MUST
NOT respawn `flywheel:1`.

**Permit gate:** `.flywheel/scripts/peer-orch-respawn-permit.sh` is the
canonical pre-flight before `/flywheel:respawn` targets a peer
`orchestrator_pane`.

**Canonical 6-step recovery protocol:**

1. Read `~/.local/state/flywheel/session-topology.jsonl` with latest-by-
   `effective_at` semantics for both `flywheel` and the target session.
2. Refuse unless the actor is the latest `flywheel` orchestrator pane.
3. Refuse self-orchestrator recovery: target `flywheel:<orchestrator_pane>` is
   the calling-in-sick path and must be recovered by a peer.
4. Respect `kill-recover-drill.sh` protected-session doctrine. Active client
   and high-risk sessions are refused unless a specific Joshua-approved
   exception is encoded in the permit gate; `skillos:1` peer-orch recovery is
   the validated exception for this rule, while drill damage remains refused.
5. Require freeze evidence before permit: either a hash-identical buffer sample
   across the configured window, or robot activity state in
   `{ERROR, UNKNOWN, deaf}`.
6. On `--apply`, write
   `~/.local/state/flywheel/peer-orch-recovery.jsonl`, then run
   `/flywheel:respawn`; verify the recovered pane is live and log any repeated
   recovery pattern to the learning substrate.

**Doctor contract:** `flywheel-loop doctor --scope peer-orch-recovery --json`
MUST expose `peer_orch_recovery_count_24h`, `last_peer_orch_recovery_ts`,
`peer_orch_recovery_targets_top`, and
`peer_orch_recovery_self_refuse_count_24h`. Status is `warn` when recovery
count exceeds 5 in 24h and `fail` when self-refuse count is nonzero.

**Forbidden outputs:**

- Treating peer orchestrator panes as human-only or untouchable after freeze
  evidence exists.
- Respawning `flywheel:1` from `flywheel:1`.
- Bypassing `.flywheel/scripts/peer-orch-respawn-permit.sh` before peer
  orchestrator recovery.
- Calling a peer-orch recovery clean without a permit/refuse ledger row and
  post-respawn liveness evidence.
- Using stale topology rows instead of latest-by-`effective_at`.

**Evidence:** Joshua correction 2026-05-05T04:38Z; memory
`feedback_flywheel_owns_orch_pane_recovery.md`; bead `flywheel-3rxt3`;
validated recovery of `skillos:1` at 2026-05-05T04:39Z; permit gate
`.flywheel/scripts/peer-orch-respawn-permit.sh`; fixture
`tests/peer-orch-respawn-permit.sh`.

**Cross-references:** L48, L57, L70, L75, L80, L82, L101, L107, and L110.

