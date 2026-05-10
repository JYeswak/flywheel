---
title: "Idempotency Receipt Integrity Amendments Implementation"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# Idempotency Receipt Integrity Amendments Implementation

task_id: amendment-idempotency-receipt-integrity-2026-05-06
bead: flywheel-mission-lock-idempotency-receipt-integrity-amendments-2026-05-06
scope: Phase 4 Wave 1 implementation
socraticode_queries: 6
indexed_chunks_observed: 968

## Summary

This amendment implements the six Phase 3 Lens 2 findings by adding a dispatch
receipt schema and a replay guard primitive. The guard gives dispatch and close
paths one shared question: "Have we already completed, started, or never seen
this deterministic dispatch input?"

The implementation is intentionally local and append-only. It does not mutate
the Phase 3 audit reports, Phase 2 refine artifacts, Phase 5 polish document,
peer repos, `.flywheel/MISSION.md`, or sibling amendment surfaces.

## Artifacts

| Artifact | Purpose |
|---|---|
| `.flywheel/validation-schema/v1/dispatch-receipt.schema.json` | Canonical additive receipt envelope for dispatch replay identity, replay hash, transaction markers, and per-finding completeness flags. |
| `.flywheel/scripts/idempotency-replay-guard.sh` | Canonical CLI primitive that computes the dispatch input identity, checks prior completed rows, and acquires an atomic in-flight lock when the input is new. |
| `.flywheel/tests/test_idempotency_replay_guard.sh` | Golden/structural shell test covering all IDEM findings and canonical CLI verbs. |

## Per-Finding Mitigation Table

| Finding | Summary | Mitigation shipped | Files touched | Test fixture |
|---|---|---|---|---|
| IDEM-001 | Dispatch-author can recompute and resend the same packet without deterministic prior-send lookup. | `idempotency-replay-guard.sh` computes `idempotency_key=sha256:<dispatch-input-shape>` and returns `already_completed`, `in_flight`, or `not_seen` before send. Schema adds `dispatch_identity_key`, `packet_hash`, `delivery_receipt_id`, and `previous_dispatch_log_row`. | `dispatch-receipt.schema.json`, `idempotency-replay-guard.sh` | `IDEM-001 replay detection returns already_completed with receipt_ref`. |
| IDEM-002 | Skill, alias, and minimal-mode skip receipts have semantics but no canonical field/schema identity. | Schema adds `skill_receipts[]`, `receipt_identity_key`, `action_taken`, `alias_of`, `not_applicable_reason`, `policy_version`, and `minimal_mode` receipt fields. Guard output includes `receipt_completeness.IDEM-002=true`. | `dispatch-receipt.schema.json`, `idempotency-replay-guard.sh` | `IDEM-002 completeness flags cover all findings`. |
| IDEM-003 | Skill-suite replay can drift because live catalog/alias/touched-file inputs are not hashed. | Schema adds deterministic routing input hashes: `bead_identity_hash`, `labels_hash`, `touched_files_hash`, `mission_surfaces_hash`, `skill_catalog_snapshot_hash`, `alias_registry_version`, and `socraticode_query_set_hash`. Guard canonicalizes JSON input before hashing so key order does not alter identity. | `dispatch-receipt.schema.json`, `idempotency-replay-guard.sh` | `IDEM-003 canonical JSON key order produces identical idempotency_key`. |
| IDEM-004 | Parallel audit lenses can clobber shared `STATE.json` without observed/written hashes or merge receipts. | Schema adds `state_observed_sha`, `state_written_sha`, `audit_lens_identity_key`, and `preserved_lenses`. Guard uses atomic lock directories so one worker gets `not_seen` while a concurrent duplicate gets `in_flight`. | `dispatch-receipt.schema.json`, `idempotency-replay-guard.sh` | `IDEM-004 duplicate concurrent input returns in_flight while lock exists`. |
| IDEM-005 | Append-only JSONL close replay can duplicate closed truth without a close identity or latest-row rule. | Schema adds `close_identity_key`, `previous_close_row`, `closure_reconciliation_via`, and `dedupe_policy=latest-row-by-ref_id-event`. Guard treats completed rows with the same identity as `already_completed` and points to the prior receipt. | `dispatch-receipt.schema.json`, `idempotency-replay-guard.sh` | `IDEM-005 completed ledger row suppresses duplicate execution and preserves one-line truth`. |
| IDEM-006 | Readiness/scaffold repair receipts lack lock hashes, section hashes, prior receipt refs, and repair idempotency keys. | Schema adds `mission_lock_hash`, `required_sections_hash`, `validator_schema_version`, `prior_receipt_ref`, and `repair_idempotency_key`. Guard emits transaction boundary markers for begin/commit/abort on every decision. | `dispatch-receipt.schema.json`, `idempotency-replay-guard.sh` | `IDEM-006 transaction boundary markers are present for not_seen, in_flight, already_completed, and completed records`. |

## Runtime Contract

The replay guard reads dispatch input from `--input`, `--input-file`, or stdin.
If `--idempotency-key` is not supplied, it canonicalizes JSON input or preserves
raw text, then hashes the canonical shape with SHA-256.

Decision states:

| Status | Meaning | Caller action |
|---|---|---|
| `already_completed` | A completed ledger row exists for this key/hash. | Do not rerun; point close evidence at the prior receipt. |
| `in_flight` | A lock directory exists for this key. | Do not send; wait, inspect, or repair stale lock ownership. |
| `not_seen` | No completed row and no lock existed; lock acquired unless `--no-lock` is used. | Proceed inside the transaction boundary. |
| `completed` | `--mark-completed` appended the completion row and released the lock. | Close with the emitted receipt ref. |

## Receipt Schema Fields Added

Core identity fields:

- `idempotency_key`
- `replay_detection_hash`
- `dispatch_identity_key`
- `packet_hash`
- `close_identity_key`

Transaction and replay fields:

- `transaction_boundary.begin`
- `transaction_boundary.commit`
- `transaction_boundary.abort`
- `previous_dispatch_log_row`
- `previous_close_row`
- `dedupe_policy`
- `closure_reconciliation_via`

Completeness fields:

- `receipt_completeness.IDEM-001`
- `receipt_completeness.IDEM-002`
- `receipt_completeness.IDEM-003`
- `receipt_completeness.IDEM-004`
- `receipt_completeness.IDEM-005`
- `receipt_completeness.IDEM-006`

Snapshot/hash fields:

- `bead_identity_hash`
- `labels_hash`
- `touched_files_hash`
- `mission_surfaces_hash`
- `skill_catalog_snapshot_hash`
- `socraticode_query_set_hash`
- `state_observed_sha`
- `state_written_sha`
- `mission_lock_hash`
- `required_sections_hash`

## Verification

Primary command:

```bash
bash .flywheel/tests/test_idempotency_replay_guard.sh
```

Dispatch acceptance command:

```bash
test -f /Users/josh/Developer/flywheel/.flywheel/plans/mission-lock-paradigm-extension-2026-05-06/impl/idempotency-amendments-impl.md && \
  test -x /Users/josh/Developer/flywheel/.flywheel/scripts/idempotency-replay-guard.sh && \
  bash /Users/josh/Developer/flywheel/.flywheel/scripts/idempotency-replay-guard.sh --info > /dev/null 2>&1 && \
  bash /Users/josh/Developer/flywheel/.flywheel/tests/test_idempotency_replay_guard.sh > /dev/null 2>&1 && \
  grep -q "idempotency-receipt-integrity 6 findings mitigated" /Users/josh/Developer/flywheel/INCIDENTS.md && \
  echo OK_idempotency_amendments_shipped
```
