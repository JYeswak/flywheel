---
title: "Fleet-Idle Plan - 2026-05-02"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

## Contents

- [0. Reframe First](#0-reframe-first)
  - [Lane A Reframe](#lane-a-reframe)
  - [Lane A Path Correction](#lane-a-path-correction)
  - [Lane B Reframe](#lane-b-reframe)
  - [Lane C Reframe](#lane-c-reframe)
  - [Promoted Incident Reframe](#promoted-incident-reframe)
- [1. Actual Substrate Snapshot](#1-actual-substrate-snapshot)
  - [idle-spiral-alert.json](#idle-spiral-alert-json)
  - [fleet-liveness.json](#fleet-liveness-json)
  - [last_run.json](#last-run-json)
  - [ALPS Self-Bug Substrate](#alps-self-bug-substrate)
  - [Ghost-Bead Substrate](#ghost-bead-substrate)
- [2. Real Root Cause Hierarchy](#2-real-root-cause-hierarchy)
  - [Smoking Gun - `flywheel-loop tick` Has No Dispatch Branch](#smoking-gun-flywheel-loop-tick-has-no-dispatch-branch)
  - [Minimal Source Patch](#minimal-source-patch)
  - [Cause 1 - Tick Action Set Is Observation-Only](#cause-1-tick-action-set-is-observation-only)
  - [Cause 2 - No Consumer Executes `dispatch_bead`](#cause-2-no-consumer-executes-dispatch-bead)
  - [Cause 3 - idle-spiral-alert.json Is Observation-Only Too](#cause-3-idle-spiral-alert-json-is-observation-only-too)
  - [Cause 4 - Upstream ALPS Substrate Fixes Are Required](#cause-4-upstream-alps-substrate-fixes-are-required)
  - [Cause 5 - Self-Bug Beads Stay Trapped Behind The Broken Selector](#cause-5-self-bug-beads-stay-trapped-behind-the-broken-selector)
  - [What Is Not The Root Cause](#what-is-not-the-root-cause)
- [3. Minimal Action Plan](#3-minimal-action-plan)
  - [Phase 0 - In-Flight ALPS Substrate](#phase-0-in-flight-alps-substrate)
  - [Bead 1 - flywheel-loop-dispatch-bead-branch](#bead-1-flywheel-loop-dispatch-bead-branch)
  - [Bead 2 - dispatch-bead-packet-consumer](#bead-2-dispatch-bead-packet-consumer)
  - [Bead 3 - idle-spiral-alert-consumer](#bead-3-idle-spiral-alert-consumer)
  - [Bead 4 - alps-idle-spiral-dispatch-drill](#bead-4-alps-idle-spiral-dispatch-drill)
  - [Why Only Four New Beads](#why-only-four-new-beads)
- [4. What Is Already Designed](#4-what-is-already-designed)
  - [Incident Rule - documented-bug-not-actioned-self-recursion](#incident-rule-documented-bug-not-actioned-self-recursion)
  - [ALPS In-Flight Dispatches](#alps-in-flight-dispatches)
  - [Lane C Bootstrap Procedure](#lane-c-bootstrap-procedure)
  - [Recovery Plan](#recovery-plan)
- [5. Cross-Link To Recovery Plan](#5-cross-link-to-recovery-plan)
  - [Exact Overlap](#exact-overlap)
  - [Recommendation](#recommendation)
  - [Shared Overlay](#shared-overlay)
  - [Recovery Decisions That Matter Here](#recovery-decisions-that-matter-here)
  - [Callback Value](#callback-value)
- [6. Joshua Action Items](#6-joshua-action-items)
  - [Decision 1 - Approve Binary And Slash Surface Modification](#decision-1-approve-binary-and-slash-surface-modification)
  - [Decision 2 - Approve `/flywheel:worker-tick` Command Install](#decision-2-approve-flywheel-worker-tick-command-install)
  - [Decision 3 - Decide Recovery Consolidation](#decision-3-decide-recovery-consolidation)
  - [Decision 4 - Approve ALPS Orchestrator Pane Restart](#decision-4-approve-alps-orchestrator-pane-restart)
- [7. Drill Plan](#7-drill-plan)
  - [Drill Name](#drill-name)
  - [Starting State](#starting-state)
  - [Step 1 - Consume Alert](#step-1-consume-alert)
  - [Step 2 - Dispatch To Orchestrator Pane](#step-2-dispatch-to-orchestrator-pane)
  - [Step 3 - Bead Moves To In Progress](#step-3-bead-moves-to-in-progress)
  - [Step 4 - Worker Executes Worker Tick](#step-4-worker-executes-worker-tick)
  - [Step 5 - Callback Lands](#step-5-callback-lands)
  - [Step 6 - Bead Closes Or Requeues](#step-6-bead-closes-or-requeues)
  - [Step 7 - Idle Counter Resets](#step-7-idle-counter-resets)
  - [Drill Success Criteria](#drill-success-criteria)
  - [Drill Failure Classes](#drill-failure-classes)
  - [Drill Rollback](#drill-rollback)
- [8. Implementation Sequencing](#8-implementation-sequencing)
  - [Order 0 - Phase 0 ALPS Beads](#order-0-phase-0-alps-beads)
  - [Order 1 - Source Branch Patch Dry-Run](#order-1-source-branch-patch-dry-run)
  - [Order 2 - Dispatch Packet Consumer Dry-Run](#order-2-dispatch-packet-consumer-dry-run)
  - [Order 3 - Alert Consumer Dry-Run](#order-3-alert-consumer-dry-run)
  - [Order 4 - Dispatch Ledger Dry-Run](#order-4-dispatch-ledger-dry-run)
  - [Order 5 - Approved ALPS Repair Dispatch](#order-5-approved-alps-repair-dispatch)
  - [Order 6 - Ghost Gate](#order-6-ghost-gate)
  - [Order 7 - Normal Ready-Bead Dispatch](#order-7-normal-ready-bead-dispatch)
- [9. Session Priority Table](#9-session-priority-table)
- [10. Runtime Invariants](#10-runtime-invariants)
- [11. Receipt Schema Extensions](#11-receipt-schema-extensions)
  - [Autoloop Receipt](#autoloop-receipt)
  - [Idle Alert Consumer Receipt](#idle-alert-consumer-receipt)
  - [Ghost Gate Receipt](#ghost-gate-receipt)
- [12. Non-Goals](#12-non-goals)
- [13. Risks](#13-risks)
- [14. Test Matrix](#14-test-matrix)
  - [Unit Tests](#unit-tests)
  - [Integration Tests](#integration-tests)
  - [Drill Tests](#drill-tests)
  - [Regression Tests](#regression-tests)
- [15. Acceptance Summary](#15-acceptance-summary)
- [16. Validation Ladder](#16-validation-ladder)
- [17. Final Recommendation](#17-final-recommendation)
- [18. Callback Metrics](#18-callback-metrics)
# Fleet-Idle Plan - 2026-05-02
Task: `fleet_idle_lane_d_synthesis`
Mode: plan-space synthesis, read-only substrate inputs
Output: `.flywheel/plans/fleet-idle-2026-05-02/00-FLEET-IDLE-PLAN.md`
Ladder: passed
Recommended recovery consolidation: no, keep separate but cross-cite shared substrate
Minimum new bead count: 4
Joshua decisions: 4
## 0. Reframe First
The original fleet-idle lanes were useful, but their first framing was too
broad.
The fleet is not missing all orchestration.
The fleet has orchestration substrate that mostly observes, summarizes, or
alerts.
It does not reliably consume alerts and dispatch work.
The real root cause is not "no orchestration exists."
The real root cause is "observe-only orchestration has no action consumer."
That distinction matters.
If we rebuild everything as though nothing exists, we duplicate substrate.
If we wire the missing consumer and dispatch path, the existing system can
start moving.
### Lane A Reframe
Lane A strongest finding:
The eight active sessions exist, and several have live Claude/Codex panes, but
the substrate that should turn alive panes and ready beads into continuous work
is fractured.
Original lane shorthand:
No orchestration.
Corrected interpretation:
Observe-only orchestration exists, but there is no dispatch consumer.
Evidence from Lane A:
- Global `ai.zeststream.flywheel-autoloop` is loaded.
- It writes fleet liveness and last-run state.
- It selected repos and produced tick actions.
- The observed action was `summarize_dirty_worktree`, not worker dispatch.
- Per-session loop attempts exist for ALPS and skillos.
- ALPS loop was stale/failed.
- skillos loop appears to send prompts without reliable agent execution.
Current substrate truth:
- `~/.local/state/flywheel-autoloop/idle-spiral-alert.json` is fresh.
- It reports `alpsinsurance` with `consecutive_idle_clean=19`.
- It recommends `dispatch_work_or_teardown`.
- `~/.local/state/flywheel-autoloop/fleet-liveness.json` says the fleet is
  alive.
- `~/.local/state/flywheel-autoloop/last_run.json` now says
  `status=repair_failed` for `/Users/josh/Developer/alpsinsurance`.
Conclusion:
Lane A should be read as "the dispatcher is absent or ineffective," not "there
is no loop."
### Lane A Path Correction
Lane A also corrected the ALPS path.
Wrong premise:
ALPS was assessed through stale or Desktop-style path assumptions.
Correct substrate:
ALPS has `.beads` at `/Users/josh/Developer/alpsinsurance`.
ALPS is not lacking a bead substrate.
ALPS has self-bug beads that describe the exact flywheel loop failures.
ALPS has a liveness alert that is not being consumed.
Still true:
`vrtx` and `clutterfreespaces` remain incomplete substrate cases.
`vrtx` has `.flywheel` but no `.beads`.
`clutterfreespaces` has neither `.flywheel` nor `.beads`.
Those should be bootstrap targets, but they are not the blocker for unfreezing
ALPS.
### Lane B Reframe
Lane B strongest finding:
The ghost-bead signal stands.
It found:
- 11 in-progress beads across five repos.
- 3 `GHOST_OVERDUE`.
- 7 `ORPHAN`.
- 1 `CLOSURE_FAILURE`.
- `is_cap=no`.
Corrected interpretation:
Ghost in-progress state is not the top cause of fleet idle, but it is a major
amplifier.
The dispatcher cannot safely choose new work if it cannot tell whether
`in_progress` means live ownership or stale bookkeeping.
Lane B also found a substrate bug in our own audit method:
`br list --json | jq length` can report 5 because the output is an object
envelope with five keys.
That is not a bead count.
Every scanner must normalize:
```bash
jq 'if type=="array" then . else (.issues // []) end'
```
Conclusion:
Ghost-bead cleanup is not the first runtime patch, but ghost classification
must be part of the tick receipt and dispatch safety gate.
### Lane C Reframe
Lane C strongest finding:
It designed a seven-step bootstrap and a 12-bead DAG for per-session substrate.
Original shape:
Bootstrap everything across every session.
Corrected interpretation:
Lane C is the right install/recovery substrate, but the fleet-idle fix must be
smaller.
Do not block the runtime dispatcher on the full 12-bead bootstrap.
Tightened runtime target:
1. Fix the autoloop tick action so it can dispatch, not just observe.
2. Connect `idle-spiral-alert.json` to an action consumer.
3. Ensure each session that is expected to work has a real orchestrator pane.
4. Keep bootstrap work as a dependency for sessions that lack `.beads`,
   `.flywheel`, or a path map.
Conclusion:
Lane C becomes shared substrate and acceptance language, not the minimal
runtime action plan.
### Promoted Incident Reframe
`INCIDENTS.md` lines 377-453 name the exact meta-failure.
Pattern 1:
`orchestrator-substrate-blindness`.
Meaning:
The orchestrator framed "no orchestration" before reading the live substrate.
Missed substrate:
- live processes,
- launchd state,
- autoloop state directory,
- per-session paths,
- recent JSON writes.
Pattern 2:
`documented-bug-not-actioned-self-recursion`.
Meaning:
Self-bug beads about the selector/loop do not get selected because the selector
is broken.
ALPS examples:
- `josh-1eo8p`: Restore ALPS worker-tick command surface for pane loop.
- `josh-1s3ie`: Fix `/flywheel:loop start` repo-local ALPS state writes.
- `josh-35h17`: ALPS session topology pane assignment mismatch.
Incident line 451 is the plan's center:
`idle-spiral-alert.json` already says ALPS has `consecutive_idle_clean=19`
with `recommendation=dispatch_work_or_teardown`.
No consumer acts on it.
## 1. Actual Substrate Snapshot
This plan cites current substrate, not lane assumptions.
### idle-spiral-alert.json
Path:
`~/.local/state/flywheel-autoloop/idle-spiral-alert.json`
Observed:
```json
{
  "ts": "2026-05-02T01:53:31Z",
  "alerts": [
    {
      "project": "alpsinsurance",
      "session": "alpsinsurance",
      "consecutive_idle_clean": 19,
      "idle_workers": 1,
      "last_tick_ts": "2026-05-01T15:07:30Z",
      "recommendation": "dispatch_work_or_teardown"
    }
  ]
}
```
Reading:
The alert detector is alive.
The alert contains enough routing data to trigger a targeted action.
The missing piece is the consumer.
### fleet-liveness.json
Path:
`~/.local/state/flywheel-autoloop/fleet-liveness.json`
Observed:
```json
{
  "fleet_alive": true,
  "sessions": {
    "alpsinsurance": {"total": 4, "ok": 4, "error": 0, "active": 3, "idle": 1},
    "flywheel": {"total": 5, "ok": 3, "error": 2, "active": 1, "idle": 4},
    "picoz": {"total": 4, "ok": 4, "error": 0, "active": 2, "idle": 2},
    "skillos": {"total": 3, "ok": 2, "error": 1, "active": 0, "idle": 3}
  }
}
```
Reading:
The fleet is visible.
The detector can see idle workers.
The detector's green/fresh state does not imply work is advancing.
### last_run.json
Path:
`~/.local/state/flywheel-autoloop/last_run.json`
Observed:
```json
{
  "ts": "2026-05-02T01:53:36Z",
  "status": "repair_failed",
  "reason": "repo=/Users/josh/Developer/alpsinsurance",
  "root": "/Users/josh/Developer"
}
```
Earlier Lane A observed:
```json
{
  "status": "ticked",
  "repo": "/Users/josh/Developer/vrtx",
  "tick_action": "summarize_dirty_worktree",
  "tick_decision": "DECISION: review existing repo changes before editing"
}
```
Reading:
The global autoloop is doing work.
It is not reliably dispatching work.
It either summarizes, detects, or attempts repair.
It still does not close the loop from alert to bead dispatch.
### ALPS Self-Bug Substrate
Path:
`/Users/josh/Developer/alpsinsurance/.beads`
Known self-bug beads from incident promotion:
- `josh-1eo8p`
- `josh-1s3ie`
- `josh-35h17`
They are not random backlog items.
They describe the runtime failure preventing the fleet from unsticking itself.
They must escape normal selector logic.
### Ghost-Bead Substrate
Lane B found:
- `flywheel-sum`: ghost overdue, output exists.
- `flywheel-3bk`: ghost overdue, output exists.
- `flywheel-3ul`: ghost overdue, output exists.
- `flywheel-1k7`: closure failure, callback received but bead still
  `in_progress`.
- `skillos-jdi`: orphan due missing dispatch log.
- `bd-jnujb`: orphan due missing dispatch log.
- five `zesttube` asset beads: stale orphans.
Reading:
This is not a hard cap.
It is state reconciliation debt.
It affects dispatch safety, not the existence of work.
## 2. Real Root Cause Hierarchy
Keep the causal chain short.
The canonical root cause is now source-line specific.
Overlay source:
`/tmp/dispatch_fleet_idle_lane_d_OVERLAY_root_cause.md`
### Smoking Gun - `flywheel-loop tick` Has No Dispatch Branch
The exact source-line finding:
`~/.claude/skills/.flywheel/bin/flywheel-loop` lines 2670-2693.
Current decision tree:
```bash
if [[ -z "$(repo_git_root)" ]]; then
    action="choose_git_repo"
elif [[ "$docs_state" != "ready" ]]; then
    action="fill_repo_local_mission_goal_state"
elif [[ -f "$(repo_override_path)" ]]; then
    action="$override_required"
elif [[ "${dirty:-0}" -gt 0 ]]; then
    action="summarize_dirty_worktree"
elif [[ "$(jq 'length' <<<"$tests")" -gt 0 ]]; then
    action="run_baseline_validation"
else
    action="read_repo_docs_and_find_validation"
fi
```
Critical observation:
There is no branch that checks ready beads.
There is no branch that checks idle workers.
There is no branch that emits `action="dispatch_bead"`.
The action set is hardcoded to observation/setup verbs:
- `choose_git_repo`
- `fill_repo_local_mission_goal_state`
- `execute_next_tick_override`
- `summarize_dirty_worktree`
- `run_baseline_validation`
- `read_repo_docs_and_find_validation`
None of these dispatch beads.
This makes fleet-idle a constructed behavior, not an incidental one.
The loop reads state.
The loop writes receipts.
The loop never owns the transition:
ready bead -> idle pane -> dispatch -> callback.
### Minimal Source Patch
The minimal fix is a small branch before the dirty-worktree branch.
Patch shape:
```bash
elif [[ "$(br_ready_count)" -gt 0 ]] && [[ "$(idle_workers_count)" -gt 0 ]]; then
    decision="DECISION: dispatch top ready bead to idle worker"
    action="dispatch_bead"
    packet_status=interrupt
elif [[ "${dirty:-0}" -gt 0 ]]; then
    action="summarize_dirty_worktree"
```
Why before dirty:
Most active repos are dirty.
If dirty always wins, the loop will summarize forever and never dispatch safe
ready work.
The branch must still respect safety filters:
- protected session policy,
- self-bug escape priority,
- repo path confidence,
- ghost in-progress gate,
- pane health.
But the existence of dirty files cannot remain an absolute dispatch blocker.
### Cause 1 - Tick Action Set Is Observation-Only
Top cause:
`flywheel-loop tick` cannot currently choose `dispatch_bead`.
It has no code path for it.
Failure signature:
`tick_action=summarize_dirty_worktree`
or
`status=repair_failed`
while ready/self-bug work remains available.
Expected signature:
`tick_action=dispatch_bead`
with selected bead, selected pane, dispatch ledger row, and callback deadline.
### Cause 2 - No Consumer Executes `dispatch_bead`
The overlay also identifies the second half:
Even after the new tick action exists, a consumer must read the packet and
invoke the dispatch surface.
Missing consumer behavior:
```text
read tick_action=dispatch_bead
extract bead id and idle pane
invoke /flywheel:dispatch <pane> <bead-id>
write dispatch-log row
send via ntm
track callback
```
Without this consumer, the branch only changes a receipt.
The branch and consumer are a pair.
### Cause 3 - idle-spiral-alert.json Is Observation-Only Too
The alert file is an actionable queue.
It is currently a dead letter.
It contains:
- session,
- project,
- idle count,
- idle worker count,
- recommendation.
Current ALPS alert says:
`recommendation=dispatch_work_or_teardown`.
No code reads that file and acts.
This is the same pattern as the tick decision tree:
state is detected,
state is written,
no dispatch happens.
### Cause 4 - Upstream ALPS Substrate Fixes Are Required
The ALPS self-bug beads are not the root patch, but they are dependencies:
- `josh-1eo8p`: worker-tick command surface.
- `josh-1s3ie`: loop-state write repair.
- `josh-35h17`: pane topology repair.
The dispatch branch depends on these because:
- worker-tick consumes the dispatched packet,
- loop state tells autoloop which session to dispatch to,
- pane topology tells the dispatcher where to send it.
Those beads are in flight on other panes.
Do not duplicate them here.
### Cause 5 - Self-Bug Beads Stay Trapped Behind The Broken Selector
ALPS has self-bug beads describing the selector/loop failure.
The normal selector cannot choose them because the selector lacks a dispatch
action.
That is self-recursion.
The new branch must special-case self-bug beads so the selector can choose the
fix for the selector.
### What Is Not The Root Cause
Not root cause:
- "No orchestration exists."
- "Every project has exactly five in-progress beads."
- "No ALPS `.beads` exists."
- "The fleet is dead."
- "Recovery plists alone will fix runtime idleness."
Correct statement:
The fleet is alive and instrumented, but the `flywheel-loop tick` decision tree
has no dispatch action and no consumer to execute one.
## 3. Minimal Action Plan
The goal is not to bootstrap the whole universe.
The goal is to flip fleet-idle from sticking to flowing.
That requires four new beads plus Phase 0 in-flight ALPS work.
### Phase 0 - In-Flight ALPS Substrate
Status:
Already in flight or already identified on other panes.
Do not file duplicate beads for:
- `josh-1eo8p`: ALPS worker-tick command surface.
- `josh-1s3ie`: `/flywheel:loop start` repo-local ALPS state writes.
- `josh-35h17`: ALPS topology pane assignment mismatch.
Phase 0 purpose:
Make ALPS capable of receiving and executing the dispatch once the source-line
dispatch branch exists.
Phase 0 acceptance:
- ALPS has a working local `/flywheel:worker-tick` command surface.
- ALPS `/flywheel:loop start` writes state to the repo-local `.flywheel`.
- ALPS topology declares the correct orchestrator and worker panes.
- The stale/wedged orchestrator pane is either restarted or explicitly replaced
  after Joshua approval.
Phase 0 is not counted as new bead work here.
### Bead 1 - flywheel-loop-dispatch-bead-branch
Priority: P0
Effort: S
Leverage: highest
Purpose:
Patch `~/.claude/skills/.flywheel/bin/flywheel-loop` lines 2670-2693 so
`tick` can emit `action=dispatch_bead`.
Patch budget:
Target is no more than 30 lines.
Inputs:
- `br_ready_count`
- `idle_workers_count`
- existing docs/override/dirty/test decision state
Required branch:
```bash
elif [[ "$(br_ready_count)" -gt 0 ]] && [[ "$(idle_workers_count)" -gt 0 ]]; then
    decision="DECISION: dispatch top ready bead to idle worker"
    action="dispatch_bead"
    packet_status=interrupt
```
Placement:
Before the `dirty` branch.
Reason:
Dirty repo state currently wins over all dispatch work.
That makes dirty active repos summarize instead of work.
Acceptance:
- Unit fixture with ready beads and idle workers emits `dispatch_bead`.
- Unit fixture with no ready beads keeps current behavior.
- Unit fixture with no idle workers keeps current behavior.
- Dirty repo with safe ready self-bug work emits `dispatch_bead`, not
  `summarize_dirty_worktree`.
- Receipt includes selected action and reason.
Measurable outcome:
`flywheel-loop tick` can produce `tick_action=dispatch_bead`.
Callback metric:
`tick_action=dispatch_bead`.
### Bead 2 - dispatch-bead-packet-consumer
Priority: P0
Effort: M
Leverage: highest
Purpose:
Write the consumer for `tick_action=dispatch_bead`.
Problem:
The new branch is not enough by itself.
A receipt with `action=dispatch_bead` still needs a consumer that sends work to
a pane.
Desired behavior:
The consumer reads the dispatch packet and invokes:
```text
/flywheel:dispatch <pane> <bead-id>
```
or the equivalent helper path that writes the same ledger and uses `ntm send`.
Inputs:
- tick packet with `action=dispatch_bead`,
- selected bead id,
- selected idle pane,
- `bv --robot-next` or `br ready --json`,
- autonomy/protected-session filter,
- dispatch template,
- NTM send target.
Dispatch rules:
1. Prefer self-bug escape beads over ordinary work.
2. Prefer session-local work over cross-session work.
3. Never dispatch protected ALPS/Picoz mutating work without policy approval.
4. Never dispatch into a pane that is shell-only, wrong cwd, or health-error
   unless the dispatch is explicitly a repair/restart prompt.
5. Always write dispatch-log row before `ntm send`.
6. Always include expected callback deadline.
Acceptance:
- A dry-run packet renders the exact `/flywheel:dispatch` call.
- A real apply after approval sends exactly one `ntm send`.
- The dispatch-log row contains `task_id`, `bead`, `target_session`,
  `target_pane`, `callback_expected_by`, and `origin_tick_ts`.
- If `bv --robot-next` is unavailable or returns no work, fallback to
  normalized `br ready --json`.
- If the selected repo is dirty and the dirty state blocks safe work, the action
  must be `NO_ACTION_WITH_REASON`, not silent summary-only.
Measurable outcome:
At least one autoloop tick produces a dispatch row rather than only a summary
or repair failure.
Callback metric:
`dispatch_bead_consumed=yes`.
### Bead 3 - idle-spiral-alert-consumer
Priority: P0
Effort: M
Leverage: high
Purpose:
Consume `~/.local/state/flywheel-autoloop/idle-spiral-alert.json` and route it
into the new dispatch branch.
Allowed actions:
1. `DISPATCH_SELF_BUG`
2. `DISPATCH_READY_BEAD`
3. `NO_ACTION_WITH_REASON`
Selection rules:
1. If session has idle workers and self-bug beads older than five tick cadences,
   select the oldest highest-priority self-bug.
2. Else if session has safe ready beads, select the top ready bead.
3. Else if session has no safe work, write `NO_ACTION_WITH_REASON`.
4. Else if the orchestrator pane is unhealthy, dispatch a pane-restart decision
   to Joshua-disposes or protected-session policy.
Acceptance:
- With the current ALPS alert, the consumer selects one of
  `josh-1eo8p`, `josh-1s3ie`, or `josh-35h17`.
- It writes a decision receipt containing `source=idle-spiral-alert`.
- It writes `origin_alert_ts`.
- It writes `selected_bead`.
- It writes `why_this_bead`.
- It writes `target_session=alpsinsurance`.
- It writes `target_pane=<orchestrator_or_worker>`.
- It refuses to dispatch if protected-session policy requires human approval.
- It emits `NO_ACTION_WITH_REASON` instead of silently skipping.
Measurable outcome:
An ALPS idle alert is consumed within one autoloop tick.
Callback metric:
`idle_alerts_consumed=1`.
### Bead 4 - alps-idle-spiral-dispatch-drill
Priority: P1
Effort: M
Leverage: high
Purpose:
Prove the end-to-end runtime path on ALPS after Phase 0 and Beads 1-3.
Inputs:
- current ALPS idle alert,
- ALPS self-bug bead,
- orchestrator pane contract,
- dispatch ledger,
- callback pane.
Acceptance:
- ALPS idle alert exists.
- Autoloop consumes it within one tick.
- A self-bug bead is selected.
- Dispatch goes through NTM to the target pane.
- Bead moves to `in_progress` only after dispatch acceptance.
- Callback lands.
- Bead closes or requeues explicitly.
- `consecutive_idle_clean` resets to 0 or records a no-reset reason.
- Ghost-bead scan runs as a receipt-only safety check.
Measurable outcome:
ALPS goes from idle alert to callback without manual bead selection.
Callback metric:
`alps_idle_drill_passed=yes`.
### Why Only Four New Beads
These four changes cover the runtime path:
source branch -> dispatch consumer -> idle alert consumer -> ALPS drill.
Lane C's 12-bead bootstrap remains useful, but it is not the minimum runtime
unlock.
Recovery's 12-plus bead plan remains useful, but it protects reboot survival.
The fleet-idle plan should not wait for full recovery implementation.
## 4. What Is Already Designed
### Incident Rule - documented-bug-not-actioned-self-recursion
This incident already prescribes the self-bug escape.
The rule says self-bug beads must escape normal selector logic.
Matcher:
`/flywheel:|autoloop|loop start|worker-tick|tick fails|orchestrator|dispatch|callback|substrate/`
plus failure terms:
`fail|broken|missing|drift|regression|stuck`
Trigger:
open self-bug bead older than five tick cadences.
Required behavior:
- force visible,
- escape normal negative-cache and selection logic,
- trigger doctor fail signal.
This is split across Bead 1's `dispatch_bead` branch and Bead 3's
idle-alert/self-bug selection rule.
### ALPS In-Flight Dispatches
The ALPS beads are not new discoveries:
- `josh-1eo8p`
- `josh-1s3ie`
- `josh-35h17`
They are the first workload for the new consumer.
Do not create duplicates.
Do not bury them behind general bootstrap work.
They are the runtime test cases.
### Lane C Bootstrap Procedure
Lane C already designed:
- session path registration,
- `.flywheel` init,
- `.beads` init,
- locked docs,
- NTM watcher plist install,
- per-project flywheel-loop plist install,
- orchestrator pane activation.
Use that design when a session lacks substrate.
Do not require all seven steps before ALPS dispatch repair.
### Recovery Plan
The recovery plan already designed:
- recovery manifest,
- restore state machine,
- watcher plists,
- boot helper,
- baseline checkpoints,
- retention,
- protected-session approval,
- drill evidence.
Use it for reboot survival.
Do not convert fleet-idle into a recovery subproject.
## 5. Cross-Link To Recovery Plan
Recovery plan path:
`/Users/josh/Developer/flywheel/.flywheel/plans/recovery-system-2026-05-01/`
### Exact Overlap
Shared surface 1:
Per-session orchestrator pane.
Fleet-idle needs it for runtime dispatch.
Recovery needs it after restore.
Shared surface 2:
Autoloop install and launchd runner.
Fleet-idle needs it to keep work moving.
Recovery needs it to restart after reboot.
Shared surface 3:
Session path and topology authority.
Fleet-idle needs it to avoid wrong cwd and stale ALPS aliases.
Recovery needs it to restore correct sessions.
Shared surface 4:
Dispatch ledger.
Fleet-idle needs it for ghost classification.
Recovery needs it to classify orphan work after reboot.
Shared surface 5:
Baseline checkpoints.
Fleet-idle does not directly need checkpoint payloads, but it needs a
confidence gate before restarting wedged protected sessions.
Recovery owns the checkpoint implementation.
### Recommendation
Do not merge fleet-idle into the recovery bead DAG.
Use cross-cites and shared primitives.
Reasoning:
- Recovery is boot-time survival.
- Fleet-idle is runtime dispatch flow.
- Recovery can be green while runtime work still does not move.
- Runtime dispatch can be green while reboot recovery still lacks checkpoint
  proof.
- A merged DAG will become too broad and delay the P0 runtime fix.
### Shared Overlay
Create a small shared overlay in both plans:
`shared-session-runtime-substrate`.
Fields:
- `session`
- `repo_path`
- `orchestrator_pane`
- `worker_panes`
- `dispatch_log_path`
- `loop_state_path`
- `watcher_plist_path`
- `protected_policy`
- `checkpoint_required_before_restart`
Recovery can fill watcher and checkpoint fields.
Fleet-idle can fill dispatch and loop fields.
### Recovery Decisions That Matter Here
From recovery audit:
- D02: v1 protection scope.
- D06: boot timeline and dependency DAG.
- D07: orphan redispatch side-effect policy.
- D08: manual rescue without live orchestrator.
- D10: Beads DB restore policy.
Fleet-idle should inherit:
- protected-session boundaries,
- no Beads DB writes from recovery,
- dispatch orphan caution,
- dry-run/apply separation.
### Callback Value
For this dispatch, consolidation answer:
`consolidate_with_recovery=no`.
Meaning:
Do not merge DAGs.
Do cross-cite shared substrate.
## 6. Joshua Action Items
Keep this to four decisions.
### Decision 1 - Approve Binary And Slash Surface Modification
Question:
Approve modifications to `/flywheel:loop` and
`~/.claude/skills/.flywheel/bin/flywheel-loop` so autoloop can emit
`tick_action=dispatch_bead`?
Why it matters:
Without this, the loop can keep summarizing, repairing, and alerting without
moving work.
Default recommendation:
Approve for dry-run first, then apply after one ALPS repair dispatch dry-run.
### Decision 2 - Approve `/flywheel:worker-tick` Command Install
Question:
Approve installing the `/flywheel:worker-tick` command file needed by ALPS and
other session-local panes?
Why it matters:
`josh-1eo8p` exists because ALPS lacks a reliable worker-tick command surface.
Default recommendation:
Approve.
Use ALPS as the reference implementation after dry-run.
### Decision 3 - Decide Recovery Consolidation
Question:
Should fleet-idle merge into recovery, or stay separate with cross-cites?
Default recommendation:
Stay separate with cross-cites.
Reason:
Runtime dispatch and reboot recovery share substrate but have different success
metrics and risk boundaries.
Callback value:
`consolidate_with_recovery=no`.
### Decision 4 - Approve ALPS Orchestrator Pane Restart
Question:
Approve restart or replacement of the wedged ALPS orchestrator pane after
checkpoint/protected-session preflight?
Why it matters:
The alert consumer can select the right work, but ALPS still needs a receiving
orchestrator pane.
Default recommendation:
Approve only after:
- NTM health snapshot,
- dispatch ledger snapshot,
- no active protected side-effect operation,
- recovery/protected restart receipt.
## 7. Drill Plan
The drill proves the whole runtime path, not just a detector.
### Drill Name
`alps-idle-alert-to-callback-drill`
### Starting State
Required current signal:
`idle-spiral-alert.json` contains:
- `session=alpsinsurance`
- `consecutive_idle_clean>=19`
- `idle_workers>=1`
- `recommendation=dispatch_work_or_teardown`
Required current liveness:
`fleet-liveness.json` shows ALPS:
- `total=4`
- `ok=4`
- `idle=1`
Required current work:
At least one ALPS self-bug bead exists:
- `josh-1eo8p`
- `josh-1s3ie`
- `josh-35h17`
### Step 1 - Consume Alert
Run the alert consumer.
Expected:
- alert row marked consumed in a receipt,
- selected bead is one of the ALPS self-bug beads,
- decision source is `idle-spiral-alert`.
Receipt fields:
- `origin_alert_ts`
- `selected_bead`
- `target_session`
- `target_pane`
- `dispatch_allowed`
- `protected_policy_checked`
### Step 2 - Dispatch To Orchestrator Pane
Send the selected task via NTM.
Expected:
- dispatch-log row exists before send,
- `ntm send alpsinsurance --pane=<target>` succeeds,
- callback pane is known,
- deadline is recorded.
Receipt fields:
- `event=dispatch_sent`
- `bead=<id>`
- `origin=idle_spiral_alert`
- `callback_expected_by`
### Step 3 - Bead Moves To In Progress
The selected bead transitions only if dispatch is accepted.
Expected:
- status changes from ready/open to `in_progress`,
- assignee or owner identifies the pane/agent,
- no unrelated beads change.
If mutation approval is not granted:
- dry-run receipt shows the exact transition that would happen.
### Step 4 - Worker Executes Worker Tick
The receiving pane runs `/flywheel:worker-tick` parity.
Expected:
- worker reads dispatch,
- worker writes output artifact,
- worker sends callback to pane 1,
- no source changes unless the bead explicitly allows them.
### Step 5 - Callback Lands
Expected:
- dispatch-log row receives `callback_received_at`,
- callback status is `done` or `blocked`,
- output path exists,
- bead closure/reopen decision is explicit.
### Step 6 - Bead Closes Or Requeues
Expected:
- if acceptance passed, bead closes;
- if blocked, bead returns to ready/open with blocker reason;
- no bead remains in stale `in_progress`.
### Step 7 - Idle Counter Resets
Expected:
Next `idle-spiral-alert.json` either:
- removes ALPS alert,
- or ALPS `consecutive_idle_clean` resets to 0,
- or writes a new explicit reason why ALPS did not reset.
### Drill Success Criteria
The drill passes only if:
- alert consumed within one tick,
- dispatch sent,
- bead status changed,
- callback landed,
- closure/requeue was explicit,
- idle counter reset or documented reason exists.
### Drill Failure Classes
Failure class 1:
`alert_not_consumed`.
Failure class 2:
`selected_bead_not_self_bug_escape`.
Failure class 3:
`dispatch_log_missing_before_send`.
Failure class 4:
`ntm_send_failed`.
Failure class 5:
`worker_tick_surface_missing`.
Failure class 6:
`callback_missing_after_deadline`.
Failure class 7:
`bead_left_in_progress_after_callback`.
Failure class 8:
`idle_counter_not_reset`.
### Drill Rollback
If the drill mutates bead status:
- write previous status,
- write selected bead,
- write restore command,
- keep dispatch log,
- never delete the audit trail.
## 8. Implementation Sequencing
### Order 0 - Phase 0 ALPS Beads
Start with the existing ALPS self-bugs.
Do not file duplicate ALPS worker-tick or loop-state beads.
Use them as acceptance fixtures.
### Order 1 - Source Branch Patch Dry-Run
Implement the source-line branch first.
The dry-run proves `flywheel-loop tick` can emit `dispatch_bead`.
No `ntm send`.
No bead mutation.
Output:
`tick_action=dispatch_bead selected_bead=<id> idle_worker=<pane>`
### Order 2 - Dispatch Packet Consumer Dry-Run
Implement the packet consumer next.
It reads the `dispatch_bead` packet and prints the dispatch call.
No `ntm send`.
No bead mutation.
Output:
`/flywheel:dispatch <pane> <bead-id>`
### Order 3 - Alert Consumer Dry-Run
Implement the idle-spiral-alert consumer.
It reads the ALPS alert and routes it into the `dispatch_bead` path.
No `ntm send`.
No bead mutation.
Output:
`would_dispatch josh-... to alpsinsurance pane ...`
### Order 4 - Dispatch Ledger Dry-Run
Add dispatch-log dry-run.
It should emit the exact JSON row that would be written.
No send yet.
### Order 5 - Approved ALPS Repair Dispatch
After Joshua approval, run one repair dispatch.
This should target a self-bug bead, not arbitrary client work.
### Order 6 - Ghost Gate
Add the ghost/in-progress gate before broad normal dispatch.
This prevents stale status from blocking or confusing scheduling.
### Order 7 - Normal Ready-Bead Dispatch
Only after self-bug and ghost logic work, dispatch ordinary ready work.
Protected filters remain active.
## 9. Session Priority Table
| session | runtime priority | reason | immediate action |
|---|---:|---|---|
| `alpsinsurance` | P0 | idle alert, self-bug beads, client reference implementation | consume alert and dispatch self-bug repair |
| `flywheel` | P0 | brain repo, dispatcher lives here | modify loop/autoloop logic after approval |
| `picoz` | P1 | healthy panes, safety-critical | dry-run only until protected policy confirms |
| `zesttube` | P1 | ready work + ghost beads | apply ghost gate before dispatch |
| `skillos` | P1 | skill HQ, custom loop delivery suspect | repair submit assurance after ALPS |
| `vrtx` | P2 | no `.beads`, selected by autoloop wrongly | bootstrap or exclude from dispatcher |
| `clutterfreespaces` | P2 | no `.flywheel`, no `.beads` | bootstrap path, not dispatch target |
| `zeststream-v2` | P2 | panes wrong cwd, no `.flywheel` in actual repo | repair topology/bootstrap first |
## 10. Runtime Invariants
Invariant 1:
An idle alert older than one tick must be consumed or carry a no-action reason.
Invariant 2:
Self-bug beads escape normal selector logic.
Invariant 3:
`tick_action=summarize_dirty_worktree` cannot be the only outcome when
`idle_workers>0` and safe self-bug work exists.
Invariant 4:
No dispatch occurs without a dispatch-log row.
Invariant 5:
No callback can leave a bead in stale `in_progress` without a
`closure_failure` receipt.
Invariant 6:
No scanner counts `br list --json` using raw `jq length`.
Invariant 7:
Protected sessions default to dry-run or repair-only until Joshua approves
mutating work.
Invariant 8:
Each session's repo path comes from topology/config, not pane cwd alone.
Invariant 9:
Autoloop selected repo must either have `.beads`, or the action must be
bootstrap/exclude, not ordinary tick.
Invariant 10:
Fleet alive is not the same as fleet flowing.
## 11. Receipt Schema Extensions
### Autoloop Receipt
Add:
```json
{
  "tick_action": "dispatch_bead|summarize_dirty_worktree|repair_failed|no_action",
  "action_reason": "string",
  "origin_alert_ts": "string|null",
  "selected_bead": "string|null",
  "target_session": "string|null",
  "target_pane": "number|null",
  "protected_policy_checked": true,
  "dispatch_log_row_written": true,
  "no_action_reason": "string|null"
}
```
### Idle Alert Consumer Receipt
Add:
```json
{
  "consumer_ts": "string",
  "alerts_seen": 1,
  "alerts_consumed": 1,
  "self_bug_candidates": ["josh-1eo8p"],
  "selected_action": "DISPATCH_SELF_BUG",
  "selected_bead": "josh-1eo8p",
  "why": "self-bug older than five tick cadences"
}
```
### Ghost Gate Receipt
Add:
```json
{
  "repos_scanned": 5,
  "total_in_progress": 11,
  "ghost_overdue": 3,
  "orphans": 7,
  "closure_failures": 1,
  "active": 0,
  "dispatch_allowed": true
}
```
## 12. Non-Goals
Do not implement the full recovery plan in this fleet-idle wave.
Do not install all watcher plists as a prerequisite for ALPS repair dispatch.
Do not auto-close ghost beads.
Do not auto-reopen protected-client beads without review.
Do not treat `fleet_alive=true` as success.
Do not treat `repair_failed` as an adequate terminal outcome if a self-bug bead
exists.
Do not dispatch arbitrary ALPS client work as the first drill.
Do not bypass Joshua's protected-session decision for ALPS pane restart.
## 13. Risks
Risk 1:
Dispatching into a wedged ALPS pane fails silently.
Mitigation:
Require orchestrator contract and pane restart decision.
Risk 2:
Self-bug selection chooses the wrong bead.
Mitigation:
Use explicit regex and age threshold; log `why_this_bead`.
Risk 3:
Autoloop dispatches into protected work.
Mitigation:
Protected filter defaults to dry-run/repair-only.
Risk 4:
Ghost gate blocks too much work.
Mitigation:
Gate emits recommendations but does not mutate or halt unless safety proof is
missing.
Risk 5:
Recovery and fleet-idle duplicate session maps.
Mitigation:
Shared overlay schema, cross-cites, no merged DAG.
Risk 6:
`bv --robot-next` is unavailable or produces unexpected shape.
Mitigation:
Fallback to normalized `br ready --json`.
Risk 7:
Dispatcher writes a dispatch row but send fails.
Mitigation:
Row state transitions from `prepared` to `send_failed` with reason.
Risk 8:
Callback lands but bead remains in progress.
Mitigation:
Lane B closure-failure gate surfaces it next tick.
## 14. Test Matrix
### Unit Tests
Consumer parses a single ALPS alert.
Consumer ignores empty alert list and writes no-action.
Consumer selects self-bug before ordinary work.
Consumer refuses protected mutating work without approval.
Consumer normalizes Beads JSON object envelope.
Consumer handles missing `.flywheel/dispatch-log.jsonl`.
Consumer handles missing `.beads`.
### Integration Tests
Dry-run ALPS alert consumes current fixture.
Dry-run dispatch writes prepared row to a temp ledger.
Dry-run NTM command renders exact target session and pane.
Ghost gate classifies Lane B fixture counts.
Autoloop dry-run emits `tick_action=dispatch_bead`.
### Drill Tests
ALPS repair dispatch dry-run.
ALPS repair dispatch apply after approval.
Callback receipt update.
Idle counter reset.
### Regression Tests
`vrtx` with no `.beads` must not be selected for ordinary dispatch.
`zeststream-v2` panes in `/Users/josh` must not be treated as repo-ready.
`br list --json | jq length` bug must not recur.
`repair_failed` cannot silently satisfy an idle alert.
## 15. Acceptance Summary
The fleet-idle wave is complete when:
1. Current ALPS alert is consumed within one tick.
2. The selected work is a self-bug repair bead.
3. Autoloop can emit `tick_action=dispatch_bead`.
4. Dispatch-log row is written before send.
5. ALPS pane receives the dispatch or records a protected restart blocker.
6. Callback lands or overdue status is explicit.
7. Selected bead closes or requeues.
8. ALPS idle counter resets or has a reasoned no-reset receipt.
9. Ghost-bead gate runs in the same tick family.
10. Recovery plan is cross-cited but not merged.
## 16. Validation Ladder
1. Reframe section addresses all three lane premise errors:
PASS.
Lane A is reframed as observe-only orchestration.
Lane B stands as ghost-bead signal and cap correction.
Lane C is tightened to consumer + dispatch + orchestrator contract.
2. Root cause chain is at most five deep:
PASS.
The chain has four causes.
3. Action plan is at most five beads:
PASS.
The plan has four new beads plus Phase 0 existing ALPS work.
4. Cross-link to recovery plan is explicit:
PASS.
Recommendation is keep separate but cross-cite shared substrate.
5. Joshua action items are at most five:
PASS.
There are four.
6. Drill plan covers full ALPS flowing path:
PASS.
Alert -> dispatch -> in_progress -> callback -> close/requeue -> idle reset.
7. Cites actual substrate:
PASS.
Cites `idle-spiral-alert.json`, `fleet-liveness.json`, `last_run.json`,
`INCIDENTS.md`, lane outputs, and recovery plan files.
8. No mutations to source/state during synthesis:
PASS.
This synthesis only writes the requested plan file.
9. `ladder_passed=yes` only if 1-8 clean:
PASS.
## 17. Final Recommendation
Ship the runtime fix first.
Start with ALPS because the system is already telling us it is idle and already
has the exact self-bug beads.
Do not wait for every watcher plist, checkpoint, or bootstrap target to land.
Do not merge fleet-idle into recovery.
Use recovery's topology, watcher, protected-session, and checkpoint work as
shared substrate.
The smallest useful change is:
`idle-spiral-alert.json` becomes an action queue.
The next useful change is:
autoloop gains `tick_action=dispatch_bead`.
The first proof is:
ALPS idle alert becomes an ALPS self-bug dispatch and callback.
## 18. Callback Metrics
```text
ladder_passed=yes
min_beads=4
joshua_decisions=4
consolidate_with_recovery=no
```
