---
bead_id: flywheel-zjm8v
task_id: flywheel-zjm8v-bd80de
worker_identity: MistyCliff
ts: 2026-05-10T16:50:00Z
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
  - third-fillin-mae86-vc3zs-tfgt3-pattern
  - test-surface-fillin-tests-its-real-downstream-binary
  - per-surface-test-assertions-add-8-extra-tests
---

Third fillin in the doctrine-lane decomposition (after mae86 / vc3zs / tfgt3
all shipped 920-1000/1000 in the same tick). Pattern is now well-established:
6 substantive subcommands + per-surface --schema + topic_help + ledger
integration + ~30 min wall clock per surface.

The interesting wrinkle this time was that the surface IS a test of another
binary (sync-canonical-doctrine.sh), so the canonical-cli surfaces had to
probe THAT downstream binary, not just the harness's own substrate:

  doctor.sync_binary_executable      — is the binary I'm here to test ready?
  validate sync-binary               — does it parse + carry the flags I depend on?
  validate fixture-state PATH        — does my TMP fixture have the layout
                                       my synthetic test sets up?

This pattern (test-surface validates its real downstream) reads better than
a generic harness check would, and means the surface stays useful as
sync-canonical-doctrine.sh itself evolves.

The other notable choice was AG5: the per-surface assertion fillin in
tests/test-sync-canonical-doctrine-canonical-cli.sh. Tests 14-21 add 8
concrete assertions:
  - 14/15: doctor concrete checks (≥6, includes load-bearing sync_binary)
  - 16:    health envelope concrete
  - 17:    repair --dry-run lists planned actions
  - 18:    repair --apply --idem-key actually mutates AND writes audit row
            (uses isolated TMP audit log — no global pollution per
            feedback_validator_uses_isolated_tmpdir doctrine 2026-05-08)
  - 19:    validate sync-binary contract envelope
  - 20:    audit row_count + recent
  - 21:    why numeric id provenance

The isolated TMP audit log in test 18 is load-bearing — without it, every
test run would append to the user's real $HOME/.local/state log. Cleanly
contained.

Pattern note for sister fillin beads: the daily-report-enabled-repos /
dispatch-author-contract-probe / mae86 / vc3zs / tfgt3 / now-zjm8v exemplar
chain is the canonical template. Add ~30 min per surface for the test-shape-
vs-canonical-cli rigor reconciliation; another ~10 min for per-surface test
assertions (test boundary widening from tfgt3-style single-file).
