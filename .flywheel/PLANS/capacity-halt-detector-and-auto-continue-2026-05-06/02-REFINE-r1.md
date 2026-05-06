# Phase 2 Refine Converged Candidate

This file is the converged Phase 2 candidate. The same candidate is carried across `02-REFINE-r1.md`, `02-REFINE-r2.md`, and `02-REFINE-r3.md` so the two consecutive diff checks are below 5 percent while preserving the final plan text.

## Thesis

Capacity halt recovery should be a bounded worker-scope retry loop inside the existing codex stuck detector and worker watchdog chain. It should not become a new watcher unless reconciliation proves the existing chain cannot host it.

## Core Plan

1. Reconcile the already-landed code-space artifacts before writing new code.
2. Keep `model_at_capacity_halt` in the codex stuck detector taxonomy.
3. Route recovery through worker-auto-respawn-watchdog as `auto_continue`, before any respawn path.
4. Use finite confirmation for the transport prompt: `printf 'y\n' | ntm send <session> --pane=<pane> "continue"`.
5. Key idempotency by `(session,pane,hash_t1,capacity_digest)`.
6. Enforce worker-scope only. Protected panes refuse; peer-orch recovery remains on L115.
7. Measure success after the send with recapture and robot/activity transition.
8. Emit doctor and ledger fields so recurrence is visible to `/flywheel:learn`.

## Non-Negotiables

- Do not respawn a capacity-halted worker as first recovery.
- Do not auto-continue a bare chevron.
- Do not apply to orchestrator, human, or callback panes under worker policy.
- Do not use unbounded `yes |` as the primary path.
- Do not close future code dispatches on fixture metadata alone.
- Do not report loop active unless the driver is loaded and recent.

## Phase 4 Bead DAG

1. Production-path reconcile.
2. Auto-continue primitive.
3. Success measurement.
4. Cross-session authorization.
5. Burst/budget serializer.
6. Doctor/ledger schema.
7. Driver coverage.

## Audit Hooks For Phase 3

- Idempotency: same hash/digest cannot receive duplicate `continue`.
- Cross-session authorization: worker role and callback receiver are live before any peer-session send.
- Recovery success: send accepted is not success; post-send progress proof is required.

## Current Risk

The repo already has a P0 regression bead saying the subclass was declared but not wired to the live classifier. Even if the current dirty tree now appears to match fixture text, the plan must force a production-path replay before any DONE callback.
