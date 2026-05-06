---
name: failure-taxonomy-receipts
description: Candidate skill for stable failure_class, retry_policy, and recovery_hint fields in validation receipts and doctor JSON.
status: approval_only
source_bead: flywheel-w3pr.3
phase4_verdict: ADOPT
---

# Failure Taxonomy Receipts

Use this candidate skill when a validation surface, doctor signal, callback
validator, or repair helper emits machine-readable failure JSON.

## Contract

Receipts should classify at least:

- `transient`
- `persistent`
- `correctness`
- `missing_artifact`
- `invalid_callback`
- `context_drift`
- `unknown`

Each class should define `retry_policy` and `recovery_hint`. Correctness
regressions and invalid callbacks must not be classified as flakes.

## Source Evidence

- Phase 4 verdict: `.flywheel/jeff-corpus/v1/learnings/04-adopt-extend-avoid.md`, "Error handling and recovery taxonomy" = ADOPT.
- `frankensqlite/crates/fsqlite-harness/src/ci_gate_matrix.rs:453` classifies retry decisions by failure class and lane.
- `asupersync/docs/wasm_dx_error_taxonomy.md:1` defines error codes and recoverability classes.
- `agentic_coding_flywheel_setup/README.md:3421` documents resume decisions and common failure recovery.
- `flywheel_connectors/crates/fcp-webhook/tests/e2e_webhook_delivery_retry.rs:169` distinguishes verified delivery, replay, timestamp drift, and unauthorized delivery.

## Approval Gates

- Install only after `flywheel-esdx` standardizes receipt fields and fixtures.
- Keep the taxonomy stable; adding new classes should require schema migration tests.
