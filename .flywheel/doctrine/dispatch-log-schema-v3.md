# Dispatch Log Schema v3

`dispatch-log.jsonl` schema v3 is an additive callback-row extension. v2 rows
continue to parse as legacy rows unless they opt into v3 with `schema_version: 3`
or carry one of the v3 fields below.

## v2 to v3 Diff

Schema v3 adds post-callback cleanup and tiered close-bar evidence:

- `post_callback_worktree_removed: bool|null`
- `post_callback_branch_local_deleted: bool|null`
- `post_callback_stash_dropped: bool|null`
- `post_callback_main_ff_status: ok|behind|diverged|unknown`
- `post_callback_auto_push_status: ok|blocked|swept|skipped`
- `close_class: substrate_class|runtime_class`
- `runtime_receipt_path: string|null`
- `runtime_artifacts: object`

The schema sidecar lives at
`.flywheel/validation-schema/v1/dispatch-log-entry-v3.schema.json`.

## Tiered Close Bar

This follows the CFS iOS-app mission pivot from 2026-05-20T04:00Z:
substrate-class beads close on code-path evidence, while runtime-class beads
require a concrete runtime receipt.

`substrate_class` close rows require code evidence: a reachable commit field
(`commit_sha` or `commit`) and `tests=PASS`.

`runtime_class` close rows require:

- `runtime_receipt_path` naming the receipt;
- `runtime_artifacts` populated with concrete runtime facts, such as TestFlight
  build number, device model, OS version, timestamp, API status, latency, or
  payload hash.

Runtime receipt evidence is what prevents false-idle-after-silent-artifact-write:
a worker cannot claim DONE for runtime work by only writing an artifact and
dropping the callback discipline.

## Validation

Use:

```bash
.flywheel/scripts/callback-envelope-validator.sh --row-json '<json>' --json
.flywheel/scripts/worker-tick-contract-postcallback-verify.sh --row-json '<json>' --json
```

The first script validates callback-row semantics. The second is a stricter
pre-callback gate for workers and orchestrators before they send DONE.
