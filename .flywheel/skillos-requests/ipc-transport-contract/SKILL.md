---
name: ipc-transport-contract
description: "Use when 'IPC transport', 'transport contract', 'JSON envelope', 'callback envelope', 'DONE callback', 'BLOCKED callback', 'delivery verification', 'transport health', 'send receipt', 'pane visibility', 'resend idempotency', 'durable audit row', or 'fire-and-forget dispatch'."
license: MIT
distribution: forbidden
version: 0.1.0
status: skillos-request
---

# IPC Transport Contract

> Skillos request: draft sibling skill for cross-process transport envelopes, callback receipts, and delivery verification. This package stays in flywheel until Joshua approves publication or routes it to skillos.

## Hard Rules

1. Define the envelope schema before adding a new transport surface.
2. Treat send success as only `sent`; completion requires visibility, acknowledgement, or callback proof.
3. Every envelope includes `schema_version`, `transport`, `message_id`, `correlation_id`, `sender`, `recipient`, `operation`, `payload_ref`, `status`, `evidence`, and `created_at`.
4. Do not place raw secrets, access tokens, prompt text with credentials, or full private payloads inside transport envelopes.
5. Persist a durable audit row for send, visibility probe, acknowledgement, callback, retry, duplicate suppression, and failure.
6. Resends require `correlation_id` plus an `idempotency_key`; never create a fresh logical job for a retry.
7. Transport health must report send availability, queue depth or pane visibility, stale callbacks, last successful delivery, and failure-class counts.
8. Flywheel callbacks preserve DONE/BLOCKED, DID/DIDNT/GAPS, `mission_fitness`, `josh_request_id`, and `br_close_executed`; the skill augments the callback envelope, it does not replace the worker contract.
9. A dispatch must carry `callback_expected_by` and a post-send probe plan before it can be called live.
10. Failure classes are deterministic: `transport_unavailable`, `pane_not_visible`, `ack_timeout`, `callback_missing`, `duplicate_message`, `schema_invalid`, and `redaction_violation`.
11. Cross-transport bridges must record both source and target envelope IDs so humans can trace handoff boundaries.
12. The executable self-test must verify structure, trigger saturation, envelope fields, anti-pattern coverage, and publication staging text.

## THE EXACT PROMPT

```
Create or review an IPC transport contract for <surface>.

Use the ipc-transport-contract skill. Produce:
1. A JSON envelope schema with schema_version, transport, message_id,
   correlation_id, sender, recipient, operation, payload_ref, status,
   evidence, created_at, callback_expected_by, and idempotency_key.
2. A delivery verification plan that distinguishes send, visibility, ack,
   callback, and durable audit row evidence.
3. A transport health shape with machine-readable status, stale callback
   detection, failure classes, and retry/idempotency behavior.
4. A resend policy that uses correlation_id + idempotency_key and suppresses
   duplicates.
5. A self-test or validator command for the surface.

Preserve any existing DONE/BLOCKED callback fields. Cite Jeff corpus evidence
and flywheel adaptation notes when authoring a reusable skill or doctrine rule.
```

## Decision Tree

```
What are you changing?
├─ New pane, queue, MCP, Agent Mail, socket, or subprocess handoff
│  └─ Start with JSON Envelope Schema, then Delivery Verification.
├─ Existing dispatch says "sent" but humans still poll manually
│  └─ Add callback_expected_by, visibility probe, and durable audit rows.
├─ Worker callbacks drift or omit required fields
│  └─ Validate callback envelope without deleting DONE/BLOCKED fields.
├─ Retrying work after timeout
│  └─ Reuse correlation_id, set idempotency_key, record retry_count.
├─ A bridge converts between transports
│  └─ Persist source_message_id and target_message_id.
└─ Unsure if transport is healthy
   └─ Add transport health command or probe with JSON output and exit codes.
```

## JSON Envelope Schema

Minimum transport envelope:

```json
{
  "schema_version": "ipc.transport.v1",
  "transport": "ntm|agent-mail|mcp|cli|socket|queue",
  "message_id": "msg_20260508_0001",
  "correlation_id": "task-or-bead-id",
  "idempotency_key": "transport:correlation:attempt-purpose",
  "sender": {"agent": "orchestrator", "surface": "flywheel:0.1"},
  "recipient": {"agent": "worker", "surface": "flywheel:0.2"},
  "operation": "dispatch|callback|ack|health|retry|cancel",
  "payload_ref": {"kind": "file", "uri": "/tmp/dispatch.md", "sha256": "..."},
  "status": "draft|sent|visible|acknowledged|done|blocked|failed|duplicate",
  "callback_expected_by": "2026-05-08T20:30:00Z",
  "evidence": [{"kind": "pane_probe", "ref": "ntm copy flywheel:2"}],
  "created_at": "2026-05-08T20:00:00Z"
}
```

Payloads live behind `payload_ref` when large, private, or mutable. The envelope carries references and proof, not full secret-bearing bodies.

## Delivery Verification

Use staged proof. Do not collapse the stages into one boolean.

| Stage | Meaning | Example Evidence |
|---|---|---|
| `sent` | Transport accepted a write request. | `ntm send` exit 0, Agent Mail message id, MCP result id. |
| `visible` | Recipient surface can actually see the work. | `ntm copy` contains task id, inbox fetch includes subject. |
| `acknowledged` | Recipient explicitly received it. | `acknowledge_message`, callback preamble, reservation receipt. |
| `completed` | Work closed with DONE/BLOCKED and evidence. | `verify-callback-delivery.sh`, bead close reason, evidence file. |
| `audited` | Durable row exists for future investigation. | JSONL dispatch log row or agent-mail archive id. |

Flywheel adaptation: `verify-callback-delivery.sh` is the callback-delivery gate for NTM dispatches. A dispatch that only has send evidence remains incomplete until the callback is visible on the orchestrator pane.

## Transport Health Shape

A health probe reports a JSON envelope and exits non-zero on degraded or critical transport state.

```json
{
  "schema_version": "ipc.transport_health.v1",
  "transport": "ntm",
  "status": "green|degraded|critical",
  "send_available": true,
  "visibility_available": true,
  "queue_depth": 0,
  "stale_callback_count": 0,
  "last_successful_delivery_at": "2026-05-08T20:00:00Z",
  "failure_counts": {
    "transport_unavailable": 0,
    "pane_not_visible": 0,
    "ack_timeout": 0,
    "callback_missing": 0,
    "duplicate_message": 0,
    "schema_invalid": 0,
    "redaction_violation": 0
  }
}
```

Canonical CLI scoping fit: transport wrappers should expose doctor/health/repair when they become operator-facing CLIs; the transport contract itself at least requires `--json`, schema discipline, deterministic exit codes, and durable audit rows.

## Resend And Idempotency

Retries use the original `correlation_id` and a stable `idempotency_key` derived from transport, logical task, recipient, and operation. A retry may increment `attempt`, but it must not create a second logical bead, callback timer, or deliverable. Duplicate callbacks are marked `duplicate` and linked to the first completed envelope.

## Durable Audit Rows

Minimum audit row:

```json
{
  "schema_version": "ipc.transport_audit.v1",
  "event": "sent|visible|acknowledged|completed|retry|failed|duplicate",
  "message_id": "msg_20260508_0001",
  "correlation_id": "flywheel-njzi-50c2e1",
  "transport": "ntm",
  "actor": "CloudyMill",
  "evidence_ref": "/tmp/flywheel-njzi-50c2e1-evidence.txt",
  "failure_class": null,
  "created_at": "2026-05-08T20:00:00Z"
}
```

Durable audit rows are for reconstruction. Callbacks are transient coordination messages; audit rows are the substrate that survives compaction and pane churn.

## Source Evidence

Jeff corpus maps this skill request directly:

- `06-skill-enhancement-matrix.md`: `ipc-transport-contract` row says transport guidance is spread across NTM, Agent Mail, MCP, and CLI skills and asks for JSON envelope schema, transport health, delivery verification, resend/idempotency, and durable audit rows.
- `01-doctrine-cluster.md`: `ipc-and-transport-contracts` defines process boundaries as contracts with JSON/robot modes, envelopes, command schemas, queues, sockets, and health checks.
- `01-doctrine-cluster.md`: `callback-and-receipt-envelope` requires callbacks, receipts, status fields, evidence artifacts, and validation.
- `02-code-patterns.md`: `callback-envelope-shape` says flywheel should keep DONE/BLOCKED fields and back them with reusable envelope validation helpers.
- Socraticode flywheel precedent: the `fire-and-forget-dispatch` incident says send success is not enough; monitored liveness windows, callback timers, and post-send probes are required.

## Flywheel Adaptation Notes

Flywheel has several transports: NTM pane sends, Agent Mail messages, MCP tool calls, shell/CLI wrappers, and JSONL audit logs. This skill treats all of them as IPC boundaries. The local adaptation is strict about preserving existing worker callback semantics while adding envelope discipline around them.

NTM dispatches should continue using `verify-callback-delivery.sh` and callback fields such as DID/DIDNT/GAPS, `mission_fitness`, `josh_request_id`, and `br_close_executed`. Agent Mail should continue using message IDs and acknowledgements. MCP tools should expose schema and error envelopes. CLI wrappers should follow canonical-cli-scoping for `--json`, health, doctor, repair, and exit-code behavior.

This draft is not published to `~/.claude/skills`. Skillos owns final review, naming, JSM handling, and any publication decision.

## Executable Self-Test

Run from the repo root:

```bash
.flywheel/skillos-requests/ipc-transport-contract/scripts/self_test.sh .flywheel/skillos-requests/ipc-transport-contract
```

The self-test checks:

- frontmatter and trigger phrase count;
- required sections and evidence references;
- envelope field coverage;
- delivery verification and transport health terminology;
- anti-pattern table shape;
- publication staging text.

## Publication Staging

If Joshua approves publication, stage through skillos/JSM rather than mutating the live skills directory from this dispatch:

```bash
SKILL_SRC=/Users/josh/Developer/flywheel/.flywheel/skillos-requests/ipc-transport-contract
bash /Users/josh/.claude/skills/skill-builder/scripts/validate-skill.sh "$SKILL_SRC"
jsm push "$SKILL_SRC" --review
```

If `jsm push` is not the correct local surface, skillos should translate this into the current JSM publication command and preserve this request as the provenance artifact.

## Anti-Patterns

| Anti-Pattern | Why It Fails | Fix |
|---|---|---|
| Fire-and-forget dispatch. | A successful send call proves only that bytes left one process. It does not prove the recipient surface rendered the task, that a worker accepted it, or that the callback returned. | Split delivery into sent, visible, acknowledged, completed, and audited stages, then require evidence for each stage that matters. |
| Generic success envelope. | `{"ok": true}` cannot tell an operator which task, transport, recipient, retry, or evidence path was involved. During incidents, every generic envelope becomes another manual archaeology problem. | Use `schema_version`, `message_id`, `correlation_id`, `idempotency_key`, transport, status, and evidence refs. |
| Raw payloads in transport logs. | Envelopes are durable and often copied into panes, JSONL, or archives. Putting full prompt bodies or secrets there leaks private substrate into every downstream audit path. | Store large or private content behind `payload_ref`; keep envelopes to identifiers, hashes, redacted summaries, and proof refs. |
| Resend without correlation. | A retry with a fresh identity creates duplicate callbacks, double work, and ambiguous bead closure. The operator cannot tell whether the second message superseded or duplicated the first. | Keep `correlation_id` stable, use `idempotency_key`, record retry attempts, and mark duplicates explicitly. |
| Replacing flywheel callbacks with a new abstraction. | Flywheel workers and orchestrators already depend on DONE/BLOCKED, DID/DIDNT/GAPS, `mission_fitness`, and bead close fields. Replacing them breaks existing gates. | Wrap and validate the existing callback fields; add schema and audit proof around them. |
| No durable audit row. | Pane scrollback and human memory vanish. Without durable rows, incidents recur because the next worker cannot inspect what actually happened. | Write append-only audit rows for send, visibility, ack, callback, retry, failure, and duplicate suppression. |
| Transport-specific prose. | A prose-only rule for one channel cannot be reused for MCP, Agent Mail, NTM, and CLI boundaries. Each surface drifts into a custom contract. | Define transport-neutral envelope fields and allow transport-specific evidence refs under the same schema. |
