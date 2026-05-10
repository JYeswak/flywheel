---
title: "Phase 3 AUDIT r1 Lens 1 - Observability, Safety, Cross-Session Boundary"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# Phase 3 AUDIT r1 Lens 1 - Observability, Safety, Cross-Session Boundary

Plan: `orchestrator-workforce-supervision-2026-05-04`
Lens: observability + safety + cross-session boundary
Input: `00-PLAN.md` r2, Lane A addendum, cross-session callback fuckup log
Skill: `jeff-convergence-audit`

## Audit Summary

The r2 plan correctly absorbs `cross-session-dispatch-no-callback-closure` as a
P0 class, but the audit finds several places where the plan can still fail
silently or fail open unless Phase 4 makes the contracts stricter.

Findings total: 11
P0 findings: 4
P1 findings: 5
P2 findings: 2

No gap beads are filed in this Phase 3 lens because the dispatch is READ-ONLY.
These findings should become amendments or beads during Phase 4 DECOMPOSE.

## Findings Register

| finding_id | severity | section_of_plan | description | proposed_mitigation | requires_joshua_decision |
|---|---|---|---|---|---|
| F1 | P0 | Section 5 Layer 1; Section 8 B09 | `remote_session_orch_alive` is named, but its proof contract is underspecified. A probe can say an orch pane exists while the loop driver is marker-only, stale, or not processing callback messages. | B09 must require three proofs before cross-session dispatch: live orch pane, verified loop driver/prompt delivery within two cadence windows, and recent callback-processing heartbeat. Add fixtures for `pane_alive_driver_dead` and `callback_lands_unprocessed`. | no |
| F2 | P0 | Section 4 failure catalog; Section 6 doctor signal | `callback_orphan_count` counts orphaned dispatches after deadline, but the plan does not define how to discover remote repo `in_progress` beads when the flywheel dispatch log is missing or malformed. Today's fuckup included a `br` jq schema fragility that returned empty work. | B06/B09 must cross-check flywheel dispatch log against remote repo `br list --status in_progress --json` using schema-validated parsing. Orphan detection passes only when both local dispatch and remote bead state are queried or a typed source error is emitted. | no |
| F3 | P0 | Section 5 Layer 4 auto-recovery; Section 10 Q6 | The plan says refuse cross-session dispatch if remote orch is dead, but it leaves a human one-shot override open without a required receipt shape. That can recreate the exact cross-session orphan under pressure. | Require `cross-session-dispatch-override/v1` receipt with target session, remote orch proof failure, human approver, expiry, callback route, and orphan-risk acknowledgement. Without receipt, refusal is mandatory. | yes |
| F4 | P0 | Section 5 Layer 2; Section 5 Layer 3 | SQLite is rebuildable from JSONL, but the plan does not say what happens when JSONL writes stall, lock, truncate, or silently stop while SQLite still serves stale current state. | Add supervisor self-watchdog: every collector batch writes a heartbeat row; `doctor` compares current-state freshness against raw ledger tail. If ledger freshness exceeds threshold, dashboard status becomes `supervisor_observability_degraded` and auto-recovery is disabled. | no |
| F5 | P1 | Section 5 Layer 1 collectors | Collector timeouts are not specified. A stuck `ntm`, MCP, `br`, or doctor probe can hang the supervisor cycle and prevent the failure from surfacing. | Every collector must have timeout, exit-code class, stderr capture, and typed timeout sample. The watch loop must continue with degraded state rather than block the whole mesh. | no |
| F6 | P1 | Section 5 Layer 3 classifier enum | `unknown_source_conflict` is a fail-closed state, but the plan does not require the dashboard to show which sources conflict. Operators may see "unknown" without a repairable cause. | Current-state rows must expose `source_conflicts_json` in dashboard JSON and `why`. Human view should include compact source pairs, sample ages, and conservative decision. | no |
| F7 | P1 | Section 5 Layer 4 auto-recovery | `stuck_thinking` allows status probe and possible interrupt, but no guard distinguishes long quiet reasoning from actual stuck output except velocity/byte delta. A quiet but valid worker could be interrupted. | Require task-aware grace periods: callback deadline, last tool activity, and prompt type feed the threshold. Interrupt requires two consecutive zero-delta samples plus no active tool/session evidence. | no |
| F8 | P1 | Section 5 Layer 5 escalation | Escalation outputs include diagnostic bead drafts and fuckup rows, but no dedupe key is defined. A noisy failure can file duplicate beads every watch cycle. | Escalations require deterministic dedupe key: `failure_class:session:pane:task_id:window`. Repeats update the existing receipt/bead until TTL expires. | no |
| F9 | P1 | Section 8 B10 final conformance/daemon | Observability of observability itself is deferred to final conformance, but daemon death can make all earlier layers invisible. This should not wait until B10. | Split a self-watchdog acceptance gate into B01/B02/B03: schema, heartbeat collector, and freshness checker must exist before any recovery dispatcher. B10 only proves daemon survival end-to-end. | no |
| F10 | P2 | Section 5 Layer 1 topology collector; Section 8 B09 | Session topology changes are recognized, but pane role changes are not versioned. A respawned worker pane can inherit old task/callback assumptions. | Topology samples need `topology_epoch`, pane PID/process identity, and role effective time. State aggregation invalidates assignments when epoch or pid changes. | no |
| F11 | P2 | Section 6 CLI surface | `/flywheel:supervisor --silence` can hide a noisy pane, but the plan does not state whether silence affects doctor signals, callback debt, or only human display. | Define silence as display-only unless paired with an explicit dispatch/recovery deferral receipt. Doctor JSON must still count hidden debt and failures. | yes |

## Lens Coverage

### 1. Silent-Failure Paths

Covered by F1, F2, F4, F5, and F9.

The largest silent-failure risk is that the supervisor's own collectors or
state pipeline fail while the dashboard continues to show stale current state.
The plan says receipts are truth, but Phase 4 must make receipt freshness a
first-class truth source.

### 2. Visibility Gaps

Covered by F6, F8, F10, and F11.

The plan has good state names, but dashboard and `why` outputs must expose the
specific source conflict and topology epoch. Otherwise the operator gets a
classification without a repairable cause.

### 3. Cross-Session Callback Boundary Integrity

Covered by F1, F2, and F3.

r2 names the right failure class, but B09 needs a stricter proof contract:
remote orch pane alive is not enough; the remote loop driver and callback
processing heartbeat must be live too.

### 4. Fail-Closed vs Fail-Open

Covered by F3, F5, F7, and F11.

The plan is mostly fail-closed, but human override, quiet THINKING interrupts,
collector hangs, and silence/mute semantics are places where the implementation
could fail open without additional gates.

### 5. Observability Of Observability

Covered by F4 and F9.

Self-watchdog cannot be deferred to final conformance only. It must land in the
contract/collector/index phases so recovery never runs on stale or missing
supervisor state.

### 6. Cross-Session Topology Change

Covered by F10.

The plan distinguishes missing/stale sessions, but not role epochs or pane PID
changes. That is enough to misroute callback expectations after respawn.

## Phase 4 Amendments

Required amendments before bead creation:

1. Add B09 gates for remote orch driver and callback-processing heartbeat.
2. Add callback orphan cross-check against remote `br in_progress` state.
3. Add supervisor self-watchdog to B01/B02/B03, not only B10.
4. Add timeout/error sample contract for every collector.
5. Add dedupe key to escalation receipts.
6. Add topology epoch and pane process identity to state schema.

Joshua-disposes decisions:

1. Whether human cross-session dispatch override is allowed at all.
2. Whether `/flywheel:supervisor --silence` may suppress operator display only
   or may also defer dispatch/recovery with a receipt.

## Three-Q Audit

Validated:

Each finding cites a section of `00-PLAN.md` and a concrete failure mode from
the r2 synthesis or the 04:00Z skillos fuckup.

Documented:

Findings are structured for Phase 4 decomposition and include mitigation shape.

Surfaced:

P0/P1 findings are explicit and should become bead amendments in Phase 4. No
separate gap beads were created because this audit dispatch is read-only.

## Closeout

DID:

1. Silent-failure paths audited.
2. Visibility gaps audited.
3. Cross-session callback boundary integrity audited.
4. Fail-closed vs fail-open posture audited.
5. Observability-of-observability audited.
6. Cross-session topology change audited.

DIDNT:

- Did not mutate plan source beyond this audit artifact.
- Did not create beads during Phase 3 read-only audit.

GAPS:

- none outside findings register

Ladder:

passed
