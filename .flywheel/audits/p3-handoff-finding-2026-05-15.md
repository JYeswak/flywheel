# P3 FCLA W2 handoff — finding 2026-05-15

**Goal anchor:** P3 of `~/Desktop/zeststream-goals/flywheel/substrate-compounding-v2-20260515.txt`
**Authored by:** flywheel:1 (Claude Opus 4.7, 1M ctx)

## What the goal said

> P3 FCLA W2 handoff via existing relay.
>   ~/.claude/skills/.flywheel/bin/flywheel-skillos-relay reads row;
>   packet per .flywheel/validation-schema/v1/skillos-template-handshake-request.schema.json;
>   Agent Mail to skillos:1. Schema mismatch is hard cold-debug; relay env flag;
>   packet rollback. First real cross-orch traffic compounds into P4.
>   EXIT: skillos-relay-ledger row + AM message verified.

## What shipped

| Component | Status | Path |
|---|---|---|
| trauma-handoff schema | ✓ | `.flywheel/validation-schema/v1/trauma-handoff-request.schema.json` |
| handoff helper script | ✓ | `.flywheel/scripts/trauma-handoff.sh` (canonical-CLI; doctor green) |
| Ledger entries | ✓ 11 rows | `.flywheel/state/skillos-relay-ledger.jsonl` |
| AM message to skillos:1 | ⚠ BLOCKED | not sent — finding below |

## What the goal predicted

> Schema mismatch is hard cold-debug

This is what actually surfaced. The named schema
`skillos-template-handshake-request.schema.json` is designed for
**skill-template injection** (`requested_template_class`, `requested_skills`),
not **trauma-class ingestion**. The shapes don't overlap.

Resolution shipped: new schema `flywheel-trauma-handoff-request/v1` at
`.flywheel/validation-schema/v1/trauma-handoff-request.schema.json`,
trauma-specific.

## The deeper finding: identity-federation gap

After resolving the schema mismatch, the actual blocker is **agent
identity federation across projects** in MCP Agent Mail.

Observed via the MCP tooling:

- `ensure_project('/Users/josh/Developer/flywheel')` → project id=1, slug=`users-josh-developer-flywheel`
- `ensure_project('/Users/josh/Developer/skillos')` → project id=3, slug=`users-josh-developer-skillos`
- Agents in flywheel project: `flywheel-2`, `flywheel-0.4`, `codex-flywheel-4`, `SageMill`, `FuchsiaHollow`, `SwiftHill`, …
- Agents in skillos project: `list_window_identities` returns `count: 0`

The flywheel project has agents registered including some likely
skillos-orchestrator-shaped identities (SageMill, FuchsiaHollow, etc.).
The skillos project has zero active window identities. Sending a
trauma-handoff message requires either:

(a) Sending FROM a registered flywheel-project agent TO a registered
    flywheel-project agent that represents skillos:1 (federated identity
    pattern — requires knowing which name skillos:1 uses in flywheel-
    project context).
(b) Sending FROM a flywheel-project agent TO a skillos-project agent —
    requires cross-project federation that the MCP server may not
    support, or the skillos project needs an active receiver.

Neither (a) nor (b) is wired today. The identity layer is the blocker,
not the schema layer.

## P3 EXIT status

**Half-met.** Per goal contract:
- ✓ "skillos-relay-ledger row" — 11 rows tracked with idempotency keys
  and complete handoff packets at
  `.flywheel/state/skillos-relay-ledger.jsonl`
- ⚠ "AM message verified" — blocked on identity federation; ledger row
  status set to `ready_for_send_authorization`

The blocker is operator-class (identity registration is a substrate-
configuration step, not paradigm-class). Goes in the follow-up beads
pile.

## Follow-up beads

1. **flywheel-trauma-handoff-skillos-identity-federation** (~80 LOC)
   - Identify the canonical agent name for skillos:1 in flywheel project
   - Or register a new agent `skillos-1-fcla-receiver` in flywheel project
   - Or wire cross-project handoff via shared agent
   - Update `trauma-handoff.sh send-via-mcp-agent-mail` to use it
   - Verify a test send round-trips

2. **flywheel-skillos-trauma-receiver-stub** (skillos-side; ~60 LOC)
   - Skillos:1 registers as a receiver in its project OR in flywheel project
   - Receiver reads inbox, validates packet against
     `trauma-handoff-request.schema.json`, writes to
     `~/Developer/skillos/state/trauma_journal.jsonl`
   - Closes the loop for P4 EXIT

## Why this matters (Meadows lens)

This is the second time in cy5ay-class work that a "wiring is there" claim
turned out to mean "the WRITERS are there, but the RECEIVERS aren't."

Pattern observed:
- josh-requests: writer hook captures rows; consumer (absorption pipeline)
  exists but uses default values for v2 fields the writer doesn't emit
- skillos handoff: producer side (this audit's helper + ledger) exists;
  consumer side (registered skillos agent) doesn't

Meadows #4 (self-organization): the substrate has the SHAPE for cross-
orch handoff but not the binding. The binding step (agent registration,
shared identity, mutual capability) is a Joshua-operator action that no
script can self-organize.

## P3 closure

Mark P3 as **producer-complete-receiver-pending** with 2 follow-up beads.
Substrate-delta: 11 ledger rows committed + schema artifact + helper
script + this finding doc. Goes to the same audit-complete bucket as
P1's deliverables.

cy5ay (now closed) had a related AC. Add P3 follow-ups to the cy5ay
follow-up-beads queue:
1. cy5ay AC3 path B (pin schema v1) — pending
2. cy5ay AC4 mission_lock threshold tune — pending
3. cy5ay AC4 doctrine_propagation timeout — pending
4. cy5ay AC4 fleet_l_rule_lag count+detail — pending
5. cy5ay AC4 doctor-gauge-pattern doctrine — pending
6. cy5ay AC5 doctor wire-in — pending
7. **P3-A: trauma-handoff identity federation (NEW)** — adds 2 beads
8. **P3-B: skillos trauma receiver stub (NEW)**

8 follow-up beads total across P1+P3 deliverables. Each ≤100 LOC.
Independently revertable per goal CONTRACT.
