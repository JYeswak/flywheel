---
title: "Capacity Halt Detector And Auto-Continue Recovery Plan"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# Capacity Halt Detector And Auto-Continue Recovery Plan

Plan arc: `capacity-halt-detector-and-auto-continue-recovery`.
Dispatch: `plan-capacity-halt-detector-and-auto-continue-2026-05-06`.
Current phase after this dispatch: `decompose`.
Scope: plan-space only; Phase 4/5 code work is out of scope.

## Final Thesis

Capacity halt recovery is a bounded worker-scope retry loop inside the existing codex stuck detector and worker watchdog chain. It is not a new watcher unless Phase 4 reconciliation proves the existing chain cannot host it.

## Evidence Base

- Five-instance empirical class: `fuckup-log#L1544`, `#L1575`, `#L1579`.
- Later recurrence during this plan arc: `fuckup-log#L1619`.
- Production-path regression that must be reconciled first: `fuckup-log#L1620`.
- Current sibling shapes: `codex-template-stuck-detector`, `worker-auto-respawn-watchdog`, `frozen-pane-detector`, `fleet-watcher-coverage-probe`.
- Skills/source-(a): `planning-workflow`, `research-triad`, `codebase-archaeology`, `jeff-convergence-audit`, `donella-meadows-systems-thinking`, `codex-cli-tracker`, `loop-enforcement`, `accretive-cron-orchestration`, `observability-platform`, `socraticode`.

## Detection Contract

- Match only if the last 50 lines include `selected model is at capacity` or `please try a different model`.
- Require ready chevron/prompt evidence.
- Require stable two-frame sample before automated apply.
- Emit subclass `model_at_capacity_halt`.
- Emit recommended recovery `auto_continue`.
- Bare chevron remains not-capacity.

## Recovery Contract

- Worker panes only.
- First action: finite-confirmed `ntm send <session> --pane=<pane> "continue"`.
- Idempotency key: `(session,pane,hash_t1,capacity_digest)`.
- Budget: 5 auto-continue attempts per pane per hour, plus stop after 3 failed success checks.
- Success requires post-send proof: output delta, capacity text disappears, or robot activity moves to THINKING/GENERATING.
- Budget exhaustion routes to notify/fallback-model/redispatch; no first-line respawn.

## Authorization Contract

- Latest topology decides pane role.
- Orchestrator, human, and callback panes are refused under worker policy.
- Peer-session workers require remote orchestrator/callback liveness proof before apply.
- Peer orchestrators stay on L115 permit-gate path.
- Flywheel self-orchestrator recovery is never self-applied.

## Phase 4 Bead DAG Preview

1. `capacity-halt-production-path-reconcile`
2. `capacity-halt-auto-continue-primitive`
3. `capacity-halt-success-measurement`
4. `capacity-halt-cross-session-authorization`
5. `capacity-halt-burst-budget`
6. `capacity-halt-doctor-ledger`
7. `capacity-halt-driver-coverage`

## Phase 3 Disposition

Audit disposition: `auto_advance`.

No TRUE blocker class remains for Phase 4 decomposition. The known P0 regression is not a blocker to planning; it is the first Phase 4 bead and has a crisp reconciliation path.

## Follow-Up Boundary

This dispatch does not mutate scripts or tests. The next worker must reserve code/test paths, reconcile current dirty artifacts, and prove live-string classification plus launchd/driver coverage before claiming the capacity-halt system is shipped.
