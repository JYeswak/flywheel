# Failure Taxonomy Contract

owner_bead: flywheel-esdx
schema_version: failure-taxonomy-envelope/v1
status: canonical

## Purpose

Validation receipts, doctor JSON, worker callbacks, and repair helpers must emit
stable failure fields instead of one-off prose strings:

```json
{
  "schema_version": "failure-taxonomy-envelope/v1",
  "raw_failure": "validator_verdict=BLOCK_CLOSE_open_child_wbnb",
  "failure_class": "gate_unmet_open_children",
  "retry_policy": "none",
  "recovery_hint": "Close or explicitly preserve the named child blocker before retrying parent close.",
  "reason_code": "open_child_blocks_close",
  "matched_alias": "block_close_open_child"
}
```

Required fields:

- `failure_class`: one of the canonical values below.
- `retry_policy`: one of `none`, `exponential`, `manual`, `permanent`.
- `recovery_hint`: one operator-readable next step.
- `raw_failure`: the original string, preserved for compatibility.
- `reason_code`: a stable subclass suitable for dashboards.
- `matched_alias`: the alias rule that classified the raw failure.

## Retry Policies

| retry_policy | deterministic meaning |
|---|---|
| `none` | Retrying cannot make progress because an explicit gate is unmet or the state is intentionally blocked. |
| `exponential` | A bounded wait-and-retry may succeed without code or operator changes. |
| `manual` | An operator or worker must change substrate state, callback fields, artifacts, or command shape before retry. |
| `permanent` | Treat as a correctness defect until code, tests, or schema are fixed; do not classify as a flake. |

## Canonical Classes

| failure_class | retry_policy | recovery_hint | common raw aliases |
|---|---|---|---|
| `transient` | `exponential` | Rerun the bounded probe once; if it repeats, promote to persistent with the timeout source attached. | `runtime_unresponsive`, `test_timeout`, `doctor_timeout`, `timeout` |
| `persistent` | `manual` | Repair the persistent substrate condition, then rerun the validator from the same receipt. | `database_locked`, `schema_mismatch`, `io_error`, repeated transient failures |
| `correctness` | `permanent` | Fix the implementation, dependency graph, or failing assertion before retry; do not silence or ignore. | `test_failed`, `assertion_failed`, `l112_verify_failed`, `dependency_inversion`, `cycle_detected` |
| `missing_artifact` | `manual` | Restore or regenerate the referenced evidence artifact, then rerun validation with the same evidence path. | `artifact_missing`, `missing_artifact`, `evidence_missing`, `closed_bead_artifact_missing_count` |
| `invalid_callback` | `manual` | Resend a callback with the required numeric fields, evidence, and durable no-bead/bead routing receipt. | `invalid_callback`, `callback_malformed`, `missing_did_didnt_gaps`, `orch_callback_missing_l61_fields`, `remediation_missing` |
| `context_drift` | `manual` | Reprobe from both orchestrator and agent contexts; do not summarize until the contexts agree or the drift is named. | `context_drift`, `agent_context_probe_drift_count` |
| `gate_unmet_open_children` | `none` | Close or explicitly preserve the named child blocker before retrying parent close. | `BLOCK_CLOSE_open_children_preserved`, `BLOCK_CLOSE_open_child_wbnb`, `open_child_blocks_close`, `open_child_*` |
| `tmp_dir_not_released` | `manual` | `rm -rf $TMPDIR/<bead-id>.* && re-run br close`. | `tmp_dir_not_released`, `BLOCK_CLOSE_tmp_dir_not_released`, `tmp_dir_released=false`, `tmp_dir_released=missing` |
| `dcg_blocked_destructive_command` | `manual` | Read the DCG reason and use a non-destructive alternate command; do not retry the same blocked command. | `dcg_block_handled=redirect_truncate_varfolders`, `dcg_blocked`, `redirect_truncate_*` |
| `file_reservation_conflict` | `manual` | Coordinate with the active reservation holder, wait for lease expiry, or release the stale reservation before writing. | `file_reservation_conflict`, `shared_append_reservation_conflict`, `append_reservation_conflict`, `bead_close_blocked_by=.beads_reservation_conflict_*` |
| `unknown` | `manual` | Preserve the raw failure string, add a taxonomy alias or new migration-tested class, then rerun classification. | any unmatched failure shape |

These eleven classes cover the Jeff-derived minimum set: transient, persistent,
correctness, missing artifact, invalid callback, context drift, and unknown.
The four flywheel-specific classes capture the recurring dispatch surfaces
mined for this bead: open-child close blocks, tmp lifecycle close blocks, DCG
destructive-command handling, and Agent Mail/file-reservation conflicts.

## Mined Failure Shapes

Observed sources included `.flywheel/receipts/`, `.flywheel/dispatch-log.jsonl`,
`.flywheel/callback-validation-log.jsonl`, `INCIDENTS.md`, `AGENTS.md`, `tests/`,
and `.flywheel/validation-schema/v1/`.

Representative raw shapes:

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

## Jeff Pattern Import

Jeff's upstream Beads Rust surface already treats errors as structured routing
data: `ErrorCode` has stable names, retryability, and category exit codes in
`/Users/josh/Developer/beads_rust/src/error/structured.rs`. NTM also exposes
machine-readable `error_code` plus operator hints in its overlay/feed surfaces.
This contract mirrors that shape locally while preserving flywheel-specific raw
strings as compatibility aliases.

## Joshua Lens

PASS. This is not bare mission fit. The operator-experience pattern is that
ad-hoc failure strings are tomorrow's grep fragility. A 25-year operations
manager does not let every callback invent a new failure language; every error
class becomes a runbook entry, and this taxonomy is the runbook table of
contents. It also creates turnover resilience: the next operator can route
`BLOCK_CLOSE_open_child_wbnb`, `redirect_truncate_varfolders`, or a reservation
conflict without knowing the pane history.

## Adoption Rule

Validators may keep legacy raw fields during migration, but every JSON failure
surface should add the `failure-taxonomy-envelope/v1` fields above. New aliases
are compatible changes. New `failure_class` values require a doc update, helper
mapping, and fixture proving correctness failures and invalid callbacks are not
classified as transient flakes.
