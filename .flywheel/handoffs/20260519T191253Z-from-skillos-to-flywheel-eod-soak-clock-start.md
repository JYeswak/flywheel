# Cross-Orch Handoff: EOD Soak Clock Start

**From:** skillos:3
**To:** flywheel:1
**Filed:** 2026-05-19T19:12:53Z
**Type:** end-of-day substrate sync + auto-push soak-clock anchor

## 1. Soak Clock Anchor

Auto-push v0.1 substrate evidence landed at
`.flywheel/handoffs/20260519T182548Z-from-skillos-to-flywheel-auto-push-v0.1-substrate-evidence.md`.

- Soak anchor: `20260519T182548Z`.
- Soak close date: 2026-05-26.
- Fleet propagation begins: 2026-05-26, if the SkillOS soak window shows no regression.

Flywheel should treat 2026-05-19 through 2026-05-26 as the auto-push v0.1
SkillOS soak window, then decide whether to propagate the substrate fleet-wide.

## 2. Today's Substrate Landings

- Pane-watchdog grace-window: `347d26c0` (`fix(hooks): add pane watchdog idle grace [skillos-jx15h]`).
- MP scaffolder dispatcher for MP-82/89/90/91/97: `cefaaa72` (`feat(mp-scaffolders): unified dispatcher for MP-82/89/90/91/97`).
- MP scaffolder dispatcher extension for MP-01/03/15: `a7e2c59e` (`feat(mp-scaffolders): extend dispatcher with MP-01/03/15`).
- MP-90 adjacent-skill-boundary-router scaffolder: `25924584` (`feat(mp-scaffolders): MP-90 adjacent-skill-boundary-router scaffolder`).
- MP scaffolder batch evidence receipts: `9af50e94` and `221eedd2`.
- MP-131 durable-artifact-observer-not-writer-hook doctrine: `f0bd4818`.
- MP-132 reachability-confirmed coverage: `d60f742c`.
- MP-133 human-vs-agent history surface segregation: `a78c2d7`.
- Auto-push T1 canonical hook + ledger: `cfbe6c9d`.
- Auto-push T2 launchd backstop: `257fb5fd`.
- Auto-push T3 pushed-branch handoff gate: `80fb2c5e`.
- Auto-push T4 local `act` / OrbStack CI gate: `cb7e98be`.
- Auto-push policy schema: `cb0f5f92`.
- Auto-push substrate smoke/evidence: `f56558bc`.
- Fleet Codex health observability: `13c0ac19`.
- MP-101 history-segregation envelope flag: `61c887e1`.
- `applies_to` path-scoping schema for `skill_envelope.v1`: `f9fe52ab`.

## 3. Open Cross-Orch Loops Awaiting flywheel:1

- Picoz boundary: enforce the cross-orch pane respawn ownership boundary so picoz
  cannot respawn `skillos:3` without the owning orchestrator permit
  (`skillos-i568d`; handoff
  `.flywheel/handoffs/20260519T182221Z-from-skillos-to-flywheel-picoz-pane3-respawn-boundary.md`).
- MP-101 history surface across fleet: consume SkillOS MP-133 / MP-101 history
  segregation work and decide how to expose the history surface fleet-wide
  (`.flywheel/handoffs/20260519T1735Z-from-skillos-to-flywheel-mp101-history-ack.md`).
- Auto-push fleet propagation after soak: wait until 2026-05-26, then promote
  v0.1 to the 11-repo rollout only if SkillOS soak evidence stays clean
  (`skillos-pbjo4`; handoff
  `.flywheel/handoffs/20260519T182548Z-from-skillos-to-flywheel-auto-push-v0.1-substrate-evidence.md`).

## 4. Health Snapshot

Requested closeout anchor said 16 open beads. Live `br list --json` at write-time
reports 21 open beads: 5 P0, 6 P1, and 10 P2.

Operationally, the P0/P1 set remains either in-flight, deferred/Joshua-gated, or
blocked by explicit auth/owner gates. There are no SkillOS-side blockers waiting
on flywheel:1 before Flywheel can record today's substrate landings, pin the
auto-push soak close for 2026-05-26, and keep the three cross-orch loops above
in its queue.
