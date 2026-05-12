# Flywheel Adaptation

## Local Transports

Flywheel uses several IPC surfaces:

- NTM pane dispatch and callback delivery.
- Agent Mail messages and acknowledgements.
- MCP tool calls and their JSON results.
- CLI wrappers around local substrate.
- JSONL logs and bead close reasons as durable receipts.

The skill treats each surface as a transport with a schema and evidence ladder.

## Preserve Existing Callback Contracts

The local worker callback contract already carries operational meaning. Keep these fields:

- DONE/BLOCKED status.
- DID/DIDNT/GAPS accounting.
- `mission_fitness`.
- `josh_request_id`.
- `br_close_executed`.
- validation evidence path.
- callback delivery verification result.

The IPC transport contract should validate and wrap these fields, not replace them.

## NTM Dispatches

For NTM dispatches, the delivery proof ladder maps cleanly:

| Stage | Flywheel Probe |
|---|---|
| `sent` | `ntm send` result. |
| `visible` | `ntm copy` or `ntm grep` sees the task id on the target pane. |
| `acknowledged` | worker preamble, reservation receipt, or explicit ACK. |
| `completed` | DONE/BLOCKED callback. |
| `audited` | dispatch log, evidence file, bead close reason. |

`verify-callback-delivery.sh` remains the local callback gate.

## Agent Mail

Agent Mail already has message IDs, acknowledgement calls, archive files, and file reservations. This skill's role is to normalize those receipts with the same correlation/idempotency vocabulary used by other transports.

## MCP And CLI

MCP surfaces should return JSON envelopes with schema versions and deterministic failure classes. CLI wrappers should follow canonical-cli-scoping: `--json`, schema output, exit codes, `doctor`, `health`, `repair`, `validate`, `audit`, and `why` when state is involved.

## Publication Path

This directory is a flywheel-local skillos request. Do not mutate `~/.claude/skills` from worker dispatches. If Joshua approves, skillos should run validation, update the skill body, and stage publication through JSM with review.
