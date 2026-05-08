# Flywheel Adaptation Notes

## Why This Belongs in Skillos

Failure taxonomy is cross-cutting: AGENTS doctrine, callback validation,
validation-fix beads, fuckup-log promotion, Beads close gates, and pane recovery
all need the same failure fields. A consumer session should not hard-code a new
live skill; it should hand a draft to skillos so the skill can become reusable
across repos and sessions.

## Existing Flywheel Anchors

- AGENTS.md L52: every finding becomes a bead/update or explicit
  `no_bead_reason`.
- AGENTS.md L53: BLOCKED and trauma-bearing DONE callbacks log fuckup rows.
- AGENTS.md L71: worker callbacks are claims until validation receipts prove
  them.
- AGENTS.md L80: callbacks must preserve DID/DIDNT/GAPS.
- AGENTS.md L118: stable failure reason codes before prose.
- Tests such as `tests/validation-fix-bead.sh`, `tests/validate-callback.sh`,
  and `tests/failure-class-emit.sh` already use `failure_class`,
  `retry_policy`, `recovery_hint`, and typed receipt fields.

## Adaptation Boundaries

- This draft must not mutate `~/.claude/skills/`.
- This draft must not publish via JSM.
- It is valid to cite publication commands for skillos/Joshua review.
- Flywheel callback fields stay authoritative. Failure taxonomy receipts are
  evidence artifacts consumed by validators and callbacks.

