## agent-mail-identity-needs-registration

Date: 2026-05-08

Promotion Action: NEW

Class: `agent-mail-identity-needs-registration`

Event Count: 7 events in 7 days

Severity: medium

Cost: Agent Mail identity rows reached `needs_registration` without a
same-loop drain to token-safe registration broadcast or deferral. Dispatch and
callback code then had to choose between operating with incomplete
file-reservation/contact identity or attempting ad-hoc registration in
pane-visible context.

Root Cause: The identity registry can represent `needs_registration`, and
`agentmail-registration-broadcast.sh` can drain live rows safely, but this
trauma class lacked a layer-2 incident rule forcing handlers to classify each
row as live-broadcastable, deferrable, or already active before dispatch/Agent
Mail operations.

Forever-Rule: A `needs_registration` identity row is not a worker prompt to
paste registration material. Resolve identity by
`(session,pane,fleet_mail_project_key)`, run or cite
`agentmail-registration-broadcast.sh --doctor --json`, honor active
`identity-registration-deferral/v1` receipts for dead sessions, and only
continue once the row is `active`, broadcasted, or explicitly deferred. Never
mint from memory or send raw registration tokens through NTM, callbacks, or
reports.

Fix Applied/Status: NEW layer-2 INCIDENTS entry from `/flywheel:learn
--promote agent-mail-identity-needs-registration`. The entry gives
`flywheel-77qds` L56 coverage and points future scans at L76/L58, the identity
registry, and the token-safe registration broadcaster.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L574`: needs-registration row
  evidence; body intentionally not quoted.
- `~/.local/state/flywheel/fuckup-log.jsonl#L588-L615`: later six-row cluster;
  bodies intentionally not quoted.
- `AGENTS.md` L76: `AGENTMAIL-IDENTITY-CANONICAL`.
- `AGENTS.md` L58: `SECRET-MATERIAL-NEVER-IN-PANE-TEXT`.
- Broadcaster: `.flywheel/scripts/agentmail-registration-broadcast.sh`.
- Fixture coverage: `tests/agentmail-registration-broadcast.sh`.
- Identity registry tests: `tests/agent-mail-identity-registry.sh`.
- Bead: `flywheel-77qds`.

