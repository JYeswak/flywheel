# flywheel-esdx Failure Taxonomy Evidence

bead: flywheel-esdx
generated_at: 2026-05-08T00:00:00-06:00
schema_version: failure-taxonomy-evidence/v1

## DID

| AG | status | evidence |
|---|---|---|
| 1 | PASS | Mined `.flywheel/receipts/`, `.flywheel/dispatch-log.jsonl`, `.flywheel/callback-validation-log.jsonl`, `INCIDENTS.md`, `AGENTS.md`, `tests/`, and `.flywheel/validation-schema/v1/` for raw failure shapes. |
| 2 | PASS | Authored `.flywheel/doctrine/failure-taxonomy.md` with 10 canonical `failure_class` values. |
| 3 | PASS | Every canonical class has deterministic `retry_policy` and one-line `recovery_hint`. |
| 4 | PASS | Authored `.flywheel/scripts/failure-class-emit.sh` to emit JSON envelope fields from raw failure strings. |
| 5 | PASS | Added `tests/failure-class-emit.sh` fixture proving open-child, DCG, reservation, runtime, artifact, context drift, correctness, invalid callback, and unknown mappings. |
| 6 | PASS | Correctness regressions and invalid callbacks are explicitly asserted not to classify as transient flakes. |
| 7 | PASS | `.flywheel/canonical-paths.txt` links the taxonomy doc, helper, and tests. |
| 8 | PASS | Validator script left untouched because pane 2 owns `.flywheel/scripts/validate-callback-before-close.sh`. |

did: 8/8
didnt: did not patch the four-lens validator; did not mutate pane 4 evidence; did not manually edit `.beads/issues.jsonl`.
gaps: validator adoption is intentionally left as follow-up work for the owner of the validator edit lane.

## Mined Shapes

Representative recurring shapes:

- `validator_verdict=BLOCK_CLOSE_open_children_preserved`
- `validator_verdict=BLOCK_CLOSE_open_child_wbnb`
- `open_child_blocks_close`
- `dcg_block_handled=redirect_truncate_varfolders`
- `bead_close_blocked_by=.beads_reservation_conflict_PurpleMeadow`
- `file_reservation_conflict`
- `shared_append_reservation_conflict`
- `append_reservation_conflict`
- `artifact_missing`
- `evidence_missing`
- `runtime_unresponsive`
- `context_drift`
- `missing_did_didnt_gaps`

## Canonical Classes

failure_classes_count: 10

- `transient` -> `retry_policy=exponential`
- `persistent` -> `retry_policy=manual`
- `correctness` -> `retry_policy=permanent`
- `missing_artifact` -> `retry_policy=manual`
- `invalid_callback` -> `retry_policy=manual`
- `context_drift` -> `retry_policy=manual`
- `gate_unmet_open_children` -> `retry_policy=none`
- `dcg_blocked_destructive_command` -> `retry_policy=manual`
- `file_reservation_conflict` -> `retry_policy=manual`
- `unknown` -> `retry_policy=manual`

## Jeff Citation

The imported pattern mirrors Jeff's structured error style: Beads Rust defines
stable `ErrorCode` names with retryability and exit-code categories in
`/Users/josh/Developer/beads_rust/src/error/structured.rs`; NTM surfaces
machine-readable `error_code` and operator hints in its overlay/feed tests.
Flywheel keeps raw failure strings as compatibility aliases while routing by
stable class fields.

## Joshua Lens

PASS. This is not bare mission fit. The operator-experience pattern is that
ad-hoc failure strings are tomorrow's grep fragility. A 25-year operations
manager makes every recurring error class a runbook entry; this taxonomy is the
runbook table of contents. It creates turnover resilience because the next
operator can route open-child blocks, DCG redirects, file-reservation conflicts,
invalid callbacks, and correctness regressions without reading pane scrollback.

## Validation

Expected commands:

```text
bash tests/failure-class-emit.sh
bash -n .flywheel/scripts/failure-class-emit.sh
```

Socraticode:

- `socraticode_queries=5`
- `indexed_chunks_observed=50`
