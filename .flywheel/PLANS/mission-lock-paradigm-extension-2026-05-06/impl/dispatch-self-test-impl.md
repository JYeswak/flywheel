---
title: "Dispatch Self-Test Delivery Identity Implementation"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# Dispatch Self-Test Delivery Identity Implementation

Task: `wave3-dispatch-self-test-delivery-identity-2026-05-06`
Bead: `flywheel-dispatch-self-test-delivery-identity-2026-05-06`
Status: shipped 2026-05-06

## Scope

This implementation adds the dispatch-time identity self-test at:

- `.flywheel/scripts/dispatch-self-test-delivery-identity.sh`
- `.flywheel/tests/test_dispatch_self_test_delivery_identity.sh`

It consumes these Wave 1/2 artifacts as read-only inputs:

- `.flywheel/scripts/idempotency-replay-guard.sh`
- `.flywheel/scripts/plan-state-lens-merge.sh`
- `.flywheel/scripts/dispatch-author-contract-probe.sh`
- `.flywheel/doctrine/dispatch-author-skill-routing-contract.md`
- `.flywheel/validation-schema/v1/dispatch-receipt.schema.json`
- `.flywheel/dispatch-log.jsonl`

## Behavior

`pretest --packet <path> --json` runs before send. It extracts an explicit
`idempotency_key` when present, otherwise derives `sha256:<hash>` from Task ID,
target pane, and packet body. It rejects malformed packets without Task ID or
target, checks the dispatch log for prior identity rows, and uses an atomic
per-key lock so two concurrent pretests cannot both proceed.

`verify-identity --idempotency-key <key> --dispatch-log <path> --json` is the
read-only prior-state lookup. It returns `proceed`, `refuse_in_flight`,
`refuse_complete`, or `refuse_duplicate` with the prior dispatch envelope.

`mark-delivered --idempotency-key <key> --json` writes one canonical
`delivery_confirmed` event to the self-test delivery ledger, never to the live
dispatch log. Re-running it for the same key returns `refuse_complete` and does
not append a duplicate row.

## Finding Mitigation

| Finding | Mitigation |
|---|---|
| `SEC-001` | Packet parsing never logs packet bodies, secret values, Agent Mail tokens, or raw env output. The emitted JSON contains only identity keys, prior state, refs, and reasons. |
| `IDEM-001` | Duplicate dispatch keys are resolved before send. Completed prior dispatches short-circuit with `refuse_complete`; in-flight or unverified callbacks return `refuse_in_flight`. |
| `CSR-003` | The checker consumes the dispatch-author contract output shape and treats route identity as data, so skillos/template handshakes can be replayed without re-sending completed work. |
| `CSR-006` | The test suite includes negative and race fixtures that prove malformed packets and concurrent duplicate pretests fail closed. |

## Replay-Guard Interaction

The Wave 1 replay guard owns durable close/completion receipts. This script
owns the pre-send delivery identity check. The two share the same identity-key
shape and transaction semantics:

- replay guard: close-time `not_seen | in_flight | already_completed | completed`
- self-test: send-time `proceed | refuse_in_flight | refuse_complete | refuse_duplicate`

The self-test uses a lock directory, not `.flywheel/dispatch-log.jsonl`, for
race suppression. That keeps the live dispatch ledger read-only outside the
canonical send path.

## Dispatch Integration

`/flywheel:dispatch` should call:

```bash
.flywheel/scripts/dispatch-self-test-delivery-identity.sh pretest \
  --packet "$dispatch_packet" \
  --dispatch-log .flywheel/dispatch-log.jsonl \
  --json
```

Integration rule:

- `verdict=proceed`: continue to the existing send path.
- `verdict=refuse_in_flight`: stop before send and report the prior dispatch.
- `verdict=refuse_complete`: stop before send and emit an already-complete receipt.
- `verdict=refuse_duplicate`: stop before send and repair the packet identity.

After callback delivery verification succeeds, the canonical close/send wrapper
may call `mark-delivered` with the same key. The helper intentionally writes to
the self-test delivery ledger so direct script execution cannot mutate the live
dispatch log.

## Validation

`bash .flywheel/tests/test_dispatch_self_test_delivery_identity.sh` passed with
7 required cases and 18 total checks:

- fresh key proceeds
- duplicate without callback refuses in-flight
- callback received but unverified refuses in-flight
- verified callback refuses complete
- malformed packet fails with reason
- concurrent pretest lets exactly one writer proceed
- mark-delivered appends exactly one canonical row
