## L84 — LOCKED-WORKER-IDENTITIES-CANONICAL

---
id: L84
title: Locked worker identities canonical
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: agent-mail-identity-sprawl-recurring
---

Worker panes MUST keep a durable Agent Mail identity bound to
`(session,pane,role)` across compaction, restart, and Mac reboot. Dispatches
must cite the registry identity; workers must echo that identity in callbacks.

**How to apply:**
- Preallocate rows with
  `.flywheel/scripts/agent-mail-pre-allocate-worker-identities.sh --apply --json`
  from latest `~/.local/state/flywheel/session-topology.jsonl`.
- Registry rows live at
  `~/.local/state/flywheel/agent-mail/sessions/<session>:<pane>.json` and use
  schema `agent-mail-identity-registry/v2` with role
  `orch|worker|callback|archived`.
- `flywheel-loop identity --session <session> --pane <pane> --json` is the
  resolver. If a topology-declared worker pane is missing, the resolver creates
  a deterministic `needs_registration` row instead of requiring ad-hoc
  registration.
- `flywheel-loop doctor --json` MUST expose
  `worker_identity_registered_count` and
  `agentmail_orphan_session_rows_count`.
- Dispatch packets and worker callbacks MUST include
  `identity_name=<registry-identity-name>`.
- Topology shrink archives stale rows instead of minting replacements; archived
  rows preserve provenance.
- A LaunchAgent or equivalent boot-time runner MUST refresh preallocation after
  Mac reboot.

**Forbidden outputs:**
- Registering a fresh worker Agent Mail identity because the pane lost context.
- Dispatching work to a topology-declared worker pane with no registry row.
- Reporting callback completion without `identity_name=<registry-identity-name>`.
- Treating a tokenless worker row as missing identity; it is an explicit
  `needs_registration` identity until Joshua approves a mailbox token.

**Evidence:** bead `flywheel-et7t`; script
`.flywheel/scripts/agent-mail-pre-allocate-worker-identities.sh`; tests
`tests/locked-worker-identities.sh`; schema
`.flywheel/validation-schema/v1/agent-mail-identity-registry.schema.json`.

**Companion rules:** L51 (Agent Mail reservations), L58 (secret material never in pane
text), L65 (identity proof beats command name), L76 (AgentMail identity
canonical), L80 (DID/DIDNT/GAPS callbacks), and the Agent Mail skill.

