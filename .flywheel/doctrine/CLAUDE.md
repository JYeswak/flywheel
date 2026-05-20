# .flywheel/doctrine

Doctrine is the durable operating memory for flywheel. Treat it as a measured substrate, not a scratchpad.

## Conventions

- Amend existing doctrine when the new evidence refines the same rule; author a new file only for a distinct pattern, rule, or incident class.
- Preserve append-only history for incident, learning, and rule ledgers unless a generator explicitly owns the file and has a round-trip check.
- New claims need evidence: script path, test command, audit row, receipt, bead, or source URL.
- Meta-pattern docs should identify the executable surface expected to enforce the pattern when one exists.
- Avoid broad prose-only guidance when a validator, fixture, or audit row can carry the rule.
