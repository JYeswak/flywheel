## L76 — AGENTMAIL-IDENTITY-CANONICAL

---
id: L76
title: AgentMail identity canonical
status: long_term
shipped: 2026-05-04
review_due: 2026-11-04
trauma_class: agentmail-identity-sprawl
---

Every orchestrator and worker MUST resolve its Agent Mail identity from the
durable session:pane registry before using Agent Mail. Ad-hoc
`register_agent` calls are forbidden except inside the resolver-mediated
registration path.

**How to apply:**
- Resolve identity with
  `flywheel-loop identity --session <session> --pane <pane> --json`.
- Canonical registry rows live at
  `~/.local/state/flywheel/agent-mail/sessions/<session>:<pane>.json`.
- Canonical token files live at
  `~/.local/state/flywheel/agent-mail/tokens/<identity>.token` with mode 600.
- First-time registration returns `status=needs_registration` and must be
  handled as an explicit Joshua-disposes decision, not by silently minting a new
  mailbox identity.
- Rotations preserve `predecessor_identity` and `rotation_reason`.
- Cross-orch handshakes carry `identity_resolved=<identity_name>` and never raw
  bearer tokens; token proof stays local as `token_path` and `token_sha256`.
- `flywheel-loop doctor --json` MUST expose `.identity_registry`,
  `identity_registry_drift`, and `identity_token_orphan`.
- `.flywheel/scripts/agentmail-registration-broadcast.sh` MUST broadcast only
  token-safe registration requests to live `needs_registration` orchestrator
  panes, honor active deferral receipts for dead sessions, and expose
  `agentmail_pending_registration_broadcasts_count`.

**Forbidden outputs:**
- Calling Agent Mail `register_agent` directly because a pane lost token context.
- Storing registration tokens only in pane environment variables or scrollback.
- Creating a new identity after compaction/reboot without a registry row linking
  it to its predecessor.
- Sending raw Agent Mail registration tokens through NTM, cross-orch packets,
  callbacks, or daily reports.

**Evidence:** bead `flywheel-g9mi`; memory
`feedback_agentmail_identity_canonical.md`; schema
`.flywheel/validation-schema/v1/agent-mail-identity-registry.schema.json`;
tests `tests/agent-mail-identity-registry.sh`.

**Companion rules:** L58 (secret material never in pane text), L60 (doctor signal
contract), L65 (identity proof beats command name), L70 (chain repair), L71
(validate/redispatch), L73 (runtime leak sibling), and the Agent Mail skill.


