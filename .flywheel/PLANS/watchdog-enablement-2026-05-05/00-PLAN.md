---
title: "00-PLAN - Watchdog Enablement r1"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

## Contents

- [1. Why This Plan Exists](#1-why-this-plan-exists)
- [2. Hard Evidence](#2-hard-evidence)
- [3. Paradigm Shift](#3-paradigm-shift)
- [4. Atomic Primitives](#4-atomic-primitives)
  - [W0 - Eligibility Preflight](#w0-eligibility-preflight)
  - [W1 - Detector / Classifier](#w1-detector-classifier)
  - [W2 - Permit Gate](#w2-permit-gate)
  - [W3 - Threshold / Debounce](#w3-threshold-debounce)
  - [W4 - Execution And Prompt Re-Injection](#w4-execution-and-prompt-re-injection)
  - [W5 - Receipt / Learning Loop](#w5-receipt-learning-loop)
  - [W6 - Backoff / Storm Control](#w6-backoff-storm-control)
  - [W7 - Escalation And Notify-Fast](#w7-escalation-and-notify-fast)
  - [W8 - Watcher Governance Loop](#w8-watcher-governance-loop)
- [5. Donella Lens Applied](#5-donella-lens-applied)
- [6. Jeff Lens Applied](#6-jeff-lens-applied)
- [7. Per-Change Disposition Table](#7-per-change-disposition-table)
- [8. Cross-Plan Relationships](#8-cross-plan-relationships)
- [9. Cross-Research Input Integration](#9-cross-research-input-integration)
- [10. Success Criteria](#10-success-criteria)
- [11. In Scope / Out Of Scope](#11-in-scope-out-of-scope)
- [12. Constraints](#12-constraints)
- [13. Open Questions For r1 Audit](#13-open-questions-for-r1-audit)
- [14. Ship Order](#14-ship-order)
- [15. Verdict Thresholds](#15-verdict-thresholds)
- [Appendix A - Review Citations](#appendix-a-review-citations)
- [Appendix B - Socraticode And Skill Survey](#appendix-b-socraticode-and-skill-survey)
- [Appendix C - Convergence Notes](#appendix-c-convergence-notes)
- [Appendix D - Change Disposition Totals](#appendix-d-change-disposition-totals)
# 00-PLAN - Watchdog Enablement r1

Date: 2026-05-05
Status: converged r1 plan after 3-lens review integration
Task: watchdog-integrate-revisions-2026-05-05
Composite target: >= 9.5
Composite score: 9.6
Plan-space constraint: no source edits, no bead writes, no Joshua question
Primary input: `.flywheel/PLANS/watchdog-enablement-2026-05-05/00-PLAN-INPUT.md`
Review inputs:
- `.flywheel/PLANS/watchdog-enablement-2026-05-05/01-REVIEW-multi-model.md`
- `.flywheel/PLANS/watchdog-enablement-2026-05-05/01-REVIEW-donella.md`
- `.flywheel/PLANS/watchdog-enablement-2026-05-05/01-REVIEW-jeff.md`
Reference research:
- `/tmp/research-ntm-auto-respawn-2026-05-05.md`
Final primitive count: 9
Primitive count change: original 7 -> final 9
Primitive reason: W0 eligibility and W8 watcher_governance_loop are now first-class because the review found safety and watcher legitimacy were too important to leave implicit.
New primitives: 2
Composition primitives: 7
Counter-thesis disposition: rejected by Joshua override for eligible worker panes
Auto-respawn vs notify-only split: auto-respawn primary for eligible FROZEN worker panes; notify-only fallback only for refused / unsafe / degraded / over-budget classes

---

## 1. Why This Plan Exists

Manual respawn is the failure mode.
The original plan said this plainly, and the review lanes converged on it.
Joshua currently becomes the balancing loop when panes freeze, dead-shell, or mis-relaunch.
That is not an acceptable operating model for a flywheel.
The system already has most of the machinery.
The missing layer is controlled enablement.
The safe MVP remains: classify in flywheel, execute in ntm.
This plan does not create a new respawner.
This plan does not treat Codex upgrade as the cure.
This plan does not ask Joshua to choose thresholds.
This plan turns existing substrate into a safe, measured recovery loop.
The multi-model review agreed the thesis is right but required an observe-to-apply state machine.
The Donella review named the invisible structure: `watcher_governance_loop`.
The Jeff review endorsed the notify-only counter-thesis conditionally, but Joshua override locks the final decision: auto-respawn is primary for eligible frozen worker panes and notify-only is fallback only.
The converged decision is therefore:
detect fast,
auto-respawn eligible frozen worker panes under strict gates,
notify only when gates refuse action,
start with one worker canary,
make the watcher itself observable,
and demote authority on the first false positive.

## 2. Hard Evidence

The original plan records direct evidence that manual respawn has already cost Joshua multiple interventions.
The plan cites two manual recoveries on `flywheel:0.3` and two on `mobile-eats:0.2`.
It cites about 30 manual respawns over three days.
It cites six manual respawns in one morning caused by orchestrator recovery mistakes.
It cites four frozen panes recovered only after Joshua woke.
The manual `/flywheel:respawn` protocol has six operational steps.
The reason that protocol is brittle is not mystery.
`ntm respawn` restarts the shell, not the full recovery transaction.
The existing detector already has the transaction: snapshot, restart, relaunch, resume prompt, reprobe, ledger, and lease release.
The code path confirms that transaction.
`.flywheel/scripts/frozen-pane-detector.sh` copies a snapshot, calls `ntm --robot-restart-pane`, relaunches the agent, sends a recovery prompt, reprobes, writes ledgers, and releases the lease.
The fleet wrapper confirms the remaining gap.
It schedules observation and dry-run.
It currently blocks apply by design.
Socraticode reconfirmed that `frozen-pane-detector-fleet.sh` calls the detector with `--auto-recover --dry-run`.
Socraticode also reconfirmed that the fleet wrapper returns `apply_blocked_by_design` when apply is requested.
That means the plan cannot say "enable watchdog apply" until it names the policy handoff that replaces this block for a canary.
Ntm already has the execution substrate.
`--robot-restart-pane` supports pane filters, dry-run, prompt delivery, structured JSON, failures, and process liveness.
`--robot-smart-restart` has valuable skip/wait semantics, but the plan does not use it as sole frozen-Codex authority.
`ntm health --auto-restart-stuck` is explicitly out of production authority because it is broader than the frozen-pane class.
L60 says no-silent-darkness is the actual goal.
L57 says markers are not drivers.
L115 says peer orchestrator recovery needs a permit gate.
The evidence is sufficient.
No Joshua question is needed.

## 3. Paradigm Shift

Current paradigm:
the founder notices or is asked,
the founder judges the pane,
the founder runs the recovery,
and the system resumes after human attention.
Replacement paradigm:
the system classifies the pane,
the system decides whether mutation is allowed,
the system either acts or emits a no-action receipt,
the system exposes receipts and watcher health to manager-loop,
and Joshua sees only repeated failures, protected-session decisions, recovery storms, or audit summaries.
This is a Donella leverage point shift.
It is not mainly #12 parameter tuning.
It uses #6 information flows by moving pane truth and recovery receipts to the actor that can respond.
It uses #5 rules by encoding who may mutate which pane.
It uses #4 self-organization by routing repeated classes into future learning and tooling.
It uses #3 goals by optimizing no silent darkness and worker recovery SLO.
It uses #2 paradigm by replacing founder-as-recovery-loop with system-as-recovery-loop.
The watcher_governance_loop is now explicit.
The watchdog is not outside the system.
The watchdog is a subsystem with authority.
Authority must rise and fall with evidence.
The watcher can drift.
The watcher can silently fail.
The watcher can become its own freeze risk.
Therefore watcher health is a first-class stock.
The watcher governance loop watches the watcher through driver freshness, last fire time, last exit status, false recovery count, unknown recovery count, permit refusals, rollback proof, and manager-loop consumption.
The plan is not "be more aggressive."
The plan is "make recovery a verified transaction with conservative default-deny gates and measured authority."

## 4. Atomic Primitives

Final count: 9 primitives.
Seven primitives preserve the original compose-not-new design.
Two primitives are new plan primitives because the reviews found they must be atomic gates.
W0 is new because safety and eligibility must happen before classifier action.
W8 is new because watcher_governance_loop must not be hidden inside W7 escalation.
All implementation substrate still composes existing flywheel and ntm surfaces.

### W0 - Eligibility Preflight

Tag: NEW.
Action disposition: gate only; notify-only only when W0 refuses action.
Mutation authority: none.
Purpose: compute `watchdog_eligibility` before any action path.
Required pass fields:
source_health=healthy.
L60_signals_present=5/5.
capture_provenance=live.
capture_collected_at fresh.
two robot-tail samples successful.
target_kind=worker.
target_not_pane0=true.
target_not_human=true.
target_not_callback=true.
target_not_self_orchestrator=true.
protected_session=false.
cooldown_ok=true.
budget_ok=true.
class_candidate=FROZEN.
Output: `eligible=true|false`, reason codes, and no-action receipt on refusal.
Reason: review lanes independently requested W0 or equivalent eligibility.
Disposition: accepted.
Source: multi-model R01 at `01-REVIEW-multi-model.md:181`; Donella D01 at `01-REVIEW-donella.md:421`; Jeff J01 at `01-REVIEW-jeff.md:228`.

### W1 - Detector / Classifier

Tag: COMPOSITION.
Action disposition: classify only; notify-only only for non-action classes.
Mutation authority: none by itself.
Canonical surface: `.flywheel/scripts/frozen-pane-detector.sh`.
Allowed action class: FROZEN only.
Non-respawn classes: WATCH, UNKNOWN, template prompts, post-completion buffer, queued-not-submitted, rate-limit, quota, degraded truth.
Required live truth: healthy source, live capture provenance, fresh capture timestamp, and two successful samples.
W1 emits class and evidence.
W1 does not mutate without W0, W2, W3, W6, and W8 authority.
Reason: the detector already exists and has fixtures.
Source: original W1 and multi-model R11 at `01-REVIEW-multi-model.md:401`.

### W2 - Permit Gate

Tag: COMPOSITION.
Action disposition: permit gate; notify-only only on refusal.
Mutation authority: none by itself.
Worker pane default: eligible only after W0 and W1 pass.
Pane 0 default: deny.
Human pane default: deny.
Callback pane default: deny.
Self-orchestrator pane default: deny.
Protected session default: deny.
Peer orchestrator default: separate permit track.
Peer-orch surface: `.flywheel/scripts/peer-orch-respawn-permit.sh`.
Output: permit/refuse row with reason and next safe action.
Reason: mutation without explicit permit recreates the original danger.
Source: multi-model R13 at `01-REVIEW-multi-model.md:442`; Donella W2 audit at `01-REVIEW-donella.md:153`.

### W3 - Threshold / Debounce

Tag: COMPOSITION.
Action disposition: timing gate; notify-only only before action threshold or on timeout refusal.
Mutation authority: none by itself.
Decision: 90s detect/log and 5m act for first worker apply canary.
After 24h dry-run, at least 20 clean cycles, one worker canary, zero false positives, zero unknown recoveries, and rollback proof, action threshold may tighten by policy.
Threshold changes are policy revisions, not operator improvisation.
Reason: sensing and acting are different feedback functions.
Source: multi-model R02 at `01-REVIEW-multi-model.md:206`; Donella D02 at `01-REVIEW-donella.md:427`; Jeff J02 at `01-REVIEW-jeff.md:239`.

### W4 - Execution And Prompt Re-Injection

Tag: COMPOSITION.
Action disposition: act-and-respawn, but only when W0-W3, W6, W8, and L60 pass.
Mutation authority: yes, only for eligible worker panes.
Preferred executor: `ntm --robot-restart-pane`.
Fallback executor: `ntm respawn SESSION --panes=PANE --force`, only if robot restart-pane fails and W0/W2/W6 remain true.
Non-MVP executor: direct production `ntm health --auto-restart-stuck`.
Non-MVP authority: `--robot-smart-restart` as sole frozen-Codex authority.
Transaction: snapshot, acquire lease, restart pane, relaunch agent, send resume prompt, reprobe, write receipt, release lease.
Prompt source order:
active dispatch receipt for session/pane,
latest worker callback expectation,
bead assignment from dispatch packet if present,
fallback safety prompt to run inbox/bead resume checks and continue only if safe.
Reason: restart without prompt provenance is not recovery.
Source: multi-model R07 at `01-REVIEW-multi-model.md:316`; Donella D10 at `01-REVIEW-donella.md:475`; Jeff J06 at `01-REVIEW-jeff.md:275`.

### W5 - Receipt / Learning Loop

Tag: COMPOSITION.
Action disposition: measurement and receipt emission.
Mutation authority: none.
Required for every path: recovery or no-action receipt.
Recovery receipt fields:
session,
pane,
class,
pre_state,
post_state,
snapshot path,
idempotency key,
ntm version,
Codex version if visible,
model id if visible,
action taken,
cooldown state,
post-probe result,
policy version,
authority state,
eligibility reason codes.
No-action receipt fields:
class,
recovery_allowed=false,
refusal_reason,
source_health,
L60 signals,
snapshot or sample path,
next_safe_action,
escalation target.
Manager-loop summary fields:
watchdog_last_fire_ts,
watchdog_driver_verified,
watcher_authority_state,
frozen_detected_count_24h,
auto_respawn_success_rate,
false_positive_respawn_count_24h,
unknown_recovery_count_24h,
protected_apply_count_24h,
same_pane_second_respawn_1h,
detector_cycle_freshness_p95_s.
Reason: information flow is incomplete until a consumer can use it.
Source: multi-model R12 at `01-REVIEW-multi-model.md:420`; Donella D05 at `01-REVIEW-donella.md:445`; Jeff J05 at `01-REVIEW-jeff.md:267`.

### W6 - Backoff / Storm Control

Tag: COMPOSITION.
Action disposition: suppression gate; notify-only fallback for over-budget, repeated, rate-limit, and quota classes.
Mutation authority: none by itself.
Policy:
first respawn per pane per hour may apply if all gates pass.
second same-pane respawn inside 1h escalates and does not re-act.
global cap is four respawns per session per hour.
rate-limit and quota classes never respawn.
Rate-limit branch emits `class=RATE_LIMITED`, `recovery_allowed=false`, and `next_action=wait_or_account_rotation`.
Quota branch emits `class=QUOTA`, `recovery_allowed=false`, and `next_action=wait_or_account_rotation`.
Budget exhaustion emits no-action receipt and manager-loop alert.
Reason: repeated recovery should dampen and learn, not amplify.
Source: multi-model R10 at `01-REVIEW-multi-model.md:381`; Donella D09 at `01-REVIEW-donella.md:469`; Jeff J11 at `01-REVIEW-jeff.md:316`.

### W7 - Escalation And Notify-Fast

Tag: COMPOSITION.
Action disposition: notify-only fallback and escalation only.
Mutation authority: none.
Notify-fast applies when class=FROZEN but eligibility refuses mutation.
Notify-fast applies when protected session needs recovery without encoded permit.
Notify-fast applies when source health is degraded.
Notify-fast applies when W6 suppresses repeated recovery.
Notify-fast applies when post-recovery verification fails.
Notify-fast applies when watchdog itself stops firing.
Escalation target is manager-loop first unless a protected or repeated failure requires Joshua.
No-action receipt is mandatory before escalation.
Reason: notify-only is useful only as a fallback/refusal branch; eligible FROZEN worker panes take the auto-respawn path once gates pass.
Source: multi-model R06 at `01-REVIEW-multi-model.md:295`; Jeff counter-thesis at `01-REVIEW-jeff.md:18`; Donella D12 at `01-REVIEW-donella.md:487`.

### W8 - Watcher Governance Loop

Tag: NEW.
Action disposition: authority governor; notify-only only when W8 demotes or refuses apply authority.
Mutation authority: none by itself, but it authorizes or demotes W4 policy.
Purpose: who watches the watchdog.
Authority states:
disabled,
observe,
canary_apply,
worker_apply,
peer_orch_dry_run,
peer_orch_apply.
Initial state: observe.
Forbidden transition: disabled -> worker_apply.
Forbidden transition: observe -> peer_orch_apply.
Forbidden transition: canary_apply -> worker_apply without zero false positives and manager-loop consumption.
Authority rises with:
clean dry-run cycles,
successful canary apply,
zero false positives,
zero unknown recoveries,
driver proof,
rollback proof,
manager-loop consumption.
Authority falls with:
false recovery,
unknown recovery,
degraded-truth apply,
stale driver,
missing receipt,
budget exhaustion,
watchdog_last_fire_ts stale,
manager-loop unable to consume summary.
Required self-health fields:
watchdog_last_fire_ts,
watchdog_driver_verified,
watchdog_last_exit_status,
watchdog_apply_enabled,
watchdog_authority_state,
watchdog_false_recovery_count_24h,
watchdog_unknown_recovery_count_24h,
watchdog_marker_only_count.
Reason: the invisible structure cannot be a paragraph; it must be a feedback loop.
Source: Donella D03 at `01-REVIEW-donella.md:433`; multi-model R04 at `01-REVIEW-multi-model.md:248`; Jeff J04 at `01-REVIEW-jeff.md:258`.

## 5. Donella Lens Applied

System boundary: flywheel worker-pane recovery and its watcher-governance control plane.
Primary stock: live dispatchable worker capacity.
Secondary stock: hidden frozen pane burden.
Secondary stock: founder interruption burden.
Secondary stock: unsafe mutation exposure.
Secondary stock: recovery receipts.
Secondary stock: watcher legitimacy.
Secondary stock: recovery storm pressure.
Core goal: no silent darkness with zero false recovery.
Core feedback question: does the actor with authority receive fresh truth before action?

W0 leverage point: #5 rules and #6 information flows.
W0 stock: unsafe mutation exposure.
W0 inflow: candidate actions from classifier.
W0 outflow: refused actions and eligible actions.
W0 loop topology: balancing safety loop.
W0 governance feedback path: refusal reasons feed W8 authority and W5 receipts.

W1 leverage point: #6 information flows.
W1 stock: hidden frozen pane burden.
W1 inflow: frozen, dead-shell, deaf, stale, unknown, and queued states.
W1 outflow: classified state with evidence.
W1 loop topology: observation loop.
W1 governance feedback path: degraded source or unknown class demotes W8 authority.

W2 leverage point: #5 rules.
W2 stock: unsafe mutation exposure.
W2 inflow: eligible candidates.
W2 outflow: permitted worker actions and refused special/protected panes.
W2 loop topology: balancing permit loop.
W2 governance feedback path: permit refusals and protected refusals feed W8 and manager-loop.

W3 leverage point: #9 delays.
W3 stock: recovery latency and false-positive risk.
W3 inflow: time since stable frozen evidence.
W3 outflow: log-only, canary action, or suppression.
W3 loop topology: delay-control loop.
W3 governance feedback path: threshold false positives demote authority.

W4 leverage point: #10 material structure.
W4 stock: dead worker slots.
W4 inflow: eligible frozen panes.
W4 outflow: recovered panes or failed verification.
W4 loop topology: repair loop.
W4 governance feedback path: post-probe success raises canary confidence; failure demotes W8.

W5 leverage point: #6 information flows and #4 self-organization.
W5 stock: recovery receipts.
W5 inflow: decisions, actions, refusals, and post-probes.
W5 outflow: manager-loop summaries, audits, future beads, and learning rows in later tasks.
W5 loop topology: learning loop.
W5 governance feedback path: missing receipt demotes W8.

W6 leverage point: #8 negative feedback.
W6 stock: recovery storm pressure.
W6 inflow: repeated freeze candidates and rate-limit/quota events.
W6 outflow: suppression, wait branch, manager-loop alert, and later root-cause work.
W6 loop topology: storm-control balancing loop.
W6 governance feedback path: budget exhaustion demotes W8 and blocks W4.

W7 leverage point: #4 self-organization.
W7 stock: unresolved unsafe or repeated conditions.
W7 inflow: refused protected needs, failed verification, repeated suppression, degraded truth, watcher silence.
W7 outflow: fallback notification, manager-loop alert, escalation receipt, later non-plan work.
W7 loop topology: escalation and learning loop.
W7 governance feedback path: escalation class counts feed W8.

W8 leverage point: #3 goals, #5 rules, and #6 information flows.
W8 stock: watcher legitimacy.
W8 inflow: clean evidence, driver proof, canary success, rollback proof.
W8 outflow: demotion, STOP, rollback, authority freeze, manager-loop alert.
W8 loop topology: watcher_governance_loop.
W8 governance feedback path: W8 is the path; it authorizes, holds, or demotes the watcher.

Highest leverage decision: add W8 and W0 as primitives.
Why: this prevents leverage theater.
Thresholds remain useful but secondary.
Rules and information flow carry the safety burden.
Self-organization carries the learning burden.
The paradigm shift is valid only if W8 prevents the watcher from becoming invisible.

## 6. Jeff Lens Applied

Jeff read: this should not become a new respawner.
The final plan composes existing primitives.
The plan keeps ntm source work out of scope.
The plan keeps Codex upgrade out of scope.
The plan keeps broad health auto-restart out of production authority.
The plan keeps smart-restart advisory rather than sole authority.
The plan keeps peer-orch recovery behind permit gates.
The plan keeps protected sessions default-deny.
Joshua override rejects notify-only as the primary strategy.
Auto-respawn is the primary live behavior for eligible FROZEN worker panes once dry-run, canary, rollback, L60, budget, and watcher-authority gates pass.
Notify-only is a fallback branch only.
Notify-only applies to protected, unknown, watch, degraded-truth, over-budget, rate-limit, quota, peer-orch dry-run, watcher-stale, and failed-verification classes.
Notify-only does not apply to an eligible FROZEN worker pane after the action gate is open.
The auto-respawn decision is therefore split:
W0: gate; notify-only fallback on refusal.
W1: classify; notify-only fallback for non-action classes.
W2: permit; notify-only fallback on denied targets.
W3: threshold; notify-only fallback before action threshold or on stale evidence.
W4: act-and-respawn; primary path for eligible FROZEN worker panes.
W5: receipt; emits both recovery and no-action receipts.
W6: storm control; notify-only fallback on repeated, over-budget, rate-limit, or quota classes.
W7: escalation; notify-only fallback for refused or failed paths.
W8: authority governance; notify-only fallback on demotion or stale watcher proof.
Final decision: notify faster is not the strategy; auto-respawn is the strategy, and notify-only is the safety fallback.
Implementation posture later: patch flywheel policy surfaces only.
No ntm source churn.
No second detector.
No second respawner.

## 7. Per-Change Disposition Table

Summary:
ACCEPT: 41
REVISE: 4
REJECT: 0
DEFER: 0
Total dispositioned: 45 / 45

| ID | Source | Change | Disposition | Rationale |
|---|---|---|---|---|
| R01 | multi-model | Add W0 eligibility preflight | ACCEPT | Promoted to W0; safety gates were too scattered. Source `01-REVIEW-multi-model.md:181`; corroborated by Donella D01 and Jeff J01. |
| R02 | multi-model | Split detect threshold and action threshold | ACCEPT | Final policy is 90s detect/log and 5m act for first canary. Source `01-REVIEW-multi-model.md:206`; no counter-evidence. |
| R03 | multi-model | Name fleet apply handoff | ACCEPT | Central gap is current `apply_blocked_by_design`. Source `01-REVIEW-multi-model.md:227`; Socraticode confirmed wrapper block. |
| R04 | multi-model | Promote watchdog self-health to required state | ACCEPT | Integrated into W8 self-health fields. Source `01-REVIEW-multi-model.md:248`; L57 supports driver proof. |
| R05 | multi-model | Add recovery state machine | REVISE | Accepted as state transitions across W0-W8, not a separate 10th primitive. Source `01-REVIEW-multi-model.md:271`; revised to avoid extra abstraction. |
| R06 | multi-model | Add notify-fast non-mutation branch | ACCEPT | Integrated only as fallback/refusal path under Joshua override; eligible FROZEN workers use auto-respawn primary. Source `01-REVIEW-multi-model.md:295`; Jeff conditional notify-first is overridden. |
| R07 | multi-model | Define resume prompt source | ACCEPT | Integrated into W4. Source `01-REVIEW-multi-model.md:316`; corroborated by Donella D10 and Jeff J06. |
| R08 | multi-model | Require canary evidence before threshold tightening | ACCEPT | Integrated into W3 and ship order. Source `01-REVIEW-multi-model.md:338`; agent-lifecycle canary doctrine supports it. |
| R09 | multi-model | Add explicit rollback test | ACCEPT | Integrated into W8, success criteria, and Phase 0. Source `01-REVIEW-multi-model.md:360`; lifecycle skill requires reversibility. |
| R10 | multi-model | Route rate limits to wait, not recovery | ACCEPT | Integrated into W6. Source `01-REVIEW-multi-model.md:381`; ntm smart-restart WAITING state supports this. |
| R11 | multi-model | Add L60 preflight to in-scope list | ACCEPT | Integrated as hard mutation preflight. Source `01-REVIEW-multi-model.md:401`; AGENTS L60 forbids unknown recovery. |
| R12 | multi-model | Add manager-loop consumer contract | ACCEPT | Integrated into W5 and cross-plan relationships. Source `01-REVIEW-multi-model.md:420`; no counter-evidence. |
| R13 | multi-model | Separate worker and peer-orch lanes | ACCEPT | Integrated into W2, W7, W8, and ship order. Source `01-REVIEW-multi-model.md:442`; L115 supports separation. |
| R14 | multi-model | Add fixture-based acceptance before live apply | ACCEPT | Integrated into ship order and success criteria. Source `01-REVIEW-multi-model.md:463`; detector self-test evidence supports it. |
| R15 | multi-model | Add positive no-action receipt requirement | ACCEPT | Integrated into W5 and W7. Source `01-REVIEW-multi-model.md:484`; Donella D05 agrees. |
| R16 | multi-model | Add apply identity and version fields | REVISE | Kept policy version, authority state, and reason codes; omitted excess identity detail until implementation. Source `01-REVIEW-multi-model.md:505`; plan-space scope argues for compact fields. |
| R17 | multi-model | Add degraded truth stop condition to thresholds | ACCEPT | Integrated into W0, W8, and red thresholds. Source `01-REVIEW-multi-model.md:525`; L60 supports. |
| R18 | multi-model | Add seven-day before/after chart definition | ACCEPT | Integrated into success criteria. Source `01-REVIEW-multi-model.md:545`; no counter-evidence. |
| D01 | donella | Add W0 eligibility preflight | ACCEPT | Promoted to W0. Source `01-REVIEW-donella.md:421`; aligns with R01/J01. |
| D02 | donella | Split detection and action thresholds | ACCEPT | Integrated into W3. Source `01-REVIEW-donella.md:427`; aligns with R02/J02. |
| D03 | donella | Add watcher-governance loop | ACCEPT | Promoted to W8 and named `watcher_governance_loop`. Source `01-REVIEW-donella.md:433`; this is the invisible structure. |
| D04 | donella | Require L60 before apply | ACCEPT | Integrated into W0 and constraints. Source `01-REVIEW-donella.md:439`; AGENTS L60 confirms. |
| D05 | donella | Require no-action receipts | ACCEPT | Integrated into W5. Source `01-REVIEW-donella.md:445`; no counter-evidence. |
| D06 | donella | Define manager-loop consumer contract | REVISE | Accepted but placed in W5 and Section 8 instead of a separate primitive. Source `01-REVIEW-donella.md:451`; revised for plan compactness. |
| D07 | donella | Require rollback proof before apply | ACCEPT | Integrated into W8 and Phase 0. Source `01-REVIEW-donella.md:457`; lifecycle skill supports. |
| D08 | donella | Define canary promotion and demotion | ACCEPT | Integrated into W8 authority states. Source `01-REVIEW-donella.md:463`; no counter-evidence. |
| D09 | donella | Define rate-limit wait branch | ACCEPT | Integrated into W6. Source `01-REVIEW-donella.md:469`; ntm WAITING state supports. |
| D10 | donella | Define prompt provenance | ACCEPT | Integrated into W4. Source `01-REVIEW-donella.md:475`; aligns with R07/J06. |
| D11 | donella | Treat false positive as demotion signal | ACCEPT | Integrated into W8 and verdict thresholds. Source `01-REVIEW-donella.md:481`; no counter-evidence. |
| D12 | donella | Treat watchdog silence as recovery failure | ACCEPT | Integrated into W8 and W7. Source `01-REVIEW-donella.md:487`; L57 supports. |
| J01 | jeff | Add W0 eligibility preflight | ACCEPT | Promoted to W0. Source `01-REVIEW-jeff.md:228`; aligns with R01/D01. |
| J02 | jeff | Resolve threshold question | ACCEPT | Integrated into W3. Source `01-REVIEW-jeff.md:239`; no Joshua question needed. |
| J03 | jeff | Name current fleet-wrapper block | ACCEPT | Integrated into hard evidence, W8, and ship order. Source `01-REVIEW-jeff.md:249`; Socraticode confirmed. |
| J04 | jeff | Add watcher self-health fields | ACCEPT | Integrated into W8. Source `01-REVIEW-jeff.md:258`; L57 supports. |
| J05 | jeff | Add no-action receipts | ACCEPT | Integrated into W5. Source `01-REVIEW-jeff.md:267`; aligns with R15/D05. |
| J06 | jeff | Add prompt provenance | ACCEPT | Integrated into W4. Source `01-REVIEW-jeff.md:275`; aligns with R07/D10. |
| J07 | jeff | Add rollback gate | ACCEPT | Integrated into Phase 0 and W8. Source `01-REVIEW-jeff.md:283`; lifecycle rollback doctrine supports. |
| J08 | jeff | Add L60 hard preflight | ACCEPT | Integrated into W0 and constraints. Source `01-REVIEW-jeff.md:290`; AGENTS L60 confirms. |
| J09 | jeff | Define worker vs peer-orch lanes | ACCEPT | Integrated into W2, W8, and ship order. Source `01-REVIEW-jeff.md:298`; L115 confirms. |
| J10 | jeff | Define canary count minimum | ACCEPT | Integrated into W3, success criteria, and ship order. Source `01-REVIEW-jeff.md:307`; no counter-evidence. |
| J11 | jeff | Keep rate-limit branch explicit | ACCEPT | Integrated into W6. Source `01-REVIEW-jeff.md:316`; ntm smart-restart WAITING supports. |
| J12 | jeff | Add apply policy version | REVISE | Kept policy version and authority state; merged with R16 to avoid bloated receipt fields. Source `01-REVIEW-jeff.md:323`; revised for compactness. |
| J13 | jeff | Add degraded-truth red condition | ACCEPT | Integrated into red thresholds. Source `01-REVIEW-jeff.md:331`; L60 confirms. |
| J14 | jeff | Define seven-day chart | ACCEPT | Integrated into success criteria. Source `01-REVIEW-jeff.md:339`; aligns with R18. |
| J15 | jeff | Prohibit source churn in the plan | ACCEPT | Integrated into out of scope and green thresholds. Source `01-REVIEW-jeff.md:349`; no counter-evidence. |

## 8. Cross-Plan Relationships

Watchdog is a substrate-layer plan.
It sits below manager-loop, fleet-autonomy, and mission-coverage.
It does not choose mission work.
It keeps worker capacity alive and safe so mission work can continue.
Manager-loop consumes watchdog receipts and watcher governance state.
Fleet-autonomy consumes recovery SLO and storm-control state as a balancing loop.
Mission-coverage consumes capacity indirectly by proving completed work maps to mission outcomes.
The shared vocabulary is:
no_silent_darkness,
watchdog_authority_state,
watchdog_last_fire_ts,
recovery_receipt_coverage,
manual_respawn_count_7d,
false_positive_respawn_count_7d,
unknown_auto_recovery_count_7d,
protected_session_auto_apply_count,
same_pane_second_respawn_1h,
detector_cycle_freshness_p95_s.
Watchdog ships before broad manager-loop apply.
Watchdog ships before fleet-autonomy assumes continuous dispatch capacity.
Watchdog receipts become manager-loop summaries, not a new pane-message flood.
Peer-orch recovery remains a separate track because its authority boundary differs from worker-pane recovery.
The substrate ordering is:
watchdog: keep panes alive and safe,
manager-loop: aggregate state and choose next action,
fleet-autonomy: choose work and damp divergent loops,
mission-coverage: prove completed work maps to mission surfaces.

## 9. Cross-Research Input Integration

Ntm research conclusion remains accepted.
Classify in flywheel.
Execute in ntm.
Use frozen-pane-v2 plus `ntm --robot-restart-pane`.
Keep `ntm respawn` as fallback.
Do not use broad health auto-restart as production authority.
Do not make smart-restart sole authority.
Codex research conclusion remains accepted.
Codex 0.128.0/gpt-5.5 migration is canary evidence, not the freeze cure.
Watchdog metrics should ship before fleet-wide Codex migration.
After watchdog metrics exist, a Codex canary can compare frozen strike rate before and after upgrade.
Skills baseline conclusion:
loop-enforcement, observability, uptime/SLA, agent-monitoring, and human-in-the-loop are adjacent patterns.
They reinforce W8 rather than replace the dispatch-listed skills.
Socraticode conclusion:
flywheel and ntm already contain the needed execution and observation substrate.
The missing work is policy integration and evidence routing.
No paid API auth, npm global upgrade, or ntm source modification is in scope.

## 10. Success Criteria

Composite score remains >= 9.5 after r1 audit.
manual_respawn_count_7d reaches 0 for eligible worker panes.
frozen_pane_MTTR_p95 is <= 180s after action threshold is tightened.
auto_respawn_success_rate is >= 95% after dry-run and canary.
false_positive_respawn_count_7d is 0.
unknown_auto_recovery_count_7d is 0.
protected_session_auto_apply_count is 0 unless explicit encoded permit exists.
same_pane_second_respawn_1h escalates and does not re-act.
recovery_receipt_coverage is 100%.
no_action_receipt_coverage is 100%.
watchdog_last_fire_ts is <= 2 cadence windows old.
watchdog_driver_verified is true before apply.
watchdog_authority_state is explicit.
manager_loop_consumed_watchdog_summary_count is >0 before worker expansion.
rollback_probe_passed is true before apply.
L60_signals_present is 5/5 before mutation.
source_health_degraded_apply_count is 0.
rate_limit_restart_count is 0.
quota_restart_count is 0.
prompt_provenance_present_pct is 100% for recoveries.
Seven-day before/after chart rows:
manual_respawn_count,
frozen_detected_count,
auto_respawn_applied_count,
auto_respawn_success_rate,
false_positive_respawn_count,
unknown_auto_recovery_count,
protected_apply_count,
same_pane_second_respawn_1h,
detector_freshness_p95,
watchdog_authority_state_changes.

## 11. In Scope / Out Of Scope

In scope:
Enable `.flywheel/scripts/frozen-pane-detector-fleet.sh` as watchdog surface.
Use `.flywheel/scripts/frozen-pane-detector.sh` as classifier/applier.
Preserve dry-run before apply.
Add W0 eligibility as a first-class plan primitive.
Add W8 watcher_governance_loop as a first-class plan primitive.
Use L60 no-silent-darkness as hard preflight.
Apply only to eligible worker panes after permit, threshold, budget, truth, and authority gates.
Emit recovery and no-action receipts.
Expose manager-loop consumable watchdog summary.
Keep peer-orch recovery behind `.flywheel/scripts/peer-orch-respawn-permit.sh`.
Define rollout, rollback, and verdict thresholds.

Out of scope:
Codex version/auth migration.
Paid API-key GPT-5.5 migration.
Ntm source work.
New respawner script.
Second detector.
`--robot-smart-restart` as sole authority.
Direct production `ntm health --auto-restart-stuck`.
Protected client-session auto-recovery.
`flywheel:1` self-recovery.
New manager-loop implementation logic.
New mission-coverage logic.
Bead creation from this plan-space task.
Source edits from this integration task.

## 12. Constraints

Plan-space only for this artifact.
No source edits.
No bead writes.
No Joshua question.
Ntm only for pane operations.
Protected sessions default deny.
Pane 0 default deny.
Human pane default deny.
Callback pane default deny.
Flywheel self-orchestrator default deny.
Peer orchestrator requires permit decision.
Source health degraded blocks apply.
L60 less than 5/5 blocks apply.
Capture provenance not live blocks apply.
Stale capture timestamp blocks apply.
UNKNOWN blocks apply.
WATCH blocks apply.
Template prompt blocks respawn.
Post-completion buffer blocks respawn.
Queued-not-submitted uses its own non-respawn branch.
Rate-limit blocks respawn.
Quota blocks respawn.
First respawn per pane per hour may apply only after all gates pass.
Second same-pane respawn inside one hour escalates and does not re-act.
Session cap is four respawns per hour.
Rollback path must be tested before apply.
Apply authority must be visible through W8.
Manager-loop consumption must exist before expansion.
No silent launchd apply enablement.
No hidden env-only promotion to apply.

## 13. Open Questions For r1 Audit

Question 1: does W8 authority state need a concrete schema before implementation, or is the field list sufficient for bead decomposition?
Recommended r1 audit stance: require a schema before source edit.
Question 2: should the first worker apply canary target one specific flywheel pane or any eligible worker pane chosen by the detector?
Recommended r1 audit stance: one explicit pane for the first canary.
Question 3: should 5m action threshold tighten after 24h dry-run plus one canary, or require seven-day evidence first?
Recommended r1 audit stance: tighten only after 24h dry-run plus one canary for flywheel workers; require seven days before peer-orch apply.
Question 4: should no-action receipts flow to manager-loop immediately or be summarized hourly?
Recommended r1 audit stance: immediate compact summary plus hourly rollup.
Question 5: should `watchdog_authority_state` demotion auto-disable LaunchAgent apply or merely block the apply branch?
Recommended r1 audit stance: block apply branch immediately; disable LaunchAgent apply on repeated demotion.
These are r1 audit questions, not Joshua blockers.

## 14. Ship Order

Phase 0.0: integrate this r1 plan.
Rationale: plan-space mistakes cost less than code-space mistakes.
Phase 0.1: verify detector self-test and fixture coverage.
Rationale: classification trust comes before action.
Phase 0.2: verify fleet wrapper doctor, disabled/default observe contract, and `apply_blocked_by_design` current state.
Rationale: the policy handoff must start from known current behavior.
Phase 0.3: define W0 eligibility schema and W8 authority schema.
Rationale: gates need machine-readable contracts.
Phase 0.4: prove rollback with STOP file and LaunchAgent disable/unload.
Rationale: apply authority must be reversible.
Phase 1.0: run dry-run watchdog cycle for 24h or at least 20 cycles.
Rationale: observe before action.
Phase 1.1: write manager-loop consumable dry-run summary.
Rationale: producer receipts need a consumer.
Phase 1.2: prove zero degraded-truth apply attempts and zero unknown recovery plans.
Rationale: L60 is the hard safety boundary.
Phase 2.0: implement canary-only apply path replacing fleet wrapper `apply_blocked_by_design` only under explicit canary policy.
Rationale: this is the narrow source edit later, not in plan-space.
Phase 2.1: run one flywheel worker pane canary with 90s detect and 5m act.
Rationale: auto-respawn is primary for eligible FROZEN worker panes, but the first canary remains conservative and gate-bound.
Phase 2.2: require snapshot, lease, restart, relaunch, prompt, reprobe, ledger, and manager-loop summary.
Rationale: recovery is a transaction, not a kill.
Phase 2.3: verify rollback still works after canary.
Rationale: lifecycle discipline requires reversible authority.
Phase 3.0: expose budget, false-positive, unknown, protected, and authority metrics.
Rationale: W8 needs signals.
Phase 3.1: stop or demote if any false positive appears.
Rationale: authority falls faster than it rises.
Phase 4.0: expand to non-protected worker panes only.
Rationale: worker path is the bounded MVP.
Phase 5.0: run peer-orch dry-run track through permit gate.
Rationale: peer-orch has different rules.
Phase 5.1: keep `PEER_ORCH_AUTO_RESPAWN=0` until seven-day permit receipts are clean.
Rationale: peer-orch apply has higher blast radius.
Phase 6.0: use watchdog metrics to inform Codex canary research.
Rationale: upstream upgrade decisions need local baseline data.

## 15. Verdict Thresholds

GREEN:
compose-not-new preserved.
W0 eligibility present.
W8 watcher_governance_loop present.
24h dry-run receipts exist.
At least 20 dry-run cycles exist.
No degraded-truth apply.
No unknown auto-recovery.
No protected-session auto-apply.
Manager-loop can read recovery metrics.
Rollback proof passed.
No ntm source edits.
No new respawner.
No second detector.

YELLOW:
detector works but watcher freshness is not manager-loop visible.
threshold tightening remains unresolved after canary.
peer-orch dry-run emits permit refusals but no apply.
receipts lack non-core fields.
prompt provenance falls back to generic safety prompt.
manager-loop consumes hourly summary but not immediate compact rows.
W8 authority state exists in prose but not schema.

RED:
apply can touch pane 0.
apply can touch human pane.
apply can touch callback pane.
apply can touch protected session without encoded permit.
apply can touch flywheel self-orchestrator.
apply can recover UNKNOWN.
apply can recover WATCH.
apply can recover template prompt.
apply can recover post-completion buffer.
apply can recover queued-not-submitted as respawn.
apply occurs while source_health is degraded.
apply occurs with capture_provenance not live.
apply occurs with stale capture_collected_at.
apply occurs with L60 less than 5/5.
direct production `ntm health --auto-restart-stuck`.
Codex upgrade treated as watchdog substitute.
same pane can respawn twice in 1h without escalation.
mutation lacks snapshot.
mutation lacks receipt.
watchdog apply enabled without W8 authority state.
`apply_blocked_by_design` removed without canary gate.

## Appendix A - Review Citations

Multi-model verdict: revise, composite 9.6, at `01-REVIEW-multi-model.md:1`.
Multi-model core finding: observe-to-apply state machine needed, at `01-REVIEW-multi-model.md:13`.
Multi-model R01: W0 eligibility, at `01-REVIEW-multi-model.md:181`.
Multi-model R02: threshold split, at `01-REVIEW-multi-model.md:206`.
Multi-model R03: fleet apply handoff, at `01-REVIEW-multi-model.md:227`.
Multi-model R04: watchdog self-health, at `01-REVIEW-multi-model.md:248`.
Multi-model R05: recovery state machine, at `01-REVIEW-multi-model.md:271`.
Multi-model R06: notify-fast branch, at `01-REVIEW-multi-model.md:295`.
Multi-model R07: prompt source, at `01-REVIEW-multi-model.md:316`.
Multi-model R08: canary evidence, at `01-REVIEW-multi-model.md:338`.
Multi-model R09: rollback test, at `01-REVIEW-multi-model.md:360`.
Multi-model R10: rate-limit wait, at `01-REVIEW-multi-model.md:381`.
Multi-model R11: L60 preflight, at `01-REVIEW-multi-model.md:401`.
Multi-model R12: manager-loop consumer, at `01-REVIEW-multi-model.md:420`.
Multi-model R13: worker vs peer-orch lanes, at `01-REVIEW-multi-model.md:442`.
Multi-model R14: fixture acceptance, at `01-REVIEW-multi-model.md:463`.
Multi-model R15: no-action receipts, at `01-REVIEW-multi-model.md:484`.
Multi-model R16: apply identity fields, at `01-REVIEW-multi-model.md:505`.
Multi-model R17: degraded truth red condition, at `01-REVIEW-multi-model.md:525`.
Multi-model R18: seven-day chart, at `01-REVIEW-multi-model.md:545`.
Donella verdict: revise, composite 9.7, at `01-REVIEW-donella.md:1`.
Donella invisible structure: watcher-governance loop, at `01-REVIEW-donella.md:1`.
Donella D01: W0 eligibility, at `01-REVIEW-donella.md:421`.
Donella D02: threshold split, at `01-REVIEW-donella.md:427`.
Donella D03: watcher-governance loop, at `01-REVIEW-donella.md:433`.
Donella D04: L60 before apply, at `01-REVIEW-donella.md:439`.
Donella D05: no-action receipts, at `01-REVIEW-donella.md:445`.
Donella D06: manager-loop consumer, at `01-REVIEW-donella.md:451`.
Donella D07: rollback proof, at `01-REVIEW-donella.md:457`.
Donella D08: canary promotion/demotion, at `01-REVIEW-donella.md:463`.
Donella D09: rate-limit wait branch, at `01-REVIEW-donella.md:469`.
Donella D10: prompt provenance, at `01-REVIEW-donella.md:475`.
Donella D11: false-positive demotion, at `01-REVIEW-donella.md:481`.
Donella D12: watchdog silence failure, at `01-REVIEW-donella.md:487`.
Jeff verdict: revise, composite 9.6, at `01-REVIEW-jeff.md:1`.
Jeff counter-thesis: conditional in review, at `01-REVIEW-jeff.md:18`; rejected for primary strategy by Joshua override in this r1 integration.
Jeff J01: W0 eligibility, at `01-REVIEW-jeff.md:228`.
Jeff J02: threshold answer, at `01-REVIEW-jeff.md:239`.
Jeff J03: fleet wrapper block, at `01-REVIEW-jeff.md:249`.
Jeff J04: watcher self-health, at `01-REVIEW-jeff.md:258`.
Jeff J05: no-action receipts, at `01-REVIEW-jeff.md:267`.
Jeff J06: prompt provenance, at `01-REVIEW-jeff.md:275`.
Jeff J07: rollback gate, at `01-REVIEW-jeff.md:283`.
Jeff J08: L60 hard preflight, at `01-REVIEW-jeff.md:290`.
Jeff J09: worker vs peer-orch lanes, at `01-REVIEW-jeff.md:298`.
Jeff J10: canary count minimum, at `01-REVIEW-jeff.md:307`.
Jeff J11: rate-limit branch, at `01-REVIEW-jeff.md:316`.
Jeff J12: apply policy version, at `01-REVIEW-jeff.md:323`.
Jeff J13: degraded truth red condition, at `01-REVIEW-jeff.md:331`.
Jeff J14: seven-day chart, at `01-REVIEW-jeff.md:339`.
Jeff J15: prohibit source churn, at `01-REVIEW-jeff.md:349`.

## Appendix B - Socraticode And Skill Survey

Socraticode project `/Users/josh/Developer/flywheel`: green.
Socraticode project `/Users/josh/Developer/flywheel`: 694 indexed chunks observed.
Socraticode project `/Users/josh/Developer/ntm`: green.
Socraticode project `/Users/josh/Developer/ntm`: 31,740 indexed chunks observed.
Socraticode searches run: 10 K>=10 searches plus status checks.
Flywheel search themes:
fleet apply blocked by design,
watcher governance,
no silent darkness,
peer-orch permit,
manager-loop consumption.
Ntm search themes:
robot restart pane,
smart restart,
respawn defaults,
capture provenance,
health auto-restart.
Skill baseline query: `watcher governance loop watchdog notification self-monitoring`.
Skills-best-practices adjacent hits:
loop-enforcement,
observability-platform,
uptime-monitoring,
sla-monitoring,
agent-monitoring,
human-in-the-loop.
Mandatory skills consulted:
planning-workflow,
donella-meadows-systems-thinking,
jeff-planning-enhanced,
jeff-convergence-audit,
canonical-cli-scoping,
protected-session-recovery,
agent-lifecycle,
accretive-cron-orchestration,
flywheel:skills-best-practices.
Planning-workflow exact integrate prompt applied: integrate revisions in-place, use ultrathink, and report agreement levels.
Donella skill applied: stock, flow, feedback, leverage, and anti-pattern analysis.
Jeff planning applied: plan-space first, convergence before implementation, blunder hunt.
Canonical CLI scoping applied: doctor, health, dry-run, apply, audit, JSON, and rollback surfaces remain required later.
Protected-session recovery applied: protected sessions default deny and require explicit authorized evidence.
Agent-lifecycle applied: canary first and rollback under five minutes.
Accretive cron orchestration applied: watcher health is a self-regulating loop, not prose.

## Appendix C - Convergence Notes

All three lanes agreed on W0 eligibility.
All three lanes agreed on threshold split.
All three lanes agreed on no-action receipts.
All three lanes agreed on prompt provenance.
All three lanes agreed on rollback before apply.
All three lanes agreed on rate-limit wait branch.
All three lanes agreed on L60 preflight.
All three lanes agreed on worker vs peer-orch separation.
All three lanes agreed on zero ntm source edits.
The only meaningful conflict was notify-only versus auto-respawn.
Joshua override resolves it: auto-respawn is primary for eligible FROZEN worker panes.
This plan keeps notify-only only as a permanent fallback/refusal branch.
This plan makes act-and-respawn available only in W4 and only for eligible worker panes.
That keeps the safety gates without preserving founder-as-recovery-loop.
The other meaningful conflict was whether watcher governance is a section or a primitive.
This plan makes it W8.
That is the structural answer to the invisible structure.

## Appendix D - Change Disposition Totals

ACCEPT rows: 41.
REVISE rows: 4.
REJECT rows: 0.
DEFER rows: 0.
Total rows: 45.
Revised items:
R05: state machine incorporated across W0-W8 rather than standalone primitive.
R16: receipt identity fields compacted to policy version, authority state, and reason codes.
D06: manager-loop consumer contract placed in W5 and relationship section.
J12: apply policy version merged with R16 to avoid bloated receipt fields.
No rejected items.
No deferred items.
Composite remains 9.6 because all high-severity review findings are structurally integrated.
