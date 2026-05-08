# Jeff Evidence for failure-taxonomy-receipts

## Matrix Candidate

`.flywheel/jeff-corpus/v1/learnings/06-skill-enhancement-matrix.md:39-45`
names `failure-taxonomy-receipts` as a new sibling skill candidate:

- Patterns: `error-handling-and-recovery` and `callback-and-receipt-envelope`.
- Gap: no live sibling skill owns deterministic failure classes, retry policy,
  recovery hints, and DONE/BLOCKED receipt fields together.
- Outline: failure class registry, retry policy matrix, callback receipt fields,
  no-bead/fuckup routing, validator fixtures.

## Doctrine Clusters

`.flywheel/jeff-corpus/v1/learnings/01-doctrine-cluster.md:98-114` describes
the error-handling-and-recovery cluster: errors are classified, routed, and made
recoverable with clear commands instead of hidden behind generic status.

`.flywheel/jeff-corpus/v1/learnings/01-doctrine-cluster.md:134-150` describes
callback-and-receipt-envelope: worker or agent completion is structured
evidence with callbacks, receipts, status fields, and artifacts that validators
can check.

## Code Pattern Findings

`.flywheel/jeff-corpus/v1/learnings/02-code-patterns.md:133-152` says flywheel
should diverge from generic Jeff success envelopes only where flywheel needs
DONE/BLOCKED fields, while keeping common envelope tests.

The same file's cross-pattern note says callbacks are transient envelopes,
audit logs are durable receipts, and frontmatter is metadata schema. This draft
keeps that distinction by making failure receipts validator evidence rather
than replacing the worker callback contract.

