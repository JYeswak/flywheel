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
- Three-predicate dispatch check: if there is a named next bead, at least one
  worker pane is idle, and no blocker is on that path, dispatch immediately.
  Do not ask Joshua to select the action.

**Forbidden phrase catalog:** These phrases are L70 punt signals when the data
already names an action:
- "should I"
- "should we"
- "want me to"
- "do you want me to"
- "would you like me to"
- "shall I"
- "let me know if"
- "let me know when"
- "if you want me to"
- "if you'd like"
- "when you're ready"
- "say the word"
- "just say"
- "want to proceed"
- "confirm and I'll"
- "the next move is yours"
- "standing by"

**False-premise debunks:**
- "I should ask because the user is busy." No. The user is busy because the
  orchestrator is asking instead of dispatching when the state is decidable.
- "I need permission because this is important." Importance raises the need for
  evidence and validation, not for a question-shaped handoff.
- "I should wait for the next tick." No. If the next bead, idle pane, and
  blocker-free path are known now, waiting is the failure mode.
- "I am being safe by asking." No. Safety is concrete blocker classification,
  scoped dispatch, reservations, tests, and callback validation.

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
`feedback_three_audit_questions_per_surface.md` umbrella,
`feedback_meat_puppet_gate_at_phase_complete.md` (Joshua's 2026-05-03T16:48Z
"this is the major fuck up that keeps happening over and over" callout — the
genesis incident this rule was distilled from; defines the forbidden
"Joshua-disposes pending" framing on data-decided dispatches),
`feedback_orch_punt_is_l70_failure_dispatch_dont_ask.md` (data-decides corollary
naming this rule by id),
`feedback_data_decides_not_human_meatpuppet.md` (don't render Joshua as a
meat-puppet gate when probe + Donella + Jeff methodology already decides),
`feedback_donella_first_no_stop_to_ask.md` (apply 7-step Donella filter on
every action before treating it as Joshua-disposes),
`feedback_orchestrator_must_finish_p0_before_filing_more.md` (Joshua's
2026-05-04 callout — *"orchestrators can not let this shit happen — this is a
major fuck up and learning lesson — why are we having workers do work and then
not finishing it out?"* — orchestrator drives oldest open P0s to closure
before filing/dispatching new beads; trauma class
`orchestrator-buries-old-p0-under-new-work`; measurement at
`.flywheel/tests/test-orchestrator-must-finish-p0-before-filing-more.sh`).

**Detector substrate:** `.flywheel/scripts/punt-phrase-detector.py` scans
dispatch logs and handoff bodies for the forbidden phrase catalog. Daily report
surfaces recent findings so punt patterns become per-tick negative feedback
instead of weekly review debt.

**Shard status:** This rule is canonical in the shard set created by
`flywheel-oq267` / agents-md shard extraction. The current canonical shard path
is `.flywheel/rules/L024-L70-orch-no-punt-next-actionable-runs-same-tick-not-next-tick.md`;
the generated `AGENTS.md`, `.flywheel/AGENTS-CANONICAL.md`, and
`templates/flywheel-install/AGENTS.md` mirrors must be regenerated from shards.

