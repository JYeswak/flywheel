# Identity Deferral Doctrine

owner_bead: flywheel-ulha
l_rule: L138
schema_version: identity-deferral-doctrine/v1
status: canonical

## L138 — IDENTITY-DEFERRAL-AFTER-RESERVATION-CLEAR

---
id: L138
title: Identity deferral after reservation clear
status: long_term
shipped: 2026-05-08
review_due: 2026-11-08
trauma_class: identity-deferral-reservation-drift
---

Identity decisions are state reads, not dispatch-time memory. When a worker
observes an active Agent Mail file reservation on `AGENTS.md`,
`.flywheel/AGENTS-CANONICAL.md`, `.flywheel/AGENTS.md`, or `.beads/issues.jsonl`
while identity doctrine or Beads ownership is relevant, it MUST defer identity
decisions until the reservation clears. After the reservation clears, the worker
MUST re-read the current doctrine and registry state before acting.

**When this triggers:**
- A file reservation conflict touches `AGENTS.md`, `.flywheel/AGENTS-CANONICAL.md`,
  `.flywheel/AGENTS.md`, or `.beads/issues.jsonl`.
- A worker is about to call `register_agent`, `create_agent_identity`,
  `macro_start_session`, `rename_window`, or any identity preallocation/rotation
  helper based on remembered doctrine.
- A callback, handoff, or cross-orch packet needs `identity_name`,
  `identity_primary_key`, or Agent Mail ownership fields while the doctrine
  surface is reserved.

**Required behavior after the reservation clears:**
1. Re-read `AGENTS.md` and `.flywheel/AGENTS-CANONICAL.md` if present.
2. Re-read `~/.local/state/flywheel/agent-mail/sessions/<session>:<pane>.json`.
3. Resolve identity by `(session, pane, fleet_mail_project_key)`, not by the
   current mailbox name.
4. If an `identity-registration-deferral/v1` receipt applies, honor it instead
   of minting a new identity.
5. Only then send Agent Mail, mutate registry state, or report identity fields
   in callbacks.

**Forbidden outputs:**
- Minting or registering a fresh identity from memory after an AGENTS reservation
  conflict clears.
- Treating a cleared reservation as permission to continue with pre-conflict
  doctrine assumptions.
- Using `identity_name` as the primary key for attribution, callback routing, or
  registry updates.
- Reporting a reservation conflict as an unclassified string. The canonical
  failure class is `file_reservation_conflict` per
  `.flywheel/doctrine/failure-taxonomy.md`.

**Doctor and receipt surface:**
- The deferral receipt schema is
  `.flywheel/validation-schema/v1/identity-registration-deferral.schema.json`.
- Fixture coverage is `tests/identity-deferral-receipt.sh`.
- `flywheel-loop identity --doctor --json` reports `deferred_count`,
  `deferred_rows`, and `receipt_honored`; the status is `pass` only when active
  receipts cover all eligible drift rows.

**Why:** The last two days exposed at least six identity rotation triggers:
agent-mail name policy, resolver-MCP generated names, compaction continuity,
missing-token recovery, path canonicalization, and strict-mode preallocated-name
rejection. All six are harmless under the right primary key and damaging when a
worker mints from memory. File reservation conflicts are the same operator pain
class: an agent works from stale doctrine because another worker owns the
surface that defines the current rule.

**Joshua lens:** Identity is state, not an event. A 25-year operations manager
expects every shift change to leave a runbook for who owns what; minting
identity from memory is the rookie mistake the runbook prevents. This rule
creates turnover resilience because the next operator can wait for the
reservation to clear, re-read the source of truth, and recover the stable
session:pane:project owner without knowing which mailbox name rotated yesterday.

**Evidence:** bead `flywheel-ulha`; source bead `flywheel-dekp`; memory
`feedback_identity_stability_session_pane_project_primary_key.md`; memory
`feedback_workers_read_not_mint_identity.md`; schema
`.flywheel/validation-schema/v1/identity-registration-deferral.schema.json`;
fixture `tests/identity-deferral-receipt.sh`; failure taxonomy
`.flywheel/doctrine/failure-taxonomy.md` class `file_reservation_conflict`.

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet.
