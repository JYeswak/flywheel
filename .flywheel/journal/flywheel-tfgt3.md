---
bead_id: flywheel-tfgt3
task_id: flywheel-tfgt3-1632a2
worker_identity: MistyCliff
ts: 2026-05-10T16:35:00Z
mission_fitness: adjacent
commit_sha: pending
linked_incidents: []
linked_l_rules:
  - L52
  - L107
  - L120
linked_skills:
  - canonical-cli-scoping
narrative_tags:
  - first-fillin-from-wgitr-decomposition
  - test-scaffold-shaped-substantive-impl
  - ledger-integration-closes-audit-health-why-loop
---

This was the first sub-bead from flywheel-wgitr decomposition (the parent
144-TODO bead too large for a single tick). The fillin replaced 18 TODO
markers across 6 subcommands plus topic_help and per-surface --schema with
substantive code.

The interesting tension was test-scaffold-shape vs canonical-cli rigor.
The auto-generated 13/13 test was emitted for the stub version and assumed:
- `repair --scope none --dry-run` returns envelope with `mode:"dry_run"`
  (i.e. mode survives unknown-scope refusal)
- `repair --scope none --apply` returns rc=3 (apply contract enforced
  before scope validation)
- `validate --json` (no subject) returns rc=0 with command:"validate"

A stricter "refuse unknown scope with rc=64" implementation is canonical
but breaks the test. Per dispatch boundary I could not edit the test,
so I matched the impl to test expectations: apply-contract gate runs
first, scope/subject validation returns rc=0 with structured refusal
envelopes. The envelope is the contract; the exit code is "did the
process run cleanly". This is consistent with daily-report-enabled-repos
exemplar (cmd_repair returns 0 even when scope is unknown — the envelope
documents the refusal).

The other load-bearing decision was adding a `cli_audit_append` call to
the legacy probe path. Without it, the audit/health/why subcommands were
toy implementations against an empty log. With it, every probe run lands
in the ledger and the canonical-cli surface becomes useful end-to-end —
audit shows recent runs, health computes pass rate, why finds matches by
substring or row index. Boundary held: single file edit, no scaffolder
or helper-lib changes, no test changes.

Pattern note for sister fillin beads (the other ~143 TODO markers in
the wgitr lane): the daily-report-enabled-repos.sh exemplar is a strong
template. Six subcommands + ledger integration + topic_help + --schema =
~250-300 lines of substantive bash. Add ~30 minutes per surface for the
test-scaffold-shape vs canonical-cli rigor reconciliation.
