# Jeff Evidence

This request comes directly from Jeff corpus synthesis, not from a new local invention.

## Skill Matrix Row

`/Users/josh/Developer/flywheel/.flywheel/jeff-corpus/v1/learnings/06-skill-enhancement-matrix.md` contains the `ipc-transport-contract` row:

| Proposed Skill | Pattern Coverage | Need | Suggested Content |
|---|---|---|---|
| `ipc-transport-contract` | `ipc-and-transport-contracts + callback-envelope-shape` | Transport guidance is spread over NTM, Agent Mail, MCP, and CLI skills; a sibling skill should define machine envelopes and delivery verification. | JSON envelope schema; transport health; delivery verification; resend/idempotency; durable audit rows. |

## Doctrine Clusters

`01-doctrine-cluster.md` defines `ipc-and-transport-contracts` as a repeated design posture: process boundaries need explicit contracts, JSON/robot modes, command schemas, queue/socket boundaries, and transport health checks. The flywheel adaptation calls out pane/agent orchestration and the need to codify callback/transport envelopes before adding more paths.

The same file defines `callback-and-receipt-envelope`: callbacks and receipts need expected fields, evidence artifacts, and validation. The flywheel adaptation calls out worker callbacks and closeout receipts as the local surface.

## Code Patterns

`02-code-patterns.md` lists `callback-envelope-shape` as a DIVERGE pattern. Jeff's strict callback envelopes are useful, but flywheel must preserve existing DONE/BLOCKED fields. The adaptation is to back the existing callback shape with reusable envelope validation helpers instead of replacing it.

## Flywheel Precedent

Socraticode returned the `fire-and-forget-dispatch` incident: send success is not enough. A real dispatch needs monitored liveness windows, callback timers, and post-send probes. It also surfaced the local `verify-callback-delivery.sh` callback-delivery gate.

That precedent is why this skill draft distinguishes `sent`, `visible`, `acknowledged`, `completed`, and `audited` instead of using one success boolean.
