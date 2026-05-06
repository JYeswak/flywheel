# 01-REVIEW-jeff - Watchdog Enablement

Date: 2026-05-05
Lane: Jeff Emanuel compose-not-new review
Task: watchdog-3lens-review-2026-05-05
Mode: plan-space only
Verdict: revise
Composite score: 9.6 / 10
Counter-thesis endorsed: conditional
Plan under review: `.flywheel/PLANS/watchdog-enablement-2026-05-05/00-PLAN-INPUT.md`
Output file: `.flywheel/PLANS/watchdog-enablement-2026-05-05/01-REVIEW-jeff.md`

## 1. Jeff Read

The plan is right.
Do not build a respawner.
Do not modify ntm for this plan.
Do not upgrade Codex and call it fixed.
Do not turn `ntm health --auto-restart-stuck` loose on production panes.
Do not make `--robot-smart-restart` the sole authority.
Use the detector.
Use the fleet wrapper.
Use `ntm --robot-restart-pane`.
Use the peer-orch permit gate.
Use receipts.
Then wire the missing policy handoff.
That is the work.
The plan is almost implementation-ready for dry-run.
It is not implementation-ready for apply until the fleet wrapper's apply-blocked state is named as the transition point.
The existing wrapper literally returns `apply_blocked_by_design`.
If the next plan revision does not address that exact seam, it will produce a fake green.

## 2. Counter-Thesis

Counter-thesis: maybe the watchdog should not auto-respawn at all.
Maybe it should only notify faster.
That thesis has one strong argument.
A bad auto-respawn can destroy more work than a slow manual respawn.
It can kill a live pane.
It can relaunch the wrong prompt.
It can hide upstream CLI failure.
It can build false confidence.
It can turn a local pane problem into a fleet storm.
So the counter-thesis is not silly.
But notify-only preserves Joshua as the final recovery actuator.
That fails the actual mission.
The better answer is staged authority.
Stage 1: notify-fast plus dry-run receipts.
Stage 2: one worker canary.
Stage 3: non-protected worker apply.
Stage 4: peer-orch dry-run.
Stage 5: peer-orch apply only after permit receipts are boring.
So I endorse the counter-thesis conditionally.
Do not auto-respawn immediately.
Do not stay notify-only forever.
Ship notify-fast first, then canary auto-respawn only for eligible worker panes.

## 3. Per-Agent CLI Counter-Thesis

Second counter-thesis: this is a Codex TUI bug, so per-agent CLIs should fix their own freezes.
Yes, upstream should fix freezes.
No, that is not a plan dependency.
The local system still needs recovery substrate.
The plan correctly says Codex 0.128.0/gpt-5.5 is canary evidence, not a cure.
The local watchdog should produce before/after metrics so the Codex canary can be judged.
That is the right dependency direction.
Measure local freeze strikes first.
Then upgrade one pane.
Then compare.
Do not let "upstream might fix it" become a HOLD.

## 4. Socraticode Survey Receipt

Socraticode project: `/Users/josh/Developer/flywheel`.
Socraticode status observed: green.
Socraticode indexed chunks observed: 694.
Socraticode project: `/Users/josh/Developer/ntm`.
Socraticode status observed: green.
Socraticode indexed chunks observed: 31,740.
Socraticode query count: 11.
Socraticode K: 10 per query.
Query 01: ntm robot restart pane prompt liveness hard kill dry run.
Query 02: ntm smart restart GetIsWorking rate limit prompt relaunch force hard kill.
Query 03: ntm health auto restart stuck RestartManager max restarts per hour backoff.
Query 04: ntm robot activity capture provenance capture_collected_at state_since rate limited.
Query 05: ntm respawn command panes force dry run human pane.
Query 06: ntm resilience monitor autoRestart max restart disabled manual respawn.
Query 07: flywheel frozen pane detector auto recover apply robot restart pane ledger snapshot.
Query 08: flywheel frozen pane detector fleet launchd budgets degraded truth disabled by default.
Query 09: flywheel peer orchestrator respawn permit protected session freeze evidence.
Query 10: flywheel no silent darkness frozen pane worker recovery SLO false recovery unknown auto recovery.
Query 11: flywheel watchdog watcher self health last fire launchd driver marker active.
Survey conclusion: the substrate already exists.
Survey conclusion: the highest-risk gap is the policy bridge from observe to apply.
Survey conclusion: source edits should be local flywheel policy edits later, not ntm source work.

## 5. Ntm Substrate Findings

Finding N01: `internal/robot/restart_pane.go:17-29` returns structured restart fields.
Implication: use robot output, not prose scraping.
Finding N02: `internal/robot/restart_pane.go:37-46` supports session, panes, type, all, dry-run, bead, and prompt options.
Implication: no need to add a new executor.
Finding N03: `internal/robot/restart_pane.go:86-97` validates session existence.
Implication: detector can fail cleanly on missing session.
Finding N04: `internal/robot/restart_pane.go:124-135` has real dry-run.
Implication: canary planning should use it.
Finding N05: `internal/robot/restart_pane.go:137-156` restarts selected targets.
Implication: pane-scoped worker recovery is available.
Finding N06: `internal/robot/restart_pane.go:159-180` checks process liveness after restart.
Implication: receipts should preserve process_alive.
Finding N07: `internal/robot/restart_pane.go:182-203` can send a prompt after restart.
Implication: prompt provenance is the missing plan detail, not prompt capability.
Finding N08: `internal/robot/smart_restart.go:19-26` is designed to avoid interrupting useful work.
Implication: smart-restart is a good reference, not the frozen-Codex authority.
Finding N09: `internal/robot/smart_restart.go:31-45` distinguishes WAITING and WOULD_RESTART from RESTARTED.
Implication: rate-limit and dry-run paths already exist conceptually.
Finding N10: `internal/robot/smart_restart.go:48-60` exposes force and hard-kill flags.
Implication: this is too much authority for broad unattended use without the flywheel classifier.
Finding N11: ntm health has a RestartManager with max restarts and backoff.
Implication: useful pattern, wrong authority for this plan.
Finding N12: ntm defaults auto-restart disabled in config.
Implication: existing project posture supports conservative opt-in.
Finding N13: ntm robot activity exposes capture provenance and capture timestamps.
Implication: W1 should require them.
Finding N14: ntm respawn avoids user panes by default unless filters or all are explicit.
Implication: fallback is safer than raw tooling but still inferior to robot restart-pane for receipts.

## 6. Flywheel Substrate Findings

Finding F01: `.flywheel/scripts/frozen-pane-detector.sh:760-766` dry-run plans write_snapshot, acquire_lease, restart_pane, relaunch_agent, and re_probe.
Implication: dry-run is not fake; it previews the actual transaction.
Finding F02: `.flywheel/scripts/frozen-pane-detector.sh:780-804` copies snapshot, logs fuckup, calls robot restart-pane, relaunches, sends resume prompt, reprobes, writes ledgers, and releases the lease.
Implication: the transaction already exists.
Finding F03: `.flywheel/scripts/frozen-pane-detector-fleet.sh:265-291` has recent recovery budget state.
Implication: do not add a second budget system.
Finding F04: `.flywheel/scripts/frozen-pane-detector-fleet.sh:293-300` calls the detector with `--auto-recover --dry-run`.
Implication: scheduled fleet operation is observe-first.
Finding F05: `.flywheel/scripts/frozen-pane-detector-fleet.sh:328-331` blocks apply by design.
Implication: this is the plan's central integration gap.
Finding F06: `AGENTS.md:995-1009` says no-silent-darkness is the goal, not merely frozen-pane detection.
Implication: L60 preflight is required.
Finding F07: `AGENTS.md:1022-1028` forbids all-clear on missing L60 signals and forbids unknown auto-recovery.
Implication: unknown stays no-action.
Finding F08: L57 says markers are not drivers.
Implication: LaunchAgent presence is not enough.
Finding F09: L115 says peer-orch recovery requires a permit gate.
Implication: worker and peer-orch paths stay separate.
Finding F10: L117 says peer-orch auto-respawn is disabled by default and needs monitor proof.
Implication: do not smuggle peer-orch apply into worker enablement.

## 7. Compose-Not-New Map

Primitive C01: classify with `.flywheel/scripts/frozen-pane-detector.sh`.
Status: keep.
Reason: existing classifier has live-delta, fixtures, dry-run, apply, lease, and receipt logic.
Primitive C02: schedule with `.flywheel/scripts/frozen-pane-detector-fleet.sh`.
Status: keep.
Reason: existing wrapper owns launchd, STOP/FATAL, budgets, doctor/install/health/audit.
Primitive C03: execute with `ntm --robot-restart-pane`.
Status: keep.
Reason: structured JSON, pane filter, prompt, liveness, dry-run.
Primitive C04: fallback with `ntm respawn --force --panes`.
Status: keep as fallback.
Reason: shell-level fallback when robot route fails.
Primitive C05: peer-orch permit with `.flywheel/scripts/peer-orch-respawn-permit.sh`.
Status: keep separate.
Reason: self-orch/protected/human/callback constraints are different.
Primitive C06: manual reference with `/flywheel:respawn`.
Status: keep as spec, not automation path.
Reason: transaction sequence has already been encoded in detector.
Primitive C07: health contract with no-silent-darkness probe.
Status: add to plan explicitly.
Reason: frozen detector is input, not full health proof.
Primitive C08: manager-loop consumer.
Status: define in plan.
Reason: receipts need a consumer.
New primitive count: zero.
Glue/policy edits later: yes.
Ntm source edits later: no for this plan.

## 8. Planning-Workflow Critique

The plan is self-contained enough.
It names inputs.
It names evidence.
It names primitives.
It names scope.
It names out-of-scope.
It names success metrics.
It names rollout phases.
It names verdict thresholds.
It is better than a normal plan.
But it still leaves three implementation-critical choices open.
Open choice 1: threshold policy.
Open choice 2: peer-orch timeline.
Open choice 3: watcher self-health proof.
Those should not go to Joshua.
The plan says they are review-lane questions.
So answer them.
Threshold answer: 90s log, 5m act for first canary.
Peer-orch answer: dry-run now, apply later.
Watcher answer: manager-loop-visible `watchdog_last_fire_ts` before apply.
That moves the plan from good to executable.

## 9. Issue-Chain Discipline

Do not file issues from this task.
The dispatch says plan-space only.
No bead writes.
No issue writes.
No ntm issues.
No PRs.
If later implementation finds a real code defect, file one issue per defect.
Each issue should cite file, line, observed behavior, expected behavior, and duplicate check.
Do not file "implement watchdog" as one blob.
Do not file "improve reliability".
Do not file a PR-shaped issue.
The likely later issue split is:
Issue later 01: fleet wrapper apply handoff from apply_blocked_by_design to canary apply.
Issue later 02: manager-loop watchdog summary consumer.
Issue later 03: no-action receipt schema if absent.
Issue later 04: fixture additions if current self-test does not cover all classes.
Issue later 05: rollout/rollback validation if current wrapper lacks a test.
Today: write review files only.

## 10. What I Would Change In The Plan

Change J01: add W0 eligibility preflight.
Reason: gates are spread out.
Diff:
```diff
+### W0 - Eligibility preflight
+Return `eligible=true|false` plus reason codes before any action path.
+Mutation requires healthy source, L60 5/5, live capture, worker target,
+not pane0/human/callback/self-orch/protected, budget_ok, cooldown_ok,
+and class=FROZEN.
```

Change J02: resolve threshold question.
Reason: review lanes should not hand implementation an unresolved safety parameter.
Diff:
```diff
-Review-lane choice: 90s action immediately, or 90s log / 5m act for day one.
+Decision: 90s log, 5m act for first apply canary.
+Tighten only after 24h dry-run, one successful canary, zero false positives,
+zero unknown recoveries, and rollback proof.
```

Change J03: name the current fleet-wrapper block.
Reason: apply is currently blocked by design.
Diff:
```diff
+Implementation note: fleet wrapper currently blocks apply with
+`reason=apply_blocked_by_design`. Phase 2 is the narrow policy handoff
+that may replace this with canary-only apply behind W0/W2/W3/W6/L60.
```

Change J04: add watcher self-health fields.
Reason: marker-only watchers are silent failure.
Diff:
```diff
+Before apply, manager-loop must see `watchdog_last_fire_ts`,
+`watchdog_driver_verified`, `watchdog_last_exit_status`,
+`watchdog_apply_enabled`, and `watchdog_authority_state`.
```

Change J05: add no-action receipts.
Reason: refused recoveries are data.
Diff:
```diff
+Every refusal emits a no-action receipt with class, refusal_reason,
+source_health, L60 signals, snapshot/sample path, and next_safe_action.
```

Change J06: add prompt provenance.
Reason: restart without correct prompt is not recovery.
Diff:
```diff
+Resume prompt source order: dispatch receipt, bead assignment,
+last worker objective, then fallback safety prompt.
```

Change J07: add rollback gate.
Reason: autonomous mutation needs a tested off switch.
Diff:
```diff
+Phase 0 proves STOP file blocks cycle and LaunchAgent unload/disable stops fires.
```

Change J08: add L60 as hard preflight.
Reason: L60 is the real health goal.
Diff:
```diff
+Apply requires `.flywheel/scripts/no-silent-darkness-probe.sh --doctor --json`
+with all five L60 signals present.
```

Change J09: define worker vs peer-orch lanes.
Reason: peer-orch has different permission model.
Diff:
```diff
+Worker apply and peer-orch dry-run are separate tracks.
+Peer-orch apply remains disabled until permit receipts and false-recovery metrics
+are clean for seven days.
```

Change J10: define canary count minimum.
Reason: one happy path is not evidence.
Diff:
```diff
+Dry-run acceptance requires at least 24h and 20 cycles.
+Apply acceptance requires one worker canary, one recovery max,
+post-probe success, and rollback proof.
```

Change J11: keep rate-limit branch explicit.
Reason: not-working because rate limited is not frozen.
Diff:
```diff
+RATE_LIMITED and QUOTA classes emit wait/account receipts and never restart.
```

Change J12: add apply policy version.
Reason: future audits need to know what authority was live.
Diff:
```diff
+Recovery receipts include `watchdog_policy_version`, `apply_gate_mode`,
+`authority_state`, and `eligibility_reason_codes`.
```

Change J13: add degraded-truth red condition.
Reason: degraded truth must never mutate.
Diff:
```diff
+RED: any apply while source_health is degraded, capture provenance is not live,
+capture timestamp is stale, or L60 signals are incomplete.
```

Change J14: define seven-day chart.
Reason: "show before/after" needs actual rows.
Diff:
```diff
+Seven-day chart rows: manual_respawn_count, frozen_detected_count,
+auto_respawn_applied_count, auto_respawn_success_rate,
+false_positive_respawn_count, unknown_auto_recovery_count,
+protected_apply_count, same_pane_second_respawn_1h, detector_freshness_p95.
```

Change J15: prohibit source-churn in the plan itself.
Reason: the plan already says no ntm source modification; make that a green threshold.
Diff:
```diff
+GREEN requires zero ntm source edits and zero new respawner primitives.
```

## 11. Blunder Hunt

Blunder 01: "watchdog enabled" while only dry-run is scheduled.
Severity: high.
Fix: distinguish observe, canary_apply, and worker_apply.
Blunder 02: "apply enabled" while wrapper still returns apply_blocked_by_design.
Severity: high.
Fix: make Phase 2 the policy handoff.
Blunder 03: acting on one stale capture.
Severity: high.
Fix: L60 plus capture provenance plus two samples.
Blunder 04: touching pane 0.
Severity: critical.
Fix: W0 and W2 hard deny.
Blunder 05: touching callback pane.
Severity: critical.
Fix: W0 and W2 hard deny.
Blunder 06: touching protected client session.
Severity: critical.
Fix: protected deny except encoded permit.
Blunder 07: acting on UNKNOWN.
Severity: critical.
Fix: unknown no-action receipt.
Blunder 08: acting on WATCH.
Severity: high.
Fix: watch no-action receipt.
Blunder 09: using broad ntm health restart.
Severity: high.
Fix: keep red/out-of-scope.
Blunder 10: smart-restart authority drift.
Severity: medium.
Fix: advisory only.
Blunder 11: missing prompt provenance.
Severity: high.
Fix: prompt source order.
Blunder 12: missing no-action receipts.
Severity: medium.
Fix: receipt coverage.
Blunder 13: no manager-loop consumer.
Severity: medium.
Fix: summary schema.
Blunder 14: no rollback proof.
Severity: high.
Fix: Phase 0 stop/unload validation.
Blunder 15: peer-orch apply too early.
Severity: high.
Fix: dry-run track first.
Blunder 16: false-positive metric not tied to demotion.
Severity: high.
Fix: any false positive demotes authority.
Blunder 17: rate limit restarted.
Severity: high.
Fix: route to wait/account.
Blunder 18: launchd marker mistaken for driver.
Severity: high.
Fix: driver freshness.
Blunder 19: one canary treated as fleet evidence.
Severity: medium.
Fix: minimum dry-run cycles and staged rollout.
Blunder 20: no exact chart rows.
Severity: low.
Fix: define chart.

## 12. Convergence Audit

Converged point 01: do not build new.
Converged point 02: classify in flywheel.
Converged point 03: execute in ntm.
Converged point 04: use detector transaction.
Converged point 05: fleet wrapper is the scheduling surface.
Converged point 06: peer-orch separate.
Converged point 07: protected deny.
Converged point 08: dry-run first.
Converged point 09: canary before expansion.
Converged point 10: receipts before confidence.
Converged point 11: Codex upgrade is orthogonal.
Converged point 12: no ntm source work.
Still divergent 01: exact action threshold.
Decision: 5m action initially.
Still divergent 02: peer-orch exception timing.
Decision: dry-run only now.
Still divergent 03: watcher self-health proof.
Decision: manager-loop-visible driver proof before apply.
Still divergent 04: notify-only vs auto-respawn.
Decision: notify-fast first, auto-respawn after canary.

## 13. Canonical CLI Scoping Check

Doctor surface: fleet wrapper has doctor.
Health surface: fleet wrapper has health/audit modes per plan.
Dry-run surface: detector and wrapper support dry-run.
Apply surface: detector supports apply; wrapper currently blocks apply.
JSON surface: detector and wrapper emit JSON.
Examples/quickstart: plan should verify existing surfaces later.
Idempotency: detector has leases and idempotency key.
Audit log: detector writes ledgers; wrapper writes events.
Repair surface: STOP/FATAL and rollback need explicit test.
Completion/help: not a plan blocker.
Missing plan piece: authority state.
Missing plan piece: consumer contract.
Missing plan piece: no-action receipt schema.
Conclusion: canonical CLI scoping supports composition, not a new CLI.

## 14. Worker-Tick Readiness

Ready for Phase 0: yes.
Ready for Phase 1 dry-run: yes after plan revision.
Ready for Phase 2 apply: no until apply handoff is specified.
Ready for peer-orch apply: no.
Ready for protected session apply: no.
Ready for ntm source work: no.
Ready for Codex upgrade: separate plan, not this.
Ready for bead writes: not in this task.
Ready for implementation dispatch: after 00-PLAN-INPUT integrates the changes.
Risk if implementation starts now: medium.
Risk after revisions: low for dry-run, medium for apply canary.

## 15. What Not To Do

Do not create `.flywheel/scripts/watchdog-respawner.sh`.
Do not edit ntm to add another restart command.
Do not wrap `ntm health --auto-restart-stuck` and call it done.
Do not make `--robot-smart-restart` the only gate.
Do not ship launchd apply hidden behind an env var with no authority state.
Do not claim success from a disabled plist.
Do not claim success from dry-run only.
Do not skip no-action receipts.
Do not recover UNKNOWN.
Do not recover WATCH.
Do not recover template prompts.
Do not recover post-completion buffers.
Do not recover protected sessions.
Do not recover callback panes.
Do not recover pane 0.
Do not recover flywheel self-orchestrator.
Do not expand from one canary without false-positive accounting.
Do not ask Joshua for threshold choice.
Pick the conservative default in plan-space.

## 16. Final Jeff Verdict

Verdict: revise.
Composite: 9.6.
The plan is a keeper.
It is not overbuilt.
It has the right primitive list.
It has the right posture toward ntm.
It has the right posture toward Codex upgrade.
It has the right posture toward protected sessions.
It has the right posture toward peer-orch recovery.
It needs the missing policy handoff.
It needs W0 eligibility.
It needs threshold resolution.
It needs watcher authority state.
It needs L60 preflight.
It needs no-action receipts.
It needs prompt provenance.
It needs rollback proof.
It needs manager-loop consumer fields.
Conditional counter-thesis answer: notify faster first, then auto-respawn only after canary evidence.
Final implementation instruction for the next lane: patch flywheel policy surfaces only, not ntm.
Final acceptance line: compose existing primitives, turn observe into canary apply by explicit policy, measure everything, and demote authority on the first false positive.

## 17. Implementation Slice For Later Non-Plan Work

Slice L01: plan revision only.
Owner later: integration planner.
Files later: `00-PLAN-INPUT.md`.
Expected output later: revised plan with W0, threshold decision, watcher authority, and apply handoff.
No source edits in this slice.

Slice L02: dry-run verification.
Owner later: flywheel worker.
Files later: tests and existing scripts only if needed.
Expected output later: detector self-test and fleet wrapper doctor evidence.
No pane mutation in this slice.

Slice L03: fleet wrapper policy handoff.
Owner later: flywheel worker.
Files later: `.flywheel/scripts/frozen-pane-detector-fleet.sh` and its tests.
Expected output later: canary-only apply path replacing `apply_blocked_by_design` behind explicit env/policy.
This is the first real code slice.

Slice L04: manager-loop consumer.
Owner later: manager-loop integrator.
Files later: manager-loop state consumer, not detector internals.
Expected output later: top-level watchdog summary fields.
This slice should not touch pane mutation logic.

Slice L05: rollback proof.
Owner later: operations worker.
Files later: fleet wrapper test and LaunchAgent dry-run docs if needed.
Expected output later: STOP and unload/disable proof.
This slice should run before canary apply.

Slice L06: canary apply.
Owner later: flywheel worker.
Files later: runtime config and receipt validation.
Expected output later: one worker pane canary, one recovery max, post-probe success.
This slice should not expand scope.

Slice L07: peer-orch dry-run.
Owner later: peer-orch recovery worker.
Files later: peer-orch monitor and permit receipts if needed.
Expected output later: dry-run permit/refusal rows only.
This slice should not enable peer-orch apply.

## 18. Tests I Would Require Later

Test T01: detector dry-run reports planned restart, relaunch, and reprobe without mutation.
Test T02: detector apply writes snapshot before mutation.
Test T03: detector apply writes recovery ledger after mutation.
Test T04: detector apply releases lease after completion.
Test T05: fleet wrapper apply remains blocked unless canary policy is explicit.
Test T06: fleet wrapper STOP file blocks cycle.
Test T07: fleet wrapper FATAL file blocks cycle.
Test T08: global budget blocks over-limit recovery.
Test T09: per-pane budget blocks second same-pane recovery.
Test T10: degraded truth blocks apply.
Test T11: missing L60 signal blocks apply.
Test T12: stale capture timestamp blocks apply.
Test T13: capture provenance unavailable blocks apply.
Test T14: UNKNOWN class emits no-action receipt.
Test T15: WATCH class emits no-action receipt.
Test T16: queued-not-submitted emits its own non-respawn branch.
Test T17: post-completion buffer emits durable receipt, not respawn.
Test T18: rate-limit text routes to wait/account branch.
Test T19: protected session refuses apply.
Test T20: pane 0 refuses apply.
Test T21: human pane refuses apply.
Test T22: callback pane refuses apply.
Test T23: self-orchestrator refuses apply.
Test T24: peer-orch target requires permit path.
Test T25: prompt provenance is present for every recovery.
Test T26: process_alive is preserved in receipt.
Test T27: manager-loop can parse watchdog summary.
Test T28: rollback proof is recorded before canary.
Test T29: false positive demotes watcher authority.
Test T30: unknown recovery count is hard zero.

## 19. Review Questions Answered

Question Q01: should day one act at 90 seconds?
Answer: no.
Question Q02: should day one detect at 90 seconds?
Answer: yes.
Question Q03: should day one act at 5 minutes?
Answer: yes, for the first canary.
Question Q04: should peer-orch apply start now?
Answer: no.
Question Q05: should `skillos:1` be a dry-run exception now?
Answer: yes, dry-run only.
Question Q06: should protected client sessions remain denied?
Answer: yes.
Question Q07: should watcher freshness be launchd doctor only?
Answer: no.
Question Q08: should manager-loop require `watchdog_last_fire_ts`?
Answer: yes.
Question Q09: should ntm source be modified?
Answer: no.
Question Q10: should Codex upgrade block this plan?
Answer: no.
Question Q11: should notify-only be the final state?
Answer: no.
Question Q12: should notify-fast be the first live behavior?
Answer: yes.
Question Q13: should dry-run rows count as full success?
Answer: no.
Question Q14: should canary apply count as fleet success?
Answer: no.
Question Q15: should false positive count demote authority?
Answer: yes.
Question Q16: should refusal receipts be mandatory?
Answer: yes.
Question Q17: should rate limits ever respawn?
Answer: no.
Question Q18: should broad health restart be used?
Answer: no.
Question Q19: should smart-restart be discarded?
Answer: no; keep it as reference/advisory, not authority.
Question Q20: should the revised plan be strict?
Answer: yes.
