# Phase 3 Audit Findings

Disposition: `auto_advance`.

## Summary

The plan is safe to advance to Phase 4 decomposition. No TRUE blocker class remains in plan-space. The known code-space regression from `fuckup-log#L1620` is handled as the first Phase 4 bead, not as a reason to pause the plan.

## Findings

| Severity | ID | Lens | Finding | Required Phase 4 action |
|---|---|---|---|---|
| Medium | M1 | Idempotency | Duplicate watchers/ticks can send repeated `continue` for the same stable screen. | Add per-pane/digest lease and attempts ledger. |
| Medium | M2 | Idempotency | Transport confirmation can hang or cascade. | Use finite `printf 'y\n'` confirmation; test fake `ntm` prompt. |
| Medium | M3 | Cross-session authorization | Peer-session worker auto-continue is still a remote pane mutation. | Require latest topology worker role plus remote orch/callback liveness proof. |
| Medium | M4 | Cross-session authorization | Protected panes must not receive worker-policy auto-continue. | Refuse orchestrator/human/callback panes; route peer orch through L115. |
| Medium | M5 | Recovery measurement | Send acknowledgement is not recovery success. | Recapture and prove output delta, capacity-text disappearance, or robot activity transition. |
| Medium | M6 | Recovery measurement | Persistent capacity can loop indefinitely. | Budget to fallback/notify/redispatch after repeated failures. |
| Low | L1 | Idempotency | Success lease close timing can produce one noisy extra tick. | Close/mark lease immediately after success proof. |
| Low | L2 | Cross-session authorization | Ledger must be rich enough for later audit. | Record actor, target, role, proof, action, rc, and result. |
| Low | L3 | Recovery measurement | Doctor success percent can be false if attempted and succeeded are conflated. | Separate attempted, transport_ack, and recovery_succeeded. |

## Blocker-Class Trace

- `missing_empirical_basis=false`: rows `L1544`, `L1575`, `L1579`, and `L1619`.
- `unsafe_unbounded_mutation=false`: bounded action and idempotency lease are required.
- `cross_session_ownership_violation=false`: protected refusal and callback proof are required.
- `no_recovery_success_measurement=false`: post-send recapture is required.
- `duplicate_substrate=false`: existing detector/watchdog chain remains authority.
- `requires_code_mutation_in_phase_3=false`: all code work is deferred to Phase 4/5.

## Auto-Advance Algorithm Output

```json
{
  "audit_disposition": "auto_advance",
  "critical": 0,
  "high": 0,
  "medium": 6,
  "low": 3,
  "next_phase": "decompose",
  "true_blocker_classes": []
}
```

## Phase 4 Entry Criteria

1. Reserve code/test/install paths before edits.
2. Reconcile existing dirty code-space capacity artifacts before patching.
3. Prove live-string classifier replay without metadata hints.
4. Prove bounded `continue` idempotency with finite confirmation.
5. Prove watcher driver/install coverage.
6. Add doctor/ledger fields before claiming shipped.
