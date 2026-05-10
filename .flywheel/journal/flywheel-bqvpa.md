---
bead_id: flywheel-bqvpa
task_id: flywheel-bqvpa-849095
worker_identity: MistyCliff
ts: 2026-05-10T17:35:00Z
mission_fitness: adjacent
commit_sha: pending
linked_incidents: []
linked_l_rules:
  - L52
  - L70
  - L107
  - L120
linked_skills:
  - canonical-cli-scoping
narrative_tags:
  - wgitr-fillin-chain-fifth-surface
  - validate-dispatch-draft-self-tests-against-real-packet
  - field-name-mapping-status-vs-verdict
---

Fifth wgitr-lane fillin (after vc3zs / tfgt3 / 39vhm / others in flight).
Same proven pattern: 6 substantive scaffold-stub subcommands + per-surface
--schema + topic_help + legacy-path ledger integration.

The interesting wrinkle was field-name mapping. The legacy lint emits
`{status, reason}` — not `{verdict, fail_reason}`. My initial `validate
dispatch-draft` handler read `.verdict` and got nothing useful. Fixed by
mapping `verdict ← legacy.status` and `fail_reason ← legacy.reason`. The
ledger-append at the end of the legacy path uses the same mapping so audit /
why see `verdict` and `fail_reason` fields consistently.

Doctor probes 11 substrate dimensions including 5 binary checks (ntm, br,
bv, flywheel-loop, bv-readiness-probe) — the binaries the lint actually
delegates to. That's the right dimensionality for this surface (it's an
orchestrator-discipline lint, so its deps are all orchestrator binaries).

The validate dispatch-draft handler self-tests against any real packet and
returned status:pass on this very dispatch (which lints clean — no question
shape, no data-backed deferral violation). Useful sanity check.

Pattern note: tfgt3 / zjm8v / s0c53 / bqvpa now form a 4-surface exemplar
chain for the wgitr fillin lane. ~30 min wall clock per surface, 920+/1000
quality bar, 0 followups when the legacy code carries the substantive logic
already and the scaffold layer just needs the canonical envelope shape.
