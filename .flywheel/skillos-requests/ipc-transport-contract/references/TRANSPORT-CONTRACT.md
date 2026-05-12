# Transport Contract

## Envelope

Every IPC handoff has a machine envelope:

```json
{
  "schema_version": "ipc.transport.v1",
  "transport": "ntm|agent-mail|mcp|cli|socket|queue",
  "message_id": "unique transport event id",
  "correlation_id": "logical task id",
  "idempotency_key": "stable retry key",
  "sender": {"agent": "name", "surface": "where it came from"},
  "recipient": {"agent": "name", "surface": "where it should arrive"},
  "operation": "dispatch|callback|ack|health|retry|cancel",
  "payload_ref": {"kind": "file|mail|artifact|inline-redacted", "uri": "...", "sha256": "..."},
  "status": "draft|sent|visible|acknowledged|done|blocked|failed|duplicate",
  "callback_expected_by": "ISO-8601 timestamp",
  "evidence": [{"kind": "probe", "ref": "path or command output id"}],
  "created_at": "ISO-8601 timestamp"
}
```

The transport may add fields, but it should not remove these core fields. `payload_ref` is preferred over inline payloads so audit rows stay durable without becoming secret sinks.

## Delivery Proof

Delivery is a ladder:

1. `sent`: the transport accepted the send request.
2. `visible`: the recipient substrate shows the message or work item.
3. `acknowledged`: the recipient or worker explicitly accepted it.
4. `completed`: the expected callback or receipt arrived with evidence.
5. `audited`: a durable row records what happened.

Every stage should have evidence. Stages can be skipped only when the skipped proof is irrelevant to the risk of that transport. For worker dispatches, `sent` alone is insufficient.

## Health

Health output uses JSON and deterministic exit codes. The minimum health fields are:

- `schema_version`
- `transport`
- `status`
- `send_available`
- `visibility_available`
- `queue_depth`
- `stale_callback_count`
- `last_successful_delivery_at`
- `failure_counts`

When a transport grows into an operator-facing CLI, apply canonical-cli-scoping: `doctor`, `health`, `repair`, `validate`, `audit`, `why`, `--json`, schema output, and exit-code discipline.

## Failure Classes

Use stable classes so dashboards, repairs, and beads can group failures:

- `transport_unavailable`
- `pane_not_visible`
- `ack_timeout`
- `callback_missing`
- `duplicate_message`
- `schema_invalid`
- `redaction_violation`

Add a new failure class only when an operator can act differently on it.

## Resend And Idempotency

Retries keep the same `correlation_id`. The `idempotency_key` should be deterministic for the logical operation. Attempts can be counted separately, but the logical task remains one task.

Duplicate detection records the duplicate envelope and points to the first completed envelope. It does not silently discard evidence.

## Durable Audit

Audit rows are append-only and reconstructable. A row records event type, message id, correlation id, transport, actor, evidence ref, failure class, and timestamp. The audit stream is what survives after panes scroll, sessions compact, or tools restart.
