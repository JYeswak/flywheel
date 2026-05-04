# DISPATCH from RubyCreek on flywheel:0.1
# Pane: flywheel:0.2
# Worker: ClaudeWorker
# Task ID: fixture-claude

## CALLBACK CONTRACT

When complete, send exactly one DONE or BLOCKED callback.

## VALIDATION BLOCK

Use `/Users/josh/Developer/flywheel/.flywheel/validation-schema/v1/schema.json`
and `/Users/josh/Developer/flywheel/.flywheel/validation-schema/v1/parse.sh`.
The orchestrator runs `validate-callback` before summary or integration.

Run proof from the agent execution context and record `status=unknown` as
non-pass when the runtime is unresponsive.

The callback must include:

```text
evidence=<paths-or-command-refs>
four_lens=brand:N,sniff:N,jeff:N,public:N
artifact_checks=<artifact-id:path:exists|missing|unknown,...>
validation_notes=<short validation summary>
files_released=<comma-list|NONE_READONLY|NONE_NO_EDITS>
beads_filed=<ids>|beads_updated=<ids>|no_bead_reason=<specific reason>
fuckups_logged=<classes|none>
next_phase=<id|none>
chain_if_capacity=<done|not_applicable>
chain_blocked_reason=<reason|none>
```

Use Agent Mail reservation before edits and release reservations before DONE.
L52 requires beads_filed, beads_updated, or no_bead_reason. L53 requires
fuckups_logged for trauma or BLOCKED callbacks.

Report evidence must include `## Four-Lens Self-Grade` with Brand, Sniff, Jeff,
and Public scores. Public must answer the Three Judges fork-and-star check.

## TASK BODY

Run `/flywheel:worker-tick /tmp/dispatch_fixture-claude.md`.
