## L70 — ORCH-NO-PUNT (next actionable runs same tick, not next tick)

---
id: L70
title: ORCH-NO-PUNT
status: long_term
shipped: 2026-05-03
review_due: 2026-11-03
trauma_class: orch-punt-to-next-tick-instead-of-next-actionable
---

When an orchestrator tick concludes by NAMING the next phase / next actionable
thing, the orchestrator MUST execute that next thing in the SAME TICK if
capacity exists. Returning to launchd to wait for the next cron firing is the
trauma class.

**Reason:** 2026-05-03T22:28Z mobile-eats:1 orch concluded "DISPATCH could not
proceed; no ready work. Next phase should be BEADS to convert the next plan
artifact into ready work" — and then sat idle waiting for the next launchd
firing. Same shape as L48-companion `orchestrator-skipped-callback-validation`
(2026-05-03T22:15Z): orchestrator IDENTIFIES the next actionable thing and
THEN PUNTS instead of doing it. Joshua flagged this as a constant problem
the same session: "I can't have this being a constant problem."

**How to apply:**
- When DISPATCH yields `no ready work` AND `next_phase=BEADS` AND ≥1 plan
  artifact awaits conversion, run BEADS phase in the SAME tick before
  returning a callback to launchd.
- When INTEGRATE phase concludes `next_phase=LEARN` AND fuckup-log has unprocessed
  rows, run LEARN in the SAME tick.
- When a worker callback names `next_phase=X` AND current pane has capacity for
  X, chain into X within the same orchestrator turn.
- Tick driver wrappers (`flywheel-loop-tick`, launchd plists) MUST chain phase
  transitions when callback names `next_phase=Y` and capacity exists. Returning
  to cron is the failure mode this rule eliminates.
- Workers receive `chain_if_capacity` instruction in dispatch packet: if your
  conclusion names `next_phase=Y` and you have remaining time/capacity, attempt
  Y immediately, otherwise file the chain reason in callback.

**Forbidden outputs:**
- "DISPATCH could not proceed... Next phase should be BEADS" without an
  immediate BEADS execution attempt in the same tick.
- "Worker idle; will redispatch next tick" when ready beads exist or when plans
  await conversion.
- Returning to launchd as the chosen action when ANY actionable phase is named
  in the conclusion.
- Treating `tick complete` as `work complete` without re-evaluating capacity.

**Mechanical gate:** `flywheel-7lby` (P0) requires:
- Tick driver chains `DISPATCH → BEADS` when `br_ready=0` AND plans exist
- Tick driver chains `BEADS → DISPATCH` when new beads land
- Doctor signal `ticks_punted_count` ≥ 1 → status=fail
- Worker dispatch packet includes `chain_if_capacity` block

**Override:** None. There is no `JOSHUA_OVERRIDE` for this — Joshua flagged
this as a recurring fleet-killer and the rule is not negotiable. If a chain
genuinely cannot proceed (capacity exhausted, deadlock detected, etc.), the
callback MUST include `chain_blocked_reason=<concrete cause>`.

**Evidence:** mobile-eats:1 scrollback 2026-05-03T22:28Z; fuckup-log row
`orch-punt-to-next-tick-instead-of-next-actionable`; bead `flywheel-7lby` (P0);
mobile-eats orch ACK 2026-05-03T22:32Z (`MOBILE-EATS ACK orch-no-punt
action=phase-chained` — proof the rule works when applied).

**Companion rules:** L48 (substrate-exhaustion-before-escalation — chain before
escalating), L60 (no-silent-darkness — punted ticks are silent darkness), L61
(ecosystem-wire-in — this rule itself wires), `flywheel-1z65`
(orchestrator validates callbacks — same family of orchestrator-knows-and-punts
trauma), `flywheel-7lby` (mechanical gate implementation),
`feedback_orchestrator_must_dispatch.md`, `feedback_flywheel_never_idles.md`,
`feedback_three_audit_questions_per_surface.md` umbrella.


