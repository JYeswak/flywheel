---
title: "01-REVIEW-donella - Watchdog Enablement"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# 01-REVIEW-donella - Watchdog Enablement

Date: 2026-05-05
Lane: Donella Meadows systems lens
Task: watchdog-3lens-review-2026-05-05
Mode: plan-space only
Verdict: revise
Composite score: 9.7 / 10
Invisible structure named: watcher-governance loop
Plan under review: `.flywheel/PLANS/watchdog-enablement-2026-05-05/00-PLAN-INPUT.md`
Output file: `.flywheel/PLANS/watchdog-enablement-2026-05-05/01-REVIEW-donella.md`

## 1. Systems Verdict

This plan is close to the correct leverage point.
It does not merely tune a threshold.
It changes who supplies the recovery loop.
That is why it matters.
The current system has a hidden stock of unrecovered frozen panes.
It also has a hidden stock of founder interruption.
The plan turns those hidden stocks into measured state.
It then routes measured state through rules, budgets, receipts, and escalation.
That is a real systems intervention.
The main weakness is that the plan models the pane-recovery loop better than it models the watcher-governance loop.
The watcher is not outside the system.
The watcher is a new actor inside the system.
It needs its own stock, flows, delays, feedback, legitimacy rules, and self-health signal.
If that structure is left implicit, the plan may recreate silent darkness with a more sophisticated detector.
The plan should therefore add a watcher-governance primitive before implementation.

## 2. Highest Leverage Diagnosis

Leverage point #12, parameters, is not where this plan wins.
The 90 second threshold is a parameter.
The 5 minute action delay is a parameter.
The per-pane hourly cap is a parameter.
Those matter, but they are not enough.
Leverage point #9, delay, matters because detection latency is currently too long.
Leverage point #8, negative feedback, matters because storm control prevents repeated recovery.
Leverage point #6, information flow, matters because frozen state and recovery receipts become visible.
Leverage point #5, rules, matters because mutation is permitted only through encoded gates.
Leverage point #4, self-organization, matters because repeated classes route into learning and future substrate.
Leverage point #3, goals, matters because the target becomes no silent darkness and recovery SLO.
Leverage point #2, paradigm, matters because founder-as-recovery-loop becomes system-as-recovery-loop.
The plan's strongest move is #2/#3/#5/#6 together.
The plan's weakest point is that #4 self-organization is still underdeveloped.
The system needs to learn from refused recoveries as carefully as from successful recoveries.
The system also needs to learn when the watcher itself becomes unreliable.
Otherwise the recovery loop can become another unobserved subsystem.

## 3. Primary Stocks

Stock S1: live dispatchable worker capacity.
Definition: worker panes that can receive, process, and complete dispatches.
Plan evidence: primary stock named at `00-PLAN-INPUT.md:224-226`.
Desired direction: increase and stabilize.
Inflow: successful launches, successful auto-recoveries, prompt re-injection, post-recovery liveness.
Outflow: frozen panes, dead-shell panes, input-deaf panes, rate-limit stalls, false respawns, watcher blind spots.
Measure: live_worker_capacity_count.
Risk: if capacity is measured only by pane existence, the stock is false.

Stock S2: hidden frozen pane burden.
Definition: frozen or deaf panes not yet classified into visible state.
Plan evidence: manual recovery evidence at `00-PLAN-INPUT.md:47-67`.
Desired direction: decrease to zero.
Inflow: CLI freezes, dead shells, queued-not-submitted failures, stale prompt buffers.
Outflow: detector classification, no-action receipt, successful recovery, protected refusal.
Measure: frozen_detected_count plus silent_dark_minutes.
Risk: false all-clear if L60 signals are missing.

Stock S3: founder interruption burden.
Definition: recovery actions that Joshua must notice, reason through, and execute.
Plan evidence: manual respawn burden at `00-PLAN-INPUT.md:20-24` and `00-PLAN-INPUT.md:53-63`.
Desired direction: zero for eligible worker panes.
Inflow: every frozen pane not autonomously handled.
Outflow: safe auto-recovery, notify-fast no-action branch, manager-loop receipt.
Measure: manual_respawn_count_7d.
Risk: notify-only reduces detection latency but preserves founder-as-recovery-loop.

Stock S4: unsafe mutation exposure.
Definition: probability mass of pane mutations that should not happen.
Plan evidence: W2 denies protected sessions and special panes at `00-PLAN-INPUT.md:138-147`.
Desired direction: zero.
Inflow: broad classifier, stale truth, missing permit, hidden apply switch, ambiguous pane type.
Outflow: W0 eligibility, W2 permit, L60 preflight, STOP/FATAL files, budgets.
Measure: false_positive_respawn_count_7d and protected_session_auto_apply_count.
Risk: one hidden bypass can erase trust in the whole loop.

Stock S5: recovery receipts.
Definition: durable rows proving decisions and outcomes.
Plan evidence: W5 receipt loop at `00-PLAN-INPUT.md:180-191`.
Desired direction: 100 percent coverage, not infinite volume.
Inflow: every recovery and every refusal.
Outflow: manager-loop aggregation, learning substrate, audits, bead updates in later non-plan tasks.
Measure: recovery_receipt_coverage.
Risk: success receipts without no-action receipts bias learning toward actions only.

Stock S6: watcher legitimacy.
Definition: justified authority of the watchdog to mutate panes.
Plan evidence: current plan implies this through gates but does not name it.
Desired direction: high when evidence is fresh, low when evidence is stale.
Inflow: clean dry-run cycles, zero false positives, live driver proof, clear refusals, successful canary.
Outflow: false recovery, unknown recovery, degraded-truth action, stale driver, missing receipt.
Measure: watchdog_driver_verified, watchdog_last_fire_ts, false_positive_count_24h.
Risk: legitimacy is invisible until it fails.

Stock S7: recovery storm pressure.
Definition: accumulated tendency to repeatedly respawn a pane or session.
Plan evidence: W6 caps recovery at `00-PLAN-INPUT.md:193-205`.
Desired direction: damped.
Inflow: repeated freeze class, flaky CLI, bad prompt relaunch, upstream outage, bad classifier.
Outflow: same-pane suppression, global budget, escalation, learning loop.
Measure: same_pane_second_respawn_1h and recoveries_per_session_hour.
Risk: if repeated failures stay local, the system churns instead of learns.

## 4. Flow Audit For W1 - Detector / Classifier

Primitive: W1.
Plan line: `00-PLAN-INPUT.md:124-136`.
Main leverage point: #6 information flow.
Stock impacted: hidden frozen pane burden.
Inflow before W1: panes become frozen without visible classification.
Outflow after W1: hidden frozen state becomes FROZEN, WATCH, UNKNOWN, queued-not-submitted, post-completion, or no-action state.
Good structure: only FROZEN may trigger respawn.
Good structure: UNKNOWN and WATCH are not action classes.
Good structure: live truth requires source health and fresh capture.
Weak structure: W1 should explicitly require L60 signals before action.
Weak structure: W1 should output refusal receipts for non-FROZEN classes.
Intervention: add W0 eligibility before W1 action.
Measure: classification_coverage_pct.
Measure: unknown_auto_recovery_count_7d.
Measure: stale_capture_refusal_count_24h.

## 5. Flow Audit For W2 - Permit Gate

Primitive: W2.
Plan line: `00-PLAN-INPUT.md:138-147`.
Main leverage point: #5 rules.
Stock impacted: unsafe mutation exposure.
Inflow before W2: candidate pane actions from detector.
Outflow after W2: permitted worker actions and refused protected/special panes.
Good structure: pane 0, human, callback, self-orch, and protected sessions default deny.
Good structure: peer-orch stays on a separate permit track.
Weak structure: permit results should be receipts, not silent branch returns.
Weak structure: protected refusals should aggregate into manager-loop top-10 if repeated.
Intervention: emit `permit_decision`, `refusal_reason`, and `next_safe_action`.
Measure: permit_refusal_count_24h.
Measure: protected_session_auto_apply_count.
Measure: self_orch_refusal_count_24h.

## 6. Flow Audit For W3 - Threshold / Debounce

Primitive: W3.
Plan line: `00-PLAN-INPUT.md:149-156`.
Main leverage point: #9 delays.
Stock impacted: recovery latency.
Inflow before W3: classified candidate freezes.
Outflow after W3: observed, logged, or eligible-to-act candidates.
Good structure: thresholds are named.
Good structure: existing defaults are already much faster than overnight human detection.
Weak structure: detection threshold and action threshold are conflated.
Weak structure: day-one action is unresolved.
Intervention: use 90s detect/log and 5m action for first canary.
Measure: detection_latency_p95_s.
Measure: action_latency_p95_s.
Measure: false_positive_by_threshold_count.

## 7. Flow Audit For W4 - Execution And Prompt Re-Injection

Primitive: W4.
Plan line: `00-PLAN-INPUT.md:158-178`.
Main leverage point: #10 structure.
Stock impacted: dead worker slots.
Inflow before W4: eligible frozen pane.
Outflow after W4: restarted shell, relaunched agent, re-injected prompt, re-probed pane.
Good structure: preferred executor is `ntm --robot-restart-pane`.
Good structure: `ntm respawn` is fallback, not primary.
Good structure: broad health restart is excluded.
Weak structure: prompt source hierarchy is not defined.
Weak structure: a restart without prompt provenance can resume wrong work or no work.
Intervention: define prompt source order from dispatch receipt, bead assignment, and fallback safety prompt.
Measure: prompt_reinjection_success_rate.
Measure: post_recovery_work_started_count.
Measure: wrong_resume_detected_count.

## 8. Flow Audit For W5 - Receipt / Learning Loop

Primitive: W5.
Plan line: `00-PLAN-INPUT.md:180-191`.
Main leverage point: #6 information flow and #4 self-organization.
Stock impacted: recovery receipts.
Inflow before W5: actions and refusals that could vanish.
Outflow after W5: durable rows for manager-loop, audits, and future learning.
Good structure: receipt fields are named.
Good structure: detector already writes useful recovery rows.
Weak structure: no-action receipts need equal emphasis.
Weak structure: manager-loop consumer schema is not named.
Intervention: require one row for every decision, not only every mutation.
Measure: recovery_receipt_coverage.
Measure: no_action_receipt_coverage.
Measure: manager_loop_consumed_receipt_count.

## 9. Flow Audit For W6 - Backoff / Storm Control

Primitive: W6.
Plan line: `00-PLAN-INPUT.md:193-205`.
Main leverage point: #8 negative feedback.
Stock impacted: recovery storm pressure.
Inflow before W6: repeated recovery candidates.
Outflow after W6: one permitted recovery, then suppression and escalation.
Good structure: one per pane per hour and four per session per hour.
Good structure: rate-limit and quota do not respawn.
Weak structure: rate-limit and quota should route to a named wait/account branch.
Weak structure: second same-pane event should trigger learning, not only escalation.
Intervention: add non-recovery class receipts and storm root-cause rollup.
Measure: same_pane_second_respawn_1h.
Measure: budget_exhausted_count_24h.
Measure: storm_root_cause_class_count.

## 10. Flow Audit For W7 - Escalation And Watcher Self-Health

Primitive: W7.
Plan line: `00-PLAN-INPUT.md:207-221`.
Main leverage point: #4 self-organization.
Stock impacted: unresolved failures and watcher legitimacy.
Inflow before W7: failed verifications, repeated suppressions, protected requests, degraded truth, watchdog silence.
Outflow after W7: manager-loop alert, learning row, future bead in non-plan tasks, tool improvement.
Good structure: watchdog itself stopping is named.
Good structure: repeated suppression and failed recovery escalate.
Weak structure: self-health is not yet a first-class state stock.
Weak structure: watchdog silence should be measured by driver proof, not only launchd presence.
Intervention: add `watchdog_last_fire_ts`, `watchdog_driver_verified`, `watchdog_apply_enabled`, and `watchdog_last_exit_status`.
Measure: watchdog_driver_freshness_s.
Measure: watchdog_marker_only_count.
Measure: watchdog_silent_dark_minutes.

## 11. Feedback Loop Topology

Loop B1: worker recovery balancing loop.
Trigger: frozen pane increases hidden frozen burden.
Sensor: frozen-pane detector.
Decision: eligibility and permit gates.
Action: restart, relaunch, prompt, reprobe.
Effect: live dispatchable worker capacity rises.
Balancing behavior: frozen burden decreases.
Risk: if the detector is stale, B1 acts on a false signal.
Control: L60 preflight and capture provenance.

Loop B2: safety balancing loop.
Trigger: recovery candidates increase unsafe mutation exposure.
Sensor: permit gate, protected-session list, pane role classification.
Decision: default deny for special panes and protected sessions.
Action: no-action receipt or manager-loop escalation.
Effect: unsafe mutation exposure decreases.
Balancing behavior: safety is preserved.
Risk: if refusals are silent, the founder still becomes the loop.
Control: notify-fast no-action branch.

Loop B3: storm-control balancing loop.
Trigger: repeated recovery of same pane or session.
Sensor: per-pane and global hourly budgets.
Decision: suppress second same-pane respawn and global over-budget action.
Action: escalation, learning row, future fix.
Effect: repeated respawn pressure decreases.
Balancing behavior: storm is damped.
Risk: if only suppressed, the root cause can persist.
Control: root-cause rollup and learning path.

Loop R1: learning reinforcing loop.
Trigger: receipts accumulate.
Sensor: manager-loop and audit queries.
Decision: repeated classes become plan/bead/tool changes in later tasks.
Action: classifier fixtures, permit changes, doctrine updates.
Effect: future classifications improve.
Reinforcing behavior: better receipts produce better classifiers, which produce safer receipts.
Risk: if receipts omit no-action branches, learning is biased.
Control: no-action receipt coverage.

Loop R2: dangerous trust reinforcing loop.
Trigger: early auto-recoveries appear successful.
Sensor: operator confidence, not enough false-positive instrumentation.
Decision: expand apply too quickly.
Action: more panes touched.
Effect: more invisible risk and possible false respawns.
Reinforcing behavior: trust grows faster than evidence.
Risk: this loop can destroy the system's legitimacy.
Control: canary acceptance, zero false positives, action threshold policy.

Loop B4: watcher-governance balancing loop.
Trigger: watchdog legitimacy rises or falls.
Sensor: last fire, driver proof, exit status, false positives, unknown recovery.
Decision: enable, keep dry-run, suppress, or rollback.
Action: apply gate state changes.
Effect: watchdog authority adjusts to evidence quality.
Balancing behavior: authority is proportional to proof.
Risk: this loop is missing if the plan treats the watcher as external.
Control: make watcher-governance an explicit primitive.

## 12. Invisible Structure The Plan Misses

The invisible structure is the watcher-governance loop.
The plan models the worker pane as a stock.
The plan models recovery as a transaction.
The plan models budget as negative feedback.
The plan models receipts as information flow.
But the watcher itself has authority.
Authority is a stock.
Authority has inflows and outflows.
Authority should rise only with clean evidence.
Authority should fall immediately with false recovery, unknown action, stale driver, or missing receipt.
If authority is not modeled, the system will treat `watchdog installed` as `watchdog legitimate`.
That is the same category as L57 marker-only loops.
A disabled LaunchAgent is not a driver.
A stale driver is not a working watcher.
An observing watcher is not an authorized applier.
A canary applier is not a fleet applier.
Those distinctions need to be state, not prose.

## 13. Watcher-Governance Stock And Flow Model

Stock WG1: watcher authority.
Inflow: clean dry-run cycles.
Inflow: successful canary apply.
Inflow: zero false positives over defined window.
Inflow: manager-loop can consume receipts.
Inflow: rollback tested.
Outflow: false positive.
Outflow: unknown recovery.
Outflow: degraded-truth apply.
Outflow: missing driver proof.
Outflow: missing no-action receipts.
Outflow: budget exhaustion.
Measure: watcher_authority_state.
Allowed values: disabled, observe, canary_apply, worker_apply, peer_orch_dry_run, peer_orch_apply.
Initial value: observe.
Forbidden transition: disabled to worker_apply.
Forbidden transition: observe to peer_orch_apply.
Forbidden transition: canary_apply to fleet_apply without zero false positives.

Stock WG2: watcher evidence.
Inflow: dry-run rows, fixture passes, recovery ledgers, no-action receipts, manager-loop reads.
Outflow: stale rows, rejected receipts, unconsumed ledgers, missing cycle fires.
Measure: evidence_freshness_s and evidence_completeness_pct.
Rule: stale evidence cannot authorize fresh mutation.

Stock WG3: watcher debt.
Inflow: every unresolved yellow condition.
Inflow: every manual respawn after watchdog is enabled.
Inflow: every refused recovery without next safe action.
Outflow: plan revision, implementation fix, future bead, doctrine update.
Measure: watchdog_debt_count.
Rule: rising debt means the intervention is not complete.

## 14. Leverage Point Mapping Per Primitive

W0 eligibility preflight: leverage point #5 rules and #6 information flow.
W0 reason: it turns implicit safety assumptions into explicit decision fields.
W0 risk if absent: the system depends on operator memory.
W1 detector: leverage point #6 information flow.
W1 reason: hidden frozen panes become classified facts.
W1 risk if weak: stale or unknown state is mistaken for frozen state.
W2 permit gate: leverage point #5 rules.
W2 reason: it defines who may be touched and under what conditions.
W2 risk if weak: protected and special panes enter mutation path.
W3 thresholds: leverage point #9 delays and #12 parameters.
W3 reason: it bounds detection and action latency.
W3 risk if overemphasized: parameter fiddling replaces structural repair.
W4 execution: leverage point #10 structure.
W4 reason: six manual steps become one transaction.
W4 risk if weak: shell restarts without agent relaunch or prompt.
W5 receipts: leverage point #6 information flow and #4 self-organization.
W5 reason: events become learning substrate.
W5 risk if weak: silent recoveries and silent refusals.
W6 backoff: leverage point #8 negative feedback.
W6 reason: repeated failures are damped.
W6 risk if weak: respawn storms.
W7 escalation: leverage point #4 self-organization.
W7 reason: repeated classes route upward into new structure.
W7 risk if weak: the same blocker recurs forever.
Watcher-governance: leverage point #3 goals, #5 rules, and #6 information flow.
Watcher-governance reason: the watchdog's authority must be tied to evidence, not existence.

## 15. Anti-Patterns Avoided

Avoided anti-pattern: reminder substitution.
The plan does not ask Joshua to remember panes.
Avoided anti-pattern: human-as-feedback-loop.
The plan removes Joshua from eligible worker recovery.
Avoided anti-pattern: parameter thrashing.
The plan treats thresholds as necessary but not sufficient.
Avoided anti-pattern: source laundering.
The plan cites code and research inputs.
Avoided anti-pattern: unconstrained automation.
The plan keeps protected sessions denied and peer-orch separate.
Avoided anti-pattern: novelty build.
The plan composes existing primitives.

## 16. Anti-Patterns Still At Risk

Risk anti-pattern: leverage theater.
If the plan says paradigm shift but only changes thresholds, it fails.
Control: add W0, state machine, and watcher-governance.
Risk anti-pattern: marker-only driver.
If LaunchAgent state is treated as watcher health, it fails.
Control: require `watchdog_last_fire_ts` and driver proof.
Risk anti-pattern: silent no-action.
If refused recoveries do not emit receipts, founder burden persists.
Control: no-action receipt coverage.
Risk anti-pattern: over-trust from early success.
If one successful canary expands to fleet apply, R2 dangerous trust loop starts.
Control: 24h dry-run, count minimums, zero false positives.
Risk anti-pattern: local optimization.
If the watchdog optimizes respawns while mission/manager loops cannot consume receipts, the larger system does not improve.
Control: manager-loop consumer contract.
Risk anti-pattern: broad classifier shortcut.
If `ntm health --auto-restart-stuck` becomes production authority, too many states are collapsed into restart.
Control: keep frozen-pane detector as authority.

## 17. Recommended Plan Revisions

Revision D01: add W0 eligibility preflight.
Why: it makes safety state explicit before classification can mutate.
Leverage point: #5 rules.
Stock protected: unsafe mutation exposure.
Measure: refusal_reason coverage.

Revision D02: split detection and action thresholds.
Why: fast sensing and conservative mutation are different functions.
Leverage point: #9 delays.
Stock protected: watcher legitimacy.
Measure: detection_latency_p95_s and action_latency_p95_s.

Revision D03: add watcher-governance loop.
Why: the watcher has authority and can itself fail.
Leverage point: #3 goals and #6 information flow.
Stock protected: watcher legitimacy.
Measure: watchdog_driver_verified and watcher_authority_state.

Revision D04: require L60 before apply.
Why: frozen pane detection is an input, not the system health contract.
Leverage point: #3 goals.
Stock protected: live dispatchable worker capacity.
Measure: L60_signals_present.

Revision D05: require no-action receipts.
Why: refusals are part of the feedback loop.
Leverage point: #6 information flow.
Stock protected: recovery receipts.
Measure: no_action_receipt_coverage.

Revision D06: define manager-loop consumer contract.
Why: information flow has not completed until a consumer can use it.
Leverage point: #6 information flow.
Stock protected: useful recovery knowledge.
Measure: manager_loop_consumed_receipt_count.

Revision D07: require rollback proof before apply.
Why: authority must be reversible.
Leverage point: #5 rules and #8 negative feedback.
Stock protected: unsafe mutation exposure.
Measure: rollback_probe_passed.

Revision D08: define canary promotion and demotion.
Why: authority should rise and fall with evidence.
Leverage point: #4 self-organization.
Stock protected: watcher legitimacy.
Measure: watcher_authority_state.

Revision D09: define rate-limit wait branch.
Why: not all non-work is failure.
Leverage point: #6 information flow.
Stock protected: recovery storm pressure.
Measure: rate_limit_no_restart_count.

Revision D10: define prompt provenance.
Why: restart without correct prompt can create a live pane doing wrong work.
Leverage point: #10 structure.
Stock protected: live dispatchable worker capacity.
Measure: prompt_provenance_present_pct.

Revision D11: treat false-positive count as a demotion signal.
Why: feedback must reduce authority after harm.
Leverage point: #8 negative feedback.
Stock protected: watcher legitimacy.
Measure: false_positive_respawn_count_24h.

Revision D12: treat watchdog silence as a recovery failure.
Why: a silent watcher is part of silent darkness.
Leverage point: #3 goal.
Stock protected: live dispatchable worker capacity.
Measure: watchdog_silent_dark_minutes.

## 18. Diff-Style Inserts

```diff
+### W0 - Watchdog eligibility preflight
+Every detector cycle computes `watchdog_eligibility` before any action path.
+Mutation requires source_health=healthy, L60_signals_present=5/5,
+live capture provenance, fresh capture timestamp, target_kind=worker,
+not pane0, not human, not callback, not self-orchestrator, not protected,
+budget_ok=true, cooldown_ok=true, and class=FROZEN.
+Every refusal emits a no-action receipt.
```

```diff
+### Watcher-governance loop
+The watcher has authority states: disabled, observe, canary_apply,
+worker_apply, peer_orch_dry_run, peer_orch_apply.
+Authority rises only through clean evidence and falls immediately on
+false positive, unknown recovery, degraded-truth apply, stale driver,
+missing receipt, or budget exhaustion.
```

```diff
-Review-lane choice: 90s action immediately, or 90s log / 5m act for day one.
+Decision: 90s detect/log and 5m act for first apply canary.
+Do not reduce action delay until 24h dry-run, one worker canary,
+zero false positives, zero unknown recoveries, and rollback proof pass.
```

```diff
+No-action receipt fields:
+session, pane, class, source_health, L60_signals_present,
+recovery_allowed=false, refusal_reason, snapshot_or_sample_path,
+next_safe_action, escalation_target, and emitted_at.
```

```diff
+Manager-loop watchdog summary fields:
+watchdog_last_fire_ts, watchdog_driver_verified, watcher_authority_state,
+frozen_detected_count_24h, auto_respawn_success_rate,
+false_positive_respawn_count_24h, unknown_recovery_count_24h,
+protected_apply_count_24h, same_pane_second_respawn_1h,
+and detector_cycle_freshness_p95_s.
```

## 19. Measurement Loop Requirements

Measure M01: manual_respawn_count_7d.
Target: zero for eligible worker panes.
Failure meaning: founder remains the recovery loop.
Measure M02: frozen_pane_MTTR_p95.
Target: <= 180 seconds after canary threshold is tightened.
Failure meaning: detection/action delay is still too slow.
Measure M03: auto_respawn_success_rate.
Target: >= 95 percent after dry-run.
Failure meaning: execution transaction is unreliable.
Measure M04: false_positive_respawn_count_7d.
Target: zero.
Failure meaning: authority must demote.
Measure M05: unknown_auto_recovery_count_7d.
Target: zero.
Failure meaning: L60 or classifier gate failed.
Measure M06: protected_session_auto_apply_count.
Target: zero unless explicit encoded permit.
Failure meaning: permit gate failed.
Measure M07: recovery_receipt_coverage.
Target: 100 percent.
Failure meaning: learning loop is broken.
Measure M08: no_action_receipt_coverage.
Target: 100 percent.
Failure meaning: refusals are invisible.
Measure M09: watchdog_driver_verified.
Target: true before apply.
Failure meaning: marker-only risk.
Measure M10: detector_cycle_freshness.
Target: <= 2 cadence windows.
Failure meaning: watcher may be stale.
Measure M11: watcher_authority_state.
Target: explicit.
Failure meaning: apply state is hidden in prose or env.
Measure M12: manager_loop_consumed_receipt_count.
Target: >0 before broad apply.
Failure meaning: receipts are producer-only.

## 20. Revised Verdict Thresholds

Green condition 01: W0 eligibility exists.
Green condition 02: L60 preflight is required for mutation.
Green condition 03: 24h dry-run receipts exist.
Green condition 04: at least 20 dry-run cycles exist.
Green condition 05: no degraded-truth apply exists.
Green condition 06: no unknown recovery exists.
Green condition 07: no protected-session apply exists.
Green condition 08: manager-loop can read watchdog metrics.
Green condition 09: rollback has been tested.
Green condition 10: worker apply canary succeeds with post-probe.
Yellow condition 01: detector works but watcher freshness is not manager-loop visible.
Yellow condition 02: threshold choice remains open.
Yellow condition 03: no-action receipts are missing non-core fields.
Yellow condition 04: peer-orch dry-run emits refusals but no apply.
Yellow condition 05: prompt provenance is generic.
Red condition 01: apply can touch pane 0.
Red condition 02: apply can touch human pane.
Red condition 03: apply can touch callback pane.
Red condition 04: apply can touch protected session without encoded permit.
Red condition 05: UNKNOWN can recover.
Red condition 06: WATCH can recover.
Red condition 07: template prompt can recover.
Red condition 08: post-completion buffer can recover.
Red condition 09: degraded truth can apply.
Red condition 10: same pane can respawn twice inside one hour.
Red condition 11: mutation lacks snapshot.
Red condition 12: mutation lacks receipt.
Red condition 13: watcher authority is implied rather than stateful.

## 21. Donella Close

The plan's deepest insight is correct.
The system should not ask the founder to be a balancing loop.
The system should balance itself.
But the moment the watchdog can mutate panes, the watchdog becomes a powerful subsystem.
Power needs feedback.
Feedback needs measures.
Measures need consumers.
Consumers need rules.
Rules need rollback.
That is the full structure.
The plan has most of it.
It needs the watcher-governance loop made explicit.
It needs thresholds separated.
It needs L60 lifted into the action gate.
It needs no-action receipts.
It needs manager-loop consumption.
It needs authority states.
With those revisions, this is a high-leverage plan.
Without them, it risks becoming parameter tuning with a launchd wrapper.
Composite score: 9.7.
Verdict: revise.
Recommended first revision phrase: "Add W0 eligibility and watcher-governance before W1."
Recommended rollout phrase: "90s sense, 5m act, one worker canary, then evidence-based tightening."
Recommended invisible structure label: watcher-governance loop.
