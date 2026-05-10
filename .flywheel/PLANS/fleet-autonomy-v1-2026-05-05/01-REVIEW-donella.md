---
title: "Donella Lens Review - Fleet Autonomy v1"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

## Contents

- [Source Grounding](#source-grounding)
- [1. Where I Disagree With The Framing](#1-where-i-disagree-with-the-framing)
- [2. Stocks And Flows Audit - P1](#2-stocks-and-flows-audit-p1)
- [2. Stocks And Flows Audit - P2](#2-stocks-and-flows-audit-p2)
- [2. Stocks And Flows Audit - P3](#2-stocks-and-flows-audit-p3)
- [2. Stocks And Flows Audit - P4](#2-stocks-and-flows-audit-p4)
- [2. Stocks And Flows Audit - P5](#2-stocks-and-flows-audit-p5)
- [2. Stocks And Flows Audit - P6](#2-stocks-and-flows-audit-p6)
- [2. Stocks And Flows Audit - M](#2-stocks-and-flows-audit-m)
- [3. Loop Topology](#3-loop-topology)
- [4. Leverage Points - P1](#4-leverage-points-p1)
- [4. Leverage Points - P2](#4-leverage-points-p2)
- [4. Leverage Points - P3](#4-leverage-points-p3)
- [4. Leverage Points - P4](#4-leverage-points-p4)
- [4. Leverage Points - P5](#4-leverage-points-p5)
- [4. Leverage Points - P6](#4-leverage-points-p6)
- [4. Leverage Points - M](#4-leverage-points-m)
- [5. The Thing The Plan Does Not See](#5-the-thing-the-plan-does-not-see)
- [6. Specific Revisions In My Voice](#6-specific-revisions-in-my-voice)
  - [Revision 1 - Rename The Goal Stock](#revision-1-rename-the-goal-stock)
  - [Revision 2 - Add Mission-Anchor Delta To P3 Before Morning Report](#revision-2-add-mission-anchor-delta-to-p3-before-morning-report)
  - [Revision 3 - Replace Cooldown With State-Change Eligibility](#revision-3-replace-cooldown-with-state-change-eligibility)
  - [Revision 4 - Make `bv` A Single Observation](#revision-4-make-bv-a-single-observation)
  - [Revision 5 - Move P4 Release Authority Out Of The Watcher](#revision-5-move-p4-release-authority-out-of-the-watcher)
  - [Revision 6 - Add Night-Time Controller Actions To M](#revision-6-add-night-time-controller-actions-to-m)
  - [Revision 7 - Add Custody Loop Primitive](#revision-7-add-custody-loop-primitive)
  - [Revision 8 - Make Repair Priority Flow Into `bv`, Not Around It](#revision-8-make-repair-priority-flow-into-bv-not-around-it)
  - [Revision 9 - Add Value Failure To Verdict Thresholds](#revision-9-add-value-failure-to-verdict-thresholds)
  - [Revision 10 - Change Out Of Scope](#revision-10-change-out-of-scope)
- [7. The Blunt Verdict](#7-the-blunt-verdict)
# Donella Lens Review - Fleet Autonomy v1

Task: `fleet-autonomy-v1-lane-donella-2026-05-05`
Reviewer lens: Donella Meadows systems thinking
Artifact reviewed: `00-PLAN-INPUT.md`
Plan evidence window: 2026-05-05T07:00Z to 2026-05-05T15:00Z
Observed outcome: 107 dispatches, 2 closures, 390 fuckups, 4 frozen or failed panes
Stated mission: founder can sleep 8+ hours while the fleet produces high-quality closures
My verdict in one sentence: revise, because the plan sees the hottest feedback loop but still protects the mental model that produced the loop.

## Source Grounding

I am using the canonical Meadows 1999 numbering.
Constants and parameters are #12, not #9.
Delays are #9.
Negative feedback strength is #8.
Positive feedback gain is #7.
Information flows are #6.
Rules are #5.
Self-organization is #4.
Goals are #3.
Paradigms are #2.
Transcending paradigms is #1.
This numbering is in `references/LEVERAGE-POINTS.md:18-37`.
The plan sometimes uses local shorthand labels.
I preserve those labels as evidence.
I do not let them govern the critique.

The stock/flow vocabulary is grounded in `references/STOCKS-AND-FLOWS.md:18-37`.
The feedback-loop vocabulary and loop sketch protocol are grounded in `references/FEEDBACK-LOOPS.md:13-34`.

The anti-patterns matter here: leverage theater, parameter thrashing, reminder substitution, human-as-feedback-loop, and grand reframe without instrumentation are named in `references/ANTI-PATTERNS.md:5-51`.
This plan flirts with all five.

The local exemplars matter too: information flow, rules, delay detection, goal shifts, dispatch-contract paradigms, and self-organization are in `data/zeststream-exemplars.json:8-95`.

The plan input's own evidence is decisive.
The stated mission is at `00-PLAN-INPUT.md:9-12`.
The failure metrics are at `00-PLAN-INPUT.md:13-25`.
The claim that the fleet appeared busy while not producing work is at `00-PLAN-INPUT.md:27`.
The three loop diagnosis is at `00-PLAN-INPUT.md:31-37`.
The proposed interventions are at `00-PLAN-INPUT.md:39-44`.
The `bv --robot-next` claim is at `00-PLAN-INPUT.md:48-52`.
The verified `bv` counterfactuals are at `00-PLAN-INPUT.md:59-70`.
The primitive list is at `00-PLAN-INPUT.md:74-208`.
The measurement artifact is at `00-PLAN-INPUT.md:212-235`.
The out-of-scope list is at `00-PLAN-INPUT.md:263-268`.
The final simplicity claim is at `00-PLAN-INPUT.md:270-274`.

Socraticode found the existing implementation split.
`idle-state-probe.sh` reads `br ready --json` at `.flywheel/scripts/idle-state-probe.sh:165-181`.
It filters candidate beads at `.flywheel/scripts/idle-state-probe.sh:220-232`.
It emits `dispatch_candidate` at `.flywheel/scripts/idle-state-probe.sh:270`.
`idle-pane-auto-dispatch.sh` consumes the probe candidate at `.flywheel/scripts/idle-pane-auto-dispatch.sh:431-479`.
It writes the dispatch prompt at `.flywheel/scripts/idle-pane-auto-dispatch.sh:241-261`.
It writes dispatch receipts at `.flywheel/scripts/idle-pane-auto-dispatch.sh:537-551`.
This means P1 is not a one-line change in the watcher.
It is a contract change between probe, watcher, tests, and status reports.

## 1. Where I Disagree With The Framing

I disagree with the phrase "Fleet Autonomy v1" as the governing goal.
Autonomy is not the stock that Joshua wants to accumulate.
Autonomy is a means.
The desired stock is founder capacity released into higher-value work.
The desired stock is also high-quality mission closure capacity.
The phrase "fleet autonomy" can easily become fleet self-reference.
When a system measures its own independence, it may preserve itself.
When a system measures founder capacity released, it must prove service.

The plan is right to say visible activity is the revealed goal.
It is wrong to stop there.
The revealed goal is more specific.
The revealed goal is "keep local contracts satisfied so the orchestrator can narrate motion."
Dispatch fired.
Callback received.
Fuckup logged.
Commit landed.
Heartbeat sent.
Each is a local success.
The global stock still did not rise.
That is not just a wrong metric.
That is a wrong accountability boundary.

I disagree with the plan's claim that the system is simple once we accept the watcher consumes the wrong primitive.
That statement is itself a mental-model shortcut.
It turns a system failure into a tool-selection failure.
The `br ready` to `bv --robot-next` change is probably necessary.
It is not sufficient.
It changes selection.
It does not change what happens after a selected bead returns BLOCKED.
It does not change what the orchestrator does with callbacks.
It does not change whether a repo mission anchor can be read mechanically.
It does not change whether a closure is counted only if it advances that anchor.
It does not change whether alps can stall for 6h50m under a heartbeat label.

The plan says "five substrate primitives plus one measurement loop."
It then lists six primitives plus one measurement.
That is small, but the mismatch matters.
Systems hide in off-by-one language.
If the plan cannot count its own primitives, it may not count its own effects.

I disagree with putting "MISSION.md or paradigm-level doctrine changes" out of scope.
The plan itself diagnoses a #3 goal failure.
The plan itself asks whether this is a #6 information-flow fix or a #3 paradigm shift.
Then it excludes paradigm-level doctrine changes.
That is like diagnosing a thermostat goal error and forbidding touching the setpoint.
It may be prudent to avoid broad doctrine edits in the first implementation wave.
It is not prudent to exclude the mission contract from the plan.
At minimum the plan needs a written definition of closure-against-mission.
At minimum the status primitive needs to read locked mission anchors.
At minimum the watcher needs a mission-license check before calling a dispatch valuable.

I disagree with the morning report as the main measurement artifact.
Morning reports are delayed feedback.
Delayed feedback can teach.
It cannot regulate a fast loop by itself.
A fleet that can generate 107 dispatches overnight needs feedback during the night.
The morning report tells Joshua what already happened.
The balancing loop must act before the 60th low-value dispatch.
The report is useful as an audit.
It is not the controller.

I disagree with treating `closure_conversion_rate` as the central stock.
It is a ratio, not a stock.
It is a useful signal.
It can be gamed by reducing dispatches.
The desired stock is mission closure value accumulated per unattended hour.
The desired flow is verified mission-progress closure per pane-hour.
The plan needs both numerator quality and denominator cost.
Without quality, closure count rewards easy closures.
Without cost, dispatch reduction can masquerade as improvement.

I disagree with naming Loop B as "frozen pane untreated" in P5.
The plan earlier names Loop B as mobile-eats reap-poll to owner-custody-missing.
P5 then reuses Loop B for frozen panes.
That is topology drift inside the plan.
The mobile-eats loop is a repeated action loop.
The frozen-pane issue is a stalled capacity stock.
They need different balancing partners.
Conflating them will build one damper and leave the other open.

I disagree with P4 living inside the watcher probe.
A cross-orchestrator reservation is shared infrastructure.
If the watcher force-releases reservations directly, the watcher becomes a policy actor.
The system already has Agent Mail reservation semantics.
The leverage point is the rule and its enforcing owner, not an opportunistic watcher side effect.
The watcher may detect stale reservations.
The reservation substrate or a named recovery tool should own release.
Otherwise every watcher becomes a little government with its own laws.

I disagree with "no Joshua gates except six TRUE-blocker classes" unless those six classes are named in this plan.
The plan asks for founder absence.
That requires explicit autonomy boundaries.
The human-in-the-loop skill says autonomy is earned and bounded.
A vague exception list is not a boundary.
It is a loophole.

I agree with the plan's instinct for stocks-before-flows.
I agree with using `bv --robot-next`.
I agree with same-bead dampening.
I agree with computed status.
I agree with bounding unbounded delays.
But I do not agree that this is mainly a patch list.
It is a goal and governance problem expressed as a patch list.

## 2. Stocks And Flows Audit - P1

Primitive: P1, watcher uses `bv --robot-next`.
Intended stock changed: ready work selected for dispatch.
More precisely: stock of dispatches pointed at high-leverage unblocked beads.
The plan also intends to reduce the stock of repeated stuck-bead dispatches.
Actual inflow changed: candidate selection moves from chronological ready list to DAG-aware priority.
Actual outflow changed: blocked or downstream-unhelpful ready beads should leave the dispatch stream.
Observed current inflow: `br ready --json` in `idle-state-probe.sh:171`.
Observed current filtering: priority <= 1 and not epic in `idle-state-probe.sh:224-228`.
Observed current candidate: first filtered candidate in `idle-state-probe.sh:270`.
Delay between flow change and stock change: one watcher tick for selection.
Delay between selection change and mission stock change: at least one worker cycle plus validation plus close.
Delay risk: if callbacks remain unvalidated, selected work may still not become mission value.
Correct stock for stated goal: partly.
The selected bead is not the goal.
The goal is mission-progress closure.
A better measured stock: "verified mission-progress closure backlog drained."
A better signal: `mission_unblocker_dispatch_rate`.
A better signal: `closed_bead_mission_anchor_delta`.
A better signal: `same_bead_redispatch_without_state_change_count`.
The plan's P1 helps if `bv` already encodes blocked state correctly.
The plan's P1 fails if `bv` lacks in-flight awareness.
The plan notices this risk at `00-PLAN-INPUT.md:102`.
The mitigation consults dispatch log for same bead in the last 30 minutes.
That is still a parameterized memory.
The structural fix is a dispatch-state ledger consumed by `bv` or the probe.
The plan calls the change one-line.
The code evidence says otherwise.
The contract change touches `idle-state-probe`, watcher tests, dispatch-log semantics, and status interpretation.
The highest leverage near P1 is not the command substitution.
It is making "eligible for dispatch" a first-class state.
That state should combine DAG rank, blocked status, in-flight status, recent attempts, and mission anchor relevance.
P1 is a #6 information-flow fix if it gives the watcher better information.
P1 becomes a #5 rule fix only if dispatch eligibility is enforced.
P1 becomes #3 goal work only if `bv` ranks by mission anchor value, not graph centrality alone.

## 2. Stocks And Flows Audit - P2

Primitive: P2, watcher self-asserts on divergent loops.
Intended stock changed: stock of runaway same-bead loops.
Actual inflow changed: after two same-bead picks, repeated dispatch inflow should stop.
Actual outflow changed: stuck beads should exit the active dispatch stream into a cooldown or escalation stream.
Delay between flow change and stock change: immediate for dispatch count.
Delay between cooldown and mission progress: uncertain.
The plan does not define what happens during cooldown.
If no alternate work is dispatched, pane-hour stock can remain idle.
If alternate work is picked, mission progress can rise.
If the same bead is a substrate blocker, cooldown can postpone the real problem.
Correct stock for stated goal: partly.
Reducing repeated dispatches is useful.
But fewer repeats is not mission progress.
A better stock: "blocked beads with named next non-human action."
A better stock: "blocked parent beads with open child decomposition complete."
A better stock: "retry attempts without new state."
P2's current rule is count >= 2 in 30 minutes.
That is a parameter.
The deeper rule is retry only after state changes.
State changes can be closure, dependency change, reservation release, new evidence, test pass, or owner decision.
Without a state-change predicate, P2 risks parameter thrashing.
The local exemplar on rules is L66/L67 in `data/zeststream-exemplars.json:23-35`.
Those rules change operator permission and retry behavior.
P2 should imitate that.
It should not merely wait 30 minutes.
It should ask: what state must be different before this bead is eligible again?
That is stronger than a cooldown.
It is a balancing loop with a real setpoint.
Setpoint: a bead cannot re-enter dispatch unless its state changed or its retry budget explicitly reset.
Actor: selection substrate.
Response: skip, decompose, escalate to repair, or close as invalid.
Delay: one watcher tick.
Measurement: `redispatch_without_state_delta_count`.

## 2. Stocks And Flows Audit - P3

Primitive: P3, `flywheel-loop status` with computed verdict.
Intended stock changed: operator understanding of fleet health.
Actual flow changed: status rows append every five minutes.
Actual outflow changed: none by itself.
A status primitive is an information flow.
It changes behavior only if a controller consumes it.
Delay between flow change and stock change: five minutes to create status.
Delay to morning ritual: up to eight hours.
Delay to corrective action: undefined.
Correct stock for stated goal: not yet.
The schema includes closures, dispatches, conversion, aging, overdue callbacks, unique bead ratio, frozen panes, and interventions.
Those are good signals.
They are not the same as mission progress.
The plan includes `Mission-progress vs locked anchors` in the human artifact.
It omits `mission_anchor_delta` from the JSON schema.
That omission is serious.
If the machine schema does not carry mission progress, the machine controller cannot act on mission progress.
The human report cannot be the only place the mission appears.
The status schema should include `mission_anchor_progress_by_repo`.
It should include `verified_closure_value_by_repo`.
It should include `pane_hours_by_repo`.
It should include `founder_intervention_minutes_saved_or_spent`.
It should include `controller_actions_taken`.
The verdict thresholds should include mission-progress failure.
Current `BROKEN` includes zero closures with >50 dispatches.
That misses two low-value closures with 107 dispatches.
The plan's own evidence is exactly that case.
A system that closes two non-mission beads can pass a zero-closure guard.
Better `BROKEN`: `mission_anchor_delta == 0 and dispatches > 20`.
Better `BROKEN`: `mission_progress_per_pane_hour < floor`.
Better `DEGRADED`: `closure_conversion >= 0.25 but mission_anchor_delta low`.
Status is #6.
If wired into dispatch gates, status becomes #8 negative feedback.
If status changes what counts as work, it supports #3.
P3 should be designed as a controller input, not only a morning report.

## 2. Stocks And Flows Audit - P4

Primitive: P4, cross-orchestrator reservation TTL enforcement.
Intended stock changed: stale shared-surface reservations.
Actual inflow changed: long-held reservations should no longer accumulate.
Actual outflow changed: stale reservations are released after 300 seconds.
Delay between flow change and stock change: up to five minutes if watcher runs at that cadence.
Delay to mission progress: one or more dispatch cycles after release.
Correct stock for stated goal: yes for one bottleneck, no for the whole goal.
Stale reservation stock directly blocks work.
The plan cites MagentaPond's 50-minute hold.
The outflow must be safe.
Force-release is a governance action.
The reservation holder may be doing a valid long operation.
The plan's safety rule is too thin.
A TTL without heartbeat semantics punishes slow valid work.
A heartbeat without TTL preserves stale locks.
The right stock is not "reservations older than 300s."
The right stock is "reservations older than lease with no proof of active holder progress."
That requires holder activity, file path, last renewal, and owner identity.
Agent Mail reservations already have TTL semantics per L51 in `AGENTS.md:181-217`.
P4 should enforce lease expiry at reservation acquisition or renewal.
The watcher can detect.
The reservation substrate should release.
The dispatch controller should skip or reroute while release is pending.
The local source says shared mutable state needs coordination protocol in `agent-orchestration` rules.
The plan's P4 should name the coordination owner.
Leverage point: #5 rules more than #9 delay.
A 300-second number is #12 unless paired with a lease rule.
The rule is: no exclusive reservation counts as blocking capacity after lease expiry unless renewed by live holder proof.

## 2. Stocks And Flows Audit - P5

Primitive: P5, pane freeze auto-respawn permit gate.
Intended stock changed: frozen worker capacity.
Actual inflow changed: frozen panes should no longer accumulate.
Actual outflow changed: frozen panes are respawned under permit.
Delay between flow change and stock change: five minutes after hash convergence.
Delay to mission progress: relaunch plus prompt injection plus work start plus close.
Correct stock for stated goal: yes for capacity, no for value.
A working pane is a buffer stock.
A frozen pane is lost capacity.
The fleet failed with four frozen or failed panes.
P5 addresses a real stock.
But P5 confuses pane motion with work value if not tied to dispatch delivery receipts.
The existing watcher already has a four-state receipt for dispatch delivery at `idle-pane-auto-dispatch.sh:372-417`.
The doctrine says transport acceptance is not work start in AGENTS L91.
P5 should reuse that receipt.
P5's mitigation mentions raw capture language.
The repo doctrine requires NTM-only pane operations.
Use the canonical frozen detector and permit gate, not ad hoc pane reads.
The plan says "no Joshua-permit override active."
It should define the permit source.
It should define protected panes from topology.
It should define recovery budget.
It should define whether relaunch replays the last dispatch or picks new work.
A pane respawn can erase context.
That is an outflow from the stock of worker-local understanding.
The balancing loop should compare capacity restored against context lost.
A safe respawn loop needs a preservation stock: `recoverable_context_receipts`.
Without that, P5 may improve capacity while damaging quality.
Leverage point: #8 negative feedback if detector-controller-response is wired.
Also #5 rules if protected panes and recovery budget are enforced.
Mostly not #3.

## 2. Stocks And Flows Audit - P6

Primitive: P6, repair-bead-aging escalation pipeline.
Intended stock changed: aging repair beads.
Actual inflow changed: repair beads should be promoted into ready queue after two hours.
Actual outflow changed: old repair beads should be dispatched or escalated.
Delay between flow change and stock change: two hours, then six hours.
Delay to mission progress: repair completion plus downstream unblocked work.
Correct stock for stated goal: yes, because substrate repair unlocks many flows.
But the plan should distinguish repair beads by blast radius.
Some repair beads are substrate blockers.
Some are hygiene.
Some are documentation.
A label alone may overpromote work.
The real stock is "mission-blocking substrate repairs aging past safe delay."
The plan names `flywheel-1eg0k` as br-sync repair.
That is likely substrate-blocking.
The general rule should require `unblocks_count`, `affected_sessions`, or `driver_health_impact`.
`bv` already has graph-aware triage.
The plan says file upstream issue if `bv` lacks repair priority.
Good.
But local watcher should not create a second priority system that fights `bv`.
The better revision is to feed repair-bead metadata into `bv` and make watcher consume one priority source.
Leverage point: #6 if repair age becomes visible.
Leverage point: #5 if repair aging creates a dispatch rule.
Leverage point: #4 if repair classes can evolve from incidents into selection policy.
Delay: two hours may still be too long for fleet-critical substrate.
Some repairs need one tick.
Some can wait six hours.
Use severity and affected-flow count.
A fixed 2h cap is a parameter.
A severity-sensitive controller is a balancing loop.

## 2. Stocks And Flows Audit - M

Primitive: M, morning ritual artifact.
Intended stock changed: Joshua's situational awareness.
Actual inflow changed: status history becomes a human-readable brief.
Actual outflow changed: none unless Joshua or orchestrator acts.
Delay between flow change and stock change: overnight.
Correct stock for stated goal: partly.
The artifact serves the founder's ops meeting.
It does not by itself let the founder sleep.
A morning report is accountability, not autonomy.
The plan says "this is the artifact you read with coffee."
That is useful.
But if Joshua must read it to steer the next day, the system still depends on him.
The morning ritual should have two parts.
First: overnight autonomous controller receipts.
Second: human brief.
The controller receipts should show which balancing loops fired without Joshua.
The human brief should show what changed, what degraded, and what the controller did.
Current M leads with fleet verdict.
It should lead with mission delta and founder intervention delta.
It should say: did the founder gain capacity?
It should say: did the fleet make high-quality progress?
It should say: did the system correct itself before morning?
It should not make dispatches and fuckups merely page two.
Fuckup stock can signal learning or thrash.
It should be split.
`new_unique_trauma_classes` is different from duplicate-encoded events.
`closed_loop_traumas` is different from open incidents.
The plan's 390 fuckups include duplicate-encoded propagation events.
The morning artifact should expose duplicate amplification as a loop.
Leverage point: #6 information flow.
It becomes #8 only if status drives night-time correction.
It supports #3 only if mission-progress stock governs verdict.

## 3. Loop Topology

I would draw the current system this way:

```text
R1 visible-activity loop
  watcher sees WAITING pane
    -> dispatch fires
    -> prompt delivered or appears delivered
    -> callback arrives or overdue event logs
    -> orchestrator has something to process
    -> more watcher confidence that work is moving
    -> watcher sees WAITING pane again

Stock rising: dispatch rows
Stock stuck: verified mission closures
Perverse signal: busy scrollback
Missing balancing partner: mission-value controller
```

R1 is the plan's main diagnosis.
P1 and P2 partially damp it.
But P1 can turn R1 into "better-looking dispatches" if mission value is absent.
P2 can reduce repeats without increasing value.
The balancing partner should be:

```text
B1 mission-value correction
  mission anchor delta low
    -> status marks value failure
    -> selector penalizes non-mission work
    -> watcher dispatches mission-licensed unblockers only
    -> closures change mission stock
    -> status clears failure
```

B1 is not yet in the plan.
P3 hints at it.
M mentions it in prose.
No primitive wires it into selection.

```text
R2 same-bead retry loop
  bead selected
    -> worker returns BLOCKED or decomposes child
    -> parent remains ready
    -> watcher selects parent again
    -> worker returns same BLOCKED
    -> parent remains ready
```

Stock rising: blocked callbacks on same bead.
Stock stuck: child completion or state transition.
Perverse signal: parent remains P0/P1 ready.
Missing balancing partner: retry-after-state-change rule.
P2 adds a cooldown.
Cooldown is weaker than state-change eligibility.
The stronger loop is:

```text
B2 retry eligibility correction
  bead attempted
    -> attempt ledger records state hash
    -> next selection compares current state hash
    -> no state delta blocks redispatch
    -> route to child/dependency/repair/escalation
    -> state changes
    -> bead eligible again
```

B2 is a #5 rule.
It is more powerful than a 30-minute #12 parameter.

```text
R3 callback-processing loop
  workers send DONE/BLOCKED
    -> orchestrator reads callback
    -> ack or notes callback
    -> worker or watcher sends another callback
    -> orchestrator spends more time processing callbacks
    -> fewer controller repairs happen
```

Stock rising: callback backlog and callback attention.
Stock stuck: closure-against-mission.
Perverse signal: callback volume feels like progress.
Plan diagnosis names this at `00-PLAN-INPUT.md:35`.
Plan primitives do not directly damp it.
P3 can expose it through `dispatch_callback_overdue_rate`.
But callback-overdue is not callback-overprocessing.
The missing balancing partner is closure-vs-callback ratio.

```text
B3 callback value gate
  callback count rises faster than closure value
    -> status marks callback thrash
    -> orchestrator stops ack-only work
    -> controller prioritizes closure, validation, or repair
    -> callback stock drains into closures or beads
```

B3 needs an actor.
The plan does not name the actor.
If the actor is Joshua in the morning, feedback is too delayed.
If the actor is `flywheel-loop status` consumed by watcher, the loop can regulate.

```text
R4 owner-custody reap-poll loop
  mobile-eats poll runs
    -> owner-custody-missing logged
    -> record commit or receipt
    -> poll runs again
    -> same owner-custody gap logged
```

Stock rising: owner-custody-missing events.
Stock stuck: owner assignment or custody contract.
The plan names this in Loop B.
No primitive specifically addresses it.
P2 same-bead cooldown is not the same loop.
P5 frozen pane recovery is not the same loop.
The missing balancing partner is custody-state repair.

```text
B4 custody correction
  owner-custody-missing count > 1 per artifact
    -> create or update owner assignment
    -> block further reap-poll for same artifact until owner state changes
    -> route uncustodied artifact to named owner queue
```

B4 is a #5 rule.
It may also be #4 self-organization if missing custody rules become doctrine.
The plan does not include it.
That is a material omission.

```text
R5 stale-reservation loop
  worker reserves shared surface
    -> worker stalls or forgets release
    -> other workers block
    -> callbacks report reservation conflict
    -> orchestrator retries or waits
    -> reservation remains
```

Stock rising: blocked work behind stale reservation.
Stock stuck: release or renewal proof.
P4 addresses this.
P4 needs holder-liveness proof.
Otherwise it converts a stale-reservation loop into a force-release conflict loop.

```text
B5 lease correction
  reservation lease expires
    -> substrate checks holder liveness
    -> live holder renews or stale holder loses lease
    -> blocked work can proceed
```

B5 is #5 rules.
The 300s number is #12.
The live-holder proof is #6.
The force-release mechanism is #8.

```text
R6 frozen-capacity decay loop
  pane freezes
    -> less capacity
    -> more backlog
    -> more stress on remaining panes
    -> more long-running or repeated dispatches
    -> more chances of freeze or stall
```

Stock falling: usable worker panes.
Stock rising: backlog and delayed feedback.
P5 addresses this.
The missing balancing partner is safe recovery with context preservation.

```text
B6 capacity recovery
  frozen detector sees converged pane
    -> protected-pane and work-signal checks
    -> snapshot context
    -> respawn
    -> replay or reselect work
    -> verify work_started
```

B6 is present in spirit.
It needs exact evidence fields.
It must avoid raw pane operations.
It must reuse existing NTM truth surfaces.

```text
R7 repair-aging loop
  substrate repair bead ages
    -> substrate remains degraded
    -> workers hit substrate failures
    -> more repair and fuckup rows
    -> dispatch selector still picks ordinary work
    -> repair bead ages further
```

Stock rising: unresolved substrate repair debt.
Stock stuck: repair closure.
P6 addresses this.
The missing balancing partner is severity-ranked repair priority integrated into the single selector.

```text
B7 repair priority correction
  repair age and affected-flow count rise
    -> selector promotes repair above ordinary work
    -> repair closes
    -> downstream work unblocks
    -> repair pressure falls
```

B7 is good.
But it should live inside `bv` or the eligibility primitive, not as separate watcher folklore.

```text
R8 morning-report dependency loop
  fleet fails overnight
    -> Joshua reads morning report
    -> Joshua issues corrective command
    -> fleet improves during day
    -> next night reveals new failure
    -> Joshua reads morning report again
```

Stock rising: founder involvement in operating the fleet.
Stock stuck: founder capacity released.
M can become R8 if it is only a human report.
The balancing partner is night-time controller action.
Without it, the morning ritual improves awareness and preserves dependency.

```text
B8 unattended correction
  status detects degradation at night
    -> controller takes permitted action
    -> action receipt logged
    -> morning report audits action
    -> human adjusts policy only when needed
```

B8 is the missing autonomy loop.
This is the heart of the critique.

## 4. Leverage Points - P1

P1 claimed leverage: better primitive selection.
Canonical classification: mostly #6 information flows.
The watcher receives graph-aware priority it did not have.
If `bv` encodes PageRank, dependencies, blocked state, and unclaimed status, it improves information quality.
If the watcher still has final ad hoc filtering, the information can be lost.
The stronger nearby leverage point: #5 rules.
Rule: a bead is dispatch-eligible only if `bv` says it is next and no in-flight or no-state-change retry guard blocks it.
The strongest nearby leverage point: #3 goals.
Goal: rank by mission-anchor delta, not only graph centrality.
Question I would ask: what does `bv --robot-next` optimize?
If it optimizes PageRank on the DAG, that may optimize substrate topology.
If mission anchors are not in the graph weights, it may not optimize founder-capacity release.
Graph centrality is not the same as mission value.
The plan's counterfactual is promising.
It says `flywheel-4m2a` was a high-leverage unblocker.
Good.
But one counterfactual does not define the goal.
Revision: P1 must include `selection_reason` and `mission_anchor_ref`.
Revision: P1 must fail closed if `bv` output lacks an id, status, score, and freshness proof.
Revision: P1 must run `bv` once, not three times.
The sample calls `bv --robot-next` three times.
That risks race and inconsistent cache freshness.
One state observation should drive one decision.
Systems oscillate when each faucet reads a different gauge.

## 4. Leverage Points - P2

P2 claimed leverage: balancing dampener for Loop A.
Canonical classification: #8 negative feedback if it compares repeats against a target and corrects.
Canonical classification: #5 rules if it changes dispatch eligibility.
Canonical classification: #12 parameters if it is only "2 attempts in 30 minutes."
The plan currently mixes all three.
The correction target is underdefined.
The target should not be "fewer than two same-bead picks."
The target should be "no redispatch without state change."
That target is exact.
It does not require guessing a universal cooldown.
The plan should record `attempt_state_hash`.
The hash can include bead status, dependency statuses, last callback verdict, reservation state, and child count.
If the state hash is unchanged, redispatch is waste.
If the state hash changed, redispatch may be valid.
This is a better negative feedback loop because it watches the actual stock.
It watches state change, not elapsed time.
The same-bead skip must not simply log idle.
Idle with safe work available is another failure mode.
The response should choose from four actions.
Action one: select next eligible bead.
Action two: create or update decomposition child.
Action three: promote repair if substrate-blocked.
Action four: escalate with probe ledger if truly human-blocked.
P2 should include this action set.

## 4. Leverage Points - P3

P3 claimed leverage: stocks-before-flows computed status.
Canonical classification: #6 information flows by default.
It becomes #8 negative feedback only when something acts on the verdict.
It becomes #5 rules if `BROKEN` or `DEGRADED` changes permitted dispatch behavior.
It becomes #3 goals if mission-progress stock governs verdict.
The plan currently creates an information flow.
It does not yet create a correction loop.
The status schema omits the plan's most important phrase: closure against locked mission anchors.
A status primitive that cannot compute mission delta cannot enforce the stated mission.
The JSON should lead with mission value.
The human view can still show closures and dispatches.
The machine view must include controller-ready fields.
Fields needed:
`mission_anchor_delta_by_repo`.
`mission_closure_value_by_repo`.
`pane_hours_by_repo`.
`mission_progress_per_pane_hour`.
`controller_action_required`.
`controller_action_taken`.
`safe_autonomous_action_remaining`.
`human_only_blocker_count`.
Without these, P3 is observability.
With these, P3 can regulate.
The plan's `BROKEN` threshold is too permissive.
Two closures with zero mission delta should be `BROKEN`.
A callback-overdue breach plus frozen panes already makes `BROKEN`.
But the core failure is value failure.
Make value failure first-class.

## 4. Leverage Points - P4

P4 claimed leverage: cap unbounded reservation delay.
Canonical classification: #12 if only a 300-second parameter.
Canonical classification: #9 if it actually changes delay relative to work rate.
Canonical classification: #5 if it changes lease rules.
The true leverage lives at #5.
The rule should be: exclusive reservations must renew with live holder proof before expiry or they stop blocking dispatch.
A force-release should require evidence.
Evidence: reservation id, holder identity, expires_ts, last_active_ts, path, blocked dispatch id.
The watcher should not invent release authority.
The watcher should call a reservation recovery command with a receipt.
The release action should be idempotent.
The status primitive should count stale leases.
The morning report should show stale-reservation recurrence.
This is not a "time cap" problem alone.
It is a contract ownership problem.
The stronger design borrows from `agent-governance`: register, bind, monitor, audit, enforce.
A reservation is a capability lease.
Treat it as such.

## 4. Leverage Points - P5

P5 claimed leverage: balancing loop for frozen panes.
Canonical classification: #8 negative feedback if detector -> rule -> respawn -> verify is complete.
Canonical classification: #5 rules if protected panes and recovery budgets are enforced.
Canonical classification: #11 buffers if it preserves spare capacity.
The plan has the right shape.
It lacks enough state preservation.
A pane is not merely a CPU slot.
It is a stock of local context.
Respawn drains that stock.
Sometimes that is right.
Sometimes it loses useful work.
The plan should measure both stocks:
usable worker capacity.
recoverable worker context.
The response should snapshot before respawn.
The response should verify after respawn.
The response should not count success until work starts.
The existing dispatch receipt has the four states needed.
Use it.
Also name false-positive cost.
A long Socraticode query can be quiet.
A long compile can be quiet.
Silence is not always freeze.
The detector must distinguish no new bytes, stable hash, process state, and expected long operation.
The plan mentions this, but should make it an acceptance gate.

## 4. Leverage Points - P6

P6 claimed leverage: repair-bead-aging escalation.
Canonical classification: #9 if it shortens delay.
Canonical classification: #6 if it surfaces hidden repair age.
Canonical classification: #5 if it creates priority rules.
Canonical classification: #4 if incidents evolve into repair classes.
The best leverage is #5 plus #4.
Do not merely set age thresholds.
Teach the system how to classify repair impact.
Repair impact should combine:
age.
blocked sessions.
blocked bead count.
affected substrate.
severity.
availability of autonomous recovery.
human-only status.
Then route.
For high-impact repairs, two hours is too slow.
For low-impact repairs, two hours may be noisy.
The stock to watch is not all repair beads.
It is mission-blocking repair debt.
The plan should keep one priority source.
If `bv` owns graph priority, feed repair impact to `bv`.
Do not create a second selector in watcher code.
Parallel priority systems become policy resistance.

## 4. Leverage Points - M

M claimed leverage: morning ritual.
Canonical classification: #6 information flow.
Potential classification: #8 if it closes the loop during the night.
Potential classification: #3 if it changes what the system calls success.
Current classification: mostly #6 with a delayed human actor.
This is useful but not enough.
The most important measurement is not "what happened?"
It is "what did the system correct without Joshua?"
The morning report should include autonomous corrections.
Examples:
same-bead loop stopped.
stale reservation released.
frozen pane recovered.
repair bead promoted.
mission-value gate blocked low-value dispatch.
human-only blocker escalated with probe ledger.
If these are absent, the fleet did not operate autonomously.
It merely ran.
The report should include "founder dependence stock."
That stock can be simple at first:
`joshua_interventions_count`.
`minutes_waiting_for_joshua`.
`human_only_blockers_open`.
`actions_taken_autonomously_that_previously_waited_for_joshua`.
This reframes the ritual from ops theater to founder-capacity accounting.

## 5. The Thing The Plan Does Not See

The invisible structural element is the conversational orchestrator.
The orchestrator is not an observer.
The orchestrator is a controller.
The orchestrator is also a bottleneck.
The orchestrator is also a reward function.
Workers optimize for what the orchestrator reaps, acknowledges, closes, and dispatches next.
If the orchestrator rewards callback volume, callback volume grows.
If the orchestrator rewards closure count, closure count may grow.
If the orchestrator rewards mission delta, mission delta may grow.
If the orchestrator preserves its own narrative authority, the fleet remains founder-shaped.

The plan says the watcher consumes the wrong primitive.
But the watcher did not create the whole failure.
The orchestrator consumed the wrong story.
It consumed "dispatches fired" and "callbacks arrived" and "commits landed."
It did not consume "founder capacity increased."
It did not consume "locked mission anchor advanced."
It did not consume "controller corrected itself before morning."

The invisible structure is not just a person or pane.
It is the conversational loop around the fleet.
A human says something.
The orchestrator turns it into prompts.
Workers respond in prose.
The orchestrator summarizes.
The system feels alive because language is flowing.
This is a powerful reinforcing loop.
It can run without the world changing.
It can run while the founder sleeps.
It can run while the founder's desired stock does not rise.

The equivalent of the foundation report whose value lay outside the model is founder attention.
Founder attention is treated as free until morning.
It is not free.
It is the scarce stock this system is supposed to release.
Every "wait for Joshua" event drains that stock.
Every unclear morning report drains that stock.
Every fleet-stats request Joshua has to issue drains that stock.
Every repeated watcher failure that Joshua has to notice drains that stock.
The plan measures Joshua manual interventions.
It does not yet model Joshua attention as the limiting stock.

The second invisible structure is the mission anchor.
It is mentioned as a target.
It is not integrated as a controller input.
If mission anchor remains prose, it is not a stock.
It is a banner.
The fleet needs a machine-readable mission-progress interface.
Without it, all closure metrics are surrogate metrics.
The plan says "closure-against-mission."
The code must ask "against which mission line?"
The callback must report "which mission anchor changed?"
The close gate must verify that claim.
The status command must aggregate it.
The watcher must prefer work that changes it.

The third invisible structure is the attempt ledger.
The dispatch log is a history.
It is not yet a state machine.
The system needs to know not just that a bead was dispatched.
It needs to know whether anything changed since last attempt.
That is the difference between memory and learning.
R1 and R2 will continue until attempt state becomes part of eligibility.

The fourth invisible structure is the fleet's accountability gradient.
Who pays for a false dispatch?
Who pays for a false DONE?
Who pays for a stale reservation?
Who pays for a morning report that arrives too late?
If the answer is Joshua, the system has not grown outside the founder.
If the answer is a controller with receipt-backed correction, the system has begun to learn.

## 6. Specific Revisions In My Voice

### Revision 1 - Rename The Goal Stock

```diff
- ## Plan: Fleet Autonomy v1
+ ## Plan: Founder-Capacity And Mission-Closure Autonomy v1

- The mission decomposes into 5 substrate primitives + 1 measurement loop.
+ The mission decomposes into 6 substrate primitives plus 1 controller loop.
+ The primary stock is founder capacity released.
+ The secondary stock is verified mission-anchor closure value.
+ Dispatches, callbacks, commits, and fuckup rows are flows or signals, not success.
```

Rationale:
The current title lets autonomy become an end.
The stated mission says founder grows outside the founder.
Name the stock the system must increase.
This is a #3 goal correction.
It also prevents `closure_conversion_rate` from becoming the false goal.

### Revision 2 - Add Mission-Anchor Delta To P3 Before Morning Report

```diff
   "closure_conversion_rate": 0.019,
+  "mission_anchor_delta_by_repo": {
+    "flywheel": {"status":"no_delta","closed_value":0,"anchor_refs":[]},
+    "skillos": {"status":"no_delta","closed_value":0,"anchor_refs":[]},
+    "alpsinsurance": {"status":"no_delta","closed_value":0,"anchor_refs":[]},
+    "mobile-eats": {"status":"no_delta","closed_value":0,"anchor_refs":[]}
+  },
+  "mission_progress_per_pane_hour": 0.0,
+  "founder_capacity_released_minutes": 0,
+  "founder_capacity_consumed_minutes": 0,
   "ready_bead_age_p95_hours": {...},
```

Rationale:
The plan puts mission progress in the human markdown example.
That is too late and too soft.
A machine controller needs mission delta in JSON.
Without this field, P3 is information flow without the goal.
This is #6 in service of #3.

### Revision 3 - Replace Cooldown With State-Change Eligibility

```diff
- If count >= 2 and no closure_event in the same window,
- log the skip with reason same-bead-cooldown.
+ If attempt_count >= 1 and attempt_state_hash is unchanged,
+ mark the bead ineligible with reason redispatch_without_state_delta.
+ Eligible retry requires one of:
+   dependency_status_changed=true
+   child_bead_closed=true
+   reservation_state_changed=true
+   repair_bead_closed=true
+   new_probe_evidence=true
+   human_only_blocker_resolved=true
+ Otherwise route to next eligible bead or decomposition/repair/escalation.
```

Rationale:
Cooldown is a parameter.
State-change eligibility is a rule.
The repeated-bead loop is caused by unchanged state, not by elapsed time.
This revision moves P2 from #12 toward #5 and #8.

### Revision 4 - Make `bv` A Single Observation

```diff
- NEXT=$(bv --robot-next 2>/dev/null | jq -r '.id // empty')
- SCORE=$(bv --robot-next 2>/dev/null | jq -r '.score // 0')
- UNBLOCKS=$(bv --robot-next 2>/dev/null | jq -r '.unblocks // 0')
+ BV_NEXT_JSON="$(bv --robot-next 2>/dev/null)"
+ NEXT="$(jq -r '.id // empty' <<<"$BV_NEXT_JSON")"
+ SCORE="$(jq -r '.score // 0' <<<"$BV_NEXT_JSON")"
+ UNBLOCKS="$(jq -r '.unblocks // 0' <<<"$BV_NEXT_JSON")"
+ SELECTION_REASON="$(jq -c '{id,score,unblocks,status,cache_freshness,reason}' <<<"$BV_NEXT_JSON")"
```

Rationale:
One decision should come from one observation.
Three separate calls can observe three subtly different states.
Delayed and inconsistent information creates oscillation.
This is a #6 information-flow hygiene fix.

### Revision 5 - Move P4 Release Authority Out Of The Watcher

```diff
- Within the watcher probe, before dispatching, check agent-mail reservations.
- If a reservation older than 300s exists, log event AND fire force-release.
+ Within the watcher probe, detect stale exclusive reservations and emit:
+   cross_orch_stale_reservation_candidate.
+ Invoke the reservation recovery primitive:
+   agent-mail-reservation-recover --reservation-id <id> --require-holder-liveness-proof --apply
+ Dispatch is blocked only for paths affected by that reservation.
+ The recovery primitive owns force-release and writes a receipt.
```

Rationale:
The watcher should not become the owner of shared-state law.
It should detect and route.
Agent Mail or a named recovery primitive should enforce leases.
This turns P4 from a time parameter into a rule with audit.

### Revision 6 - Add Night-Time Controller Actions To M

```diff
 Morning ritual = flywheel-loop status --since=overnight --human

+ Controller actions taken while founder absent:
+   same_bead_loops_stopped: <N>
+   redispatch_without_state_delta_blocked: <N>
+   stale_reservations_recovered: <N>
+   frozen_panes_recovered: <N>
+   repair_beads_promoted: <N>
+   human_only_blockers_escalated_with_probe_ledger: <N>
+   safe_work_rerouted_after_blocker: <N>
+
+ If all controller action counts are zero while verdict is DEGRADED or BROKEN,
+ classify the night as observation-only, not autonomous.
```

Rationale:
Morning awareness is not autonomy.
Autonomy requires the system to correct itself before the founder reads the report.
This adds #8 negative feedback proof.

### Revision 7 - Add Custody Loop Primitive

```diff
+ ### P7: Owner-custody loop breaker
+
+ If owner-custody-missing repeats for the same artifact twice without owner_state_delta,
+ stop reap-poll for that artifact,
+ create or update a custody repair bead,
+ assign the owning orchestrator or substrate owner,
+ and require owner_state_delta before the poll can resume.
+
+ Acceptance:
+ replay mobile-eats owner-custody-missing events;
+ assert duplicate poll count drops to <=1 per artifact without losing custody repair.
```

Rationale:
The plan names the mobile-eats owner-custody loop.
No primitive closes it.
P5 addresses frozen panes, not custody.
This is a #5 rule and #8 balancing loop.

### Revision 8 - Make Repair Priority Flow Into `bv`, Not Around It

```diff
- Watcher tier on detected repair-bead-aging:
- 0-2h normal, 2-6h P0, 6h+ Pushover + inbox.
+ Add repair-impact metadata consumed by bv:
+   repair_age_minutes
+   affected_sessions_count
+   blocked_ready_beads_count
+   substrate_class
+   autonomous_recovery_available
+   human_only_blocker
+ bv --robot-next ranks mission-blocking repair beads above ordinary work.
+ Watcher consumes bv output only.
```

Rationale:
One selector should own priority.
Multiple priority systems become policy resistance.
Repair age matters because it blocks flows.
Impact-sensitive priority is more powerful than a universal age threshold.

### Revision 9 - Add Value Failure To Verdict Thresholds

```diff
- BROKEN: 2+ threshold breaches OR closure_conversion = 0 with > 50 dispatches
+ BROKEN:
+   mission_anchor_delta_total == 0 and dispatches_total > 20
+   OR founder_capacity_consumed_minutes > founder_capacity_released_minutes
+   OR 2+ operational threshold breaches
+   OR closure_conversion = 0 with > 50 dispatches
+
+ DEGRADED:
+   closure_conversion >= 0.25 but mission_anchor_delta_total below target
+   OR controller_action_required=true and controller_action_taken=false
+   OR any single operational threshold breach
```

Rationale:
The observed failure had two closures.
A zero-closure guard misses the actual night.
Mission value must be first in the verdict.
This is #3 goal alignment.

### Revision 10 - Change Out Of Scope

```diff
- MISSION.md or paradigm-level doctrine changes
+ Broad MISSION.md rewrites remain out of scope.
+ Machine-readable mission-anchor delta extraction is in scope.
+ A one-paragraph goal contract defining closure-against-mission is in scope.
+ Status and watcher gates may consume that contract.
```

Rationale:
The plan diagnoses goal misalignment.
It cannot forbid goal instrumentation.
This keeps implementation bounded while allowing the high-leverage change.

## 7. The Blunt Verdict

Verdict: revise.
Do not reject.
Do not ship unchanged.
The plan is pointed at real failure.
It is small enough to implement.
But it is still mostly structural patches dressed as goal work.

The strongest plan sentence is the mission statement.
The weakest plan sentence is the last one.
The system is not simple once the watcher consumes the right primitive.
The watcher is one valve.
The orchestrator is another valve.
The mission anchor is a hidden goal.
The founder's attention is an unpriced stock.
The callback stream is a reinforcing loop.
The morning report is delayed feedback.
The repair queue is a bottleneck.
The reservation substrate is a rule system.
The pane fleet is a buffer.
These are the system.

The plan's best leverage is available.
It is not only #6 information flow.
It is #3 goal definition expressed in machine-readable status and selector rules.
It is #5 dispatch eligibility rules that prevent repeated action without state change.
It is #8 feedback loops that act during the night.
It is #4 self-organization when repeated fuckups change future selection policy.
It is #2 paradigm only if the fleet stops asking "how do we keep agents moving?"
The better paradigm asks "how does the founder's scarce attention compound outside the founder?"

If this plan ships unchanged, I expect improvement.
Same-bead loops should drop.
Some stale work should be skipped.
Some panes should recover faster.
The morning report should be clearer.
But I do not expect six-month survival.
The system will find new ways to look busy.
It will optimize the new visible metrics.
It will produce better dispatches without necessarily producing better mission closure.
It will move the bottleneck from selection to validation, from validation to mission scoring, or from mission scoring back to founder interpretation.

If revised as above, the plan becomes sturdier.
It would measure the right stock.
It would act before morning.
It would make redispatch depend on state change.
It would make mission anchors executable.
It would keep one priority source.
It would price founder attention.
It would distinguish awareness from autonomy.
That is the difference between a fleet that runs and a flywheel that learns.
