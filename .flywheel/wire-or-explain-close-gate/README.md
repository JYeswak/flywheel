# Tick Close Permit Gate

The Tick Close Permit Gate reads the wire-or-explain ledger at tick close and returns a `TickCloseResult` decision. It is intentionally narrow: no ledger mutation, no bead mutation, and no doctor rewrites. In shadow mode it reports the rows that would block close; in enforce mode unresolved local rows produce a stable nonzero exit and a durable failed-tick receipt.

## Operator Surface

```bash
python3 .flywheel/scripts/wire-or-explain-close-gate.py --json --dry-run
python3 .flywheel/scripts/wire-or-explain-close-gate.py --mode enforce --json
python3 .flywheel/scripts/wire-or-explain-close-gate.py --mode enforce --override override.json --json
python3 .flywheel/scripts/wire-or-explain-close-gate.py --why --json
python3 .flywheel/scripts/wire-or-explain-close-gate.py --schema
```

Required result fields are `allowed`, `exit_code`, `reason_code`, `row_count`, `top_actions`, `override_state`, `receipt_path`, and `would_block`. Receipts default to `~/.local/state/flywheel/wire-or-explain/closeout-receipts/` unless `--receipt-dir` is supplied.

## Exit Codes

| Code | Meaning |
|---:|---|
| 0 | Close allowed, including shadow-mode would-block reports. |
| 1 | Enforce mode found unresolved local rows. |
| 2 | Usage or schema error. |
| 3 | Ledger parse or read failure. |
| 4 | Fleet-scoped unresolved row is owned by this orchestrator. |

## Close Policy

Local ownership is derived from `ship_repo`, `session_id`, and `owning_orch`. Cross-orchestrator rows remain visible in `top_actions` and warnings, but do not hard-fail the local close unless the row is fleet-scoped and ownership matches this orchestrator. Skill-candidate rows keep their `route_to_skillos` action so the tick has a concrete drain path instead of a prose exception.

## Modes And Overrides

Mode order is `bootstrap -> shadow -> enforce`. Shadow mode keeps close allowed and reports `would_block=true`; enforce mode returns the stable unresolved-row exit code. Bootstrap mode accepts a one-shot bootstrap override only when the override has `bootstrap=true` plus B8 dogfood self-test proof.

Structured overrides use `--override <json>` and must include `reason`, `owner`, `expires_at`, and `affected_rows`. Expired, incomplete, or already consumed bootstrap overrides are rejected and surfaced as unresolved `override:*` action rows. Active overrides write a separate scrubbed receipt under `~/.local/state/flywheel/wire-or-explain/override-receipts/` unless `--override-receipt-dir` is supplied.

`--why --json` returns a row-ID-keyed decision map so callbacks and closeout receipts can cite exact blocking rows instead of prose-only summaries.

Part of the Yuzu Method framework by ZestStream.
