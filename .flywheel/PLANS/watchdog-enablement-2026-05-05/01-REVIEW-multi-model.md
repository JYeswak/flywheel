---
title: "01-REVIEW-multi-model - Watchdog Enablement"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# 01-REVIEW-multi-model - Watchdog Enablement

Date: 2026-05-05
Lane: multi-model triangulation
Task: watchdog-3lens-review-2026-05-05
Mode: plan-space only
Reviewer posture: planning-workflow research-stage review
Verdict: revise
Composite score: 9.6 / 10
Recommended disposition: keep the plan, revise the gate ordering before implementation
Plan under review: `.flywheel/PLANS/watchdog-enablement-2026-05-05/00-PLAN-INPUT.md`
Output file: `.flywheel/PLANS/watchdog-enablement-2026-05-05/01-REVIEW-multi-model.md`

## 1. Executive Finding

The plan is correct in its main thesis.
Manual respawn is not a mere annoyance; it is the active failure mode.
The plan correctly refuses a novelty build.
It composes the existing frozen-pane detector, fleet wrapper, ntm restart surface, peer-orch permit gate, and receipt loop.
The plan also correctly keeps Codex upgrade work orthogonal.
The major required revision is not architectural direction.
The required revision is the exact observe-to-apply state machine.
Today the detector can apply recovery, but the fleet wrapper deliberately blocks apply.
That blocker is visible in `.flywheel/scripts/frozen-pane-detector-fleet.sh:328-331`.
The plan should make that policy transition explicit before any source change begins.
The second required revision is threshold separation.
The plan currently leaves open whether day one should act at 90 seconds or log at 90 seconds and act at 5 minutes.
The review consensus is: log at 90 seconds, act at 5 minutes for the first apply canary, then reduce action delay only after false-positive evidence stays at zero.
The third required revision is watchdog self-health.
The plan names watcher freshness, but it should promote `watchdog_last_fire_ts`, `watchdog_driver_verified`, and `watchdog_fleet_apply_enabled` into manager-loop visible state before apply.
Without that, the recovery loop can itself go dark.
That would recreate L57 marker-only failure under a different name.

## 2. Required Prompt Applied

The planning-workflow prompt asks for a complete review of the entire plan.
It asks for better architecture, new features, changed features, robustness, reliability, performance, usefulness, and detailed rationale.
It asks for each proposed change to be expressed as a git-diff style change against the original plan.
This file follows that instruction.
The review does not propose source edits.
The review proposes plan revisions only.
The output is organized as a triaged change set.
Each change includes plan evidence, rationale, and a diff-style insertion or replacement.
The scoring model uses four lenses requested by the dispatch.
Lens A: planning-workflow conformance.
Lens B: paradigm soundness.
Lens C: Joshua taste.
Lens D: public publishability.
The proposed implementation artifact remains the existing plan, not a new code patch.

## 3. Scorecard

Planning-workflow conformance: 9.4 / 10.
Reason: the input plan is self-contained, cites inputs, names scope, names out-of-scope items, and has success criteria.
Deduction: the plan does not yet spell the state transition that changes the fleet wrapper from apply-blocked to canary-apply.
Deduction: the plan leaves threshold choice as an open review-lane question instead of recommending a conservative default.
Paradigm soundness: 9.7 / 10.
Reason: founder-as-recovery-loop becomes system-as-recovery-loop.
Reason: the plan targets Meadows leverage points #2, #3, #5, and #6.
Deduction: the watcher-governance loop is implicit rather than fully modeled.
Joshua taste: 9.6 / 10.
Reason: compose-first, no ntm source edits, no new respawner, no Codex-upgrade magical thinking.
Reason: the plan keeps protected sessions default-deny.
Deduction: the current plan should be more explicit that source-health degradation blocks action, not merely warns.
Public publishability: 9.5 / 10.
Reason: the plan is legible, evidence-driven, and maps goals to metrics.
Deduction: public readers would need the state machine and apply gate spelled out.
Composite: 9.6 / 10.
Verdict: revise before implementation.

## 4. Evidence Ledger From Plan

Evidence 01: the plan opens with "Manual respawn is the failure mode" at `00-PLAN-INPUT.md:20`.
Evidence 02: it says Joshua still becomes the recovery loop at `00-PLAN-INPUT.md:22-24`.
Evidence 03: it frames the MVP as classify in flywheel and execute in ntm at `00-PLAN-INPUT.md:26-30`.
Evidence 04: it says the detector and execution primitives exist at `00-PLAN-INPUT.md:32-35`.
Evidence 05: it correctly rejects Codex upgrade as a freeze cure at `00-PLAN-INPUT.md:37-39`.
Evidence 06: it places watchdog under manager-loop, fleet-autonomy, and mission-coverage at `00-PLAN-INPUT.md:41-43`.
Evidence 07: it names multi-repo manual recovery evidence at `00-PLAN-INPUT.md:47-55`.
Evidence 08: it names six manual respawns in one morning at `00-PLAN-INPUT.md:61-63`.
Evidence 09: it records the brittle six-step manual slash protocol at `00-PLAN-INPUT.md:69-72`.
Evidence 10: it states `ntm respawn` restarts a shell but does not relaunch the agent at `00-PLAN-INPUT.md:74-77`.
Evidence 11: it says the detector already has snapshot, restart, relaunch, resume, reprobe, and ledger at `00-PLAN-INPUT.md:79-87`.
Evidence 12: it says the fleet wrapper is disabled by default and observation-only at `00-PLAN-INPUT.md:89-92`.
Evidence 13: it states the replacement paradigm at `00-PLAN-INPUT.md:101-105`.
Evidence 14: it binds the change to Donella #2, #3, #5, and #6 at `00-PLAN-INPUT.md:107-112`.
Evidence 15: it forbids acting on one stale robot-activity row at `00-PLAN-INPUT.md:117-120`.
Evidence 16: W1 makes frozen-pane-detector the canonical classifier at `00-PLAN-INPUT.md:124-136`.
Evidence 17: W2 denies pane 0, human, callback, self-orch, and protected sessions by default at `00-PLAN-INPUT.md:138-147`.
Evidence 18: W3 names 90s threshold and the day-one threshold question at `00-PLAN-INPUT.md:149-156`.
Evidence 19: W4 prefers `ntm --robot-restart-pane` and keeps `ntm respawn` as fallback at `00-PLAN-INPUT.md:158-169`.
Evidence 20: W4 rejects broad `ntm health --auto-restart-stuck` and sole smart-restart authority at `00-PLAN-INPUT.md:170-178`.
Evidence 21: W5 lists receipt fields at `00-PLAN-INPUT.md:180-191`.
Evidence 22: W6 limits recovery to one per pane per hour and four per session per hour at `00-PLAN-INPUT.md:193-205`.
Evidence 23: W7 escalates failed verification, repeated recovery, budget exhaustion, degraded truth, protected recovery, and watchdog silence at `00-PLAN-INPUT.md:207-221`.
Evidence 24: the plan names healthy capacity as the primary stock at `00-PLAN-INPUT.md:224-235`.
Evidence 25: the plan correctly says threshold tuning alone is parameter fiddling at `00-PLAN-INPUT.md:263-265`.
Evidence 26: Jeff lens says this should not become a new respawner at `00-PLAN-INPUT.md:270-282`.
Evidence 27: Jeff lens says no ntm source work and no second detector at `00-PLAN-INPUT.md:287-291`.
Evidence 28: the plan layers watchdog below manager-loop, fleet-autonomy, and mission-coverage at `00-PLAN-INPUT.md:297-321`.
Evidence 29: the plan keeps Codex 0.128.0/gpt-5.5 as canary evidence, not cure, at `00-PLAN-INPUT.md:331-337`.
Evidence 30: the plan says no auth, upgrade, or ntm source modification is needed at `00-PLAN-INPUT.md:345-348`.
Evidence 31: success criteria include manual burden, MTTR, success rate, false positives, unknown recovery, storm control, protected gate, receipts, and watcher health at `00-PLAN-INPUT.md:350-362`.
Evidence 32: scope preserves dry-run before apply at `00-PLAN-INPUT.md:367-375`.
Evidence 33: out of scope excludes Codex migration, ntm source work, broad health restart, protected auto-recovery, self-recovery, and bead creation at `00-PLAN-INPUT.md:377-383`.
Evidence 34: constraints name default deny and budget gates at `00-PLAN-INPUT.md:385-399`.
Evidence 35: open questions include threshold, peer-orch permit timeline, and watcher self-health at `00-PLAN-INPUT.md:401-410`.
Evidence 36: proposed ship order is phase-based, dry-run first, canary second, peer-orch later at `00-PLAN-INPUT.md:412-429`.
Evidence 37: verdict thresholds define green, yellow, and red conditions at `00-PLAN-INPUT.md:431-445`.
Evidence 38: the close says the value is turning built substrate into a safe measured recovery loop at `00-PLAN-INPUT.md:447-448`.

## 5. Evidence Ledger From Code And Socraticode

Socraticode status: flywheel green, 694 chunks indexed.
Socraticode status: ntm green, 31,740 chunks indexed.
Socraticode query count for this lane package: 11 codebase searches plus 2 status checks.
Ntm result 01: `internal/robot/restart_pane.go` exposes session, pane filters, dry-run, bead, prompt, restart result, failure result, and process-alive fields.
Ntm result 02: `internal/robot/restart_pane.go:124-135` makes dry-run explicit and mutation-free.
Ntm result 03: `internal/robot/restart_pane.go:137-205` restarts selected panes, verifies process liveness, and can send a prompt after restart.
Ntm result 04: `internal/robot/smart_restart.go:19-26` correctly refuses to interrupt working agents and handles rate limits.
Ntm result 05: `internal/robot/smart_restart.go:31-45` distinguishes RESTARTED, SKIPPED, WAITING, FAILED, and WOULD_RESTART.
Ntm result 06: `internal/robot/smart_restart.go:48-60` has force, dry-run, prompt, hard-kill, and hard-kill-only options.
Ntm result 07: `internal/robot/health.go` has restart budgets and backoff, but it is broader than this plan should use for frozen Codex worker authority.
Ntm result 08: `internal/config/config.go` has auto-restart disabled by default in resilience and health defaults.
Ntm result 09: `internal/robot/robot.go` has capture provenance and capture timestamp fields that the watchdog should require.
Ntm result 10: `internal/cli/respawn.go` defaults away from pane 0/user panes unless filters or all are supplied.
Flywheel result 01: frozen-pane detector can execute restart, relaunch, resume prompt, reprobe, ledger, and lease release at `.flywheel/scripts/frozen-pane-detector.sh:780-804`.
Flywheel result 02: frozen-pane detector dry-run plans recovery without mutation at `.flywheel/scripts/frozen-pane-detector.sh:760-766`.
Flywheel result 03: frozen-pane detector fleet wrapper currently calls detector with `--auto-recover --dry-run` at `.flywheel/scripts/frozen-pane-detector-fleet.sh:293-300`.
Flywheel result 04: fleet wrapper blocks apply by design at `.flywheel/scripts/frozen-pane-detector-fleet.sh:328-331`.
Flywheel result 05: fleet wrapper already has one-hour budget state at `.flywheel/scripts/frozen-pane-detector-fleet.sh:265-291`.
Flywheel result 06: L60 says no-silent-darkness, not merely frozen-pane detection, is the real goal at `AGENTS.md:995-1009`.
Flywheel result 07: L60 forbids auto-recovering unknown source or loops with fewer than 5/5 L60 signals at `AGENTS.md:1022-1028`.
Flywheel result 08: L57 says markers are not drivers and forbids loop-running claims from state files alone.
Flywheel result 09: L115 requires a permit gate for peer-orch recovery.
Flywheel result 10: L117 requires peer-orch monitor freshness and leaves auto-respawn disabled by default.
Flywheel result 11: no-silent-darkness should be a pre-flight to any pane recovery decision, not a dashboard afterthought.

## 6. Consensus Triangulation

Consensus 01: keep the plan.
Consensus 02: do not add ntm source work.
Consensus 03: do not build a second respawner.
Consensus 04: use frozen-pane-detector as the classifier and applier.
Consensus 05: use frozen-pane-detector-fleet as the launchd/fleet wrapper.
Consensus 06: use `ntm --robot-restart-pane` as preferred execution.
Consensus 07: keep `ntm respawn` as fallback, not primary.
Consensus 08: keep peer-orch recovery separate behind the permit gate.
Consensus 09: keep protected sessions default-deny.
Consensus 10: keep Codex 0.128.0/gpt-5.5 as canary input, not freeze cure.
Consensus 11: require live truth and L60 signals before mutation.
Consensus 12: require snapshot and recovery ledger before calling a recovery clean.
Consensus 13: require post-recovery liveness proof.
Consensus 14: require budget gates before any apply.
Consensus 15: require false-positive count to remain zero.
Consensus 16: require unknown auto-recovery to remain zero.
Consensus 17: expose watchdog health to manager-loop before apply.
Consensus 18: use 90s detection for visibility.
Consensus 19: do not act at 90s on day one.
Consensus 20: act at 5m for first apply canary unless repeated evidence proves 90s action safe.

## 7. Divergence Triangulation

Divergence 01: whether day-one action threshold should be 90s or 5m.
Resolution: split detect threshold from action threshold.
Divergence 02: whether peer-orch `skillos:1` exception should apply immediately.
Resolution: allow dry-run permit track now, keep apply disabled until worker canary receipts are clean.
Divergence 03: whether watcher self-health belongs in manager-loop before or after apply.
Resolution: before apply.
Divergence 04: whether `--robot-smart-restart` should be used as an additional guard.
Resolution: it can be advisory, but not sole authority and not required for MVP.
Divergence 05: whether `ntm health --auto-restart-stuck` should be reused.
Resolution: no production authority for this plan; too broad.
Divergence 06: whether auto-respawn is the right end state.
Resolution: yes for eligible worker panes after evidence, no for protected/unknown/peer-orch until gates prove safe.
Divergence 07: whether a notify-only phase is enough.
Resolution: notify-only reduces founder latency but does not eliminate founder-as-recovery-loop.
Divergence 08: whether source edits should begin immediately.
Resolution: no; revise plan first, then implement a narrow policy handoff.

## 8. Proposed Change R01 - Add A W0 Eligibility Preflight

Change ID: R01.
Severity: high.
Type: plan architecture revision.
Plan evidence: W1 begins with detector/classifier at `00-PLAN-INPUT.md:124`.
Problem: action eligibility is spread across W1, W2, W6, W7, L60, and fleet wrapper policy.
Rationale: the first primitive should be a single eligibility function that returns reason codes before detector action.
Joshua taste: good; it centralizes gates instead of scattering conditionals.
Reliability effect: prevents accidental mutation when one gate is skipped.
Performance effect: minor; one extra JSON decision record is acceptable.
Publishability effect: strong; readers can understand when the watchdog may act.
Diff target: insert before W1.

```diff
+### W0 - Eligibility preflight
+Before W1 classification may mutate a pane, compute `watchdog_eligibility`.
+Required pass fields: source_health=healthy, L60_signals_present=5/5,
+capture_provenance=live, capture_collected_at fresh, target_kind=worker,
+target_not_pane0=true, target_not_human=true, target_not_callback=true,
+target_not_self_orchestrator=true, protected_session=false, cooldown_ok=true,
+budget_ok=true, class_candidate=FROZEN.
+Output reason codes for every refusal.
```

## 9. Proposed Change R02 - Split Detect Threshold And Action Threshold

Change ID: R02.
Severity: high.
Type: threshold policy revision.
Plan evidence: the plan asks 90s action, 5m action, or 90s log / 5m act at `00-PLAN-INPUT.md:401-404`.
Problem: one threshold cannot serve both SLO observability and mutation safety on day one.
Rationale: detection should be fast; mutation should be conservative until false-positive evidence exists.
Joshua taste: good; fast signal without premature mutation.
Reliability effect: reduces false positive respawn risk.
Performance effect: retains early alerting and metrics.
Publishability effect: makes the rollout more defensible.
Diff target: replace W3 final sentence.

```diff
-Review-lane choice: 90s action immediately, or 90s log / 5m act for day one.
+Decision: split thresholds. Day 0 and Day 1 use 90s detect/log and 5m act.
+After 24h dry-run plus one worker apply canary with false_positive_respawn_count=0,
+the action threshold may be reduced by policy, not by ad hoc operator choice.
```

## 10. Proposed Change R03 - Name The Fleet Apply Handoff

Change ID: R03.
Severity: high.
Type: apply gate revision.
Plan evidence: current plan says enable the fleet wrapper at `00-PLAN-INPUT.md:367-370`.
Problem: the fleet wrapper currently emits `apply_blocked_by_design` when APPLY is set.
Rationale: the plan must say exactly what future implementation changes from blocked to canary apply.
Joshua taste: high; it confronts the actual integration gap.
Reliability effect: prevents a false "enabled" report while apply remains blocked.
Performance effect: avoids wasted loops that observe forever.
Publishability effect: readers see the control-plane transition.
Diff target: insert under Phase 2.

```diff
+Phase 2 prerequisite: replace fleet wrapper `apply_blocked_by_design` with a
+canary-only apply path guarded by W0 eligibility, W2 permit, W3 action threshold,
+W6 budget, L60 no-silent-darkness, STOP/FATAL files, and explicit
+`WATCHDOG_CANARY_APPLY=1`.
```

## 11. Proposed Change R04 - Promote Watchdog Self-Health To Required State

Change ID: R04.
Severity: high.
Type: observability revision.
Plan evidence: watcher freshness is listed at `00-PLAN-INPUT.md:362` and open question 3 at `00-PLAN-INPUT.md:406-407`.
Problem: a watcher that stops firing can create silent darkness while all old receipts look healthy.
Rationale: L57 requires driver proof, not marker proof.
Joshua taste: high; this prevents fake health.
Reliability effect: catches dead watchdogs.
Performance effect: cheap JSON state.
Publishability effect: strong; self-observing watchdogs are safer.
Diff target: resolve open question 3.

```diff
-Watcher self-health: launchd doctor freshness alone, or require
-`watchdog_last_fire_ts` in manager-loop before apply?
+Decision: require manager-loop-visible watchdog state before apply:
+`watchdog_last_fire_ts`, `watchdog_driver_verified`,
+`watchdog_last_exit_status`, `watchdog_apply_enabled`,
+`watchdog_false_recovery_count_24h`, and `watchdog_unknown_recovery_count_24h`.
```

## 12. Proposed Change R05 - Add A Recovery State Machine

Change ID: R05.
Severity: high.
Type: state model revision.
Plan evidence: W1-W7 are atomic primitives but not an explicit state machine.
Problem: primitive lists do not prevent illegal transitions.
Rationale: auto-recovery needs one machine-readable state transition path.
Joshua taste: high; less prose, more contract.
Reliability effect: reduces edge-case drift.
Performance effect: negligible.
Publishability effect: strong.
Diff target: insert after W7.

```diff
+Recovery state machine:
+OBSERVE -> CANDIDATE -> ELIGIBLE -> APPLYING -> RECOVERED.
+OBSERVE -> UNKNOWN -> NO_ACTION_RECEIPT.
+CANDIDATE -> REFUSED -> NO_ACTION_RECEIPT.
+ELIGIBLE -> SUPPRESSED -> ESCALATION_RECEIPT.
+APPLYING -> FAILED_VERIFY -> ESCALATION_RECEIPT.
+No transition may skip receipt emission.
```

## 13. Proposed Change R06 - Add A Notify-Fast Non-Mutation Branch

Change ID: R06.
Severity: medium.
Type: feature revision.
Plan evidence: W7 escalates repeated suppression and failed recovery at `00-PLAN-INPUT.md:207-218`.
Problem: the plan does not explicitly say what happens when a pane is frozen but not eligible to mutate.
Rationale: founder burden drops even when action is refused if the system reports the exact refusal fast.
Joshua taste: good; no fake autonomy, no silence.
Reliability effect: high for protected and peer-orch cases.
Performance effect: no mutation cost.
Publishability effect: good.
Diff target: add under W7.

```diff
+Non-mutation branch: if class=FROZEN but eligibility refuses apply,
+write a no-action receipt and route a compact manager-loop alert with
+`refusal_reason`, `snapshot`, `source_health`, and `next_safe_action`.
+This is notify-fast, not auto-respawn.
```

## 14. Proposed Change R07 - Define Resume Prompt Source

Change ID: R07.
Severity: medium.
Type: reliability revision.
Plan evidence: manual protocol includes resume prompt at `00-PLAN-INPUT.md:69-72`.
Problem: W4 says sends a resume prompt, but not where that prompt is derived from.
Rationale: post-recovery prompt quality determines whether the restarted worker resumes safely.
Joshua taste: high; exact, local, no generic "continue".
Reliability effect: reduces wrong-work continuation.
Performance effect: saves operator inspection.
Publishability effect: useful operational detail.
Diff target: expand W4.

```diff
+Resume prompt source order:
+1. active dispatch receipt for session/pane if available,
+2. latest worker callback expectation from dispatch log,
+3. bead assignment from reservation/dispatch packet if present,
+4. fallback safety prompt: run inbox/bead resume checks, then continue only if safe.
```

## 15. Proposed Change R08 - Require Canary Evidence Before Threshold Tightening

Change ID: R08.
Severity: medium.
Type: rollout revision.
Plan evidence: success criteria require 95% success after dry-run and zero false positives at `00-PLAN-INPUT.md:356-358`.
Problem: the plan does not say how many cycles prove the canary.
Rationale: "24h dry-run" is better if paired with minimum observation counts.
Joshua taste: high; evidence over vibes.
Reliability effect: reduces premature global enablement.
Performance effect: no impact.
Publishability effect: improves auditability.
Diff target: expand Phase 1 and Phase 2.

```diff
+Phase 1 acceptance: at least 24h, at least 20 detector cycles,
+at least one synthetic frozen fixture, zero degraded-truth apply attempts,
+zero unknown recovery plans, and manager-loop summary readable.
+Phase 2 acceptance: one flywheel worker pane canary, one recovery max,
+post-probe success, zero false positive, rollback verified.
```

## 16. Proposed Change R09 - Add Explicit Rollback Test

Change ID: R09.
Severity: medium.
Type: operational safety revision.
Plan evidence: constraints mention rollback by LaunchAgent disable/unload plus STOP file at `00-PLAN-INPUT.md:398-399`.
Problem: rollback exists as a sentence, not a testable acceptance gate.
Rationale: every autonomous mutation path needs a proven stop path.
Joshua taste: high.
Reliability effect: high.
Performance effect: negligible.
Publishability effect: strong.
Diff target: add to Phase 0.

```diff
+Phase 0 must prove rollback before apply:
+create STOP file, run cycle, observe no mutation;
+unload/disable LaunchAgent, verify no scheduled fire;
+remove STOP only after doctor reports stopped state cleanly.
```

## 17. Proposed Change R10 - Route Rate Limits To Wait, Not Recovery

Change ID: R10.
Severity: medium.
Type: classifier revision.
Plan evidence: W6 says rate-limit and quota classes never respawn at `00-PLAN-INPUT.md:199-202`.
Problem: the plan should also say what branch receives them.
Rationale: non-action classes need receipts too.
Joshua taste: good; no hidden ignored class.
Reliability effect: prevents quota flapping.
Performance effect: avoids pointless restarts.
Publishability effect: good.
Diff target: expand W1 or W6.

```diff
+Rate-limit/quota branch: emit `class=RATE_LIMITED` or `class=QUOTA`,
+`recovery_allowed=false`, `next_action=wait_or_account_rotation`,
+and never call pane restart surfaces from this branch.
```

## 18. Proposed Change R11 - Add L60 Preflight To In-Scope List

Change ID: R11.
Severity: high.
Type: doctrine integration revision.
Plan evidence: W1 requires live truth; L60 says no-silent-darkness is broader than frozen pane detection.
Problem: the in-scope list does not explicitly include `.flywheel/scripts/no-silent-darkness-probe.sh`.
Rationale: L60 forbids auto-recovering unknown source or fewer than 5/5 signals.
Joshua taste: high.
Reliability effect: high.
Performance effect: one probe per decision path.
Publishability effect: high.
Diff target: add to in-scope.

```diff
+8. Run `.flywheel/scripts/no-silent-darkness-probe.sh --doctor --json`
+before any apply decision and require 5/5 L60 signals for mutation.
```

## 19. Proposed Change R12 - Add Manager-Loop Consumer Contract

Change ID: R12.
Severity: medium.
Type: integration revision.
Plan evidence: recovery receipts should be manager-loop input at `00-PLAN-INPUT.md:305-308`.
Problem: the plan does not name the schema manager-loop expects.
Rationale: producer success is not enough; consumer visibility is part of the loop.
Joshua taste: high; no orphan receipts.
Reliability effect: high.
Performance effect: small.
Publishability effect: good.
Diff target: expand relationship section.

```diff
+Manager-loop consumer contract:
+watchdog emits one compact row per cycle with `session`, `pane`, `class`,
+`decision`, `reason`, `action_taken`, `latency_s`, `budget_state`,
+`false_positive_count_24h`, `unknown_recovery_count_24h`,
+and `watchdog_last_fire_ts`.
```

## 20. Proposed Change R13 - Separate Worker And Peer-Orch Lanes In Rollout

Change ID: R13.
Severity: medium.
Type: rollout revision.
Plan evidence: peer-orch stays on separate permit track at `00-PLAN-INPUT.md:144-146` and Phase 5 at `00-PLAN-INPUT.md:428-429`.
Problem: peer-orch dry-run and worker apply can accidentally be discussed as one enablement.
Rationale: peer-orch recovery has different ownership and self-recovery constraints.
Joshua taste: high.
Reliability effect: high.
Performance effect: no downside.
Publishability effect: clear.
Diff target: expand Phase 5.

```diff
+Peer-orch track is a separate rollout lane:
+worker apply can go green without peer-orch apply;
+peer-orch remains dry-run until permit receipts, false-recovery counts,
+and self-respawn refusals are visible for seven days.
```

## 21. Proposed Change R14 - Add Fixture-Based Acceptance Before Live Apply

Change ID: R14.
Severity: medium.
Type: test planning revision.
Plan evidence: Phase 0 includes detector self-test at `00-PLAN-INPUT.md:414-415`.
Problem: self-test existence is good, but the plan should name the fixture classes that matter.
Rationale: avoid test theater.
Joshua taste: high.
Reliability effect: high.
Performance effect: no runtime cost.
Publishability effect: strong.
Diff target: expand Phase 0.

```diff
+Phase 0 fixture acceptance must cover:
+frozen identical buffer, stale tail, post-respawn residue,
+stale template prompt, missing L60 signal, queued-not-submitted,
+post-completion buffer, rate-limit text, and degraded source health.
```

## 22. Proposed Change R15 - Add A Positive No-Action Receipt Requirement

Change ID: R15.
Severity: medium.
Type: receipt revision.
Plan evidence: W5 lists no-action reason among receipt fields at `00-PLAN-INPUT.md:185-188`.
Problem: no-action receipts are not as strongly emphasized as recovery receipts.
Rationale: refusals are learning data and prevent silent non-recovery.
Joshua taste: high.
Reliability effect: high.
Performance effect: small.
Publishability effect: strong.
Diff target: expand W5.

```diff
+Every non-recovery path must emit a no-action receipt with:
+`class`, `recovery_allowed=false`, `refusal_reason`,
+`source_health`, `l60_signals_present`, `next_safe_action`,
+and `escalation_target` if any.
```

## 23. Proposed Change R16 - Add Apply Identity And Version Fields

Change ID: R16.
Severity: low.
Type: audit revision.
Plan evidence: W5 names ntm and Codex version if visible at `00-PLAN-INPUT.md:182-187`.
Problem: audit identity should include the actor policy, not just versions.
Rationale: after rollout, root cause needs to know which policy enabled action.
Joshua taste: good.
Reliability effect: medium.
Performance effect: no meaningful cost.
Publishability effect: good.
Diff target: expand W5.

```diff
+Receipt version fields also include:
+`watchdog_policy_version`, `fleet_wrapper_version`, `apply_gate_mode`,
+`canary_scope`, and `eligibility_reason_codes`.
```

## 24. Proposed Change R17 - Add Degraded Truth Stop Condition To Green/Yellow/Red

Change ID: R17.
Severity: high.
Type: verdict threshold revision.
Plan evidence: red thresholds include unknown and protected violations at `00-PLAN-INPUT.md:441-445`.
Problem: degraded source health should be explicitly red if apply occurs.
Rationale: L60 makes truth quality a mutation precondition.
Joshua taste: high.
Reliability effect: high.
Performance effect: no downside.
Publishability effect: high.
Diff target: expand RED.

```diff
+RED: any apply while `source_health.status != healthy`,
+`capture_provenance != live`, stale `capture_collected_at`,
+or `L60_signals_present < 5/5`.
```

## 25. Proposed Change R18 - Add A Seven-Day Before/After Chart Definition

Change ID: R18.
Severity: low.
Type: measurement revision.
Plan evidence: the plan asks for a 7-day before/after chart at `00-PLAN-INPUT.md:364-365`.
Problem: the chart is requested but not defined.
Rationale: define the chart now to prevent vanity metrics later.
Joshua taste: good.
Reliability effect: medium.
Performance effect: no runtime cost.
Publishability effect: good.
Diff target: expand success criteria.

```diff
+Seven-day chart rows:
+manual_respawn_count, frozen_detected_count, auto_respawn_applied_count,
+auto_respawn_success_rate, false_positive_respawn_count,
+unknown_auto_recovery_count, protected_apply_count,
+same_pane_second_respawn_1h, detector_cycle_freshness_p95.
```

## 26. Risk Register

Risk 01: apply remains blocked in fleet wrapper and the team falsely reports watchdog enabled.
Control: R03.
Risk 02: detector fires on stale or degraded truth.
Control: R01 and R11.
Risk 03: 90s action creates false positive respawns.
Control: R02 and R08.
Risk 04: protected sessions get touched by a generic worker path.
Control: R01, R13, and W2.
Risk 05: peer-orch recovery is mixed with worker recovery.
Control: R13.
Risk 06: the watchdog goes silent while old receipts look healthy.
Control: R04 and R12.
Risk 07: rate limits are misclassified as frozen panes.
Control: R10 and fixture acceptance.
Risk 08: no-action outcomes vanish.
Control: R15.
Risk 09: manager-loop cannot consume recovery data.
Control: R12.
Risk 10: rollback is assumed but untested.
Control: R09.
Risk 11: `ntm health --auto-restart-stuck` becomes a shortcut.
Control: keep it red and out of scope.
Risk 12: `--robot-smart-restart` becomes sole authority.
Control: keep it advisory/non-MVP.
Risk 13: Codex upgrade is treated as a substitute fix.
Control: keep orthogonal canary language.
Risk 14: a second respawner appears.
Control: Jeff compose-not-new rule.
Risk 15: receipt coverage falls below 100 percent.
Control: R15 and W5.
Risk 16: a same-pane storm burns recovery budget.
Control: W6 and R12 budget fields.
Risk 17: source-health failures cause human escalation without structured no-action receipt.
Control: R15.
Risk 18: launchd marker is mistaken for driver.
Control: R04.
Risk 19: canary success is asserted with one happy path.
Control: R08.
Risk 20: public review sees automation as aggressive pane killing.
Control: state machine, permit, and no-action branch.

## 27. Acceptance Checklist

Acceptance 01: plan has W0 eligibility preflight.
Acceptance 02: plan has detect threshold separate from action threshold.
Acceptance 03: plan names 90s detect and 5m action for day-one apply canary.
Acceptance 04: plan names current `apply_blocked_by_design` fleet-wrapper state.
Acceptance 05: plan names the policy that permits canary apply.
Acceptance 06: plan requires L60 no-silent-darkness preflight.
Acceptance 07: plan requires watcher self-health state before apply.
Acceptance 08: plan names manager-loop consumer fields.
Acceptance 09: plan requires no-action receipts.
Acceptance 10: plan defines rollback test.
Acceptance 11: plan defines fixture classes.
Acceptance 12: plan defines chart rows.
Acceptance 13: plan keeps ntm source work out of scope.
Acceptance 14: plan keeps Codex migration out of scope.
Acceptance 15: plan keeps protected sessions default-deny.
Acceptance 16: plan keeps peer-orch recovery dry-run until permit receipts prove safe.
Acceptance 17: plan forbids unknown recovery.
Acceptance 18: plan forbids degraded-truth apply.
Acceptance 19: plan forbids same-pane second respawn in one hour.
Acceptance 20: plan requires post-recovery liveness proof.
Acceptance 21: plan requires snapshot before mutation.
Acceptance 22: plan requires recovery ledger.
Acceptance 23: plan requires idempotency key.
Acceptance 24: plan requires source health in receipts.
Acceptance 25: plan routes rate-limit and quota to wait/account handling.
Acceptance 26: plan contains explicit stop/unload rollback.
Acceptance 27: plan separates worker and peer-orch rollout.
Acceptance 28: plan names success as lower manual burden with zero false recovery.
Acceptance 29: plan grades yellow if watcher freshness is missing.
Acceptance 30: plan grades red if apply can touch pane 0, human, callback, or protected sessions.

## 28. Recommended Revised Ship Order

Revised phase 0.0: freeze all source edits and revise plan with R01-R18.
Revised phase 0.1: run detector self-test and fixture matrix.
Revised phase 0.2: run fleet wrapper doctor and prove disabled/default observe state.
Revised phase 0.3: run rollback test with STOP and LaunchAgent disable/unload.
Revised phase 0.4: record baseline manual_respawn_count_7d and detector freshness.
Revised phase 1.0: dry-run watchdog for 24h with at least 20 cycles.
Revised phase 1.1: emit manager-loop consumable summary without mutation.
Revised phase 1.2: prove no degraded-truth apply attempt.
Revised phase 1.3: prove unknown recovery count remains zero.
Revised phase 2.0: enable canary apply only for one flywheel worker pane.
Revised phase 2.1: use 90s detect and 5m action threshold.
Revised phase 2.2: require snapshot, lease, restart, relaunch, resume prompt, reprobe, ledger.
Revised phase 2.3: prove rollback still works after canary.
Revised phase 3.0: expose budget, false-positive, unknown, and protected metrics.
Revised phase 3.1: stop if any false positive appears.
Revised phase 4.0: expand to non-protected worker panes.
Revised phase 5.0: peer-orch dry-run permit track only.
Revised phase 5.1: peer-orch apply remains disabled until seven-day receipts are clean.

## 29. Final Multi-Model Verdict

Verdict: revise.
Keep the plan's thesis.
Keep the primitive set.
Keep compose-not-new.
Keep flywheel classification and ntm execution.
Keep Codex upgrade out of the critical path.
Revise the plan to add W0 eligibility.
Revise the plan to split detect and action thresholds.
Revise the plan to name the fleet-wrapper apply handoff.
Revise the plan to require watchdog self-health before apply.
Revise the plan to include L60 as a mutation preflight.
Revise the plan to add no-action receipts.
Revise the plan to define canary acceptance and rollback tests.
Reject any implementation that starts with ntm source work.
Reject any implementation that treats 90s as day-one action threshold without clean canary evidence.
Reject any implementation that reports "watchdog enabled" while fleet apply remains blocked by design.
Reject any implementation that can touch pane 0, human pane, callback pane, protected sessions, or unknown source.
Overall grade: A-.
Composite score: 9.6.
Confidence: high.
Proposed change count: 18.
Public publishability after revisions: yes.
Implementation readiness after revisions: yes, for Phase 0 and Phase 1.
Implementation readiness for apply: conditional on R01-R18 being integrated into the plan.
