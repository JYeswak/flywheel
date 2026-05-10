---
title: "Phase 3 Audit Round 1"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# Phase 3 Audit Round 1

Audit method: broad sweep using the `jeff-convergence-audit` style, limited to three lenses required by dispatch. Scope is plan-space; no code was changed.

## Lens 1 - Idempotency

Question: Does double-`continue` cascade?

Finding M1: A duplicate `continue` can cascade if the same capacity-halt screen is processed by multiple watchers or ticks. The plan resolves this with a per-pane/digest idempotency key and recovery lease keyed by `(session,pane,hash_t1,capacity_digest)`.

Finding M2: The `Continue anyway? [y/N]` transport prompt can hang automation if confirmation is not supplied. The plan resolves this with finite `printf 'y\n'` input and forbids unbounded `yes |` as primary path.

Finding L1: A second `continue` after success may be harmless but noisy. The post-send success check should close the lease before the next tick.

Residual risk: medium until Phase 4 implements and tests the lease.

## Lens 2 - Cross-Session Authorization

Question: Can flywheel recover alps/skillos/mobile-eats workers without violating ownership?

Finding M3: Worker auto-continue is a cross-session pane mutation when the target is in another session. The plan resolves this by requiring latest topology role `worker` plus remote orchestrator/callback liveness proof before apply.

Finding M4: Orchestrator/human/callback panes must not receive worker-policy auto-continue. The plan resolves this with protected refusal and L115 permit-gate routing for peer orchestrators.

Finding L2: Capacity-halt is a narrower action than respawn, but it still mutates a remote pane. Ledger rows must record actor, target, role, proof, action, and result.

Residual risk: medium until Phase 4 wires topology and role tests.

## Lens 3 - Recovery Success Measurement

Question: How do we know `continue` worked rather than getting swallowed?

Finding M5: Send acknowledgement alone is transport success, not recovery success. The plan resolves this with post-send recapture and success predicates: output hash changes, capacity text disappears, or robot activity transitions to THINKING/GENERATING.

Finding M6: Persistent model capacity should not loop forever. The plan resolves this with attempt budgets and fallback/notify after repeated failure.

Finding L3: Doctor fields must separate `attempted`, `transport_ack`, and `recovery_succeeded`; otherwise `/flywheel:learn` will mine false wins.

Residual risk: medium until Phase 4 creates the ledger schema and tests.

## TRUE Blocker Class Trace

1. Missing empirical basis: false. Rows `L1544`, `L1575`, `L1579`, and `L1619` prove recurrence.
2. Unbounded unsafe mutation: false after plan constraints. Phase 4 must implement lease and worker-scope checks.
3. Cross-session ownership violation: false after plan constraints. Phase 4 must enforce topology and callback proof.
4. No success measurement: false after plan constraints. Phase 4 must implement post-send measurement.
5. Duplicate existing substrate: false. Plan reuses detector/watchdog chain and avoids sibling watcher by default.
6. Out-of-scope code mutation required now: false. Phase 1-3 deliverable is complete without code-space mutation.

Audit disposition: `auto_advance`.

Critical findings: 0.
High findings: 0.
Medium findings: 6.
Low findings: 3.
