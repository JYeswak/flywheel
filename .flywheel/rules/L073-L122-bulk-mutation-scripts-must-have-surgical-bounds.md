## L122 — BULK-MUTATION-SCRIPTS-MUST-HAVE-SURGICAL-BOUNDS

---
id: L122
title: Bulk mutation scripts must have surgical bounds
status: long_term
shipped: 2026-05-06
review_due: 2026-11-06
trauma_class: scope-creep-on-frontmatter-sweep
---

Any script that performs bulk mutation across a shared skill library,
cross-repo file set, or fleet-shared operating substrate MUST enforce an
in-memory pre/post diff, a per-file diff cap, and a session-level circuit
breaker before its first production run.

**How to apply:**
- Use `~/.claude/skills/.flywheel/scripts/bulk-mutation-surgical-bound.sh` or
  an equivalent guard for every candidate file write.
- The guard reads pre/post content in memory, refuses oversized diffs per file,
  records `aborted-surgical-bound` rows, and opens the circuit after
  `max_consecutive_aborts`.
- Live mutation requires an explicit apply mode; dry-run receipts must show
  `migrated`, `skipped`, `aborted`, and circuit-breaker counts matching intent
  before commit.
- `flywheel doctor` exposes `bulk_mutation_surgical_bound_missing_count` as a
  warn-first invariant for existing script debt.

**Forbidden outputs:**
- Running a broad sweep over shared skills, commands, hooks, scripts, or repo
  files without a dry-run receipt and per-file abort gate.
- Writing a candidate file before diffing the complete pre/post content.
- Continuing mutation after consecutive surgical-bound aborts trip the breaker.

**Evidence:** proposal
`~/.claude/skills/.flywheel/proposals/L-scope-creep-on-frontmatter-sweep-2026-05-06.md`;
skillos artifact `state/skillos-L-promotion-authoring-2026-05-06.md`; canonical
guard `~/.claude/skills/.flywheel/scripts/bulk-mutation-surgical-bound.sh`;
test `~/.claude/skills/.flywheel/tests/test_bulk_mutation_surgical_bound.sh`.

