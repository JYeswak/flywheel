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

**Companion memories:**
- `feedback_workers_read_not_mint_identity.md` — Joshua's 2026-05-04 callout
  (*"workers grab new agentmail identities every time they register. they need
  to have locked identities that survive reboot"*) — the genesis incident this
  rule was distilled from. Names the trauma class
  `agent-mail-identity-sprawl-recurring`, the canonical resolver path
  `~/.local/state/flywheel/agent-mail/sessions/<session>:<pane>.json`, and the
  fail-closed-without-registry-row contract this rule mechanizes.
- `feedback_identity_stability_session_pane_project_primary_key.md` — sibling
  discipline naming `(session, pane, project)` as the primary key for identity
  stability across rotation/respawn.
- `feedback_agent_mail_token_echo.md` — paired discipline (do not echo
  registration tokens in pane text after registry resolve).
- `reference_lavenderglen_fleet_mail.md` — example registry identity for
  flywheel-p1's cross-orch role.

