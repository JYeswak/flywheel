# DISPATCH from RubyCreek on flywheel:0.1
# Pane: flywheel:0.3
# Worker: CodexWorker
# Task ID: fixture-codex

## CALLBACK CONTRACT

Codex worker panes execute this dispatch as worker-tick parity and send exactly
one DONE or BLOCKED callback.

## VALIDATION BLOCK

Validation receipt schema:
`/Users/josh/Developer/flywheel/.flywheel/validation-schema/v1/schema.json`
Parser:
`/Users/josh/Developer/flywheel/.flywheel/validation-schema/v1/parse.sh`

The orchestrator must run `validate-callback` before summary, closeout, or
learn routing. Runtime probes must come from the agent execution context; an
unresponsive runtime maps to `status=unknown`, not pass.

Callback fields:

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

Agent Mail reservation is required for edits; release the reservation before
callback. L52 governs bead/no-bead receipts. L53 governs fuckups_logged.

Report evidence must include `## Four-Lens Self-Grade` with Brand, Sniff, Jeff,
and Public scores. Public must answer the Three Judges fork-and-star check.

## TASK BODY

Read this dispatch file and execute it as `/flywheel:worker-tick` parity.
