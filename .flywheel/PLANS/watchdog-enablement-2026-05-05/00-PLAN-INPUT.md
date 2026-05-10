---
title: "00-PLAN-INPUT - Watchdog Enablement"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# 00-PLAN-INPUT - Watchdog Enablement

Date: 2026-05-05
Status: plan-space input for review lanes
Constraint: no source edits, no bead writes, no Joshua question
Output: `.flywheel/PLANS/watchdog-enablement-2026-05-05/00-PLAN-INPUT.md`
Primary inputs:
- `/tmp/research-ntm-auto-respawn-2026-05-05.md`
- `/tmp/research-codex-gpt55-upgrade-2026-05-05.md`
- `.flywheel/scripts/frozen-pane-detector.sh`
- `.flywheel/scripts/frozen-pane-detector-fleet.sh`
- `.flywheel/scripts/peer-orch-respawn-permit.sh`
- `/Users/josh/.claude/commands/flywheel/respawn.md`
- `feedback_orchestrators_kill_panes_without_respawn.md`

---

## 1. Why this plan exists

Manual respawn is the failure mode.

The current fleet still lets Joshua become the recovery loop when a pane is
frozen, dead-shell, or mis-relaunched. That violates the system goal: the
flywheel should recover tactical substrate failures without founder attention.

The pain is not missing machinery. The ntm research says the safe MVP is
"classify in flywheel, execute in ntm" using frozen-pane-v2 plus ntm
respawn/restart-pane, not bare health idle restart and not robot-smart-restart
as the only gate (`/tmp/research-ntm-auto-respawn-2026-05-05.md:12-16`,
`/tmp/research-ntm-auto-respawn-2026-05-05.md:651-654`).

The plan exists because the detector and execution primitives exist, but the
watchdog is not yet enabled as an action loop. The research names this directly:
promote frozen-pane-v2 from script to controlled worker-pane service
(`/tmp/research-ntm-auto-respawn-2026-05-05.md:747-756`).

The correct intervention is therefore not "upgrade Codex and hope."
Codex research says stable 0.128.0 fixes zero exact known local freeze bugs and
still requires canary evidence (`/tmp/research-codex-gpt55-upgrade-2026-05-05.md:382-421`).

This plan makes watchdog enablement the substrate layer under manager-loop,
fleet-autonomy, and mission-coverage. Those plans choose work and grade mission
coverage. This one keeps the workers alive enough for those plans to matter.

## 2. Hard evidence

Joshua already named the failure class. The memory says orchestrators across
flywheel, mobile-eats, and others kill or lose panes without auto-respawning the
agent; today included two manual recoveries on `flywheel:0.3` and two on
`mobile-eats:0.2`
(`/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_orchestrators_kill_panes_without_respawn.md:1-7`).

The dispatch packet escalates the same class to about 30 manual respawns over
three days and names Joshua's burden as the failure signal
(`/tmp/dispatch_plan-watchdog-enablement-2026-05-05.md:42-45`).

That same memory records pane 3 ERROR twice in one session and manual recovery
cost of 2x for flywheel alone
(`/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_orchestrators_kill_panes_without_respawn.md:26-31`).

The stronger follow-up memory records six manual respawns in one morning caused
by orchestrator recovery mistakes
(`/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_orchestrator_is_the_killer_not_codex.md:7-18`).

The manager-loop plan gives the overnight fleet-level symptom: four frozen panes
were recovered only after Joshua woke
(`.flywheel/PLANS/manager-loop-architecture-2026-05-05/00-PLAN-INPUT.md:21-29`).

The manual slash protocol is six operational steps: capture pane tail, author a
resume prompt, respawn shell, relaunch agent, wait for the banner, and inject
the resume prompt
(`/Users/josh/.claude/commands/flywheel/respawn.md:21-31`).

The underlying reason the six-step path is brittle is that `ntm respawn` kills
and restarts the shell but does not relaunch the agent or inject a resume prompt
(`/tmp/research-ntm-auto-respawn-2026-05-05.md:69-74`,
`/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_ntm_respawn_relaunches_shell_only.md:7-18`).

The detector already has the missing recovery transaction: snapshot, restart,
relaunch, resume prompt, reprobe, and ledger
(`/tmp/research-ntm-auto-respawn-2026-05-05.md:289-294`,
`/tmp/research-ntm-auto-respawn-2026-05-05.md:600-608`).

The detector code confirms the action path: it copies a snapshot, calls
`ntm --robot-restart-pane`, relaunches the agent command, sends a resume prompt,
reprobes, writes strike and recovery ledgers, and releases the lease
(`.flywheel/scripts/frozen-pane-detector.sh:780-804`).

The fleet wrapper confirms why the system is still mostly observe-only: scheduled
cycles are disabled by default and observation-only
(`.flywheel/scripts/frozen-pane-detector-fleet.sh:44-59`,
`.flywheel/scripts/frozen-pane-detector-fleet.sh:95-110`).

## 3. Paradigm shift

Current paradigm:

The orchestrator detects or hears about a pane freeze, then asks Joshua or waits
for Joshua to notice. The founder supplies the balancing loop.

Replacement paradigm:

The orchestrator's watchdog detects a frozen worker pane and acts within
encoded permit gates. Joshua only sees receipts, repeated failures, protected
session requests, or recovery storms.

This is a Donella leverage point #2/#3/#5 shift:

- #2 paradigm: founder-as-recovery-loop becomes system-as-recovery-loop.
- #3 goal: optimize no-silent-darkness and recovery SLO, not "avoid touching panes."
- #5 rules: pane mutation becomes allowed only through detector, permit, budget, and receipt gates.
- #6 information flow: frozen state and recovery receipts reach manager-loop as metrics.

The shift is not "be more aggressive." It is "make recovery a verified
transaction with conservative default-deny gates."

The removal-class anti-pattern remains forbidden: touching a pane on one stale
robot-activity row. The detector uses byte-delta and multi-frame evidence; the
memory explicitly says a single capture is not enough
(`/Users/josh/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_single_capture_misses_freeze.md:7-18`).

## 4. 7 atomic primitives

### W1 - Detector/classifier

Use `.flywheel/scripts/frozen-pane-detector.sh` as the canonical classifier.
It is existing primitive 8 and defaults to observation/dry-run unless
`--auto-recover --apply` is supplied
(`/tmp/research-ntm-auto-respawn-2026-05-05.md:289-294`).
Only `FROZEN` may trigger respawn; `WATCH`, `UNKNOWN`, template prompts,
post-completion buffer, and queued-not-submitted are non-respawn classes
(`/tmp/research-ntm-auto-respawn-2026-05-05.md:386-430`,
`/tmp/research-ntm-auto-respawn-2026-05-05.md:665-670`).
Required live truth: healthy source, live capture provenance, fresh
`capture_collected_at`, and two successful robot-tail samples
(`/tmp/research-ntm-auto-respawn-2026-05-05.md:661-664`).

### W2 - Permit gate

Determine whether a pane may mutate automatically. Flywheel worker panes are
eligible after detector gates pass. Pane 0, human panes, callback panes,
self-orchestrator panes, and protected sessions are denied by default
(`/tmp/research-ntm-auto-respawn-2026-05-05.md:655-660`).
Peer orchestrators stay on the separate permit track; the permit script refuses
protected sessions and self/callback/human panes, and permits only confirmed
freeze evidence (`.flywheel/scripts/peer-orch-respawn-permit.sh:187-245`).
Default: `deny_protected_session`.

### W3 - Threshold/debounce

Decide when observation becomes action. Existing defaults are 90s frozen
threshold, 60s queued threshold, 60s timer drift, 100 byte minimum live delta,
and 1s sample interval (`/tmp/research-ntm-auto-respawn-2026-05-05.md:548-556`).
The MVP repeats 90s, <100 bytes, >=60s timer drift, one recovery per pane/hour,
and four per session/hour (`/tmp/research-ntm-auto-respawn-2026-05-05.md:671-682`).
Review-lane choice: 90s action immediately, or 90s log / 5m act for day one.

### W4 - Execution and prompt re-injection

Preferred executor: detector calls `ntm --robot-restart-pane` with pane filter,
then relaunches the agent and sends a resume prompt. Research says this route
supports session/pane selection, dry-run, optional prompt, liveness checks, and
structured robot JSON output
(`/tmp/research-ntm-auto-respawn-2026-05-05.md:76-107`,
`/tmp/research-ntm-auto-respawn-2026-05-05.md:253-260`).
Fallback executor: `ntm respawn SESSION --panes=PANE --force` if robot
restart-pane parsing fails. Research names this fallback explicitly
(`/tmp/research-ntm-auto-respawn-2026-05-05.md:100-107`,
`/tmp/research-ntm-auto-respawn-2026-05-05.md:687-690`).
Non-MVP executor: do not use `ntm health --auto-restart-stuck` directly for
production Codex panes because its health/idle classifier is too broad
(`/tmp/research-ntm-auto-respawn-2026-05-05.md:269-279`,
`/tmp/research-ntm-auto-respawn-2026-05-05.md:717-719`).
Non-MVP authority: do not use `--robot-smart-restart` as sole frozen-Codex
authority. Issue #114 is closed, but remaining work-state divergence means it is
not operationally complete for smart-restart authority
(`/tmp/research-ntm-auto-respawn-2026-05-05.md:471-488`,
`/tmp/research-ntm-auto-respawn-2026-05-05.md:140-149`).

### W5 - Receipt/learning loop

Required fields: session, pane, class, pre-state, post-state, snapshot path,
idempotency key, ntm version, Codex version if visible, action taken, cooldown
state, and post-probe result.
MVP receipts require pre_state, post_state, class,
snapshot path, ntm version, Codex version, model id if visible, action taken,
cooldown state, post-probe result, and no-action reason
(`/tmp/research-ntm-auto-respawn-2026-05-05.md:694-704`).
Current detector code writes recovery rows with event, session, pane, reason,
lease key, idempotency key, snapshot, re-probe, and latency fields
(`.flywheel/scripts/frozen-pane-detector.sh:484-512`).

### W6 - Backoff/storm control

Policy:
- first respawn per pane per hour logs receipt and may apply
- second respawn for the same pane within 1h escalates instead of re-acting
- global cap: maximum four respawns per session per hour
- rate-limit and quota classes never respawn
The research recommends one per pane per hour, max four
per session per hour, no http_429, no quota, no rate-limit text, and lease-based
idempotency (`/tmp/research-ntm-auto-respawn-2026-05-05.md:676-684`).
The fleet wrapper already has global and per-pane hourly budget fields
(`.flywheel/scripts/frozen-pane-detector-fleet.sh:26-29`,
`.flywheel/scripts/frozen-pane-detector-fleet.sh:265-291`).

### W7 - Escalation and watcher self-health

Escalate to Joshua on:
- auto-respawn fails verification
- second same-pane recovery needed inside 1h
- global budget exhausted
- source health degraded while pane appears frozen
- protected session needs recovery outside encoded permit
- watchdog itself stops firing
Research says alert only on repeated suppression or failed
recovery, and launchd should start disabled or dry-run first
(`/tmp/research-ntm-auto-respawn-2026-05-05.md:705-710`).
The fleet wrapper exposes doctor/install/health/audit modes and writes disabled
LaunchAgent state, event rows, stop files, fatal state, and recovery budgets
(`.flywheel/scripts/frozen-pane-detector-fleet.sh:44-59`,
`.flywheel/scripts/frozen-pane-detector-fleet.sh:147-235`).

## 5. Donella lens applied

Primary stock: live, dispatchable worker capacity.

Secondary stocks:
- manual-respawn burden on Joshua
- frozen-pane strike count
- false recovery count
- unknown auto-recovery count
- protected-session refusals
- watcher freshness
- recovery receipts

Inflow to healthy capacity:
- successful worker launches
- successful auto-recoveries
- prompt re-injection
- post-recovery liveness probes

Outflow from healthy capacity:
- frozen panes
- dead-shell panes
- input-deaf panes
- false respawns
- rate-limit stalls
- watchdog blind spots

Leverage point distribution:

| Primitive | Main leverage point | Stock impacted | Flow change | Loop topology |
|---|---|---|---|---|
| W1 Detector | #6 information flow | hidden frozen panes | pane truth becomes classified state | observation loop |
| W2 Permit gate | #5 rules | unsafe mutations | mutation allowed only under encoded contract | balancing safety loop |
| W3 Threshold | #9 delays | recovery latency | stale detection delay becomes bounded | delay-shortening loop |
| W4 Execution | #10 structure | dead worker slots | recovery path becomes one transaction | repair loop |
| W5 Receipt | #6 information flow | invisible recoveries | actions become metrics and learning input | measurement loop |
| W6 Backoff | #8 negative feedback | respawn storms | repeated recovery is damped | storm-control loop |
| W7 Escalation | #4 self-organization | unresolved failures | repeated classes route upward | learning/escalation loop |

The highest leverage parts are W1, W2, W5, and W7. Thresholds are necessary but
not sufficient; threshold tuning without permit and receipts is only parameter
fiddling.

The paradigm-level claim is narrow: human-as-watchdog is replaced by
system-as-watchdog, not by unconstrained automation.

## 6. Jeff lens applied (compose-not-new check)

Jeff read:

This should not become a new respawner.

Compose existing primitives:
- `.flywheel/scripts/frozen-pane-detector.sh` classifies and can apply recovery.
- `.flywheel/scripts/frozen-pane-detector-fleet.sh` wraps it at launchd/fleet scope.
- `ntm --robot-restart-pane` is the structured execution primitive.
- `ntm respawn --force` is fallback execution.
- `.flywheel/scripts/peer-orch-respawn-permit.sh` gates peer orchestrator recovery.
- `/flywheel:respawn` is the manual reference transaction.

Research explicitly says missing pieces are integration gaps, not absence of
restart primitives (`/tmp/research-ntm-auto-respawn-2026-05-05.md:336-346`).

Canonical-cli-scoping consequence:

Do not modify ntm source for this plan. Do not create a second detector. Do not
call raw lower-level pane tooling in plan scope. Make the existing detector's
dry-run/apply surface the canonical control plane.

Expected compose-vs-new split: 7 compose, 0 new primitives. Implementation may
need small glue/policy edits later, but the plan primitive set is entirely
compose-first.

## 7. Relationship to manager-loop / fleet-autonomy / mission-coverage

Watchdog enablement sits below the other three plans.

Fleet-autonomy asks how the fleet chooses work and avoids divergent loops. Its
P5 already names pane freeze auto-respawn as a balancing loop
(`.flywheel/PLANS/fleet-autonomy-v1-2026-05-05/00-PLAN-INPUT.md:178-193`).

Manager-loop asks how orchestrators consume aggregate state instead of drowning
in pane messages. Watchdog recovery receipts should be one input to manager-loop
ops-log/top-10 state, not another pane-message stream
(`.flywheel/PLANS/manager-loop-architecture-2026-05-05/00-PLAN-INPUT.md:40-56`).

Mission-coverage asks whether work maps to mission surfaces. Watchdog does not
choose mission work; it preserves the worker capacity needed for mission work to
continue.

Layering:
- watchdog: keep panes alive and safe
- manager-loop: aggregate state and choose next action
- fleet-autonomy: enforce autonomous work selection and loop dampening
- mission-coverage: prove completed work maps to mission outcomes

Therefore watchdog should ship before broad manager-loop apply mode, and before
fleet-autonomy assumes workers are continuously dispatchable.

## 8. Cross-research input integration (ntm + Codex research)

ntm research conclusion:

Enable a conservative frozen-pane watchdog for worker panes first, keep
peer-orch respawn behind permit gates, and use frozen-pane-v2 classification plus
ntm execution (`/tmp/research-ntm-auto-respawn-2026-05-05.md:12-16`).

Codex research conclusion:

Codex 0.128.0/gpt-5.5 migration is a canary decision, not the freeze cure. It
fixes zero exact known local freeze bugs, and fleet migration is not recommended
without TUI canary evidence
(`/tmp/research-codex-gpt55-upgrade-2026-05-05.md:382-421`,
`/tmp/research-codex-gpt55-upgrade-2026-05-05.md:519-580`).

Convergence:

The watchdog is the immediate operational fix. Codex upgrade is orthogonal and
should run after watchdog metrics exist, so the canary can measure whether
frozen strikes rise or fall.

Plan implication:

No part of watchdog enablement depends on paid API auth, npm global upgrade, or
ntm source modification. The action surface is local flywheel script policy.

## 9. Success criteria (measurement loops)

| Loop | Metric | Target |
|---|---|---|
| Manual burden | manual_respawn_count_7d | 0 |
| Recovery latency | frozen pane MTTR p95 | <= 180s worker SLO |
| Action quality | auto_respawn_success_rate | >= 95% after dry-run |
| Safety | false_positive_respawn_count_7d | 0 |
| Safety | unknown_auto_recovery_count_7d | 0 |
| Storm control | same_pane_second_respawn_1h | escalated, not repeated |
| Protected gate | protected_session_auto_apply_count | 0 unless explicit permit |
| Receipt loop | recovery_receipt_coverage | 100% |
| Watcher health | detector cycle freshness | <= 2 cadence windows |

Review lanes should insist on a 7-day before/after chart. A one-off "it ran" is
not proof. A decreasing manual-respawn count with zero false recovery is proof.

## 10. In scope

1. Enable `.flywheel/scripts/frozen-pane-detector-fleet.sh` as watchdog surface.
2. Use `.flywheel/scripts/frozen-pane-detector.sh` as classifier/applier.
3. Preserve dry-run before apply.
4. Apply only to worker panes after permit, threshold, budget, and truth gates.
5. Emit receipts usable by manager-loop and `/flywheel:learn`.
6. Keep peer-orch recovery behind `.flywheel/scripts/peer-orch-respawn-permit.sh`.
7. Define rollout and verdict thresholds.

## 11. Out of scope

Codex version/auth migration, paid API-key GPT-5.5 migration, ntm source work,
`--robot-smart-restart` as sole authority, direct production
`ntm health --auto-restart-stuck`, protected client-session auto-recovery,
`flywheel:1` self-recovery, new manager-loop/mission-coverage logic, and bead
creation from this plan input.

## 12. Constraints

Permit gate: protected sessions default deny; pane 0, human pane, callback pane,
and flywheel self-orchestrator deny; peer orchestrator requires permit decision.

Action budget: first respawn per pane per hour may apply and must log receipt;
second within 1h escalates to Joshua or manager-loop top-10; session cap is four
respawns per hour; degraded truth and rate-limit text block respawn.

Rollout: Day 0 dry-run only; Day 1 flywheel workers only; Day 3 non-protected
worker expansion; Day 7 peer-orch permit-gated review; flywheel orchestrator
recovery remains last and never self-applied.

Operational style: ntm only, receipts before/after mutation, rollback by
LaunchAgent disable/unload plus STOP file, no silent launchd apply enablement.

## 13. Open questions for review lanes

1. Threshold: day-one 90s action, 5m action, or 90s log / 5m act?
2. Permit timeline: peer-orch after one week, or `skillos:1` exception now while
   alpsinsurance/picoz remain hard-deny?
3. Watcher self-health: launchd doctor freshness alone, or require
   `watchdog_last_fire_ts` in manager-loop before apply?

These are review-lane questions, not Joshua blockers. The default answer for
implementation is conservative: dry-run first, workers first, protected deny.

## 14. Ship order (proposed)

Phase 0: detector self-test, fleet wrapper doctor, current metrics baseline,
LaunchAgent disabled/default observe confirmation.

Phase 1: dry-run watchdog cycle, JSONL row verification, no-mutation proof,
manager-loop-consumable summary.

Phase 2: flywheel worker apply canary, `FROZEN` only, healthy source only,
snapshot plus recovery ledger plus post-probe required.

Phase 3: budget/escalation enforcement, false-positive and unknown-auto-recovery
metrics exposed.

Phase 4: non-protected worker expansion; stop if false-positive count rises.

Phase 5: peer-orch dry-run track through permit gate; keep
`PEER_ORCH_AUTO_RESPAWN=0` until receipts prove clean.

## 15. Verdict thresholds

GREEN: compose-not-new preserved; 24h dry-run receipts; no degraded-truth apply;
no unknown auto-recovery; no protected-session auto-apply; manager-loop can read
recovery metrics.

YELLOW: detector works but watcher freshness is not proven; threshold choice is
unresolved; peer-orch dry-run emits permit refusals but no apply; receipts lack
non-core fields.

RED: apply can touch pane 0, human pane, callback pane, or protected session;
apply can recover UNKNOWN/WATCH/template/post-completion classes; direct
production `ntm health --auto-restart-stuck`; Codex upgrade treated as watchdog
substitute; same pane can respawn twice in 1h without escalation; mutation lacks
snapshot and receipt.

Reviewer verdict should be strict. This plan's value is not novelty; it is
turning already-built substrate into a safe, measured recovery loop.
