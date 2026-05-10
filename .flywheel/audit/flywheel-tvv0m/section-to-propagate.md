## agent-mail-reservation-token-path-gap

Date: 2026-05-08

Promotion Action: NEW

Class: `agent-mail-reservation-token-path-gap`

Event Count: 9 events in 7 days

Severity: medium

Cost: ALPS worker dispatches repeatedly skipped or failed L51 file
reservations because their Agent Mail identity registry exposed a safe
`token_path`, while the MCP reservation call expected an inline
`registration_token`. The result was a bad choice between violating the
no-raw-token transcript rule or proceeding without the reservation layer that
prevents concurrent file edits.

Root Cause: Two valid rules collided without a bridging primitive: L51 requires
file reservations before edits, while L58 and the Agent Mail identity registry
push workers toward token-path-only identity handling. Agent Mail reservation
tools did not accept the resolver token-path pattern, and dispatches responded
by skipping reservation instead of routing the incompatibility to a durable
tool-patch owner.

Forever-Rule: Agent Mail file reservation helpers must accept a token-path or
resolver-backed identity handle, never require workers to paste raw
registration tokens into pane-visible calls. If a reservation tool cannot
consume token-path identity, the worker must record
`agent-mail-reservation-token-path-gap`, keep edits isolated, and route a
tool-patch bead; it must not downgrade L51 to optional or echo raw token
material to satisfy the reservation call.

Fix Applied/Status: NEW layer-2 INCIDENTS entry from `/flywheel:learn
--promote agent-mail-reservation-token-path-gap`. This entry makes the
token-path-vs-inline-token reservation gap explicit and separates it from the
neighboring token-transcript exposure class: the safe target is a resolver-aware
reservation primitive, not raw-token callbacks.

Evidence:
- `~/.local/state/flywheel/fuckup-log.jsonl#L593`: reservation failed because
  `file_reservation_paths` required inline `registration_token` and did not
  accept token-path identity.
- `~/.local/state/flywheel/fuckup-log.jsonl#L600-L611`: follow-on ALPS
  dispatches hit the same L51 token-path identity boundary.
- `~/.local/state/flywheel/fuckup-log.jsonl#L614-L647`: later ALPS dispatches
  skipped Agent Mail reservation because the token-path policy still conflicted
  with inline-token tool requirements.
- Doctrine: `AGENTS.md` L51 `DISPATCH-FILE-RESERVATIONS-MANDATORY` and L58
  `SECRET-MATERIAL-NEVER-IN-PANE-TEXT`.
- Skill: `~/.claude/skills/agent-mail/SKILL.md`.
- Existing related bead: `flywheel-1d3` fleet-mail identity token vault.
- Bead: `flywheel-amzsf`.

